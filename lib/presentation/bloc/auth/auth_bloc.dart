import 'package:aaravpos/domain/repo/auth_repository.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc(this._authRepository) : super(const AuthState()) {
    on<AuthInitialized>(_onInitialized);
    on<RememberMeChanged>(_onRememberMeChanged);
    on<AuthLoginRequested>(_onLoginRequested);
    on<AuthLogoutRequested>(_onLogoutRequested);
  }

  final AuthRepository _authRepository;

  Future<void> _onInitialized(
    AuthInitialized event,
    Emitter<AuthState> emit,
  ) async {
    final rememberMe = await _authRepository.getRememberMe();
    final email = rememberMe
        ? await _authRepository.getRememberedEmail() ?? ''
        : '';
    emit(state.copyWith(rememberMe: rememberMe, email: email));
  }

  void _onRememberMeChanged(RememberMeChanged event, Emitter<AuthState> emit) {
    emit(state.copyWith(rememberMe: event.value));
  }

  Future<void> _onLoginRequested(
    AuthLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(status: AuthStatus.loading, errorMessage: null));
    try {
      await _authRepository.login(
        email: event.email,
        password: event.password,
        rememberMe: state.rememberMe,
      );
      emit(
        state.copyWith(status: AuthStatus.authenticated, email: event.email),
      );
    } catch (_) {
      emit(
        state.copyWith(
          status: AuthStatus.failure,
          errorMessage: 'Unable to login. Please try again.',
        ),
      );
    }
  }

  Future<void> _onLogoutRequested(
    AuthLogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    await _authRepository.logout();
    emit(state.copyWith(status: AuthStatus.unauthenticated));
  }

  // Compatibility helpers for existing UI calls.
  Future<void> initialize() async => add(const AuthInitialized());

  void setRememberMe(bool value) => add(RememberMeChanged(value));

  Future<void> login({required String email, required String password}) async {
    add(AuthLoginRequested(email: email, password: password));
  }

  Future<void> logout() async => add(const AuthLogoutRequested());
}
