import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

/// Named social targets — shown as explicit buttons (CLAUDE.md convention:
/// Facebook / Instagram / Twitter / TikTok, not a generic share sheet).
enum SocialPlatform { facebook, instagram, twitter, tiktok }

extension SocialPlatformLabel on SocialPlatform {
  String get label => switch (this) {
        SocialPlatform.facebook => 'Facebook',
        SocialPlatform.instagram => 'Instagram',
        SocialPlatform.twitter => 'Twitter',
        SocialPlatform.tiktok => 'TikTok',
      };
}

/// BOUNDARY (gateway) — system share. The platform is carried through for future
/// deep-linking; today it opens the OS share to the chosen app.
class SocialShareGateway {
  Future<void> shareTo(SocialPlatform platform, {required String text}) async {
    await SharePlus.instance.share(
      ShareParams(text: '$text\n\n#WiseWorkout', subject: 'My Wise Workout'),
    );
  }
}

final socialShareGatewayProvider = Provider<SocialShareGateway>((ref) => SocialShareGateway());
