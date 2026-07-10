import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../entities/enums.dart';

// (#) Opens the phone's share sheet for a named network like Facebook or
// (#) Instagram. Controls use it to push a workout post or a challenge invite out.
class SocialShareGateway {
  // (#) Shares a workout post to the chosen platform, tagging it with #WiseWorkout.
  Future<void> shareTo(SocialPlatform platform, {required String text}) async {
    await SharePlus.instance.share(
      ShareParams(text: '$text\n\n#WiseWorkout', subject: 'My Wise Workout'),
    );
  }

  // (#) Plain share for a challenge invite, where the text is a join code.
  Future<void> shareInvite(String text) async {
    await SharePlus.instance.share(
      ShareParams(text: text, subject: 'Join my Wise Workout challenge'),
    );
  }
}

// (#) Riverpod provider handing out a single social share gateway.
final socialShareGatewayProvider = Provider<SocialShareGateway>((ref) => SocialShareGateway());
