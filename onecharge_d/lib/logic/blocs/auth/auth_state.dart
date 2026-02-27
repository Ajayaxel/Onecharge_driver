import 'package:equatable/equatable.dart';

abstract class AuthState extends Equatable {
  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class AuthLogoutLoading extends AuthState {}

class AuthAuthenticated extends AuthState {
  final String message;
  final Map<String, dynamic> userData;

  AuthAuthenticated({required this.message, required this.userData});

  @override
  List<Object?> get props => [message, userData];
}

class AuthError extends AuthState {
  final String message;

  AuthError({required this.message});

  @override
  List<Object?> get props => [message];
}

class AuthUnauthenticated extends AuthState {}
