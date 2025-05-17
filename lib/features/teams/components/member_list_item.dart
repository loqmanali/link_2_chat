import 'package:flutter/material.dart';

import '../../../core/models/team.dart';
import '../../../core/models/user.dart';
import '../../../core/services/auth_service.dart';

class MemberListItem extends StatefulWidget {
  final String userId;
  final TeamRole role;
  final bool isCurrentUser;
  final bool canManage;
  final Function(TeamRole)? onRoleChanged;
  final VoidCallback? onRemove;

  const MemberListItem({
    super.key,
    required this.userId,
    required this.role,
    required this.isCurrentUser,
    required this.canManage,
    this.onRoleChanged,
    this.onRemove,
  });

  @override
  State<MemberListItem> createState() => _MemberListItemState();
}

class _MemberListItemState extends State<MemberListItem> {
  User? user;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    setState(() {
      isLoading = true;
    });

    try {
      final authService = AuthService();
      final userData = await authService.getUser(widget.userId);

      if (mounted) {
        setState(() {
          user = userData;
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
      print('Error loading user: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            // User avatar
            CircleAvatar(
              backgroundColor: _getRoleColor(widget.role).withOpacity(0.2),
              child:
                  isLoading
                      ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                      : Text(
                        user?.name.isNotEmpty == true
                            ? user!.name[0].toUpperCase()
                            : '?',
                        style: TextStyle(
                          color: _getRoleColor(widget.role),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
            ),
            const SizedBox(width: 12),

            // User info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isLoading ? 'Loading...' : (user?.name ?? 'Unknown User'),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    isLoading ? '' : (user?.email ?? ''),
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: _getRoleColor(widget.role).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _getRoleName(widget.role),
                          style: TextStyle(
                            fontSize: 10,
                            color: _getRoleColor(widget.role),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (widget.isCurrentUser) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'YOU',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            // Actions
            if (widget.canManage) ...[
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, size: 18),
                onSelected: (value) {
                  if (value == 'remove') {
                    _confirmRemove(context);
                  } else if (value.startsWith('role_')) {
                    final role = value.substring(5);
                    _changeRole(role);
                  }
                },
                itemBuilder:
                    (context) => [
                      const PopupMenuItem(
                        value: 'role_admin',
                        child: Text('Make Admin'),
                      ),
                      const PopupMenuItem(
                        value: 'role_editor',
                        child: Text('Make Editor'),
                      ),
                      const PopupMenuItem(
                        value: 'role_viewer',
                        child: Text('Make Viewer'),
                      ),
                      const PopupMenuItem(
                        value: 'remove',
                        child: Text(
                          'Remove from Team',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
              ),
            ],
          ],
        ),
      ),
    );
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

  String _getRoleName(TeamRole role) {
    switch (role) {
      case TeamRole.owner:
        return 'OWNER';
      case TeamRole.admin:
        return 'ADMIN';
      case TeamRole.editor:
        return 'EDITOR';
      case TeamRole.viewer:
        return 'VIEWER';
    }
  }

  void _changeRole(String roleName) {
    if (widget.onRoleChanged == null) return;

    TeamRole? newRole;

    switch (roleName) {
      case 'admin':
        newRole = TeamRole.admin;
        break;
      case 'editor':
        newRole = TeamRole.editor;
        break;
      case 'viewer':
        newRole = TeamRole.viewer;
        break;
    }

    if (newRole != null) {
      widget.onRoleChanged!(newRole);
    }
  }

  void _confirmRemove(BuildContext context) {
    if (widget.onRemove == null) return;

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Remove Member'),
            content: Text(
              'Are you sure you want to remove ${user?.name ?? 'this member'} from the team?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  widget.onRemove!();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Remove'),
              ),
            ],
          ),
    );
  }
}
