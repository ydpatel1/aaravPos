import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/auth_repository.dart';

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

class AuthBloc extends Cubit<AuthState> {
  AuthBloc(this._authRepository) : super(const AuthState());

  final AuthRepository _authRepository;

  Future<void> initialize() async {
    final rememberMe = await _authRepository.getRememberMe();
    final email = rememberMe ? await _authRepository.getRememberedEmail() ?? '' : '';
    emit(state.copyWith(rememberMe: rememberMe, email: email));
  }

  void setRememberMe(bool value) {
    emit(state.copyWith(rememberMe: value));
  }

  Future<void> login({required String email, required String password}) async {
    emit(state.copyWith(status: AuthStatus.loading, errorMessage: null));
    try {
      await _authRepository.login(
        email: email,
        password: password,
        rememberMe: state.rememberMe,
      );
      emit(state.copyWith(status: AuthStatus.authenticated, email: email));
    } catch (_) {
      emit(
        state.copyWith(
          status: AuthStatus.failure,
          errorMessage: 'Unable to login. Please try again.',
        ),
      );
    }
  }

  Future<void> logout() async {
    await _authRepository.logout();
    emit(state.copyWith(status: AuthStatus.unauthenticated));
  }
}
