abstract class NotificationEvent {}

class InitializeNotifications extends NotificationEvent {}

class UpdateFcmToken extends NotificationEvent {
  final String token;
  UpdateFcmToken(this.token);
}

class NotificationTapped extends NotificationEvent {
  final Map<String, dynamic> data;
  NotificationTapped(this.data);
}
