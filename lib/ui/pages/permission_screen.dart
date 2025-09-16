import 'package:flutter/material.dart';
import 'package:flutter_remix/flutter_remix.dart';
import 'package:nix/providers/music_provider.dart';
import 'package:provider/provider.dart';
import '../../providers/permission_provider.dart';

class PermissionScreen extends StatelessWidget {
  const PermissionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final permissionProvider = Provider.of<PermissionProvider>(context);

    if (permissionProvider.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Flexible(
              child: Center(
                child: Text(
                  'App Permissions',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ),
            ),
            Flexible(
              flex: 2,
              child: Column(
                children: [
                  _buildPermissionCard(
                    context,
                    icon: FlutterRemix.music_2_line,
                    title: 'Audio Access',
                    subtitle:
                        'Required to scan and play music files on your device.',
                    isGranted: permissionProvider.storageGranted,
                    onTap: () async {
                      await context.read<MusicProvider>().requestAndLoadSongs();
                      await context.read<PermissionProvider>().requestStorage();
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildPermissionCard(
                    context,
                    icon: FlutterRemix.bluetooth_line,
                    title: 'Bluetooth Access',
                    subtitle:
                        'Required to connect with Bluetooth audio devices.',
                    isGranted: permissionProvider.bluetoothGranted,
                    onTap: () async {
                      await permissionProvider.requestBluetooth();
                    },
                  ),
                ],
              ),
            ),
            const Spacer(),
            FilledButton(
              onPressed: permissionProvider.allGranted
                  ? () async {
                      await permissionProvider.savePermissionsCompleted();
                      Navigator.pushReplacementNamed(context, '/name');
                    }
                  : null,
              child: const Text('Continue'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPermissionCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isGranted,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(
                icon,
                size: 28,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              Icon(
                isGranted
                    ? Icons.check_circle
                    : FlutterRemix.error_warning_fill,
                color: isGranted
                    ? Colors.green
                    : Theme.of(context).colorScheme.error,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
