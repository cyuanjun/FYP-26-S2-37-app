import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../entities/enums.dart';

// (#) Writes into the feedback table in Supabase. Controls use it to drop off a
// (#) user's feedback message for admins to read later on their portal.
class FeedbackGateway {
  // (#) Keeps the Supabase client used to insert feedback.
  FeedbackGateway(this._client);

  final SupabaseClient _client; // (#) the Supabase client for the insert

  // (#) Inserts one feedback row, mapping the category enum to its db string.
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

// (#) Riverpod provider handing out the feedback gateway on the live client.
final feedbackGatewayProvider =
    Provider<FeedbackGateway>((ref) => FeedbackGateway(Supabase.instance.client));
