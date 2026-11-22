import 'package:flutter/material.dart';

import '../core/services/analytics_service.dart';
import '../core/services/sync_service.dart';
import 'sync_status_indicator.dart';

/// A demo screen showing how to use the sync status indicator
class SyncStatusDemo extends StatelessWidget {
  const SyncStatusDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sync Status Demo'),
        actions: [
          // Add the sync status indicator to the app bar
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Center(
              child: SyncStatusListener(onTap: () => _showSyncOptions(context)),
            ),
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Sync Status Demo',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text(
              'This demo shows how to integrate the sync status indicator into your UI.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => AnalyticsService.syncWithServer(),
              child: const Text('Manual Sync'),
            ),
            const SizedBox(height: 16),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                'بإمكانك استخدام مؤشر حالة المزامنة للتعرف على حالة المزامنة الحالية بين التطبيق وخادم Supabase.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
            ),
            const SizedBox(height: 32),
            // Show current status in a larger format
            StreamBuilder<SyncStatus>(
              stream: SyncService().syncStatusStream,
              builder: (context, snapshot) {
                final status =
                    snapshot.data ??
                    SyncStatus(isOnline: false, message: 'Initializing...');

                return Column(
                  children: [
                    Text(
                      'Current Status: ${status.message}',
                      style: const TextStyle(fontSize: 18),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Online: ${status.isOnline ? 'Yes' : 'No'}',
                      style: const TextStyle(fontSize: 16),
                    ),
                    if (status.lastSyncTime != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Last Sync: ${status.lastSyncTime!.toString()}',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ],
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Show a dialog with sync options
  void _showSyncOptions(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Sync Options'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Arabic explanation
                const Text(
                  'خيارات المزامنة:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const Text(
                  'يمكنك مزامنة البيانات يدويًا أو ضبط المزامنة التلقائية',
                  style: TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 16),
                // English explanation
                const Text(
                  'Sync Options:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const Text(
                  'You can manually sync data or configure automatic sync',
                  style: TextStyle(fontSize: 14),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  AnalyticsService.syncWithServer();
                  Navigator.pop(context);
                },
                child: const Text('Sync Now'),
              ),
            ],
          ),
    );
  }
}
