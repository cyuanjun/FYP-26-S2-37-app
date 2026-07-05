import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wise_workout/boundaries/gateways/ai_gateway.dart';
import 'package:wise_workout/controls/summarise_progress.dart';

import '../helpers/fakes.dart';

void main() {
  group('ProgressSummary.fromJson', () {
    test('stub model is not AI-generated (negative)', () {
      final s = ProgressSummary.fromJson({'summary': 'hi', 'model': 'stub'});
      expect(s.text, 'hi');
      expect(s.isAiGenerated, isFalse);
    });
    test('real model is AI-generated (positive)', () {
      final s = ProgressSummary.fromJson({'summary': 'hi', 'model': 'gpt-4o-mini'});
      expect(s.isAiGenerated, isTrue);
    });
    test('missing fields default safely', () {
      final s = ProgressSummary.fromJson({});
      expect(s.text, '');
      expect(s.model, 'stub');
    });
  });

  test('SummariseProgress returns the gateway summary (positive)', () async {
    final fake = FakeAiGateway(result: const ProgressSummary(text: '3 workouts this week.', model: 'stub'));
    final c = ProviderContainer(overrides: [aiGatewayProvider.overrideWithValue(fake)]);
    addTearDown(c.dispose);
    final summary = await c.read(summariseProgressProvider).call();
    expect(summary.text, '3 workouts this week.');
    expect(fake.calls, 1);
  });

  test('SummariseProgress propagates gateway errors (negative)', () async {
    final fake = FakeAiGateway(throwOnCall: true);
    final c = ProviderContainer(overrides: [aiGatewayProvider.overrideWithValue(fake)]);
    addTearDown(c.dispose);
    await expectLater(c.read(summariseProgressProvider).call(), throwsA(isA<Exception>()));
  });
}
