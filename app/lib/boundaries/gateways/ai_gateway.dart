import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// (#) Holds the AI progress summary that comes back from the server. If model is
// (#) 'stub' it was the plain fallback text, otherwise a real AI model wrote it.
class ProgressSummary {
  // (#) Builds a summary from the text and the name of the model that made it.
  const ProgressSummary({required this.text, required this.model});

  final String text; // (#) the summary sentence shown to the user
  final String model; // (#) which model produced it, or 'stub' for the fallback

  // (#) True when a real AI wrote this, so the UI can tag it as AI assisted.
  bool get isAiGenerated => model.isNotEmpty && model != 'stub';

  // (#) Reads the summary and model out of the JSON the edge function returns.
  factory ProgressSummary.fromJson(Map<String, dynamic> json) => ProgressSummary(
        text: (json['summary'] as String?)?.trim() ?? '',
        model: json['model'] as String? ?? 'stub',
      );
}

// (#) Talks to the two Supabase edge functions that run the AI, so the model
// (#) key never leaves the server. Controls use it to get a progress summary or
// (#) a suggested training plan.
class AiGateway {
  // (#) Keeps the Supabase client used to call the edge functions.
  AiGateway(this._client);

  final SupabaseClient _client; // (#) the Supabase client for function calls

  // (#) Calls the summarise-progress edge function and returns the AI summary.
  Future<ProgressSummary> summariseProgress({String range = 'week'}) async {
    final res = await _client.functions.invoke('summarise-progress', body: {'range': range});
    final data = res.data;
    if (data is Map) {
      return ProgressSummary.fromJson(Map<String, dynamic>.from(data));
    }
    throw Exception('Unexpected AI response: $data');
  }

  // (#) Calls the suggest-plan edge function and hands back the raw plan payload.
  // (#) GeneratePlan later turns the workout slugs in it into real ids.
  Future<Map<String, dynamic>> suggestPlan() async {
    final res = await _client.functions.invoke('suggest-plan');
    final data = res.data;
    if (data is Map) return Map<String, dynamic>.from(data);
    throw Exception('Unexpected AI response: $data');
  }
}

// (#) Riverpod provider that hands out the AI gateway wired to the live client.
final aiGatewayProvider = Provider<AiGateway>((ref) => AiGateway(Supabase.instance.client));
