import 'package:equatable/equatable.dart';
import 'package:onecharge_d/core/models/driver.dart';

abstract class LoginState extends Equatable {
  const LoginState();

  @override
  List<Object> get props => [];
}

class LoginInitial extends LoginState {}

class LoginLoading extends LoginState {}

class LoginSuccess extends LoginState {
  final String message;
  final String token;
  final Driver driver;

  const LoginSuccess({
    required this.message,
    required this.token,
    required this.driver,
  });

  @override
  List<Object> get props => [message, token, driver];
}

class LoginFailure extends LoginState {
  final String message;

  const LoginFailure({required this.message});

  @override
  List<Object> get props => [message];
}
