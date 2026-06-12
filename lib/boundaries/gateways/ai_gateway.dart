import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// AI progress summary result. `model == 'stub'` means the deterministic fallback
/// (no real model yet); anything else is a genuine LLM response.
class ProgressSummary {
  const ProgressSummary({required this.text, required this.model});

  final String text;
  final String model;

  bool get isAiGenerated => model.isNotEmpty && model != 'stub';

  factory ProgressSummary.fromJson(Map<String, dynamic> json) => ProgressSummary(
        text: (json['summary'] as String?)?.trim() ?? '',
        model: json['model'] as String? ?? 'stub',
      );
}

/// BOUNDARY (gateway) — calls the `summarise-progress` Edge Function (which holds
/// any model API key server-side). One of the two AI surfaces (build-plan §5).
class AiGateway {
  AiGateway(this._client);

  final SupabaseClient _client;

  Future<ProgressSummary> summariseProgress({String range = 'week'}) async {
    final res = await _client.functions.invoke('summarise-progress', body: {'range': range});
    final data = res.data;
    if (data is Map) {
      return ProgressSummary.fromJson(Map<String, dynamic>.from(data));
    }
    throw Exception('Unexpected AI response: $data');
  }

  /// Premium plan personalisation (the second AI surface, build-plan §5).
  /// Returns the raw suggested-plan payload: { name, description,
  /// duration_weeks, workouts_per_week, model, workouts: [{slug, day_of_week,
  /// duration_minutes, name, descriptor}] }. GeneratePlan maps slugs → ids.
  Future<Map<String, dynamic>> suggestPlan() async {
    final res = await _client.functions.invoke('suggest-plan');
    final data = res.data;
    if (data is Map) return Map<String, dynamic>.from(data);
    throw Exception('Unexpected AI response: $data');
  }
}

final aiGatewayProvider = Provider<AiGateway>((ref) => AiGateway(Supabase.instance.client));
