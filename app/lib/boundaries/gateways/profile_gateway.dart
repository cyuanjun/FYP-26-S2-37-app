import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../entities/enums.dart';
import '../../entities/profile.dart';

/// BOUNDARY (gateway) — reads/writes the `profiles` table. Controls call this;
/// the UI never queries Supabase directly.
class ProfileGateway {
  ProfileGateway(this._client);

  final SupabaseClient _client;

  Future<Profile> fetchProfile(String id) async {
    final row = await _client.from('profiles').select().eq('id', id).single();
    return Profile.fromJson(row);
  }

  /// Instant-commit preference toggle (#13.3 — no save button by design).
  Future<void> updatePreferredUnits(String id, PreferredUnits units) async {
    await _client.from('profiles').update({'preferred_units': units.name}).eq('id', id);
  }

  /// Replaces the whole notification_prefs map (#13.4 — per-flip commit).
  Future<void> updateNotificationPrefs(String id, Map<String, dynamic> prefs) async {
    await _client.from('profiles').update({'notification_prefs': prefs}).eq('id', id);
  }

  /// Fills in the user's name when the website signup didn't provide one
  /// (onboarding fallback) — also backs future #13.3 name editing.
  Future<void> updateName(String id, {required String firstName, String? lastName}) async {
    await _client.from('profiles').update({
      'first_name': firstName.trim(),
      if (lastName != null && lastName.trim().isNotEmpty) 'last_name': lastName.trim(),
    }).eq('id', id);
  }

  /// Marks first-time onboarding done — Splash/Login stop routing to the wizard.
  Future<void> completeOnboarding(String id) async {
    await _client
        .from('profiles')
        .update({'onboarding_completed_at': DateTime.now().toUtc().toIso8601String()})
        .eq('id', id);
  }
}

final profileGatewayProvider = Provider<ProfileGateway>(
  (ref) => ProfileGateway(Supabase.instance.client),
);
