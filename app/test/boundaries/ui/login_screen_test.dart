import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wise_workout/boundaries/gateways/auth_gateway.dart';
import 'package:wise_workout/boundaries/ui/auth/login_screen.dart';

import '../../helpers/fakes.dart';

// (#) Widget tests for the Login screen. They mount the real screen with a fake
// (#) auth gateway, then check it renders, that tapping log in reaches the
// (#) gateway, and that a failed sign in shows the error message.

// (#) Wraps the Login screen in a ProviderScope with the given fake auth gateway.
Widget _app(FakeAuthGateway auth) => ProviderScope(
      overrides: [authGatewayProvider.overrideWithValue(auth)],
      child: const MaterialApp(home: LoginScreen()),
    );

void main() {
  // (#) (+) Check if the screen shows the email box, the password box, and the LOG IN button.
  testWidgets('renders the email/password fields + LOG IN', (tester) async {
    await tester.pumpWidget(_app(FakeAuthGateway()));
    await tester.pumpAndSettle(); // let the AsyncNotifier build() resolve
    expect(find.text('EMAIL'), findsOneWidget);
    expect(find.text('PASSWORD'), findsOneWidget);
    expect(find.widgetWithText(ElevatedButton, 'LOG IN'), findsOneWidget);
  });

  // (#) (+) Check if typing an email and password and tapping LOG IN calls the auth gateway once.
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

  // (#) (-) Check if a failed sign in shows the "Incorrect email or password." message.
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
