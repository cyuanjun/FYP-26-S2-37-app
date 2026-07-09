import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../gateways/social_share_gateway.dart';

/// Shared invite-code popup (#11): bold title + circular close, a boxed code
/// area with inline copy, and a full-width Share action. Used from the
/// challenge detail (share icon) and right after creating a challenge.
Future<void> showInviteCodeDialog(
  BuildContext context,
  WidgetRef ref, {
  required String title,
  required String code,
  required String shareText,
}) {
  void copy() {
    Clipboard.setData(ClipboardData(text: code));
    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Code copied to clipboard.')));
  }

  return showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: AppColors.surface,
      title: Row(
        children: [
          Expanded(
            child: Text(title,
                style:
                    AppTypography.title3.copyWith(fontWeight: FontWeight.w800)),
          ),
          _CircleClose(onTap: () => Navigator.of(ctx).pop()),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Share this code so others can join',
              style: AppTypography.footnote),
          const SizedBox(height: 16),
          _CodeBox(code: code, onCopy: copy),
        ],
      ),
      actions: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () {
              ref.read(socialShareGatewayProvider).shareInvite(shareText);
              Navigator.of(ctx).pop();
            },
            icon: const Icon(Icons.ios_share_rounded, size: 18),
            label: const Text('Share'),
          ),
        ),
      ],
    ),
  );
}

/// Circular close affordance — the ring signals it's tappable.
class _CircleClose extends StatelessWidget {
  const _CircleClose({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Container(
        width: 32,
        height: 32,
        alignment: Alignment.center,
        decoration: const BoxDecoration(
            color: AppColors.surface2, shape: BoxShape.circle),
        child: const Icon(Icons.close, size: 18, color: AppColors.muted),
      ),
    );
  }
}

/// The code in its own boxed area, with inline copy.
class _CodeBox extends StatelessWidget {
  const _CodeBox({required this.code, required this.onCopy});

  final String code;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
      decoration: BoxDecoration(
        color: AppColors.surface2,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(code,
                textAlign: TextAlign.center,
                style: AppTypography.title1.copyWith(letterSpacing: 6)),
          ),
          IconButton(
            tooltip: 'Copy',
            onPressed: onCopy,
            icon: const Icon(Icons.copy_rounded,
                size: 20, color: AppColors.muted),
          ),
        ],
      ),
    );
  }
}
