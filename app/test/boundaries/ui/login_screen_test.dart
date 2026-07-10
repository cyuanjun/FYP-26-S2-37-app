import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wise_workout/boundaries/gateways/auth_gateway.dart';
import 'package:wise_workout/boundaries/ui/auth/login_screen.dart';

import '../../helpers/fakes.dart';

/// BOUNDARY (widget) test — #2 Login screen. The screen renders its fields and,
/// on tap, drives the Authenticate control (→ the auth gateway); a failed
/// sign-in surfaces the mapped error message.
Widget _app(FakeAuthGateway auth) => ProviderScope(
      overrides: [authGatewayProvider.overrideWithValue(auth)],
      child: const MaterialApp(home: LoginScreen()),
    );

void main() {
  testWidgets('renders the email/password fields + LOG IN', (tester) async {
    await tester.pumpWidget(_app(FakeAuthGateway()));
    await tester.pumpAndSettle(); // let the AsyncNotifier build() resolve
    expect(find.text('EMAIL'), findsOneWidget);
    expect(find.text('PASSWORD'), findsOneWidget);
    expect(find.widgetWithText(ElevatedButton, 'LOG IN'), findsOneWidget);
  });

  testWidgets('tapping LOG IN drives the control → auth gateway (positive)',
      (tester) async {
    final auth = FakeAuthGateway();
    await tester.pumpWidget(_app(auth));

    await tester.enterText(find.byType(TextField).at(0), 'a@b.com');
    await tester.enterText(find.byType(TextField).at(1), 'secret123');
    await tester.tap(find.widgetWithText(ElevatedButton, 'LOG IN'));
    await tester.pump(); // let the async sign-in run

    expect(auth.signInCount, 1); // the input reached the gateway
  });

  testWidgets('failed sign-in shows the mapped error message (negative)',
      (tester) async {
    final auth = FakeAuthGateway(throwOnSignIn: true);
    await tester.pumpWidget(_app(auth));

    await tester.enterText(find.byType(TextField).at(0), 'a@b.com');
    await tester.enterText(find.byType(TextField).at(1), 'wrong');
    await tester.tap(find.widgetWithText(ElevatedButton, 'LOG IN'));
    await tester.pumpAndSettle();

    expect(find.text('Incorrect email or password.'), findsOneWidget);
  });
}
