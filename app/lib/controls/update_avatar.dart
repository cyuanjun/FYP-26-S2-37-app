import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../boundaries/gateways/profile_gateway.dart';
import '../boundaries/gateways/storage_gateway.dart';
import '../core/seq_log.dart';
import 'authenticate.dart';

// (#) The Update Avatar use case (#13 profile photo). Uploads the chosen image to the
// (#) public avatars storage bucket, saves its URL on the profile, then refreshes so
// (#) every avatar in the app shows the new picture.
class UpdateAvatar {
  UpdateAvatar(this._ref);

  final Ref _ref;

  // (#) Takes the picked image bytes, uploads via the storage gateway, writes the new
  // (#) URL through the profile gateway, and invalidates the profile so avatars refresh.
  Future<void> call(Uint8List bytes) async {
    final userId = _ref.read(currentUserIdProvider);
    if (userId == null) return;
    SeqLog.msg('update-avatar', 'ProfileScreen', 'UpdateAvatar',
        'upload(${bytes.length} bytes)');
    SeqLog.msg(
        'update-avatar', 'UpdateAvatar', 'StorageGateway', 'uploadAvatar');
    final url = await _ref
        .read(storageGatewayProvider)
        .uploadAvatar(userId: userId, bytes: bytes);
    SeqLog.msg(
        'update-avatar', 'UpdateAvatar', 'ProfileGateway', 'updateAvatarUrl');
    await _ref.read(profileGatewayProvider).updateAvatarUrl(userId, url);
    _ref.invalidate(currentProfileProvider);
  }
}

// (#) Provider the profile screen uses to change the photo.
final updateAvatarProvider = Provider<UpdateAvatar>(UpdateAvatar.new);
