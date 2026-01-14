import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:onecharge_d/core/models/driver.dart';
import 'package:onecharge_d/core/models/password_update_request.dart';
import 'package:onecharge_d/core/repository/auth_repository.dart';
import 'package:onecharge_d/core/services/background_location_service.dart';
import 'package:onecharge_d/core/services/ticket_polling_service.dart';
import 'package:onecharge_d/core/storage/token_storage.dart';
import 'package:onecharge_d/presentation/profile/bloc/profile_event.dart';
import 'package:onecharge_d/presentation/profile/bloc/profile_state.dart';

class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  final AuthRepository authRepository;

  ProfileBloc({required this.authRepository}) : super(ProfileInitial()) {
    on<FetchDriverProfile>(_onFetchDriverProfile);
    on<LogoutDriver>(_onLogoutDriver);
    on<UpdatePassword>(_onUpdatePassword);
  }

  Future<void> _onFetchDriverProfile(
    FetchDriverProfile event,
    Emitter<ProfileState> emit,
  ) async {
    print('\n🔄 [BLOC EVENT] FetchDriverProfile');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    emit(ProfileLoading());
    print('📤 [STATE] ProfileLoading');

    try {
      final response = await authRepository.getDriverProfile();

      if (response.success && response.driver != null) {
        emit(ProfileLoaded(driver: response.driver!));
        print('📤 [STATE] ProfileLoaded');
        print('  👤 Driver ID: ${response.driver!.id}');
        print('  📛 Name: ${response.driver!.name}');
        print('  📧 Email: ${response.driver!.email}');
        print('  📞 Phone: ${response.driver!.phone}');
        print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');
      } else {
        emit(ProfileError(
          message: response.message ?? 'Failed to fetch driver profile',
        ));
        print('📤 [STATE] ProfileError: ${response.message}');
        print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');
      }
    } catch (e) {
      emit(ProfileError(message: 'An unexpected error occurred: ${e.toString()}'));
      print('❌ [EXCEPTION] ${e.toString()}');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');
    }
  }

  Future<void> _onLogoutDriver(
    LogoutDriver event,
    Emitter<ProfileState> emit,
  ) async {
    print('\n🔄 [BLOC EVENT] LogoutDriver');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    emit(LogoutLoading());
    print('📤 [STATE] LogoutLoading');

    // Stop background services before logout
    BackgroundLocationService().stop();
    TicketPollingService().stop();
    print('🛑 Stopped background location and ticket polling services');

    try {
      final response = await authRepository.logout();

      if (response.success) {
        // Clear local storage
        await TokenStorage.clearAll();
        
        emit(LogoutSuccess(
          message: response.message ?? 'Logged out successfully',
        ));
        print('📤 [STATE] LogoutSuccess: ${response.message}');
        print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');
      } else {
        emit(LogoutError(
          message: response.message ?? 'Failed to logout',
        ));
        print('📤 [STATE] LogoutError: ${response.message}');
        print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');
      }
    } catch (e) {
      // Even if API call fails, clear local storage
      await TokenStorage.clearAll();
      
      emit(LogoutSuccess(
        message: 'Logged out locally',
      ));
      print('⚠️ [EXCEPTION] ${e.toString()} - Cleared local storage');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');
    }
  }

  Future<void> _onUpdatePassword(
    UpdatePassword event,
    Emitter<ProfileState> emit,
  ) async {
    print('\n🔄 [BLOC EVENT] UpdatePassword');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    
    // Preserve the current driver profile if available
    Driver? currentDriver;
    if (state is ProfileLoaded) {
      currentDriver = (state as ProfileLoaded).driver;
    } else if (state is UpdatePasswordSuccess) {
      currentDriver = (state as UpdatePasswordSuccess).driver;
    } else if (state is UpdatePasswordError) {
      currentDriver = (state as UpdatePasswordError).driver;
    } else if (state is UpdatePasswordLoading) {
      currentDriver = (state as UpdatePasswordLoading).driver;
    }
    
    emit(UpdatePasswordLoading(driver: currentDriver));
    print('📤 [STATE] UpdatePasswordLoading');

    try {
      final request = PasswordUpdateRequest(
        currentPassword: event.currentPassword,
        password: event.newPassword,
        passwordConfirmation: event.passwordConfirmation,
      );

      final response = await authRepository.updatePassword(request);

      if (response.success) {
        emit(UpdatePasswordSuccess(
          message: response.message ?? 'Password updated successfully',
          driver: currentDriver,
        ));
        print('📤 [STATE] UpdatePasswordSuccess: ${response.message}');
        print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');
        
        // Re-fetch profile to ensure we have the latest data and return to ProfileLoaded state
        // Small delay to allow the success message to be shown
        await Future.delayed(const Duration(milliseconds: 500));
        final profileResponse = await authRepository.getDriverProfile();
        if (profileResponse.success && profileResponse.driver != null) {
          emit(ProfileLoaded(driver: profileResponse.driver!));
          print('📤 [STATE] ProfileLoaded (after password update)');
          print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');
        } else {
          // If re-fetch fails but we have driver data, keep showing it
          if (currentDriver != null) {
            emit(ProfileLoaded(driver: currentDriver));
            print('📤 [STATE] ProfileLoaded (using cached driver data)');
            print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');
          }
        }
      } else {
        // Convert API errors to field errors map
        Map<String, String>? fieldErrors;
        if (response.errors != null) {
          fieldErrors = <String, String>{};
          response.errors!.forEach((key, value) {
            if (value.isNotEmpty) {
              // Map API field names to UI field names
              String uiFieldName = key;
              if (key == 'current_password') {
                uiFieldName = 'currentPassword';
              } else if (key == 'password') {
                uiFieldName = 'newPassword';
              } else if (key == 'password_confirmation') {
                uiFieldName = 'confirmPassword';
              }
              fieldErrors![uiFieldName] = value.first;
            }
          });
        }
        
        emit(UpdatePasswordError(
          message: response.message ?? 'Failed to update password',
          driver: currentDriver,
          fieldErrors: fieldErrors,
        ));
        print('📤 [STATE] UpdatePasswordError: ${response.message}');
        if (fieldErrors != null) {
          print('  📋 Field Errors: $fieldErrors');
        }
        print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');
      }
    } catch (e) {
      emit(UpdatePasswordError(
        message: 'An unexpected error occurred: ${e.toString()}',
        driver: currentDriver,
      ));
      print('❌ [EXCEPTION] ${e.toString()}');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');
    }
  }
}

