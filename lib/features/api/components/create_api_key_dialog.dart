import 'package:flutter/material.dart';

import '../../../core/config/app_theme.dart';
import '../../../core/models/api_key.dart';

class CreateApiKeyDialog extends StatefulWidget {
  final Function(String name, String description, List<ApiPermission>)
  onKeyCreated;

  const CreateApiKeyDialog({super.key, required this.onKeyCreated});

  @override
  State<CreateApiKeyDialog> createState() => _CreateApiKeyDialogState();
}

class _CreateApiKeyDialogState extends State<CreateApiKeyDialog> {
  final nameController = TextEditingController();
  final descriptionController = TextEditingController();
  final formKey = GlobalKey<FormState>();
  bool isLoading = false;
  final Map<ApiPermission, bool> selectedPermissions = {
    for (var permission in ApiPermission.values) permission: false,
  };

  @override
  void initState() {
    super.initState();
    // Set default permissions
    selectedPermissions[ApiPermission.generateLinks] = true;
    selectedPermissions[ApiPermission.viewHistory] = true;
  }

  @override
  void dispose() {
    nameController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Create API Key'),
      content: Form(
        key: formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Key Name',
                  hintText: 'e.g. Mobile App Integration',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a name for your API key';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description (optional)',
                  hintText: 'e.g. Used for mobile app integration',
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 24),
              const Text(
                'Permissions',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              _buildPermissionsSelection(),
              const SizedBox(height: 16),
              const Text(
                'Security Note:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: Colors.orange,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Your API key provides access to your account data. Never share your API keys and only grant the permissions necessary for each integration.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        if (isLoading)
          const Padding(
            padding: EdgeInsets.all(8.0),
            child: SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          )
        else
          ElevatedButton(
            onPressed: _createKey,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('Create'),
          ),
      ],
    );
  }

  Widget _buildPermissionsSelection() {
    return Column(
      children:
          ApiPermission.values.map((permission) {
            return CheckboxListTile(
              title: Text(
                permission.displayName,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              subtitle: Text(
                permission.description,
                style: const TextStyle(fontSize: 12),
              ),
              value: selectedPermissions[permission],
              onChanged: (value) {
                setState(() {
                  selectedPermissions[permission] = value ?? false;
                });
              },
              dense: true,
              contentPadding: EdgeInsets.zero,
            );
          }).toList(),
    );
  }

  void _createKey() {
    if (formKey.currentState!.validate()) {
      // Check if at least one permission is selected
      final hasPermissions = selectedPermissions.values.any(
        (selected) => selected,
      );

      if (!hasPermissions) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select at least one permission'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

      setState(() {
        isLoading = true;
      });

      // Get selected permissions
      final permissions = <ApiPermission>[];
      selectedPermissions.forEach((permission, selected) {
        if (selected) permissions.add(permission);
      });

      // Call the callback
      widget.onKeyCreated(
        nameController.text.trim(),
        descriptionController.text.trim(),
        permissions,
      );

      Navigator.pop(context);
    }
  }
}
