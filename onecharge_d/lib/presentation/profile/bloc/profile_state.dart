import 'package:equatable/equatable.dart';
import 'package:onecharge_d/core/models/driver.dart';

abstract class ProfileState extends Equatable {
  const ProfileState();

  @override
  List<Object?> get props => [];
}

class ProfileInitial extends ProfileState {}

class ProfileLoading extends ProfileState {}

class ProfileLoaded extends ProfileState {
  final Driver driver;

  const ProfileLoaded({required this.driver});

  @override
  List<Object> get props => [driver];
}

class ProfileError extends ProfileState {
  final String message;

  const ProfileError({required this.message});

  @override
  List<Object> get props => [message];
}

class LogoutLoading extends ProfileState {}

class LogoutSuccess extends ProfileState {
  final String message;

  const LogoutSuccess({required this.message});

  @override
  List<Object> get props => [message];
}

class LogoutError extends ProfileState {
  final String message;

  const LogoutError({required this.message});

  @override
  List<Object> get props => [message];
}

class UpdatePasswordLoading extends ProfileState {
  final Driver? driver;

  const UpdatePasswordLoading({this.driver});

  @override
  List<Object?> get props => [driver];
}

class UpdatePasswordSuccess extends ProfileState {
  final String message;
  final Driver? driver;

  const UpdatePasswordSuccess({required this.message, this.driver});

  @override
  List<Object?> get props => [message, driver];
}

class UpdatePasswordError extends ProfileState {
  final String message;
  final Driver? driver;
  final Map<String, String>? fieldErrors;

  const UpdatePasswordError({
    required this.message,
    this.driver,
    this.fieldErrors,
  });

  @override
  List<Object?> get props => [message, driver, fieldErrors];
}

