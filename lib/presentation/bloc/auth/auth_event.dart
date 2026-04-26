part of 'auth_bloc.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class AuthInitialized extends AuthEvent {
  const AuthInitialized();
}

class AppStarted extends AuthEvent {
  const AppStarted();
}

class RememberMeChanged extends AuthEvent {
  const RememberMeChanged(this.value);

  final bool value;

  @override
  List<Object?> get props => [value];
}

class AuthLoginRequested extends AuthEvent {
  const AuthLoginRequested({required this.email, required this.password});

  final String email;
  final String password;

  @override
  List<Object?> get props => [email, password];
}

class AuthLogoutRequested extends AuthEvent {
  const AuthLogoutRequested();
}

class PasswordVisibilityToggled extends AuthEvent {
  const PasswordVisibilityToggled();
}

class OutletStatusRefreshRequested extends AuthEvent {
  const OutletStatusRefreshRequested();
}
