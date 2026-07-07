import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../controls/authenticate.dart';
import '../../../core/theme/app_colors.dart';
import '../profile/profile_screen.dart';

/// BOUNDARY — the top-right circular avatar on tab landings; the canonical
/// entry to Profile (#13), which is deliberately not a bottom-nav tab.
class AvatarButton extends ConsumerWidget {
  const AvatarButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(currentProfileProvider).value;
    final initial = (profile?.firstName?.isNotEmpty ?? false)
        ? profile!.firstName![0].toUpperCase()
        : '?';

    return Padding(
      padding: const EdgeInsets.only(right: 16),
      child: GestureDetector(
        onTap: () => Navigator.of(context, rootNavigator: true)
            .push(MaterialPageRoute(builder: (_) => const ProfileScreen())),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.surface,
            shape: BoxShape.circle,
            image: profile?.avatarUrl == null
                ? null
                : DecorationImage(
                    image: NetworkImage(profile!.avatarUrl!),
                    fit: BoxFit.cover),
          ),
          alignment: Alignment.center,
          child: profile?.avatarUrl != null
              ? null
              : Text(initial,
              style: const TextStyle(
                  fontSize: 17, fontWeight: FontWeight.w900, color: AppColors.accent)),
        ),
      ),
    );
  }
}
