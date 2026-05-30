import 'package:equatable/equatable.dart';
import '../data/models/user_model.dart'; 

abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class AuthUnauthenticated extends AuthState {}

class AuthNeedsOnboarding extends AuthState {}

class AuthOtpSent extends AuthState {
  final String mobile;
  const AuthOtpSent({required this.mobile});

  @override
  List<Object?> get props => [mobile];
}

class AuthAuthenticated extends AuthState {
  final UserModel user;
  const AuthAuthenticated({required this.user});

  @override
  List<Object?> get props => [user];
}

class AuthRegistrationRequired extends AuthState {
  final String mobile;
  const AuthRegistrationRequired({required this.mobile});

  @override
  List<Object?> get props => [mobile];
}

class AuthError extends AuthState {
  final String message;
  const AuthError({required this.message});

  @override
  List<Object?> get props => [message];
}