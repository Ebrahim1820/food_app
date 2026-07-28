import 'package:flutter/material.dart';
import 'package:food_app/controllers/food_controllers/food_business_controllers/business_partner_controller.dart';
import 'package:food_app/models/food_models/business_models/team_member_model.dart';
import 'package:food_app/constants/food/business_constants/business_settings_strings.dart';
import 'package:food_app/widgets/common/custom_dynamic_button.dart';
import 'package:design_system/design_system.dart';
import 'package:food_app/widgets/common/app_snackbar.dart';
import 'package:get/get.dart';

class TeamMembersScreen extends StatefulWidget {
  /// When provided the screen is embedded inside another Scaffold's body
  /// (no inner AppBar). The callback is invoked by the back button.
  /// When null the screen is used as a standalone route and pops via Get.back().
  const TeamMembersScreen({super.key, this.onBack});
  final VoidCallback? onBack;

  @override
  State<TeamMembersScreen> createState() => _TeamMembersScreenState();
}

class _TeamMembersScreenState extends State<TeamMembersScreen> {
  List<TeamMemberModel> _members = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadMembers();
  }

  Future<void> _loadMembers() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final members = await Get.find<BusinessPartnerController>()
          .fetchMembers();
      if (mounted) setState(() => _members = members);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final embedded = widget.onBack != null;

    // Embedded mode: live inside the dashboard IndexedStack.
    // No inner Scaffold — the outer one handles chrome.
    // Stack overlay gives us a FAB without needing a nested Scaffold.
    if (embedded) {
      return ColoredBox(
        color: AppColors.background,
        child: Stack(
          children: [
            Column(
              children: [
                _EmbeddedHeader(
                  onBack: widget.onBack!,
                  onInvite: _showInviteSheet,
                ),
                _InfoBanner(),
                Expanded(child: _buildBody(bottomPadding: 88)),
              ],
            ),
            Positioned(
              right: 16,
              bottom: 16,
              child: FloatingActionButton.extended(
                heroTag: null,
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.white,
                icon: const Icon(Icons.person_add_outlined),
                label: Text(BusinessTeamStrings.inviteButton),
                onPressed: _showInviteSheet,
              ),
            ),
          ],
        ),
      );
    }

    // Standalone-route mode: own Scaffold + AppBar + FAB.
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          color: AppColors.navy,
          onPressed: () => Get.back(),
        ),
        title: Text(
          BusinessTeamStrings.appBarTitle,
          style: const TextStyle(
            color: AppColors.navy,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        actions: [
          CustomDynamicButton(
            label: BusinessTeamStrings.inviteButton,
            onPressed: _showInviteSheet,
            variant: CustomButtonVariant.text,
            icon: Icons.person_add_outlined,
          ),
          const SizedBox(width: 8),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: null,
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        icon: const Icon(Icons.person_add_outlined),
        label: Text(BusinessTeamStrings.inviteButton),
        onPressed: _showInviteSheet,
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            _InfoBanner(),
            Expanded(child: _buildBody(bottomPadding: 100)),
          ],
        ),
      ),
    );
  }

  Widget _buildBody({required double bottomPadding}) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: AppColors.error, size: 40),
            const SizedBox(height: 12),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.gray500),
            ),
            const SizedBox(height: 16),
            CustomDynamicButton(
              label: BusinessTeamStrings.retryButton,
              onPressed: _loadMembers,
            ),
          ],
        ),
      );
    }
    if (_members.isEmpty) return _EmptyState(onInvite: _showInviteSheet);
    return ListView.separated(
      padding: EdgeInsets.fromLTRB(16, 12, 16, bottomPadding),
      itemCount: _members.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, i) => _MemberCard(
        member: _members[i],
        onEdit: _members[i].isOwner
            ? null
            : () => _showEditSheet(_members[i], i),
        onRemove: _members[i].isOwner
            ? null
            : () => _confirmRemove(_members[i], i),
      ),
    );
  }

  void _showInviteSheet() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.transparent,
      builder: (_) => _InviteSheet(
        onInvite: (member) async {
          await Get.find<BusinessPartnerController>().assignMember(
            email: member.email,
            role: member.role,
            permissions: member.permissions.map((p) => p.apiKey).toList(),
          );
          if (mounted) setState(() => _members.add(member));
          if (mounted) Navigator.of(context).pop();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  BusinessTeamStrings.inviteSentSnack(member.email),
                ),
                backgroundColor: AppColors.successDark,
              ),
            );
          }
        },
      ),
    );
  }

  void _showEditSheet(TeamMemberModel member, int index) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.transparent,
      builder: (_) => _EditPermissionsSheet(
        member: member,
        onSave: (updated) {
          setState(() => _members[index] = updated);
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(BusinessTeamStrings.permissionsUpdatedSnack),
              backgroundColor: AppColors.successDark,
            ),
          );
        },
      ),
    );
  }

  void _confirmRemove(TeamMemberModel member, int index) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(BusinessTeamStrings.removeDialogTitle),
        content: Text(BusinessTeamStrings.removeDialogBody(member.name)),
        actions: [
          CustomDynamicButton(
            label: BusinessTeamStrings.removeDialogCancel,
            onPressed: () => Navigator.of(context).pop(),
            variant: CustomButtonVariant.text,
          ),
          CustomDynamicButton(
            label: BusinessTeamStrings.removeDialogConfirm,
            accentColor: AppColors.error,
            onPressed: () async {
              Navigator.of(context).pop();
              try {
                await Get.find<BusinessPartnerController>().removeMember(
                  email: member.email,
                );
                if (mounted) setState(() => _members.removeAt(index));
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        BusinessTeamStrings.removedSnack(member.name),
                      ),
                      backgroundColor: AppColors.successDark,
                    ),
                  );
                }
              } catch (e) {
                AppSnackbar.error(
                  BusinessTeamStrings.removeFailedSnack,
                  e.toString(),
                );
              }
            },
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Embedded Header (replaces AppBar when screen is used inside IndexedStack)
// ---------------------------------------------------------------------------
class _EmbeddedHeader extends StatelessWidget {
  const _EmbeddedHeader({required this.onBack, required this.onInvite});
  final VoidCallback onBack;
  final VoidCallback onInvite;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.white,
      padding: const EdgeInsets.fromLTRB(4, 8, 8, 8),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
            color: AppColors.navy,
            onPressed: onBack,
          ),
          Expanded(
            child: Text(
              BusinessTeamStrings.appBarTitle,
              style: const TextStyle(
                color: AppColors.navy,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),
          CustomDynamicButton(
            label: BusinessTeamStrings.inviteButton,
            onPressed: onInvite,
            variant: CustomButtonVariant.text,
            icon: Icons.person_add_outlined,
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Info Banner
// ---------------------------------------------------------------------------
class _InfoBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.infoLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.infoDark.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: AppColors.infoDark, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              BusinessTeamStrings.descriptionText,
              style: const TextStyle(color: AppColors.infoDark, fontSize: 12.5),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Member Card
// ---------------------------------------------------------------------------
class _MemberCard extends StatelessWidget {
  const _MemberCard({
    required this.member,
    required this.onEdit,
    required this.onRemove,
  });

  final TeamMemberModel member;
  final VoidCallback? onEdit;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header row ──────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 12, 10),
            child: Row(
              children: [
                _Avatar(member),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              member.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                color: AppColors.navy,
                                fontSize: 15,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (member.isOwner) ...[
                            const SizedBox(width: 6),
                            _Tag('Owner', AppColors.primary),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        member.email,
                        style: const TextStyle(
                          color: AppColors.gray500,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _StatusBadge(member.status),
                    if (!member.isOwner) ...[
                      const SizedBox(height: 6),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _IconBtn(
                            icon: Icons.edit_outlined,
                            color: AppColors.primary,
                            tooltip: BusinessTeamStrings.editPermissionsTooltip,
                            onPressed: onEdit,
                          ),
                          const SizedBox(width: 2),
                          _IconBtn(
                            icon: Icons.person_remove_outlined,
                            color: AppColors.error,
                            tooltip: BusinessTeamStrings.removeMemberTooltip,
                            onPressed: onRemove,
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),

          // ── Role label ───────────────────────────────────────────────────
          if (member.role.isNotEmpty && !member.isOwner)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 6),
              child: Row(
                children: [
                  const Icon(
                    Icons.badge_outlined,
                    size: 13,
                    color: AppColors.gray400,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    member.role,
                    style: const TextStyle(
                      color: AppColors.gray500,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),

          // ── Permission chips ─────────────────────────────────────────────
          if (member.permissions.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: Wrap(
                spacing: 6,
                runSpacing: 4,
                children: member.permissions
                    .map((p) => _PermissionChip(p))
                    .toList(),
              ),
            )
          else if (!member.isOwner)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
              child: Text(
                BusinessTeamStrings.noPermissions,
                style: const TextStyle(color: AppColors.gray400, fontSize: 12),
              ),
            ),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar(this.member);
  final TeamMemberModel member;

  @override
  Widget build(BuildContext context) {
    final color = member.isOwner ? AppColors.primary : AppColors.gray500;
    return CircleAvatar(
      radius: 22,
      backgroundColor: color.withValues(alpha: 0.15),
      child: Text(
        member.initials,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 15,
        ),
      ),
    );
  }
}

class _IconBtn extends StatelessWidget {
  const _IconBtn({
    required this.icon,
    required this.color,
    required this.tooltip,
    required this.onPressed,
  });
  final IconData icon;
  final Color color;
  final String tooltip;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(icon, size: 18),
      color: color,
      tooltip: tooltip,
      onPressed: onPressed,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
      visualDensity: VisualDensity.compact,
    );
  }
}

class _PermissionChip extends StatelessWidget {
  const _PermissionChip(this.permission);
  final TeamPermission permission;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.successDark.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.successDark.withValues(alpha: 0.18),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(permission.icon, size: 11, color: AppColors.successDark),
          const SizedBox(width: 4),
          Text(
            permission.label,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.successDark,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge(this.status);
  final MemberStatus status;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      MemberStatus.active => ('Active', AppColors.successDark),
      MemberStatus.pending => ('Pending', AppColors.warningDark),
      MemberStatus.suspended => ('Suspended', AppColors.error),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag(this.label, this.color);
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Empty State
// ---------------------------------------------------------------------------
class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onInvite});
  final VoidCallback onInvite;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.group_outlined,
                size: 48,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              BusinessTeamStrings.emptyTitle,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.navy,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              BusinessTeamStrings.emptySubtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.gray500),
            ),
            const SizedBox(height: 24),
            CustomDynamicButton(
              label: BusinessTeamStrings.inviteFirstButton,
              onPressed: onInvite,
              icon: Icons.person_add_outlined,
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Invite Member — bottom sheet
// ---------------------------------------------------------------------------
class _InviteSheet extends StatefulWidget {
  const _InviteSheet({required this.onInvite});
  final Future<void> Function(TeamMemberModel) onInvite;

  @override
  State<_InviteSheet> createState() => _InviteSheetState();
}

class _InviteSheetState extends State<_InviteSheet> {
  final _emailCtrl = TextEditingController();
  final _roleCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _selected = <TeamPermission>{};
  bool _submitted = false;
  bool _loading = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _roleCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.88,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, scroll) => Container(
        decoration: const BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            _SheetHandle(),
            _SheetTitle(
              icon: Icons.person_add_outlined,
              title: BusinessTeamStrings.inviteSheetTitle,
            ),
            const Divider(height: 1),
            Expanded(
              child: Form(
                key: _formKey,
                child: ListView(
                  controller: scroll,
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
                  children: [
                    _FieldLabel(BusinessTeamStrings.emailFieldLabel),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      decoration: _inputDecoration(
                        hint: 'member@email.com',
                        icon: Icons.email_outlined,
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return BusinessTeamStrings.emailRequired;
                        }
                        if (!v.contains('@'))
                          return BusinessTeamStrings.emailInvalid;
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    _FieldLabel(BusinessTeamStrings.roleFieldLabel),
                    const SizedBox(height: 4),
                    Text(
                      BusinessTeamStrings.roleFieldOptional,
                      style: const TextStyle(
                        color: AppColors.gray400,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _roleCtrl,
                      decoration: _inputDecoration(
                        hint: BusinessTeamStrings.roleFieldHint,
                        icon: Icons.badge_outlined,
                      ),
                    ),
                    const SizedBox(height: 24),
                    _FieldLabel(BusinessTeamStrings.permissionsFieldLabel),
                    const SizedBox(height: 4),
                    Text(
                      BusinessTeamStrings.permissionsFieldHint,
                      style: const TextStyle(
                        color: AppColors.gray400,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...TeamPermission.values.map(
                      (p) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _PermissionToggle(
                          permission: p,
                          selected: _selected.contains(p),
                          onChanged: (v) => setState(() {
                            v ? _selected.add(p) : _selected.remove(p);
                          }),
                        ),
                      ),
                    ),
                    if (_submitted && _selected.isEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Text(
                          BusinessTeamStrings.selectPermissionHint,
                          style: const TextStyle(
                            color: AppColors.error,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    const SizedBox(height: 8),
                    FilledButton.icon(
                      icon: _loading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.white,
                              ),
                            )
                          : const Icon(Icons.send_outlined),
                      label: Text(
                        _loading
                            ? BusinessTeamStrings.sendingButton
                            : BusinessTeamStrings.sendInviteButton,
                      ),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: _loading ? null : _submit,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    setState(() => _submitted = true);
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await widget.onInvite(
        TeamMemberModel(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          name: _emailCtrl.text.split('@').first,
          email: _emailCtrl.text.trim(),
          isOwner: false,
          status: MemberStatus.pending,
          permissions: Set.from(_selected),
          role: _roleCtrl.text.trim(),
        ),
      );
    } catch (e) {
      AppSnackbar.error(BusinessTeamStrings.inviteFailedSnack, e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}

// ---------------------------------------------------------------------------
// Edit Permissions — bottom sheet
// ---------------------------------------------------------------------------
class _EditPermissionsSheet extends StatefulWidget {
  const _EditPermissionsSheet({required this.member, required this.onSave});
  final TeamMemberModel member;
  final ValueChanged<TeamMemberModel> onSave;

  @override
  State<_EditPermissionsSheet> createState() => _EditPermissionsSheetState();
}

class _EditPermissionsSheetState extends State<_EditPermissionsSheet> {
  late final Set<TeamPermission> _selected;

  @override
  void initState() {
    super.initState();
    _selected = Set.from(widget.member.permissions);
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.92,
      builder: (_, scroll) => Container(
        decoration: const BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            _SheetHandle(),
            // Member identity header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                    child: Text(
                      widget.member.initials,
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.member.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.navy,
                          ),
                        ),
                        Text(
                          widget.member.email,
                          style: const TextStyle(
                            color: AppColors.gray500,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _StatusBadge(widget.member.status),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView(
                controller: scroll,
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
                children: [
                  Text(
                    BusinessTeamStrings.dashboardAccessLabel,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColors.navy,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...TeamPermission.values.map(
                    (p) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _PermissionToggle(
                        permission: p,
                        selected: _selected.contains(p),
                        onChanged: (v) => setState(() {
                          v ? _selected.add(p) : _selected.remove(p);
                        }),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  CustomDynamicButton(
                    label: BusinessTeamStrings.saveChangesButton,
                    onPressed: () {
                      // TODO: PATCH /api/users/{id}/permissions
                      // Body: { "permissions": [...] }
                      widget.onSave(
                        widget.member.copyWith(
                          permissions: Set.from(_selected),
                        ),
                      );
                    },
                    fullWidth: true,
                    borderRadius: 12,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Permission Toggle Row
// ---------------------------------------------------------------------------
class _PermissionToggle extends StatelessWidget {
  const _PermissionToggle({
    required this.permission,
    required this.selected,
    required this.onChanged,
  });

  final TeamPermission permission;
  final bool selected;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
      decoration: BoxDecoration(
        color: selected
            ? AppColors.primary.withValues(alpha: 0.05)
            : AppColors.gray50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: selected
              ? AppColors.primary.withValues(alpha: 0.3)
              : AppColors.gray200,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: selected
                  ? AppColors.primary.withValues(alpha: 0.1)
                  : AppColors.gray100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              permission.icon,
              size: 18,
              color: selected ? AppColors.primary : AppColors.gray400,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  permission.label,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: selected ? AppColors.navy : AppColors.gray600,
                  ),
                ),
                Text(
                  permission.description,
                  style: const TextStyle(
                    color: AppColors.gray400,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: selected,
            onChanged: onChanged,
            activeThumbColor: AppColors.primary,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Shared sheet widgets
// ---------------------------------------------------------------------------
class _SheetHandle extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 12, bottom: 8),
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: AppColors.gray300,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}

class _SheetTitle extends StatelessWidget {
  const _SheetTitle({required this.icon, required this.title});
  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary),
          const SizedBox(width: 10),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.navy,
            ),
          ),
        ],
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontWeight: FontWeight.w600,
        color: AppColors.navy,
        fontSize: 13,
      ),
    );
  }
}

InputDecoration _inputDecoration({
  required String hint,
  required IconData icon,
}) {
  return InputDecoration(
    hintText: hint,
    prefixIcon: Icon(icon),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
  );
}
