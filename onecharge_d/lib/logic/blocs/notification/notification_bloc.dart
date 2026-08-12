import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/foundation.dart';

import '../../../core/network/api_service.dart';
import '../../../core/network/api_constants.dart';
import '../../../core/storage/auth_storage.dart';
import '../../../core/services/notification_service.dart';
import 'notification_event.dart';
import 'notification_state.dart';

class NotificationBloc extends Bloc<NotificationEvent, NotificationState> {
  final ApiService _apiService;
  final NotificationService _notificationService = NotificationService();

  NotificationBloc(this._apiService) : super(NotificationInitial()) {
    on<InitializeNotifications>(_onInitialize);
    on<UpdateFcmToken>(_onUpdateToken);
  }

  Future<void> _onInitialize(
    InitializeNotifications event,
    Emitter<NotificationState> emit,
  ) async {
    try {
      // NotificationService handles the device-side setup (permissions, foreground messages, etc.)
      await _notificationService.initialize();

      final token = await _notificationService.getToken();
      if (token != null) {
        add(UpdateFcmToken(token));
      }

      emit(NotificationActive(token: token));
    } catch (e) {
      emit(NotificationError("Failed to initialize notifications: $e"));
    }
  }

  Future<void> _onUpdateToken(
    UpdateFcmToken event,
    Emitter<NotificationState> emit,
  ) async {
    print('🚀 [FCM TOKEN]: ${event.token}');
    try {
      final authToken = await AuthStorage.getToken();
      if (authToken == null) {
        print('🔔 [NotificationBloc] No auth token found.');
        return;
      }

      final deviceType = defaultTargetPlatform == TargetPlatform.iOS
          ? 'ios'
          : 'android';

      // Calling the API explicitly using the BLoC as requested
      final response = await _apiService.post(ApiConstants.saveFcmToken, {
        'fcm_token': event.token,
        'device_type': deviceType,
      }, token: authToken);

      if (response.statusCode == 200) {
        print(
          '🔔 [NotificationBloc] Token registered with backend successfully ✅',
        );
      } else {
        print(
          '🔔 [NotificationBloc] Failed to register token: ${response.statusCode} ${response.body}',
        );
      }
    } catch (e) {
      print('🔔 [NotificationBloc] Error registering token: $e');
    }
  }
}
