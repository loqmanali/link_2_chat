import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import '../../core/config/app_theme.dart';
import '../../core/models/team.dart';
import '../../core/models/user.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/team_service.dart';
import '../../widgets/app_bar.dart';
import '../../widgets/loading_indicator.dart';
import 'components/member_list_item.dart';

class TeamDetailsScreen extends HookWidget {
  final Team team;

  const TeamDetailsScreen({super.key, required this.team});

  @override
  Widget build(BuildContext context) {
    final isLoading = useState(false);
    final updatedTeam = useState<Team>(team);
    final currentUser = useState<User?>(null);
    final teamService = useMemoized(() => TeamService(), []);
    final authService = useMemoized(() => AuthService(), []);
    final tabController = useTabController(initialLength: 3);

    // Load current user and refresh team data
    useEffect(() {
      _loadData(
        authService: authService,
        teamService: teamService,
        currentUser: currentUser,
        updatedTeam: updatedTeam,
        isLoading: isLoading,
        teamId: team.id,
      );
      return null;
    }, []);

    final isOwner = currentUser.value?.id == updatedTeam.value.ownerId;

    return Scaffold(
      appBar: CustomAppBar(
        title: updatedTeam.value.name,
        actions: [
          if (isOwner)
            PopupMenuButton<String>(
              onSelected:
                  (value) => _handleMenuAction(
                    context,
                    value,
                    updatedTeam.value,
                    teamService,
                    isLoading,
                  ),
              itemBuilder:
                  (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Text('Edit Team'),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Text('Delete Team'),
                    ),
                  ],
            ),
        ],
      ),
      body:
          isLoading.value
              ? const LoadingIndicator(message: 'Loading team details...')
              : Column(
                children: [
                  _buildTeamHeader(updatedTeam.value, isOwner),
                  TabBar(
                    controller: tabController,
                    tabs: const [
                      Tab(text: 'Members'),
                      Tab(text: 'Analytics'),
                      Tab(text: 'Settings'),
                    ],
                    labelColor: AppTheme.primaryColor,
                    unselectedLabelColor: Colors.grey,
                    indicatorColor: AppTheme.primaryColor,
                  ),
                  Expanded(
                    child: TabBarView(
                      controller: tabController,
                      children: [
                        _buildMembersTab(
                          context,
                          updatedTeam.value,
                          currentUser.value,
                          teamService,
                          isLoading,
                          updatedTeam,
                        ),
                        _buildAnalyticsTab(updatedTeam.value),
                        _buildSettingsTab(
                          context,
                          updatedTeam.value,
                          isOwner,
                          teamService,
                          isLoading,
                          updatedTeam,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
    );
  }

  Widget _buildTeamHeader(Team team, bool isOwner) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: AppTheme.primaryColor.withOpacity(0.05),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: AppTheme.primaryColor.withOpacity(0.2),
            child: Text(
              team.name.isNotEmpty ? team.name[0].toUpperCase() : '?',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryColor,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  team.name,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (team.description.isNotEmpty)
                  Text(
                    team.description,
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.people, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      '${team.members.length + 1} members',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(width: 12),
                    const Icon(
                      Icons.calendar_today,
                      size: 14,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Created ${_formatDate(team.createdAt)}',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMembersTab(
    BuildContext context,
    Team team,
    User? currentUser,
    TeamService teamService,
    ValueNotifier<bool> isLoading,
    ValueNotifier<Team> updatedTeam,
  ) {
    final isOwner = currentUser?.id == team.ownerId;
    final isAdmin =
        isOwner ||
        team.getMember(currentUser?.id ?? '')?.role == TeamRole.admin;

    return Column(
      children: [
        if (isAdmin)
          Padding(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton.icon(
              onPressed:
                  () => _showInviteMemberDialog(
                    context,
                    team,
                    teamService,
                    isLoading,
                    updatedTeam,
                  ),
              icon: const Icon(Icons.person_add),
              label: const Text('Invite Member'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(44),
              ),
            ),
          ),
        Expanded(
          child: ListView.builder(
            itemCount: team.members.length + 1, // +1 for the owner
            itemBuilder: (context, index) {
              if (index == 0) {
                // First item is always the owner
                return MemberListItem(
                  userId: team.ownerId,
                  role: TeamRole.owner,
                  isCurrentUser: currentUser?.id == team.ownerId,
                  canManage: false, // Owner can't be managed
                  onRoleChanged: null,
                  onRemove: null,
                );
              } else {
                final member = team.members[index - 1];
                return MemberListItem(
                  userId: member.userId,
                  role: member.role,
                  isCurrentUser: currentUser?.id == member.userId,
                  canManage: isAdmin && member.userId != currentUser?.id,
                  onRoleChanged:
                      isAdmin && member.userId != currentUser?.id
                          ? (TeamRole newRole) => _updateMemberRole(
                            team.id,
                            member.userId,
                            newRole,
                            teamService,
                            isLoading,
                            updatedTeam,
                          )
                          : null,
                  onRemove:
                      isAdmin && member.userId != currentUser?.id
                          ? () => _removeMember(
                            team.id,
                            member.userId,
                            teamService,
                            isLoading,
                            updatedTeam,
                          )
                          : null,
                );
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAnalyticsTab(Team team) {
    // This would show analytics data specific to the team
    return const Center(child: Text('Team analytics coming soon'));
  }

  Widget _buildSettingsTab(
    BuildContext context,
    Team team,
    bool isOwner,
    TeamService teamService,
    ValueNotifier<bool> isLoading,
    ValueNotifier<Team> updatedTeam,
  ) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Team Settings',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SwitchListTile(
                  title: const Text('Allow Members to Invite'),
                  subtitle: const Text(
                    'Let members with editor role or higher invite new members',
                  ),
                  value: team.settings.allowMembersToInvite,
                  onChanged:
                      isOwner
                          ? (value) => _updateTeamSettings(
                            team,
                            team.settings.copyWith(allowMembersToInvite: value),
                            teamService,
                            isLoading,
                            updatedTeam,
                          )
                          : null,
                ),
                const Divider(),
                SwitchListTile(
                  title: const Text('Require Approval for Links'),
                  subtitle: const Text(
                    'Links created by members will require admin approval',
                  ),
                  value: team.settings.requireApprovalForLinks,
                  onChanged:
                      isOwner
                          ? (value) => _updateTeamSettings(
                            team,
                            team.settings.copyWith(
                              requireApprovalForLinks: value,
                            ),
                            teamService,
                            isLoading,
                            updatedTeam,
                          )
                          : null,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        if (isOwner) ...[
          const Text(
            'Danger Zone',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.red,
            ),
          ),
          const SizedBox(height: 16),
          Card(
            color: Colors.red.shade50,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Delete Team',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Once you delete a team, there is no going back. Please be certain.',
                    style: TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => _confirmDeleteTeam(context, team.id),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Delete this team'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _loadData({
    required AuthService authService,
    required TeamService teamService,
    required ValueNotifier<User?> currentUser,
    required ValueNotifier<Team> updatedTeam,
    required ValueNotifier<bool> isLoading,
    required String teamId,
  }) async {
    try {
      isLoading.value = true;

      // Load current user
      final user = await authService.getCurrentUser();
      currentUser.value = user;

      // Refresh team data
      final freshTeamData = await teamService.getTeam(teamId);
      if (freshTeamData != null) {
        updatedTeam.value = freshTeamData;
      }
    } catch (e) {
      print('Error loading team data: $e');
    } finally {
      isLoading.value = false;
    }
  }

  void _handleMenuAction(
    BuildContext context,
    String action,
    Team team,
    TeamService teamService,
    ValueNotifier<bool> isLoading,
  ) {
    switch (action) {
      case 'edit':
        // Show edit team dialog
        break;
      case 'delete':
        _confirmDeleteTeam(context, team.id);
        break;
    }
  }

  void _confirmDeleteTeam(BuildContext context, String teamId) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Delete Team'),
            content: const Text(
              'Are you sure you want to delete this team? This action cannot be undone.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context); // Return to teams list
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

  Future<void> _updateTeamSettings(
    Team team,
    TeamSettings newSettings,
    TeamService teamService,
    ValueNotifier<bool> isLoading,
    ValueNotifier<Team> updatedTeam,
  ) async {
    try {
      isLoading.value = true;

      final updatedTeamData = await teamService.updateTeam(
        team.id,
        settings: newSettings,
      );

      if (updatedTeamData != null) {
        updatedTeam.value = updatedTeamData;
      }
    } catch (e) {
      print('Error updating team settings: $e');
    } finally {
      isLoading.value = false;
    }
  }

  void _showInviteMemberDialog(
    BuildContext context,
    Team team,
    TeamService teamService,
    ValueNotifier<bool> isLoading,
    ValueNotifier<Team> updatedTeam,
  ) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Invite Member'),
            content: const Text(
              'Invite member dialog will be implemented here',
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

  Future<void> _updateMemberRole(
    String teamId,
    String userId,
    TeamRole newRole,
    TeamService teamService,
    ValueNotifier<bool> isLoading,
    ValueNotifier<Team> updatedTeam,
  ) async {
    try {
      isLoading.value = true;

      final success = await teamService.updateTeamMemberRole(
        teamId,
        userId,
        newRole,
      );

      if (success) {
        // Refresh team data
        final freshTeamData = await teamService.getTeam(teamId);
        if (freshTeamData != null) {
          updatedTeam.value = freshTeamData;
        }
      }
    } catch (e) {
      print('Error updating member role: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _removeMember(
    String teamId,
    String userId,
    TeamService teamService,
    ValueNotifier<bool> isLoading,
    ValueNotifier<Team> updatedTeam,
  ) async {
    try {
      isLoading.value = true;

      final success = await teamService.removeTeamMember(teamId, userId);

      if (success) {
        // Refresh team data
        final freshTeamData = await teamService.getTeam(teamId);
        if (freshTeamData != null) {
          updatedTeam.value = freshTeamData;
        }
      }
    } catch (e) {
      print('Error removing member: $e');
    } finally {
      isLoading.value = false;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays < 1) {
      return 'today';
    } else if (difference.inDays < 2) {
      return 'yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return '$weeks ${weeks == 1 ? 'week' : 'weeks'} ago';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return '$months ${months == 1 ? 'month' : 'months'} ago';
    } else {
      final years = (difference.inDays / 365).floor();
      return '$years ${years == 1 ? 'year' : 'years'} ago';
    }
  }
}
