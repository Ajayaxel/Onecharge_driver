import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:onecharge_d/core/network/api_service.dart';
import 'package:onecharge_d/core/network/api_constants.dart';
import 'package:onecharge_d/core/storage/auth_storage.dart';
import 'package:onecharge_d/data/models/vehicle_model.dart';

// ── Global timeout for all vehicle API calls ───────────────────────────────
const Duration _kApiTimeout = Duration(seconds: 45);

/// Result of a vehicle-list page fetch.
class VehicleListResult {
  final List<VehicleModel> vehicles;
  final int totalCount;
  final int currentPage;
  final int lastPage;

  const VehicleListResult({
    required this.vehicles,
    required this.totalCount,
    required this.currentPage,
    required this.lastPage,
  });

  bool get hasMore => currentPage < lastPage;
}

/// Unified repository for all vehicle API calls with in-memory caching.
///
/// Cache rules:
/// - Vehicles list: cached per-page (page 1 cache invalidated on refresh)
/// - Current vehicle: cached until explicit refresh
class VehicleRepository {
  final ApiService _api;

  VehicleRepository(this._api);

  // ─── In-memory cache ───────────────────────────────────────────────────────
  final Map<int, List<VehicleModel>> _pageCache = {};
  int? _cachedTotalCount;
  int? _cachedLastPage;
  VehicleModel? _cachedCurrentVehicle;
  bool _currentVehicleCached = false; // distinguish null-vehicle from uncached
  // In-flight dedup: prevents parallel concurrent fetchCurrentVehicle calls
  Future<VehicleModel?>? _currentVehicleInFlight;

  // ─── Cache control ─────────────────────────────────────────────────────────

  /// Clears list cache so the next [fetchPage] goes to network.
  void invalidateListCache() {
    _pageCache.clear();
    _cachedTotalCount = null;
    _cachedLastPage = null;
  }

  /// Clears current-vehicle cache.
  void invalidateCurrentVehicleCache() {
    _currentVehicleCached = false;
    _cachedCurrentVehicle = null;
  }

  /// Clears all caches (e.g. on logout).
  void clearAll() {
    invalidateListCache();
    invalidateCurrentVehicleCache();
  }

  // ─── Vehicles list ─────────────────────────────────────────────────────────

  /// Fetches [page] of the vehicles list.
  ///
  /// Returns cached data immediately if available (avoids re-fetch on
  /// back-navigation). Pass [forceRefresh] to bypass cache for page 1.
  Future<VehicleListResult> fetchPage(
    int page, {
    bool forceRefresh = false,
  }) async {
    // Return from cache if available and not forced refresh
    if (!forceRefresh && _pageCache.containsKey(page)) {
      return VehicleListResult(
        vehicles: _pageCache[page]!,
        totalCount: _cachedTotalCount ?? _pageCache[page]!.length,
        currentPage: page,
        lastPage: _cachedLastPage ?? page,
      );
    }

    final token = await AuthStorage.getToken();
    if (token == null) throw Exception('Authentication token not found');

    // First try paginated endpoint
    try {
      final res = await _api
          .get('${ApiConstants.getVehicles}?page=$page&limit=10', token: token)
          .timeout(_kApiTimeout);
      final decoded = jsonDecode(res.body) as Map<String, dynamic>;

      if (res.statusCode == 200 && decoded['success'] == true) {
        final data = decoded['data'] as Map<String, dynamic>;
        final result = VehiclePageResponse.fromJson(data);

        // Store in cache
        _pageCache[page] = result.vehicles;
        _cachedTotalCount = result.totalCount;
        _cachedLastPage = result.lastPage;

        return VehicleListResult(
          vehicles: result.vehicles,
          totalCount: result.totalCount,
          currentPage: result.currentPage,
          lastPage: result.lastPage,
        );
      } else {
        throw Exception(
          decoded['message'] as String? ?? 'Failed to fetch vehicles',
        );
      }
    } catch (_) {
      // Fallback to non-paginated endpoint (API might not support ?page=)
      if (page == 1) {
        return _fetchLegacy(token);
      }
      rethrow;
    }
  }

  /// Legacy (non-paginated) fetch — returns all vehicles as page 1.
  Future<VehicleListResult> _fetchLegacy(String token) async {
    final res = await _api
        .get(ApiConstants.getVehicles, token: token)
        .timeout(_kApiTimeout);
    final decoded = jsonDecode(res.body) as Map<String, dynamic>;

    if (res.statusCode == 200 && decoded['success'] == true) {
      final rawList = decoded['data']['vehicles'] as List<dynamic>? ?? [];
      final vehicles = rawList
          .map((j) => VehicleModel.fromJson(j as Map<String, dynamic>))
          .toList();

      _pageCache[1] = vehicles;
      _cachedTotalCount = vehicles.length;
      _cachedLastPage = 1;

      return VehicleListResult(
        vehicles: vehicles,
        totalCount: vehicles.length,
        currentPage: 1,
        lastPage: 1,
      );
    } else {
      throw Exception(
        decoded['message'] as String? ?? 'Failed to fetch vehicles',
      );
    }
  }

  // ─── Current vehicle ───────────────────────────────────────────────────────

  /// Returns the currently active vehicle for this driver.
  /// Returns [null] if no vehicle is active.
  Future<VehicleModel?> fetchCurrentVehicle({bool forceRefresh = false}) async {
    if (!forceRefresh && _currentVehicleCached) {
      return _cachedCurrentVehicle;
    }

    // Dedup: if a fetch is already in flight, reuse it
    if (_currentVehicleInFlight != null) return _currentVehicleInFlight!;

    _currentVehicleInFlight = _doFetchCurrentVehicle();
    try {
      return await _currentVehicleInFlight!;
    } finally {
      _currentVehicleInFlight = null;
    }
  }

  Future<VehicleModel?> _doFetchCurrentVehicle() async {
    final token = await AuthStorage.getToken();
    if (token == null) throw Exception('Authentication token not found');

    final res = await _api
        .get(ApiConstants.getCurrentVehicle, token: token)
        .timeout(_kApiTimeout);
    final decoded = jsonDecode(res.body) as Map<String, dynamic>;

    if (res.statusCode == 200 && decoded['success'] == true) {
      final vehicleJson = decoded['data']?['vehicle'];
      final vehicle = vehicleJson != null
          ? VehicleModel.fromJson(vehicleJson as Map<String, dynamic>)
          : null;
      _cachedCurrentVehicle = vehicle;
      _currentVehicleCached = true;
      return vehicle;
    } else {
      throw Exception(
        decoded['message'] as String? ?? 'Failed to fetch current vehicle',
      );
    }
  }

  // ─── Select / drop-off ─────────────────────────────────────────────────────

  Future<String> selectVehicle(int vehicleId) async {
    final token = await AuthStorage.getToken();
    if (token == null) throw Exception('Authentication token not found');

    final res = await _api
        .post(ApiConstants.selectVehicle(vehicleId), {}, token: token)
        .timeout(_kApiTimeout);
    final decoded = jsonDecode(res.body) as Map<String, dynamic>;

    if (res.statusCode == 200 && decoded['success'] == true) {
      // Invalidate current vehicle cache so next fetch is fresh
      invalidateCurrentVehicleCache();
      return decoded['message'] as String? ?? 'Vehicle selected successfully';
    } else {
      throw Exception(
        decoded['message'] as String? ?? 'Failed to select vehicle',
      );
    }
  }

  Future<String> dropOffVehicle(
    int vehicleId, {
    required double latitude,
    required double longitude,
    required List<String> imagePaths,
  }) async {
    final token = await AuthStorage.getToken();
    if (token == null) throw Exception('Authentication token not found');

    // Build fields
    final fields = <String, String>{
      'latitude': latitude.toString(),
      'longitude': longitude.toString(),
    };

    // Side labels matching the API contract
    const sides = ['front', 'back', 'left', 'right', 'top', 'bottom'];

    // Build multipart files
    final files = <http.MultipartFile>[];
    for (int i = 0; i < imagePaths.length; i++) {
      final file = File(imagePaths[i]);
      final multipartFile = await http.MultipartFile.fromPath(
        'images[$i]',
        file.path,
      );
      files.add(multipartFile);
      fields['sides[$i]'] = sides[i];
    }

    final res = await _api
        .postMultipart(
          ApiConstants.dropOffVehicle(vehicleId),
          fields,
          files,
          token: token,
        )
        .timeout(_kApiTimeout);

    final decoded = jsonDecode(res.body) as Map<String, dynamic>;

    if (res.statusCode == 200 && decoded['success'] == true) {
      invalidateCurrentVehicleCache();
      invalidateListCache();
      return decoded['message'] as String? ??
          'Vehicle dropped off successfully';
    } else {
      throw Exception(
        decoded['message'] as String? ?? 'Failed to drop off vehicle',
      );
    }
  }

  /// Finds a vehicle in page-1 cache by id (used after select to get model).
  VehicleModel? findCachedVehicleById(int id) {
    for (final page in _pageCache.values) {
      try {
        return page.firstWhere((v) => v.id == id);
      } catch (_) {}
    }
    return null;
  }
}
