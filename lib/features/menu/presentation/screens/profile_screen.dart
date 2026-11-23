import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:asmita_society/core/widgets/app_skeleton.dart';
import 'package:asmita_society/core/widgets/asmita_sub_header.dart';
import 'package:asmita_society/core/widgets/app_button.dart';
import 'package:asmita_society/core/widgets/app_refresh.dart';
import 'package:asmita_society/core/widgets/asmita_toast.dart';
import 'package:asmita_society/features/auth/bloc/auth_bloc.dart';
import 'package:asmita_society/features/auth/bloc/auth_event.dart';
import 'package:asmita_society/features/auth/bloc/auth_state.dart';
import 'package:asmita_society/features/auth/data/models/user_model.dart';
import 'package:asmita_society/core/utils/property_role_resolver.dart';

class ProfileScreen extends StatefulWidget {
  final void Function(int)? onNavigateToTab;

  const ProfileScreen({super.key, this.onNavigateToTab});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isEditing = false;
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _emailController = TextEditingController();
    _phoneController = TextEditingController();

    // Trigger profile refresh on mount
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<AuthBloc>().add(AuthRefreshProfileRequested());
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _populateControllers(UserModel user) {
    _nameController.text = user.fullName;
    _emailController.text = user.emailId ?? '';
    _phoneController.text = user.mobileNumber ?? '';
  }

  void _toggleEdit() {
    setState(() {
      _isEditing = !_isEditing;
      if (!_isEditing) {
        final state = context.read<AuthBloc>().state;
        if (state is AuthAuthenticated) {
          _populateControllers(state.user);
        }
      }
    });
  }

  void _saveProfile() {
    context.read<AuthBloc>().add(
      AuthUpdateProfileRequested(
        fullName: _nameController.text,
        email: _emailController.text,
        mobile: _phoneController.text,
      ),
    );
    setState(() {
      _isEditing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthAuthenticated) {
          _populateControllers(state.user);
        } else if (state is AuthError) {
          AsmitaToast.show(
            context,
            message: state.message,
            type: AsmitaToastType.error,
          );
        }
      },
      builder: (context, state) {
        UserModel? user;
        bool isLoading = state is AuthLoading;
        if (state is AuthAuthenticated) {
          user = state.user;
          if (!_isEditing && _nameController.text.isEmpty) {
            _populateControllers(user);
          }
        }

        final isIndustrial =
            user != null && PropertyRoleResolver.isIndustrialContext(user);

        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          body: SafeArea(
            child: Column(
              children: [
                AsmitaSubHeader(
                  title: 'Profile',
                  onBackPressed: () {
                    Navigator.pop(context);
                  },
                  trailing: GestureDetector(
                    onTap: isLoading ? null : _toggleEdit,
                    behavior: HitTestBehavior.opaque,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 2,
                      ),
                      child: Icon(
                        _isEditing ? Icons.close_rounded : Icons.edit_outlined,
                        color: Theme.of(context).colorScheme.primary,
                        size: 22,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: AppRefresh(
                    onRefresh: () async {
                      context.read<AuthBloc>().add(
                        AuthRefreshProfileRequested(),
                      );
                      await Future.delayed(const Duration(milliseconds: 700));
                    },
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: user == null
                        ? _buildProfileSkeleton(context)
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _buildProfileHeader(
                                textTheme,
                                user,
                                isIndustrial,
                              ),
                              const SizedBox(height: 16),
                              _buildContactDetailsSection(textTheme, user),
                              const SizedBox(height: 16),
                              if (isIndustrial) ...[
                                _buildWorkplaceSeatingCard(textTheme, user),
                                const SizedBox(height: 16),
                                _buildReportingDelegationCard(textTheme, user),
                                const SizedBox(height: 16),
                              ],
                              if (_isEditing) ...[
                                const SizedBox(height: 8),
                                _buildSaveButton(textTheme, isLoading),
                              ],
                              const SizedBox(height: 32),
                            ],
                          ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildProfileHeader(
    TextTheme textTheme,
    UserModel user,
    bool isIndustrial,
  ) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    String initials = user.fullName.isNotEmpty
        ? user.fullName
              .trim()
              .split(' ')
              .map((e) => e.isNotEmpty ? e[0] : '')
              .take(2)
              .join()
              .toUpperCase()
        : 'U';

    final roleTitle = user.designation.isNotEmpty
        ? user.designation
        : user.primaryRole;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.dividerColor, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.onSurface.withValues(
              alpha: isDark ? 0.2 : 0.03,
            ),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 42,
            backgroundColor: theme.colorScheme.primary,
            backgroundImage:
                user.profilePictureUrl != null &&
                    user.profilePictureUrl!.isNotEmpty
                ? NetworkImage(user.profilePictureUrl!)
                : null,
            child:
                user.profilePictureUrl == null ||
                    user.profilePictureUrl!.isEmpty
                ? Text(
                    initials,
                    style: textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                : null,
          ),
          const SizedBox(height: 16),
          Text(
            user.fullName,
            style: textTheme.titleLarge?.copyWith(
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),

          // Role Badge with Score & Duty status
          Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 6,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF1E293B)
                      : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isDark
                        ? const Color(0xFF334155)
                        : const Color(0xFFCBD5E1),
                  ),
                ),
                child: Text(
                  isIndustrial
                      ? roleTitle.toUpperCase()
                      : (user.systemRole ?? user.primaryRole).toUpperCase(),
                  style: textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFF10B981).withValues(alpha: 0.25),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: Color(0xFF10B981),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      user.isActive ? 'Active' : 'Offline',
                      style: const TextStyle(
                        color: Color(0xFF059669),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
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

  // 1. WORKPLACE & SEATING CARD
  Widget _buildWorkplaceSeatingCard(TextTheme textTheme, UserModel user) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final cabin = user.cabinCode;
    final desk = user.deskCode;
    final ext = user.extensionNumber;

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.dividerColor, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.onSurface.withValues(
              alpha: isDark ? 0.2 : 0.03,
            ),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              children: [
                Icon(
                  Icons.business_center_rounded,
                  size: 16,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'WORKPLACE & SEATING',
                  style: textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: theme.dividerColor),
          _buildInfoRow(
            icon: Icons.apartment_rounded,
            label: 'Department',
            value: user.departmentName,
            showBorder: true,
          ),
          _buildInfoRow(
            icon: Icons.layers_outlined,
            label: 'Floor & Wing',
            value: user.floorWing,
            showBorder: true,
          ),
          if (desk.isNotEmpty)
            _buildInfoRow(
              icon: Icons.chair_outlined,
              label: 'Desk Code',
              value: desk,
              showBorder: cabin.isNotEmpty || ext.isNotEmpty,
            ),
          if (cabin.isNotEmpty)
            _buildInfoRow(
              icon: Icons.meeting_room_outlined,
              label: 'Cabin',
              value: cabin,
              showBorder: ext.isNotEmpty,
            ),
          if (ext.isNotEmpty)
            _buildInfoRow(
              icon: Icons.phone_forwarded_rounded,
              label: 'Intercom Ext.',
              value: ext,
              showBorder: false,
            ),
        ],
      ),
    );
  }

  // 2. REPORTING & DELEGATION CARD
  Widget _buildReportingDelegationCard(TextTheme textTheme, UserModel user) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final reportsTo = user.reportsToName;
    final reportsDesig = user.reportsToDesignation;
    final delegatedTo = user.delegatedToName;
    final delegatedDesig = user.delegatedToDesignation;

    // Resolve Approval Tier based on power score
    final power = user.rolePower ?? 50;
    String approvalTier = 'Host Level 1';
    if (power >= 90) {
      approvalTier = 'Director / Executive Level';
    } else if (power >= 70) {
      approvalTier = 'HOD Level 2 Approval Authority';
    } else if (power >= 60) {
      approvalTier = 'Team Lead (Escalation Fallback)';
    }

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.dividerColor, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.onSurface.withValues(
              alpha: isDark ? 0.2 : 0.03,
            ),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              children: [
                Icon(
                  Icons.account_tree_outlined,
                  size: 16,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'REPORTING & DELEGATION',
                  style: textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: theme.dividerColor),
          _buildInfoRow(
            icon: Icons.supervisor_account_rounded,
            label: 'Reporting To',
            value: reportsTo.isNotEmpty
                ? (reportsDesig.isNotEmpty
                      ? '$reportsTo ($reportsDesig)'
                      : reportsTo)
                : 'Direct to Executive Management',
            showBorder: true,
          ),
          _buildInfoRow(
            icon: Icons.swap_horiz_rounded,
            label: 'Delegated To',
            value: delegatedTo.isNotEmpty
                ? (delegatedDesig.isNotEmpty
                      ? '$delegatedTo ($delegatedDesig)'
                      : delegatedTo)
                : 'Direct (No Active Delegation)',
            showBorder: true,
          ),
          _buildInfoRow(
            icon: Icons.verified_user_outlined,
            label: 'Approval Tier',
            value: approvalTier,
            showBorder: false,
          ),
        ],
      ),
    );
  }

  // 3. PERSONAL & CONTACT SECTION (Editable)
  Widget _buildContactDetailsSection(TextTheme textTheme, UserModel user) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.dividerColor, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.onSurface.withValues(
              alpha: isDark ? 0.2 : 0.03,
            ),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              children: [
                Icon(
                  Icons.contact_phone_outlined,
                  size: 16,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'PERSONAL & CONTACT',
                  style: textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: theme.dividerColor),
          _buildEditableRow(
            textTheme,
            Icons.person_rounded,
            'Full Name',
            _nameController,
            true,
          ),
          _buildEditableRow(
            textTheme,
            Icons.email_rounded,
            'Email',
            _emailController,
            true,
          ),
          _buildEditableRow(
            textTheme,
            Icons.phone_rounded,
            'Phone',
            _phoneController,
            false,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    required bool showBorder,
  }) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: showBorder
            ? Border(bottom: BorderSide(color: theme.dividerColor, width: 1))
            : null,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: theme.colorScheme.primary, size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: textTheme.bodySmall?.copyWith(
                    color: textTheme.bodySmall?.color?.withValues(alpha: 0.65),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditableRow(
    TextTheme textTheme,
    IconData icon,
    String label,
    TextEditingController controller,
    bool showBorder,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: showBorder
            ? Border(
                bottom: BorderSide(
                  color: Theme.of(context).dividerColor,
                  width: 1,
                ),
              )
            : null,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(
                context,
              ).colorScheme.primary.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: Theme.of(context).colorScheme.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: textTheme.bodySmall?.copyWith(
                    color: textTheme.bodySmall?.color?.withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(height: 4),
                _isEditing
                    ? TextField(
                        controller: controller,
                        style: textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                        decoration: const InputDecoration(
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(vertical: 4),
                          border: UnderlineInputBorder(),
                        ),
                      )
                    : Text(
                        controller.text,
                        style: textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton(TextTheme textTheme, bool isLoading) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: AppButton(
        label: 'Save Profile',
        isLoading: isLoading,
        onPressed: isLoading ? null : _saveProfile,
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        borderRadius: 12,
        textStyle: textTheme.titleMedium?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildProfileSkeleton(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return AsmitaSkeleton(
      isLoading: true,
      child: Column(
        children: [
          // 1. Profile Header Card Skeleton
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: theme.dividerColor, width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: theme.colorScheme.onSurface.withValues(
                    alpha: isDark ? 0.2 : 0.03,
                  ),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                AsmitaSkeleton.circle(size: 80),
                const SizedBox(height: 16),
                AsmitaSkeleton.text(width: 150, height: 20, borderRadius: 4),
                const SizedBox(height: 8),
                AsmitaSkeleton.pill(width: 110, height: 24),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 2. Workplace Card Skeleton
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: theme.dividerColor, width: 1.5),
            ),
            child: Column(
              children: List.generate(
                3,
                (i) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      AsmitaSkeleton.circle(size: 24),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AsmitaSkeleton.text(
                              width: 80,
                              height: 10,
                              borderRadius: 3,
                            ),
                            const SizedBox(height: 6),
                            AsmitaSkeleton.text(
                              width: 140,
                              height: 14,
                              borderRadius: 4,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 3. Details Section Card Skeleton
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: theme.dividerColor, width: 1.5),
            ),
            child: Column(
              children: List.generate(
                3,
                (i) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      AsmitaSkeleton.circle(size: 24),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AsmitaSkeleton.text(
                              width: 60,
                              height: 10,
                              borderRadius: 3,
                            ),
                            const SizedBox(height: 6),
                            AsmitaSkeleton.text(
                              width: 160,
                              height: 14,
                              borderRadius: 4,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
