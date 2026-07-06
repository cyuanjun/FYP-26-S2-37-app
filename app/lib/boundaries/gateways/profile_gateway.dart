import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../entities/enums.dart';
import '../../entities/profile.dart';
import '../../entities/subscription.dart';
import '../../core/strings.dart';

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
      if (lastName.isNotBlank) 'last_name': lastName!.trim(),
    }).eq('id', id);
  }

  /// Simulated Free→Premium upgrade (#16) — the SECURITY DEFINER RPC flips the
  /// role and upserts the subscriptions row; direct role writes stay blocked.
  Future<void> startPremium() async {
    await _client.rpc<void>('start_premium');
  }

  /// The caller's subscription row, or null while Free (#13.6).
  Future<Subscription?> fetchSubscription(String id) async {
    final row =
        await _client.from('subscriptions').select().eq('id', id).maybeSingle();
    return row == null ? null : Subscription.fromJson(row);
  }

  /// Cancel / resume (#13.6) — owner-scoped status write, RLS-covered.
  Future<void> setSubscriptionStatus(String id, SubscriptionStatus status) async {
    await _client
        .from('subscriptions')
        .update({'status': status.dbValue}).eq('id', id);
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
