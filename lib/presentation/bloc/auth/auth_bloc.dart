import 'package:aaravpos/domain/repo/auth_repository.dart';
import 'package:aaravpos/presentation/bloc/session/session_bloc.dart';
import 'package:dio/dio.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc(this._authRepository, this._sessionBloc) : super(const AuthState()) {
    on<AuthInitialized>(_onInitialized);
    on<RememberMeChanged>(_onRememberMeChanged);
    on<AuthLoginRequested>(_onLoginRequested);
    on<AuthLogoutRequested>(_onLogoutRequested);
    on<PasswordVisibilityToggled>(_onPasswordVisibilityToggled);
  }

  final AuthRepository _authRepository;
  final SessionBloc _sessionBloc;

  Future<void> _onInitialized(
    AuthInitialized event,
    Emitter<AuthState> emit,
  ) async {
    final rememberMe = await _authRepository.getRememberMe();
    final email = rememberMe
        ? await _authRepository.getRememberedEmail() ?? ''
        : '';
    final password = rememberMe
        ? await _authRepository.getRememberedPassword() ?? ''
        : '';
    emit(
      state.copyWith(rememberMe: rememberMe, email: email, password: password),
    );
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
      // Login — stores token, tenantId, outletId in secure storage
      await _authRepository.login(
        email: event.email,
        password: event.password,
        rememberMe: state.rememberMe,
      );

      // Fetch outlet open/close status and push to SessionBloc
      try {
        final outletStatus = await _authRepository.fetchOutletStatus();
        _sessionBloc.setOutletOpen(outletStatus.isOpen);
      } catch (_) {
        // Non-fatal: outlet status failure should not block login
        _sessionBloc.setOutletOpen(false);
      }

      emit(
        state.copyWith(
          status: AuthStatus.authenticated,
          email: event.email,
          password: state.rememberMe ? event.password : '',
        ),
      );
    } catch (error) {
      final errorMessage = (error is DioException)
          ? (error.response?.data is Map
                    ? error.response?.data['message']
                    : null) ??
                'Unable to login. Please try again.'
          : error.toString().replaceFirst('Exception: ', '');
      emit(
        state.copyWith(status: AuthStatus.failure, errorMessage: errorMessage),
      );
    }
  }

  Future<void> _onLogoutRequested(
    AuthLogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    await _authRepository.logout();
    _sessionBloc.setOutletOpen(false);
    emit(state.copyWith(status: AuthStatus.unauthenticated));
  }

  void _onPasswordVisibilityToggled(
    PasswordVisibilityToggled event,
    Emitter<AuthState> emit,
  ) {
    emit(state.copyWith(isPasswordVisible: !state.isPasswordVisible));
  }

  // Compatibility helpers for existing UI calls.
  Future<void> initialize() async => add(const AuthInitialized());
  void setRememberMe(bool value) => add(RememberMeChanged(value));
  Future<void> login({required String email, required String password}) async =>
      add(AuthLoginRequested(email: email, password: password));
  Future<void> logout() async => add(const AuthLogoutRequested());
  void togglePasswordVisibility() => add(const PasswordVisibilityToggled());
}
