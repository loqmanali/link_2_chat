import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../core/services/analytics_service.dart';
import '../core/services/sync_service.dart';

class SyncStatusWidget extends StatelessWidget {
  final bool mini;

  const SyncStatusWidget({super.key, this.mini = false});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<SyncStatus>(
      stream: AnalyticsService.getSyncStatusStream(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return _buildStatusIndicator(
            isOnline: true,
            message: 'Ready',
            icon: Icons.cloud_done,
            color: Colors.grey,
            mini: mini,
          );
        }

        final status = snapshot.data!;

        if (status.inProgress) {
          return _buildStatusIndicator(
            isOnline: status.isOnline,
            message: 'Syncing...',
            icon: Icons.sync,
            color: Colors.blue,
            showProgress: true,
            mini: mini,
          );
        } else if (status.hasError) {
          return _buildStatusIndicator(
            isOnline: status.isOnline,
            message: 'Sync failed',
            icon: Icons.sync_problem,
            color: Colors.red,
            mini: mini,
            lastSyncTime: status.lastSyncTime,
          );
        } else if (!status.isOnline) {
          return _buildStatusIndicator(
            isOnline: false,
            message: 'Offline',
            icon: Icons.cloud_off,
            color: Colors.orange,
            mini: mini,
            lastSyncTime: status.lastSyncTime,
          );
        } else {
          return _buildStatusIndicator(
            isOnline: true,
            message: 'Synced',
            icon: Icons.cloud_done,
            color: Colors.green,
            mini: mini,
            lastSyncTime: status.lastSyncTime,
          );
        }
      },
    );
  }

  Widget _buildStatusIndicator({
    required bool isOnline,
    required String message,
    required IconData icon,
    required Color color,
    bool showProgress = false,
    DateTime? lastSyncTime,
    required bool mini,
  }) {
    if (mini) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showProgress)
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
              ),
            )
          else
            Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
          Text(message, style: TextStyle(fontSize: 12, color: color)),
        ],
      );
    }

    final dateFormatter = DateFormat('MMM d, yyyy HH:mm');
    final lastSyncText =
        lastSyncTime != null
            ? 'Last synced: ${dateFormatter.format(lastSyncTime)}'
            : 'Not synced yet';

    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            if (showProgress)
              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
              Icon(icon, color: color),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message,
                    style: TextStyle(fontWeight: FontWeight.bold, color: color),
                  ),
                  Text(
                    lastSyncText,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
            if (isOnline && !showProgress)
              IconButton(
                icon: const Icon(Icons.sync, size: 20),
                onPressed: () {
                  AnalyticsService.syncWithServer();
                },
                tooltip: 'Sync now',
              ),
          ],
        ),
      ),
    );
  }
}
