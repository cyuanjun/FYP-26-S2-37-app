import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wise_workout/boundaries/ui/profile/profile_widgets.dart';

/// BOUNDARY (widget) test — the numeric picker used for height/weight cleans
/// input before handing it back: only an in-range number reaches `onSet`, so
/// invalid input never leaves the Boundary.
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

  testWidgets('accepts an in-range value (positive)', (tester) async {
    expect(await runPicker(tester, '178'), 178);
  });

  testWidgets('rejects an out-of-range value — onSet never fires (negative)',
      (tester) async {
    expect(await runPicker(tester, '999'), isNull);
  });

  testWidgets('rejects non-numeric input — onSet never fires (negative)',
      (tester) async {
    expect(await runPicker(tester, 'abc'), isNull);
  });
}
