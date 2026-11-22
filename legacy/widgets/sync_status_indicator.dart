import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../core/services/sync_service.dart';

/// Widget to display the current synchronization status
class SyncStatusIndicator extends StatelessWidget {
  final SyncStatus status;
  final VoidCallback? onTap;

  const SyncStatusIndicator({super.key, required this.status, this.onTap});

  @override
  Widget build(BuildContext context) {
    // Format date
    final dateFormat = DateFormat('yyyy-MM-dd HH:mm');
    final lastSyncText =
        status.lastSyncTime != null
            ? dateFormat.format(status.lastSyncTime!)
            : 'Never';

    // Choose appropriate icon and color based on status
    final (icon, color) = _getIconAndColor();

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  status.message,
                  style: TextStyle(
                    fontSize: 11,
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Last sync: $lastSyncText',
                  style: TextStyle(fontSize: 10, color: color.withOpacity(0.7)),
                ),
              ],
            ),
            if (status.inProgress) ...[
              const SizedBox(width: 6),
              SizedBox(
                width: 12,
                height: 12,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Get appropriate icon and color based on status
  (IconData, Color) _getIconAndColor() {
    if (status.hasError) {
      return (Icons.error_outline, Colors.red);
    } else if (!status.isOnline) {
      return (Icons.cloud_off, Colors.orange);
    } else if (status.inProgress) {
      return (Icons.sync, Colors.blue);
    } else {
      return (Icons.cloud_done, Colors.green);
    }
  }
}

/// Widget that listens to the SyncService and displays the current status
class SyncStatusListener extends StatelessWidget {
  final VoidCallback? onTap;

  const SyncStatusListener({super.key, this.onTap});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<SyncStatus>(
      stream: SyncService().syncStatusStream,
      builder: (context, snapshot) {
        // Show a default status if no data is available yet
        final status =
            snapshot.data ??
            SyncStatus(isOnline: false, message: 'Initializing...');

        return SyncStatusIndicator(
          status: status,
          onTap: onTap ?? () => SyncService().scheduleSyncWithServer(),
        );
      },
    );
  }
}

/// Arabic alias for sync status indicator
class ArabicSyncStatusIndicator extends SyncStatusListener {
  const ArabicSyncStatusIndicator({super.key, super.onTap});
}
