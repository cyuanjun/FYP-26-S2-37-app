// Smoke test for the Splash boundary. Supabase isn't initialized in tests, so we
// render SplashScreen directly rather than the full app (which calls Supabase.initialize).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:wise_workout/boundaries/ui/splash/splash_screen.dart';

void main() {
  testWidgets('Splash shows the wordmark and CTA', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: SplashScreen()));

    expect(find.text('WISE'), findsOneWidget);
    expect(find.text('WORKOUT'), findsOneWidget);
    expect(find.text('Get started'), findsOneWidget);
  });
}
