part of 'auth_bloc.dart';

enum AuthStatus { initial, loading, authenticated, unauthenticated, failure }

class AuthState extends Equatable {
  const AuthState({
    this.status = AuthStatus.initial,
    this.rememberMe = false,
    this.email = '',
    this.errorMessage,
  });

  final AuthStatus status;
  final bool rememberMe;
  final String email;
  final String? errorMessage;

  AuthState copyWith({
    AuthStatus? status,
    bool? rememberMe,
    String? email,
    String? errorMessage,
  }) {
    return AuthState(
      status: status ?? this.status,
      rememberMe: rememberMe ?? this.rememberMe,
      email: email ?? this.email,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, rememberMe, email, errorMessage];
}
