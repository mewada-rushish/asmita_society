import 'package:equatable/equatable.dart';

sealed class SplashState extends Equatable {
  const SplashState();
  
  @override
  List<Object> get props => [];
}

class SplashInitial extends SplashState {}

class SplashLoading extends SplashState {}

class SplashRouteToOnboarding extends SplashState {}

class SplashRouteToLogin extends SplashState {}

class SplashRouteToRBAC extends SplashState {}

class SplashError extends SplashState {
  final String message;

  const SplashError(this.message);

  @override
  List<Object> get props => [message];
}