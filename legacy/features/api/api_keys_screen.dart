import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:intl/intl.dart';

import '../../core/config/app_theme.dart';
import '../../core/models/api_key.dart';
import '../../core/models/user.dart';
import '../../core/services/api_service.dart';
import '../../core/services/auth_service.dart';
import '../../widgets/app_bar.dart';
import '../../widgets/loading_indicator.dart';
import 'components/api_key_card.dart';
import 'components/create_api_key_dialog.dart';

class ApiKeysScreen extends HookWidget {
  const ApiKeysScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isLoading = useState(true);
    final apiKeys = useState<List<ApiKey>>([]);
    final currentUser = useState<User?>(null);
    final apiService = useMemoized(() => ApiService(), []);
    final authService = useMemoized(() => AuthService(), []);
    final dateFormat = DateFormat('yyyy-MM-dd HH:mm');

    // Load data when screen is opened
    useEffect(() {
      _loadData(authService, apiService, currentUser, apiKeys, isLoading);
      return null;
    }, []);

    return Scaffold(
      appBar: const CustomAppBar(title: 'API Keys'),
      body:
          isLoading.value
              ? const LoadingIndicator(message: 'Loading API keys...')
              : currentUser.value?.subscriptionTier.hasApiAccess == true
              ? _buildContent(
                context,
                apiKeys.value,
                currentUser.value!,
                apiService,
                dateFormat,
                () => _loadData(
                  authService,
                  apiService,
                  currentUser,
                  apiKeys,
                  isLoading,
                ),
              )
              : _buildUpgradePrompt(context),
      floatingActionButton:
          currentUser.value?.subscriptionTier.hasApiAccess == true
              ? FloatingActionButton(
                onPressed:
                    () => _showCreateKeyDialog(
                      context,
                      apiService,
                      currentUser.value!,
                      () => _loadData(
                        authService,
                        apiService,
                        currentUser,
                        apiKeys,
                        isLoading,
                      ),
                    ),
                child: const Icon(Icons.add),
              )
              : null,
    );
  }

  Widget _buildContent(
    BuildContext context,
    List<ApiKey> keys,
    User user,
    ApiService apiService,
    DateFormat dateFormat,
    VoidCallback onRefresh,
  ) {
    if (keys.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.vpn_key_outlined, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'No API Keys Yet',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            const Text(
              'Create an API key to integrate with external services',
              style: TextStyle(fontSize: 14, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed:
                  () => _showCreateKeyDialog(
                    context,
                    apiService,
                    user,
                    onRefresh,
                  ),
              icon: const Icon(Icons.add),
              label: const Text('Create API Key'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        onRefresh();
      },
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Your API Keys',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Use these keys to access the Link2Chat API',
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
          const SizedBox(height: 16),
          ...keys.map(
            (key) => ApiKeyCard(
              apiKey: key,
              dateFormat: dateFormat,
              onToggleActive:
                  (isActive) =>
                      _toggleKeyActive(apiService, key.id, isActive, onRefresh),
              onDelete:
                  () => _confirmDeleteKey(context, apiService, key, onRefresh),
              onCopy: () => _copyKeyToClipboard(context, key.key),
            ),
          ),
          const SizedBox(height: 24),
          const ExpansionTile(
            title: Text('API Documentation'),
            leading: Icon(Icons.book_outlined),
            children: [
              Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Base URL',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text('https://api.link2chat.app/v1'),
                    SizedBox(height: 16),
                    Text(
                      'Authentication',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Add your API key to the request headers:\nX-API-Key: your_api_key',
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Endpoints',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text('• GET /links - Get your link history'),
                    Text('• POST /links - Generate a new link'),
                    Text('• GET /analytics - Get usage statistics'),
                    Text('• GET /teams - List your teams'),
                    SizedBox(height: 16),
                    Text(
                      'For detailed documentation, visit our developer portal.',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUpgradePrompt(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.lock_outlined, size: 72, color: Colors.grey),
            const SizedBox(height: 24),
            const Text(
              'API Access Locked',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            const Text(
              'API access is available on Professional and Enterprise plans.',
              style: TextStyle(fontSize: 16, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                // Navigate to subscription screen
                Navigator.pop(context);
                Navigator.pushNamed(context, '/subscription');
              },
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
              ),
              child: const Text('Upgrade Your Plan'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _loadData(
    AuthService authService,
    ApiService apiService,
    ValueNotifier<User?> currentUser,
    ValueNotifier<List<ApiKey>> apiKeys,
    ValueNotifier<bool> isLoading,
  ) async {
    try {
      isLoading.value = true;

      // Get current user
      final user = await authService.getCurrentUser();
      currentUser.value = user;

      if (user != null && user.subscriptionTier.hasApiAccess) {
        // Get API keys
        final keys = await apiService.getUserApiKeys(user.id);
        apiKeys.value = keys;
      }
    } catch (e) {
      print('Error loading API keys: $e');
    } finally {
      isLoading.value = false;
    }
  }

  void _showCreateKeyDialog(
    BuildContext context,
    ApiService apiService,
    User user,
    VoidCallback onSuccess,
  ) {
    showDialog(
      context: context,
      builder:
          (context) => CreateApiKeyDialog(
            onKeyCreated: (name, description, permissions) async {
              final createdKey = await apiService.generateApiKey(
                user.id,
                name,
                description,
                permissions,
              );

              if (createdKey != null) {
                onSuccess();
                // Show success dialog with the key
                if (context.mounted) {
                  _showKeyCreatedDialog(context, createdKey);
                }
              }
            },
          ),
    );
  }

  void _showKeyCreatedDialog(BuildContext context, ApiKey apiKey) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('API Key Created'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Copy this key now. For security reasons, you won\'t be able to see it again.',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          apiKey.key,
                          style: const TextStyle(fontFamily: 'monospace'),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.copy),
                        onPressed:
                            () => _copyKeyToClipboard(context, apiKey.key),
                        tooltip: 'Copy to clipboard',
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
    );
  }

  Future<void> _toggleKeyActive(
    ApiService apiService,
    String keyId,
    bool isActive,
    VoidCallback onSuccess,
  ) async {
    try {
      final updated = await apiService.updateApiKey(keyId, isActive: isActive);

      if (updated != null) {
        onSuccess();
      }
    } catch (e) {
      print('Error toggling API key: $e');
    }
  }

  void _confirmDeleteKey(
    BuildContext context,
    ApiService apiService,
    ApiKey apiKey,
    VoidCallback onSuccess,
  ) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Delete API Key'),
            content: Text(
              'Are you sure you want to delete the API key "${apiKey.name}"? '
              'This action cannot be undone.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  Navigator.pop(context);
                  final success = await apiService.deleteApiKey(apiKey.id);
                  if (success) {
                    onSuccess();
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Delete'),
              ),
            ],
          ),
    );
  }

  void _copyKeyToClipboard(BuildContext context, String key) {
    Clipboard.setData(ClipboardData(text: key));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('API key copied to clipboard'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
