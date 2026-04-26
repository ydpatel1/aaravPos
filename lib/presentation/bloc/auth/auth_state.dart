part of 'auth_bloc.dart';

enum AuthStatus {
  initial,
  outletLoading,
  loading,
  authenticated,
  unauthenticated,
  failure,
}

class AuthState extends Equatable {
  const AuthState({
    this.status = AuthStatus.initial,
    this.rememberMe = false,
    this.email = '',
    this.password = '',
    this.isPasswordVisible = false,
    this.errorMessage,
  });

  final AuthStatus status;
  final bool rememberMe;
  final String email;
  final String password;
  final bool isPasswordVisible;
  final String? errorMessage;

  AuthState copyWith({
    AuthStatus? status,
    bool? rememberMe,
    String? email,
    String? password,
    bool? isPasswordVisible,
    String? errorMessage,
  }) {
    return AuthState(
      status: status ?? this.status,
      rememberMe: rememberMe ?? this.rememberMe,
      email: email ?? this.email,
      password: password ?? this.password,
      isPasswordVisible: isPasswordVisible ?? this.isPasswordVisible,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
    status,
    rememberMe,
    email,
    isPasswordVisible,
    errorMessage,
  ];
}
