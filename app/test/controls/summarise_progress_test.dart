import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wise_workout/boundaries/gateways/ai_gateway.dart';
import 'package:wise_workout/controls/summarise_progress.dart';

import '../helpers/fakes.dart';

// (#) Tests ProgressSummary parsing and the SummariseProgress control.

void main() {
  // (#) Parsing the AI summary payload.
  group('ProgressSummary.fromJson', () {
    // (#) (-) Check if a stub model is flagged as not AI-generated.
    test('stub model is not AI-generated (negative)', () {
      final s = ProgressSummary.fromJson({'summary': 'hi', 'model': 'stub'});
      expect(s.text, 'hi');
      expect(s.isAiGenerated, isFalse);
    });
    // (#) (+) Check if a real model name is flagged as AI-generated.
    test('real model is AI-generated (positive)', () {
      final s = ProgressSummary.fromJson({'summary': 'hi', 'model': 'gpt-4o-mini'});
      expect(s.isAiGenerated, isTrue);
    });
    // (#) (-) Check if missing fields default to empty text and the stub model.
    test('missing fields default safely', () {
      final s = ProgressSummary.fromJson({});
      expect(s.text, '');
      expect(s.model, 'stub');
    });
  });

  // (#) (+) Check if the control returns the summary produced by the gateway.
  test('SummariseProgress returns the gateway summary (positive)', () async {
    final fake = FakeAiGateway(result: const ProgressSummary(text: '3 workouts this week.', model: 'stub'));
    final c = ProviderContainer(overrides: [aiGatewayProvider.overrideWithValue(fake)]);
    addTearDown(c.dispose);
    final summary = await c.read(summariseProgressProvider).call();
    expect(summary.text, '3 workouts this week.');
    expect(fake.calls, 1);
  });

  // (#) (-) Check if a gateway error is propagated out of the control.
  test('SummariseProgress propagates gateway errors (negative)', () async {
    final fake = FakeAiGateway(throwOnCall: true);
    final c = ProviderContainer(overrides: [aiGatewayProvider.overrideWithValue(fake)]);
    addTearDown(c.dispose);
    await expectLater(c.read(summariseProgressProvider).call(), throwsA(isA<Exception>()));
  });
}
