import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:onecharge_d/core/repository/location_repository.dart';
import 'package:onecharge_d/core/storage/token_storage.dart';
import 'package:onecharge_d/core/utils/location_service.dart';

/// Background location service that continuously updates driver location
/// This service runs automatically when driver is logged in and has selected a vehicle
class BackgroundLocationService {
  static final BackgroundLocationService _instance = BackgroundLocationService._internal();
  factory BackgroundLocationService() => _instance;
  BackgroundLocationService._internal();

  final LocationService _locationService = LocationService();
  final LocationRepository _locationRepository = LocationRepository();
  
  Timer? _locationUpdateTimer;
  StreamSubscription<Position>? _locationStreamSubscription;
  bool _isRunning = false;
  bool _hasPermission = false;
  
  // Stream controller for location updates (for map display)
  final StreamController<Position> _locationStreamController = StreamController<Position>.broadcast();
  
  /// Stream of location updates - can be listened to by map screens
  Stream<Position> get locationStream => _locationStreamController.stream;
  
  /// Current position (last known location)
  Position? _currentPosition;
  Position? get currentPosition => _currentPosition;

  /// Check if service is currently running
  bool get isRunning => _isRunning;

  /// Start background location tracking
  /// Updates location every 30 seconds (as per API documentation recommendation)
  Future<bool> start() async {
    if (_isRunning) {
      print('📍 Background location service is already running');
      return true;
    }

    print('\n🚀 [BACKGROUND LOCATION] Starting service...');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

    // Check if driver is logged in
    final isLoggedIn = await TokenStorage.isLoggedIn();
    if (!isLoggedIn) {
      print('❌ Driver is not logged in. Cannot start location tracking.');
      return false;
    }

    // Request location permission
    _hasPermission = await _locationService.requestLocationPermission();
    if (!_hasPermission) {
      print('❌ Location permission denied. Cannot start location tracking.');
      return false;
    }

    // Get initial location and update to server
    final initialPosition = await _locationService.getCurrentLocation();
    if (initialPosition != null) {
      _currentPosition = initialPosition;
      
      // Broadcast initial location to listeners
      if (!_locationStreamController.isClosed) {
        _locationStreamController.add(initialPosition);
      }
      
      await _updateLocationToServer(
        initialPosition.latitude,
        initialPosition.longitude,
      );
    } else {
      print('⚠️ Could not get initial location. Will retry on next update.');
    }

    // Start periodic location updates (every 30 seconds)
    _locationUpdateTimer = Timer.periodic(
      const Duration(seconds: 30),
      (timer) async {
        await _updateLocationPeriodically();
      },
    );

    // Also listen to location stream for more frequent updates when moving
    _locationStreamSubscription = _locationService.getLocationStream().listen(
      (position) {
        // Update current position
        _currentPosition = position;
        
        // Broadcast to listeners (for map updates)
        if (!_locationStreamController.isClosed) {
          _locationStreamController.add(position);
        }
        
        // Update location when significant movement detected (every 10 meters)
        _updateLocationToServer(position.latitude, position.longitude);
      },
      onError: (error) {
        print('❌ Location stream error: $error');
      },
    );

    _isRunning = true;
    print('✅ Background location service started successfully');
    print('   - Updates every 30 seconds');
    print('   - Stream updates on movement (10m threshold)');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');

    return true;
  }

  /// Stop background location tracking
  void stop() {
    if (!_isRunning) {
      return;
    }

    print('\n🛑 [BACKGROUND LOCATION] Stopping service...');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

    _locationUpdateTimer?.cancel();
    _locationUpdateTimer = null;

    _locationStreamSubscription?.cancel();
    _locationStreamSubscription = null;

    _isRunning = false;
    print('✅ Background location service stopped');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');
  }
  
  /// Close the location stream controller (called on app termination)
  void dispose() {
    _locationStreamController.close();
  }

  /// Update location periodically
  Future<void> _updateLocationPeriodically() async {
    if (!_isRunning) {
      return;
    }

    // Check if still logged in
    final isLoggedIn = await TokenStorage.isLoggedIn();
    if (!isLoggedIn) {
      print('⚠️ Driver logged out. Stopping location tracking.');
      stop();
      return;
    }

    final position = await _locationService.getCurrentLocation();
    if (position != null) {
      _currentPosition = position;
      
      // Broadcast to listeners (for map updates)
      if (!_locationStreamController.isClosed) {
        _locationStreamController.add(position);
      }
      
      await _updateLocationToServer(position.latitude, position.longitude);
    } else {
      print('⚠️ Could not get location for periodic update');
    }
  }

  /// Update location to server
  Future<void> _updateLocationToServer(double latitude, double longitude) async {
    try {
      final response = await _locationRepository.updateLocation(
        latitude: latitude,
        longitude: longitude,
      );

      if (response.success) {
        print('✅ [BACKGROUND] Location updated: $latitude, $longitude');
      } else {
        print('❌ [BACKGROUND] Failed to update location: ${response.message}');
      }
    } catch (e) {
      print('❌ [BACKGROUND] Error updating location: $e');
    }
  }

  /// Restart the service (useful after re-authentication)
  Future<bool> restart() async {
    stop();
    await Future.delayed(const Duration(milliseconds: 500));
    return await start();
  }
}

