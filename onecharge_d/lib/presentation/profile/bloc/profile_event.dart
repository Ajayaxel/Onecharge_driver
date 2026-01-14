import 'package:equatable/equatable.dart';

abstract class ProfileEvent extends Equatable {
  const ProfileEvent();

  @override
  List<Object> get props => [];
}

class FetchDriverProfile extends ProfileEvent {
  const FetchDriverProfile();
}

class LogoutDriver extends ProfileEvent {
  const LogoutDriver();
}

class UpdatePassword extends ProfileEvent {
  final String currentPassword;
  final String newPassword;
  final String passwordConfirmation;

  const UpdatePassword({
    required this.currentPassword,
    required this.newPassword,
    required this.passwordConfirmation,
  });

  @override
  List<Object> get props => [currentPassword, newPassword, passwordConfirmation];
}

