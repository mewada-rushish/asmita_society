import 'package:flutter/material.dart';
import 'package:app_links/app_links.dart';
import '../routes/app_routes.dart';

class DeepLinkHandler {
  static final AppLinks _appLinks = AppLinks();

  static void init(GlobalKey<NavigatorState> navigatorKey) {
    // Handle initial uri if launched via link
    _appLinks.getInitialLink().then((uri) {
      if (uri != null) {
        handleUri(uri, navigatorKey);
      }
    }).catchError((_) {});

    // Listen for subsequent links while app is running
    _appLinks.uriLinkStream.listen((uri) {
      handleUri(uri, navigatorKey);
    }, onError: (_) {});
  }

  static void handleUri(Uri uri, GlobalKey<NavigatorState> navigatorKey) {
    // Expecting: https://admin.myasmita.com/invite/<type>/<token>
    if (uri.pathSegments.length >= 3 && uri.pathSegments[0] == 'invite') {
      final type = uri.pathSegments[1]; // 'join' or 'pass'
      final token = uri.pathSegments[2];

      final context = navigatorKey.currentContext;
      if (context == null) return;

      if (type == 'join') {
        Navigator.of(context).pushNamed(
          AppRoutes.register,
          arguments: {'inviteToken': token},
        );
      } else if (type == 'pass') {
        Navigator.of(context).pushNamed(
          AppRoutes.guardPassCheckIn,
          arguments: {'passToken': token},
        );
      }
    }
  }
}
