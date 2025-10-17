import 'package:flutter/foundation.dart';

@immutable
class LoginUiState{
  final String email;
  final String password;
  final bool isSubmitting;
  final bool success;
  final String? error;

  const LoginUiState({
    this.email = '',
    this.password = '',
    this.isSubmitting = false,
    this.success = false,
    this.error,
  });

  bool get canSubmit => email.isNotEmpty && password.length >= 6 && !isSubmitting;

  LoginUiState copyWith({
    String? email,
    String? password,
    bool? isSubmitting,
    bool? success,
    String? error,
  }) => LoginUiState(
    email: email ?? this.email,
    password: password ?? this.password,
    isSubmitting: isSubmitting ?? this.isSubmitting,
    success: success ?? this.success,
    error: error,
  );
}

@immutable
class RegisterUiState {
  final String name;
  final String surname;
  final String username;
  final bool? usernameAvailable;
  final String email;
  final String password;
  final String confirmPassword;
  final bool isSubmitting;
  final bool success;
  final String? error;

  const RegisterUiState({
    this.name = '',
    this.surname = '',
    this.username = '',
    this.usernameAvailable,
    this.email = '',
    this.password = '',
    this.confirmPassword = '',
    this.isSubmitting = false,
    this.success = false,
    this.error,
  });

  bool get passwordsMatch => password.isNotEmpty && password == confirmPassword;
  bool get canSubmit =>
      name.isNotEmpty &&
      surname.isNotEmpty &&
      username.isNotEmpty &&
      (usernameAvailable ?? false) &&
      email.isNotEmpty &&
      password.length >= 6 &&
      passwordsMatch &&
      !isSubmitting;

  RegisterUiState copyWith({
    String? name,
    String? surname,
    String? username,
    bool? usernameAvailable,
    String? email,
    String? password,
    String? confirmPassword,
    bool? isSubmitting,
    bool? success,
    String? error,
  }) => RegisterUiState(
    name: name ?? this.name,
    surname: surname ?? this.surname,
    username: username ?? this.username,
    usernameAvailable: usernameAvailable ?? this.usernameAvailable,
    email: email ?? this.email,
    password: password ?? this.password,
    confirmPassword: confirmPassword ?? this.confirmPassword,
    isSubmitting: isSubmitting ?? this.isSubmitting,
    success: success ?? this.success,
    error: error,
  );
}