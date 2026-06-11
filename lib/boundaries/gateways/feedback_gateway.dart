import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../entities/enums.dart';

/// BOUNDARY (gateway) — inserts `feedback` rows (#13.5). Fire-and-forget:
/// users have no inbound surface; admins triage on their portal.
class FeedbackGateway {
  FeedbackGateway(this._client);

  final SupabaseClient _client;

  Future<void> submitFeedback({
    required String userId,
    required FeedbackCategory category,
    required String body,
  }) async {
    await _client.from('feedback').insert({
      'user_id': userId,
      'category': switch (category) {
        FeedbackCategory.bug => 'bug',
        FeedbackCategory.featureRequest => 'feature_request',
        FeedbackCategory.general => 'general',
      },
      'body': body.trim(),
    });
  }
}

final feedbackGatewayProvider =
    Provider<FeedbackGateway>((ref) => FeedbackGateway(Supabase.instance.client));
