import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// (#) Talks to Supabase Storage buckets. Right now controls use it to upload a
// (#) user's avatar photo and hand back the public URL to save on their profile.
class StorageGateway {
  // (#) Keeps the Supabase client used to reach Storage.
  StorageGateway(this._client);

  final SupabaseClient _client; // (#) the Supabase client for storage calls

  // (#) Uploads the avatar (replacing any old one) and returns its public URL
  // (#) with a version tag on the end so the new photo shows up right away.
  Future<String> uploadAvatar(
      {required String userId, required Uint8List bytes}) async {
    final path = '$userId/avatar.jpg';
    await _client.storage.from('avatars').uploadBinary(
          path,
          bytes,
          fileOptions:
              const FileOptions(upsert: true, contentType: 'image/jpeg'),
        );
    final url = _client.storage.from('avatars').getPublicUrl(path);
    return '$url?v=${DateTime.now().millisecondsSinceEpoch}';
  }
}

// (#) Riverpod provider handing out the storage gateway on the live client.
final storageGatewayProvider =
    Provider<StorageGateway>((ref) => StorageGateway(Supabase.instance.client));
