import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Permission permission;
  final VoidCallback onGranted;

  const PermissionCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.permission,
    required this.onGranted,
  });

  Future<void> _handlePermission(BuildContext context) async {
    final status = await permission.request();
    if (status.isGranted) {
      onGranted(); // Call callback if permission granted
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('$title granted')));
    } else if (status.isPermanentlyDenied) {
      openAppSettings();
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('$title is required!')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _handlePermission(context),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Icon(icon, size: 28, color: Theme.of(context).primaryColor),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 16),
            ],
          ),
        ),
      ),
    );
  }
}
