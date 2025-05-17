import 'package:flutter/material.dart';

import '../../../core/config/app_theme.dart';
import '../../../core/models/team.dart';
import '../../../core/models/user.dart';
import '../../../core/services/auth_service.dart';

class InviteMemberDialog extends StatefulWidget {
  final Team team;
  final Function(String userId, TeamRole role) onInvite;

  const InviteMemberDialog({
    super.key,
    required this.team,
    required this.onInvite,
  });

  @override
  State<InviteMemberDialog> createState() => _InviteMemberDialogState();
}

class _InviteMemberDialogState extends State<InviteMemberDialog> {
  final emailController = TextEditingController();
  final formKey = GlobalKey<FormState>();
  TeamRole selectedRole = TeamRole.viewer;
  bool isLoading = false;
  String? errorMessage;
  List<User> userSuggestions = [];
  bool isSearching = false;

  @override
  void dispose() {
    emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Invite Team Member'),
      content: Form(
        key: formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (errorMessage != null)
                Container(
                  padding: const EdgeInsets.all(8),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    errorMessage!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              TextFormField(
                controller: emailController,
                decoration: const InputDecoration(
                  labelText: 'Email Address',
                  prefixIcon: Icon(Icons.email_outlined),
                  hintText: 'Enter member\'s email',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter an email address';
                  }
                  if (!RegExp(
                    r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                  ).hasMatch(value)) {
                    return 'Please enter a valid email address';
                  }
                  return null;
                },
                onChanged: (value) {
                  if (value.isNotEmpty && value.contains('@')) {
                    _searchUsers(value);
                  } else {
                    setState(() {
                      userSuggestions = [];
                    });
                  }
                },
              ),
              const SizedBox(height: 8),
              if (isSearching)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8.0),
                  child: Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                ),
              if (userSuggestions.isNotEmpty) ...[
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8.0),
                  child: Text(
                    'Matching Users:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
                Container(
                  constraints: const BoxConstraints(maxHeight: 150),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: userSuggestions.length,
                    itemBuilder: (context, index) {
                      final user = userSuggestions[index];
                      // Skip users who are already in the team
                      if (widget.team.hasMember(user.id)) {
                        return const SizedBox.shrink();
                      }
                      return ListTile(
                        dense: true,
                        leading: CircleAvatar(
                          backgroundColor: Colors.grey.shade200,
                          child: Text(
                            user.name.isNotEmpty
                                ? user.name[0].toUpperCase()
                                : '?',
                            style: const TextStyle(
                              color: Colors.black54,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Text(user.name),
                        subtitle: Text(
                          user.email,
                          style: const TextStyle(fontSize: 12),
                        ),
                        onTap: () {
                          emailController.text = user.email;
                          setState(() {
                            userSuggestions = [];
                          });
                        },
                      );
                    },
                  ),
                ),
              ],
              const SizedBox(height: 16),
              const Text(
                'Select Role:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              _buildRoleSelector(),
              const SizedBox(height: 16),
              const Text(
                'Role Permissions:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              ),
              const SizedBox(height: 4),
              _buildRoleDescription(),
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
            onPressed: _inviteUser,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('Invite'),
          ),
      ],
    );
  }

  Widget _buildRoleSelector() {
    return Wrap(
      spacing: 8,
      children: [
        _buildRoleChip(TeamRole.admin, 'Admin'),
        _buildRoleChip(TeamRole.editor, 'Editor'),
        _buildRoleChip(TeamRole.viewer, 'Viewer'),
      ],
    );
  }

  Widget _buildRoleChip(TeamRole role, String label) {
    final isSelected = selectedRole == role;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() {
            selectedRole = role;
          });
        }
      },
      selectedColor: _getRoleColor(role),
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.black,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }

  Widget _buildRoleDescription() {
    String description;

    switch (selectedRole) {
      case TeamRole.admin:
        description = 'Can manage team settings, members, and view all data.';
        break;
      case TeamRole.editor:
        description = 'Can create and edit links, but cannot manage the team.';
        break;
      case TeamRole.viewer:
        description = 'Can only view team data. Cannot create or edit links.';
        break;
      default:
        description = '';
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: _getRoleColor(selectedRole).withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        description,
        style: TextStyle(fontSize: 12, color: _getRoleColor(selectedRole)),
      ),
    );
  }

  Future<void> _searchUsers(String query) async {
    setState(() {
      isSearching = true;
    });

    try {
      final authService = AuthService();
      final allUsers = await authService.getAllUsers();

      // Filter users by email (partial match)
      final matchingUsers =
          allUsers
              .where(
                (user) =>
                    user.email.toLowerCase().contains(query.toLowerCase()),
              )
              .toList();

      if (mounted) {
        setState(() {
          userSuggestions =
              matchingUsers.take(5).toList(); // Limit to 5 results
          isSearching = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isSearching = false;
        });
      }
      print('Error searching users: $e');
    }
  }

  Future<void> _inviteUser() async {
    if (!formKey.currentState!.validate()) return;

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final email = emailController.text.trim();

      // Find user by email
      final authService = AuthService();
      final allUsers = await authService.getAllUsers();
      final matchingUsers =
          allUsers
              .where((user) => user.email.toLowerCase() == email.toLowerCase())
              .toList();

      if (matchingUsers.isEmpty) {
        setState(() {
          errorMessage = 'No user found with this email address.';
          isLoading = false;
        });
        return;
      }

      final user = matchingUsers.first;

      // Check if user is already a member
      if (widget.team.hasMember(user.id)) {
        setState(() {
          errorMessage = 'This user is already a member of the team.';
          isLoading = false;
        });
        return;
      }

      // Invite user
      widget.onInvite(user.id, selectedRole);

      // Close dialog
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Error inviting user: ${e.toString()}';
        isLoading = false;
      });
    }
  }

  Color _getRoleColor(TeamRole role) {
    switch (role) {
      case TeamRole.owner:
        return Colors.amber;
      case TeamRole.admin:
        return Colors.red;
      case TeamRole.editor:
        return Colors.green;
      case TeamRole.viewer:
        return Colors.blue;
    }
  }
}
