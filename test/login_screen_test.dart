import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_market/src/core/i18n/arb/app_localizations.dart';
import 'package:map_market/src/features/auth/login_screen.dart';

void main() {
  testWidgets('LoginScreen renders correctly and finds widgets', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: LoginScreen(),
        ),
      ),
    );

    // Verify that the main title 'MapMarket' is present.
    expect(find.text('MapMarket'), findsOneWidget);

    // Verify that the Email text field is present.
    // We search by the label text we assigned in the screen.
    expect(find.widgetWithText(TextFormField, 'Email'), findsOneWidget);

    // Verify that the Password text field is present.
    expect(find.widgetWithText(TextFormField, 'Password'), findsOneWidget);

    // Verify that the Login button is present.
    expect(find.widgetWithText(ElevatedButton, 'Login'), findsOneWidget);

    // Verify that the Register button is present.
    expect(find.widgetWithText(TextButton, 'Register'), findsOneWidget);
  });
}