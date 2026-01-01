import 'package:flutter/material.dart';

class AppRouter {
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  static Future<T?>? to<T>(Widget page) {
    return navigatorKey.currentState?.push<T>(
      MaterialPageRoute(builder: (_) => page),
    );
  }

  static Future<T?>? off<T>(Widget page) {
    return navigatorKey.currentState?.pushReplacement(
      MaterialPageRoute(builder: (_) => page),
    );
  }

  static void back<T>([T? result]) {
    navigatorKey.currentState?.pop(result);
  }
}