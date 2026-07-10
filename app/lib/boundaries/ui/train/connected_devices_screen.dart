import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../boundaries/gateways/ble_heart_rate_source.dart';
import '../../../controls/manage_connected_device.dart';
import '../../../core/theme/app_buttons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../entities/connected_device.dart';
import '../../../entities/enums.dart';
import '../common/status_badge.dart';

// (#) The connected devices screen. Lists your paired wearables and sensors and
// lets you add or remove them. Adding runs a real Bluetooth HR scan alongside
// the demo device list; pairing and toggling all go through the control.
class ConnectedDevicesScreen extends ConsumerWidget {
  const ConnectedDevicesScreen({super.key});

  // (#) Builds the screen: the device list with a divider between each row, and
  // an add device button at the bottom that opens the scan sheet.
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final devicesAsync = ref.watch(connectedDevicesProvider);

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: const Text('CONNECTED DEVICES',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: AppColors.ink)),
      ),
      body: devicesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
            child: Text('Could not load devices.', style: AppTypography.subheadline)),
        data: (devices) => Column(
          children: [
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                itemCount: devices.length,
                separatorBuilder: (_, _) => const Divider(color: AppColors.faint, height: 1),
                itemBuilder: (context, i) => _DeviceRow(device: devices[i]),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: OutlinedButton(
                onPressed: () => _openScanModal(context, ref),
                style: AppButtonStyles.outlinedAccent(height: 52),
                child: const Text('+ ADD DEVICE'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // (#) Opens the pairing sheet, waits for a pick, then asks the control to pair
  // it and shows a snackbar saying whether it worked. Real Bluetooth finds show
  // first; on a simulator the scan finds nothing so the demo list is the path.
  Future<void> _openScanModal(BuildContext context, WidgetRef ref) async {
    const discoverable = <(DeviceType, String)>[
      (DeviceType.appleWatch, 'Apple Watch Series 9'),
      (DeviceType.fitbit, 'Fitbit Charge 6'),
      (DeviceType.garmin, 'Garmin Forerunner 265'),
      (DeviceType.polar, 'Polar H10'),
      (DeviceType.oura, 'Oura Ring Gen3'),
      (DeviceType.other, 'Other device'),
    ];

    final picked = await showModalBottomSheet<(DeviceType, String, String?)>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: _ScanSheet(discoverable: discoverable),
      ),
    );
    if (picked == null) return;

    final device = await ref.read(manageConnectedDeviceProvider).pair(
        type: picked.$1, name: picked.$2, bleRemoteId: picked.$3);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(device == null
              ? 'Could not pair device.'
              : '${device.deviceName} connected — its heart rate feeds your next workout.')));
    }
  }
}

// (#) The bottom sheet that appears while pairing: shows a scanning spinner,
// then the list of devices to pick from.
class _ScanSheet extends StatefulWidget {
  const _ScanSheet({required this.discoverable});

  final List<(DeviceType, String)> discoverable; // (#) the demo devices to always offer

  // (#) Makes the state that tracks the scan progress and nearby finds.
  @override
  State<_ScanSheet> createState() => _ScanSheetState();
}

// (#) Holds the sheet's state: whether we're still scanning and any real devices found.
class _ScanSheetState extends State<_ScanSheet> {
  bool _scanning = true; // (#) true while the spinner shows
  List<ScannedBleDevice> _nearby = const []; // (#) real Bluetooth devices the scan turned up

  // (#) Kicks off the real BLE scan and a timer to drop the spinner after a moment.
  @override
  void initState() {
    super.initState();
    // Real scan (returns [] without Bluetooth); the spinner covers it.
    scanForHeartRateDevices().then((found) {
      if (mounted) setState(() => _nearby = found);
    });
    Future.delayed(const Duration(milliseconds: 1400), () {
      if (mounted) setState(() => _scanning = false);
    });
  }

  // (#) Builds the sheet: the spinner while scanning, then a nearby section for
  // real finds (if any) and the demo device list, each row tappable to pick it.
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('PAIR A DEVICE',
              style: AppTypography.caption2.copyWith(letterSpacing: 1.5)),
          const SizedBox(height: 12),
          if (_scanning) ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Center(
                  child: Column(children: [
                SizedBox(
                    height: 32,
                    width: 32,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: AppColors.accent)),
                SizedBox(height: 12),
                Text('Scanning for devices…', style: AppTypography.subheadline),
              ])),
            ),
          ] else ...[
            if (_nearby.isNotEmpty) ...[
              Text('NEARBY (BLUETOOTH)',
                  style: AppTypography.caption2.copyWith(letterSpacing: 1.5)),
              for (final d in _nearby)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading:
                      const Text('📡', style: TextStyle(fontSize: 24)),
                  title: Text(d.name, style: AppTypography.body),
                  subtitle: Text('Live heart rate · real device',
                      style: AppTypography.caption1),
                  trailing: const Icon(Icons.add_circle_outline,
                      color: AppColors.accent),
                  onTap: () => Navigator.of(context)
                      .pop((DeviceType.other, d.name, d.remoteId)),
                ),
              const SizedBox(height: 8),
              Text('DEMO DEVICES',
                  style: AppTypography.caption2.copyWith(letterSpacing: 1.5)),
            ],
            for (final (type, name) in widget.discoverable)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Text(type.emoji, style: const TextStyle(fontSize: 24)),
                title: Text(name, style: AppTypography.body),
                subtitle: Text(type.label, style: AppTypography.caption1),
                trailing: const Icon(Icons.add_circle_outline, color: AppColors.accent),
                onTap: () => Navigator.of(context).pop((type, name, null)),
              ),
          ],
        ],
      ),
    );
  }
}

// (#) One row in the device list: emoji, name, connected badge, last-synced
// line, and for real devices a toggle and a delete button.
class _DeviceRow extends ConsumerWidget {
  const _DeviceRow({required this.device});

  final ConnectedDevice device; // (#) the device this row shows

  // (#) Builds the friendly "last synced" line from the device's timestamp.
  String _lastSynced() {
    final t = device.lastSyncedAt;
    if (t == null) return device.isPhoneSensors ? 'Built-in · always available' : 'Not synced yet';
    final mins = DateTime.now().difference(t.toLocal()).inMinutes;
    if (mins < 1) return 'Last synced: just now';
    if (mins < 60) return 'Last synced: $mins min ago';
    final hours = mins ~/ 60;
    if (hours < 24) return 'Last synced: ${hours}h ago';
    return 'Last synced: ${hours ~/ 24}d ago';
  }

  // (#) Builds the row: the device info on the left, and for non-phone devices a
  // toggle to turn it on/off plus a delete button that confirms before removing.
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final manage = ref.read(manageConnectedDeviceProvider);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Text(device.deviceType.emoji, style: const TextStyle(fontSize: 26)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                        child: Text(device.deviceName,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.headline)),
                    const SizedBox(width: 8),
                    StatusBadge(device.isActive ? 'CONNECTED' : 'OFF',
                        bg: device.isActive ? AppColors.successBright : null,
                        fg: device.isActive ? AppColors.ink : AppColors.muted,
                        weight:
                            device.isActive ? FontWeight.w800 : FontWeight.w600,
                        borderColor: device.isActive ? null : AppColors.faint,
                        radius: 10),
                  ],
                ),
                const SizedBox(height: 2),
                Text(_lastSynced(), style: AppTypography.subheadline),
              ],
            ),
          ),
          // Phone sensors are system-managed: no toggle-off, no removal.
          if (!device.isPhoneSensors) ...[
            Switch(
              value: device.isActive,
              activeThumbColor: AppColors.bg,
              activeTrackColor: AppColors.accent,
              inactiveTrackColor: AppColors.surface2,
              onChanged: (on) => manage.setActive(device, on),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: AppColors.muted),
              onPressed: () async {
                final ok = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    backgroundColor: AppColors.surface,
                    title: Text('Remove ${device.deviceName}?'),
                    content: const Text('Past workouts keep their recorded data.'),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.of(ctx).pop(false),
                          child: const Text('Cancel')),
                      TextButton(
                          onPressed: () => Navigator.of(ctx).pop(true),
                          child: const Text('Remove',
                              style: TextStyle(color: AppColors.danger))),
                    ],
                  ),
                );
                if (ok == true) await manage.remove(device);
              },
            ),
          ],
        ],
      ),
    );
  }
}
