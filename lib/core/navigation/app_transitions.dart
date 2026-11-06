import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Centralized platform-adaptive page transitions theme.
///
/// Features:
/// - iOS: Native `CupertinoPageTransitionsBuilder` so the native swipe-back edge gesture continues to work seamlessly.
/// - Android: `ZoomPageTransitionsBuilder` (Material 3 predictive back animation).
/// - Web / Desktop: `FadeUpwardsPageTransitionsBuilder`.
class AsmitaPageTransitions {
  static const PageTransitionsTheme theme = PageTransitionsTheme(
    builders: <TargetPlatform, PageTransitionsBuilder>{
      TargetPlatform.android: ZoomPageTransitionsBuilder(),
      TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
      TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
      TargetPlatform.windows: FadeUpwardsPageTransitionsBuilder(),
      TargetPlatform.linux: FadeUpwardsPageTransitionsBuilder(),
    },
  );

  /// Helper to push a route using platform-adaptive transitions
  static Route<T> adaptiveRoute<T>({
    required WidgetBuilder builder,
    RouteSettings? settings,
    bool maintainState = true,
    bool fullscreenDialog = false,
  }) {
    if (defaultTargetPlatform == TargetPlatform.iOS || defaultTargetPlatform == TargetPlatform.macOS) {
      return CupertinoPageRoute<T>(
        builder: builder,
        settings: settings,
        maintainState: maintainState,
        fullscreenDialog: fullscreenDialog,
      );
    }
    return MaterialPageRoute<T>(
      builder: builder,
      settings: settings,
      maintainState: maintainState,
      fullscreenDialog: fullscreenDialog,
    );
  }
}
