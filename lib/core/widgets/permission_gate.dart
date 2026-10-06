import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../features/auth/bloc/auth_bloc.dart';
import '../../features/auth/bloc/auth_state.dart';

/// A wrapper widget that hides or shows its child based on the current
/// user's permissions in the AuthBloc.
class PermissionGate extends StatelessWidget {
  final String permissionKey;
  final Widget child;
  final Widget? fallback;

  const PermissionGate({
    super.key,
    required this.permissionKey,
    required this.child,
    this.fallback,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        if (state is Authenticated) {
          final hasPermission = state.user.permissions.contains(permissionKey);
          
          if (hasPermission) {
            return child;
          }
        }
        
        // If not authenticated or doesn't have permission, return fallback or empty
        return fallback ?? const SizedBox.shrink();
      },
    );
  }
}
