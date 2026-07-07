import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../boundaries/gateways/profile_gateway.dart';
import '../boundaries/gateways/storage_gateway.dart';
import '../core/seq_log.dart';
import 'authenticate.dart';

/// CONTROL — Update Avatar (#13 profile photo). Uploads the picked image to
/// the public avatars bucket, points profiles.avatar_url at it, and refreshes
/// the profile so every avatar surface updates live.
class UpdateAvatar {
  UpdateAvatar(this._ref);

  final Ref _ref;

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

final updateAvatarProvider = Provider<UpdateAvatar>(UpdateAvatar.new);
