import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:Zonova_Mist/src/core/auth/auth_provider.dart';
import 'package:Zonova_Mist/src/core/auth/auth_state.dart';
import 'package:Zonova_Mist/src/core/i18n/arb/app_localizations.dart';
import 'package:Zonova_Mist/src/core/routing/app_router.dart';
import 'package:Zonova_Mist/src/core/theme/app_theme.dart';
import 'package:Zonova_Mist/src/features/auth/login_screen.dart';
import 'package:Zonova_Mist/src/features/home/rooms/home_screen.dart';
import 'package:Zonova_Mist/src/shared/widgets/splash_screen.dart';
import 'package:Zonova_Mist/src/features/home/rooms/room_rate_page.dart';

void main() {
  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    return MaterialApp(
      title: 'Zonova Mist',
      theme: AppTheme.lightTheme,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      navigatorKey: AppRouter.navigatorKey,
      debugShowCheckedModeBanner: false,

      // 🔥 FIXED: Dashboard route එක add කරලා
      routes: {
        '/dashboard': (context) => const HomeScreen(), // 🎯 මේක තමයි dashboard
        '/room-rate': (context) => const RoomRatePage(),
      },

      // Auth state අනුව home screen එක select කරනවා
      home: authState.when(
        loading: () => const SplashScreen(),
        authenticated: (_) => const HomeScreen(),
        unauthenticated: () => const LoginScreen(),
        error: (_) => const LoginScreen(),
      ),
    );
  }
}