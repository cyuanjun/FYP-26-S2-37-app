import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// BOUNDARY (gateway) — Supabase Storage. First consumer: profile photos
/// (public `avatars` bucket, one folder per user). Expert verification docs
/// join later on a private bucket.
class StorageGateway {
  StorageGateway(this._client);

  final SupabaseClient _client;

  /// Uploads (upserting) the user's avatar and returns its public URL with a
  /// cache-busting version parameter, so a changed photo shows immediately
  /// despite the stable object path.
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

final storageGatewayProvider =
    Provider<StorageGateway>((ref) => StorageGateway(Supabase.instance.client));
