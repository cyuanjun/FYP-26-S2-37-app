import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../boundaries/gateways/feedback_gateway.dart';
import '../core/seq_log.dart';
import '../entities/enums.dart';
import 'authenticate.dart';

// (#) The Submit Feedback use case (#13.5). Takes a category and message and inserts
// (#) it via the gateway, but only after the message clears a minimum length. The
// (#) screen watches this notifier's error state to show validation messages.
class SubmitFeedback extends AsyncNotifier<void> {
  static const minBodyLength = 10; // (#) shortest allowed message, counted after trimming

  // (#) Nothing to preload.
  @override
  Future<void> build() async {}

  // (#) Trims and length-checks the body, checks the user is signed in, then inserts
  // (#) via the feedback gateway. Sets error states on failure and returns whether it sent.
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

// (#) Provider the feedback screen watches to submit and track state.
final submitFeedbackProvider =
    AsyncNotifierProvider<SubmitFeedback, void>(SubmitFeedback.new);
