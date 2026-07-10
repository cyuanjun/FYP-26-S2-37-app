import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../entities/enums.dart';
import '../../entities/profile.dart';
import '../../entities/subscription.dart';
import '../../core/strings.dart';

// (#) Reads and writes the profiles and subscriptions tables. Controls use it to
// (#) load a user's profile, change their settings, and run the premium upgrade.
class ProfileGateway {
  // (#) Keeps the Supabase client used for all profile queries.
  ProfileGateway(this._client);

  final SupabaseClient _client; // (#) the Supabase client for table calls

  // (#) Loads a user's profile row by id.
  Future<Profile> fetchProfile(String id) async {
    final row = await _client.from('profiles').select().eq('id', id).single();
    return Profile.fromJson(row);
  }

  // (#) Saves the metric/imperial choice right away, no save button needed.
  Future<void> updatePreferredUnits(String id, PreferredUnits units) async {
    await _client.from('profiles').update({'preferred_units': units.name}).eq('id', id);
  }

  // (#) Overwrites the user's notification toggle settings as a whole map.
  Future<void> updateNotificationPrefs(String id, Map<String, dynamic> prefs) async {
    await _client.from('profiles').update({'notification_prefs': prefs}).eq('id', id);
  }

  // (#) Sets the user's name, used when signup left it blank and for later editing.
  Future<void> updateName(String id, {required String firstName, String? lastName}) async {
    await _client.from('profiles').update({
      'first_name': firstName.trim(),
      if (lastName.isNotBlank) 'last_name': lastName!.trim(),
    }).eq('id', id);
  }

  // (#) Runs the start_premium RPC to flip the user to Premium. Payment is
  // (#) simulated, and the RPC is what changes the role since direct writes are blocked.
  Future<void> startPremium() async {
    await _client.rpc<void>('start_premium');
  }

  // (#) Loads the user's subscription row, or null while they are still Free.
  Future<Subscription?> fetchSubscription(String id) async {
    final row =
        await _client.from('subscriptions').select().eq('id', id).maybeSingle();
    return row == null ? null : Subscription.fromJson(row);
  }

  // (#) Cancels or resumes a subscription by writing its status.
  Future<void> setSubscriptionStatus(String id, SubscriptionStatus status) async {
    await _client
        .from('subscriptions')
        .update({'status': status.dbValue}).eq('id', id);
  }

  // (#) Saves the public URL of a newly uploaded avatar onto the profile.
  Future<void> updateAvatarUrl(String id, String url) async {
    await _client.from('profiles').update({'avatar_url': url}).eq('id', id);
  }

  // (#) Stamps onboarding as finished so the app stops sending the user to it.
  Future<void> completeOnboarding(String id) async {
    await _client
        .from('profiles')
        .update({'onboarding_completed_at': DateTime.now().toUtc().toIso8601String()})
        .eq('id', id);
  }
}

// (#) Riverpod provider handing out the profile gateway on the live client.
final profileGatewayProvider = Provider<ProfileGateway>(
  (ref) => ProfileGateway(Supabase.instance.client),
);
