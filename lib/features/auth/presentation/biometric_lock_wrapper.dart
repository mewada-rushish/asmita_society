import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:asmita_society/features/menu/bloc/preferences_bloc.dart';
import 'package:asmita_society/features/menu/bloc/preferences_state.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter/services.dart';

class BiometricLockWrapper extends StatefulWidget {
  final Widget child;

  const BiometricLockWrapper({super.key, required this.child});

  @override
  State<BiometricLockWrapper> createState() => _BiometricLockWrapperState();
}

class _BiometricLockWrapperState extends State<BiometricLockWrapper> {
  final LocalAuthentication _auth = LocalAuthentication();
  bool _isAuthenticated = false;
  bool _isAuthenticating = false;
  bool _hasPrompted = false;

  Future<void> _authenticate() async {
    if (!mounted) return;
    setState(() {
      _isAuthenticating = true;
    });

    try {
      final bool canAuthenticateWithBiometrics = await _auth.canCheckBiometrics;
      final bool isDeviceSupported = await _auth.isDeviceSupported();
      final bool canAuthenticate = canAuthenticateWithBiometrics || isDeviceSupported;
      
      debugPrint('Biometrics - canCheck: $canAuthenticateWithBiometrics, isSupported: $isDeviceSupported');

      if (!canAuthenticate) {
        debugPrint('Biometrics - Bypassing because device does not support it.');
        // If device does not support biometrics, bypass
        if (mounted) {
          setState(() {
            _isAuthenticated = true;
            _isAuthenticating = false;
          });
        }
        return;
      }

      final bool didAuthenticate = await _auth.authenticate(
        localizedReason: 'Please authenticate to access your society account',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false,
        ),
      );

      if (mounted) {
        setState(() {
          _isAuthenticated = didAuthenticate;
          _isAuthenticating = false;
        });
      }
    } on PlatformException catch (e) {
      debugPrint('Biometric Error: $e');
      if (mounted) {
        setState(() {
          _isAuthenticating = false;
          _isAuthenticated = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PreferencesBloc, PreferencesState>(
      builder: (context, prefsState) {
        if (prefsState is PreferencesInitial) {
          debugPrint('Biometrics - Waiting for preferences to load...');
          return Scaffold(
            backgroundColor: Theme.of(context).colorScheme.primary,
          );
        }

        final isBiometricEnabled = prefsState is PreferencesLoaded ? prefsState.items?.biometricLogin ?? false : false;
        debugPrint('Biometrics - Loaded! enabled: $isBiometricEnabled, hasPrompted: $_hasPrompted, isAuth: $_isAuthenticated');

        if (isBiometricEnabled && !_isAuthenticated && !_hasPrompted && !_isAuthenticating) {
          _hasPrompted = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _authenticate();
          });
        }

        // Show child if biometrics is disabled, or if we successfully authenticated.
        if (!isBiometricEnabled || _isAuthenticated) {
          return widget.child;
        }

        // Otherwise, show the lock screen
        return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.lock_person_rounded,
                size: 80,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 24),
              Text(
                'App Locked',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Please authenticate to access your account.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 48),
              if (_isAuthenticating)
                const CircularProgressIndicator()
              else
                ElevatedButton.icon(
                  onPressed: _authenticate,
                  icon: Icon(Icons.fingerprint, color: Theme.of(context).colorScheme.surface),
                  label: Text(
                    'Unlock',
                    style: TextStyle(color: Theme.of(context).colorScheme.surface),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
      },
    );
  }
}
