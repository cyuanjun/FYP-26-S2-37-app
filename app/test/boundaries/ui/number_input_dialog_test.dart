import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wise_workout/boundaries/ui/profile/profile_widgets.dart';

// (#) Tests the numeric height/weight picker dialog: only an in-range number reaches onSet.
void main() {
  // Pumps a button that opens the dialog with height bounds; returns the value
  // captured by onSet (null = the Boundary rejected it and never called back).
  Future<double?> runPicker(WidgetTester tester, String typed) async {
    double? captured;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => showNumberInputDialog(
              context,
              title: 'Height',
              unit: 'cm',
              min: 100,
              max: 250,
              onSet: (v) => captured = v,
            ),
            child: const Text('open'),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), typed);
    await tester.tap(find.text('Set'));
    await tester.pumpAndSettle();
    return captured;
  }

  // (#) (+) Check if an in-range value is accepted and passed to onSet.
  testWidgets('accepts an in-range value (positive)', (tester) async {
    expect(await runPicker(tester, '178'), 178);
  });

  // (#) (-) Check if an out-of-range value is rejected and onSet never fires.
  testWidgets('rejects an out-of-range value — onSet never fires (negative)',
      (tester) async {
    expect(await runPicker(tester, '999'), isNull);
  });

  // (#) (-) Check if non-numeric text is rejected and onSet never fires.
  testWidgets('rejects non-numeric input — onSet never fires (negative)',
      (tester) async {
    expect(await runPicker(tester, 'abc'), isNull);
  });
}
