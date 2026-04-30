import 'package:equatable/equatable.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();
  @override
  List<Object?> get props => [];
}

class AuthCheckRequested extends AuthEvent {
  const AuthCheckRequested();
}

class LoginRequested extends AuthEvent {
  final String email;
  final String password;
  const LoginRequested({required this.email, required this.password});
  @override
  List<Object?> get props => [email, password];
}

class SignupRequested extends AuthEvent {
  final String email;
  final String password;
  final String displayName;
  const SignupRequested({
    required this.email,
    required this.password,
    required this.displayName,
  });
  @override
  List<Object?> get props => [email, password, displayName];
}

class GoogleSignInRequested extends AuthEvent {
  const GoogleSignInRequested();
}

class LogoutRequested extends AuthEvent {
  const LogoutRequested();
}
