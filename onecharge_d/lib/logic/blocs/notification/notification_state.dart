abstract class NotificationState {}

class NotificationInitial extends NotificationState {}

class NotificationPending extends NotificationState {}

class NotificationActive extends NotificationState {
  final String? token;
  NotificationActive({this.token});
}

class NotificationError extends NotificationState {
  final String message;
  NotificationError(this.message);
}
