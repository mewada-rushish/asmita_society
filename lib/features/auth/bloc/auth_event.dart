import 'package:equatable/equatable.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

/// Dispatched when the app starts to check for an existing session token.
class AuthCheckRequested extends AuthEvent {}

class AuthInitiateRequested extends AuthEvent {
  final String mobile;
  const AuthInitiateRequested({required this.mobile});

  @override
  List<Object?> get props => [mobile];
}

class AuthVerifyRequested extends AuthEvent {
  final String mobile;
  final String otp;
  const AuthVerifyRequested({required this.mobile, required this.otp});

  @override
  List<Object?> get props => [mobile, otp];
}

class AuthRegisterRequested extends AuthEvent {
  final String mobile;
  final String fullName;
  final String email;
  final String gender;
  final String society;
  final String tower;
  final String floor;
  final String flat;
  final String role;

  const AuthRegisterRequested({
    required this.mobile,
    required this.fullName,
    required this.email,
    required this.gender,
    required this.society,
    required this.tower,
    required this.floor,
    required this.flat,
    required this.role,
  });

  @override
  List<Object?> get props => [mobile, fullName, email, gender, society, tower, floor, flat, role];
}

class AuthLogoutRequested extends AuthEvent {}