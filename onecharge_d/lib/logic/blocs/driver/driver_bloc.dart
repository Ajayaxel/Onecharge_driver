import 'dart:convert';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/network/api_service.dart';
import '../../../core/network/api_constants.dart';
import '../../../core/storage/auth_storage.dart';
import 'driver_event.dart';
import 'driver_state.dart';

class DriverBloc extends Bloc<DriverEvent, DriverState> {
  final ApiService _apiService;

  DriverBloc(this._apiService) : super(DriverInitial()) {
    on<FetchDriverProfile>(_onFetchDriverProfile);
    on<UpdateDriverLocal>(_onUpdateDriverLocal);
  }

  Future<void> _onFetchDriverProfile(
    FetchDriverProfile event,
    Emitter<DriverState> emit,
  ) async {
    // Fresh fetch even if data exists locally
    try {
      final token = await AuthStorage.getToken();
      if (token == null) {
        emit(DriverError('Authentication token not found'));
        return;
      }

      final response = await _apiService.get(
        ApiConstants.getProfile,
        token: token,
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        Map<String, dynamic> driverData = Map<String, dynamic>.from(
          data['data']['driver'],
        );

        // Ensure absolute URL
        String? profileImage = driverData['profile_image'];
        if (profileImage != null &&
            profileImage.isNotEmpty &&
            !profileImage.startsWith('http')) {
          driverData['profile_image'] = '${ApiConstants.baseUrl}$profileImage';
        }

        await AuthStorage.saveUserData(jsonEncode(driverData));
        emit(DriverLoaded(driverData));
      } else {
        if (state is! DriverLoaded) {
          emit(
            DriverError(data['message'] ?? 'Failed to fetch driver details'),
          );
        }
      }
    } catch (e) {
      if (state is! DriverLoaded) {
        emit(DriverError('Network error. Please check your connection.'));
      }
    }
  }

  void _onUpdateDriverLocal(
    UpdateDriverLocal event,
    Emitter<DriverState> emit,
  ) {
    emit(DriverLoaded(event.driverData));
  }
}
