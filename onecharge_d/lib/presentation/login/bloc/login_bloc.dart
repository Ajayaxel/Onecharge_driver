import 'dart:convert';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:onecharge_d/core/models/login_request.dart';
import 'package:onecharge_d/core/repository/auth_repository.dart';
import 'package:onecharge_d/core/storage/token_storage.dart';
import 'package:onecharge_d/presentation/login/bloc/login_event.dart';
import 'package:onecharge_d/presentation/login/bloc/login_state.dart';

class LoginBloc extends Bloc<LoginEvent, LoginState> {
  final AuthRepository authRepository;

  LoginBloc({required this.authRepository}) : super(LoginInitial()) {
    on<LoginSubmitted>(_onLoginSubmitted);
  }

  Future<void> _onLoginSubmitted(
    LoginSubmitted event,
    Emitter<LoginState> emit,
  ) async {
    emit(LoginLoading());

    try {
      final request = LoginRequest(
        email: event.email,
        password: event.password,
      );

      final response = await authRepository.login(request);

      if (response.success && response.token != null && response.driver != null) {
        // Store token and driver data
        await TokenStorage.saveToken(response.token!);
        await TokenStorage.saveDriverData(
          jsonEncode(response.driver!.toJson()),
        );

        emit(LoginSuccess(
          message: response.message,
          token: response.token!,
          driver: response.driver!,
        ));
      } else {
        emit(LoginFailure(message: response.message));
      }
    } catch (e) {
      emit(LoginFailure(message: 'An unexpected error occurred: ${e.toString()}'));
    }
  }
}
