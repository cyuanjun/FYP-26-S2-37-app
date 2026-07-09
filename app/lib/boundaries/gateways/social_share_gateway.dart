import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../entities/enums.dart';

/// BOUNDARY (gateway) — system share to a named platform (Facebook / Instagram /
/// Twitter / TikTok, surfaced as explicit buttons in the UI per CLAUDE.md). The
/// platform is carried through for future per-app deep-linking; today it opens the
/// OS share sheet (a real deep-link integration is a later sprint).
class SocialShareGateway {
  Future<void> shareTo(SocialPlatform platform, {required String text}) async {
    await SharePlus.instance.share(
      ShareParams(text: '$text\n\n#WiseWorkout', subject: 'My Wise Workout'),
    );
  }

  /// Generic system share (no named platform) — used for a challenge invite,
  /// where the payload is a join code rather than a per-network post.
  Future<void> shareInvite(String text) async {
    await SharePlus.instance.share(
      ShareParams(text: text, subject: 'Join my Wise Workout challenge'),
    );
  }
}

final socialShareGatewayProvider = Provider<SocialShareGateway>((ref) => SocialShareGateway());
