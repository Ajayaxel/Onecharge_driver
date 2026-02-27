import 'dart:convert';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/network/api_service.dart';
import '../../../core/network/api_constants.dart';
import '../../../core/storage/auth_storage.dart';
import '../../../core/network/reverb_service.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final ApiService _apiService;

  AuthBloc(this._apiService) : super(AuthInitial()) {
    on<LoginRequested>(_onLoginRequested);
    on<LogoutRequested>(_onLogoutRequested);
    on<AppStarted>(_onAppStarted);
  }

  Future<void> _onLoginRequested(
    LoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());

    try {
      final response = await _apiService.post(ApiConstants.login, {
        'email': event.email,
        'password': event.password,
      });

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        final token = data['data']['token'];
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

        await AuthStorage.saveToken(token);
        await AuthStorage.saveUserData(jsonEncode(driverData));

        emit(
          AuthAuthenticated(
            message: data['message'] ?? 'Login successful',
            userData: driverData,
          ),
        );
      } else {
        emit(AuthError(message: data['message'] ?? 'Login failed'));
      }
    } catch (e) {
      emit(AuthError(message: 'Network error occurred. Please try again.'));
    }
  }

  Future<void> _onLogoutRequested(
    LogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLogoutLoading());
    try {
      final token = await AuthStorage.getToken();
      if (token != null) {
        // Call logout API (optional: check response, but we usually logout locally anyway)
        await _apiService.post(ApiConstants.logout, {}, token: token);
      }
    } catch (e) {
      // Log error if needed, but proceed to clear local data
    } finally {
      ReverbService().disconnect();
      await AuthStorage.clearAuth();
      emit(AuthUnauthenticated());
    }
  }

  Future<void> _onAppStarted(AppStarted event, Emitter<AuthState> emit) async {
    final token = await AuthStorage.getToken();
    final userData = await AuthStorage.getUserData();

    if (token != null && userData != null) {
      emit(
        AuthAuthenticated(
          message: 'Welcome back!',
          userData: jsonDecode(userData),
        ),
      );
    } else {
      emit(AuthUnauthenticated());
    }
  }
}
