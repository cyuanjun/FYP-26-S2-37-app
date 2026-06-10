import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
}

final profileGatewayProvider = Provider<ProfileGateway>(
  (ref) => ProfileGateway(Supabase.instance.client),
);
