import 'package:flutter/material.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

class CrashlyticsNavigationObserver extends RouteObserver<PageRoute<dynamic>> {
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    if (route is PageRoute) {
      FirebaseCrashlytics.instance.log('Pushed route: ${route.settings.name ?? "unnamed"}');
    }
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    if (route is PageRoute) {
      FirebaseCrashlytics.instance.log('Popped route: ${route.settings.name ?? "unnamed"}');
    }
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    if (newRoute is PageRoute) {
      FirebaseCrashlytics.instance.log('Replaced route with: ${newRoute.settings.name ?? "unnamed"}');
    }
  }
}
