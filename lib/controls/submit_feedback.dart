import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../boundaries/gateways/feedback_gateway.dart';
import '../core/seq_log.dart';
import '../entities/enums.dart';
import 'authenticate.dart';

/// CONTROL — Submit Feedback (#13.5). Fire-and-forget insert; enforces the
/// 10-character minimum (counted after trim) before touching the gateway.
class SubmitFeedback extends AsyncNotifier<void> {
  static const minBodyLength = 10;

  @override
  Future<void> build() async {}

  Future<bool> submit({required FeedbackCategory category, required String body}) async {
    SeqLog.msg('submit-feedback', 'SubmitFeedbackScreen', 'SubmitFeedback',
        'submit(${category.name})');
    final trimmed = body.trim();
    if (trimmed.length < minBodyLength) {
      state = AsyncError(
          ArgumentError('Feedback must be at least $minBodyLength characters'),
          StackTrace.current);
      return false;
    }
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) {
      state = AsyncError(StateError('Not signed in'), StackTrace.current);
      return false;
    }
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      SeqLog.msg('submit-feedback', 'SubmitFeedback', 'FeedbackGateway', 'submitFeedback');
      await ref
          .read(feedbackGatewayProvider)
          .submitFeedback(userId: userId, category: category, body: trimmed);
    });
    return !state.hasError;
  }
}

final submitFeedbackProvider =
    AsyncNotifierProvider<SubmitFeedback, void>(SubmitFeedback.new);
