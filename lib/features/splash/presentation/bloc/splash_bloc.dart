import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'splash_event.dart';
import 'splash_state.dart';

class SplashBloc extends Bloc<SplashEvent, SplashState> {
  // Made public to satisfy Dart's strict initializing formal lint rules
  final FlutterSecureStorage secureStorage;

  SplashBloc({required this.secureStorage}) : super(SplashInitial()) {
    on<SplashBootSequenceInitiated>(_onBootSequenceInitiated);
  }

  Future<void> _onBootSequenceInitiated(
    SplashBootSequenceInitiated event,
    Emitter<SplashState> emit,
  ) async {
    emit(SplashLoading());

    try {
      await Future.delayed(const Duration(seconds: 2));

      final sessionToken = await secureStorage.read(key: 'jwt_session_token');
      final hasSeenOnboarding = await secureStorage.read(key: 'has_seen_onboarding');

      if (sessionToken != null && sessionToken.isNotEmpty) {
        emit(SplashRouteToRBAC());
      } else if (hasSeenOnboarding == 'true') {
        emit(SplashRouteToLogin());
      } else {
        emit(SplashRouteToOnboarding());
      }
    } catch (e) {
      emit(SplashError('Secure boot sequence failed: ${e.toString()}'));
    }
  }
}