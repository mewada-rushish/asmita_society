import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:asmita_society/core/constants/design_system.dart';
import 'package:asmita_society/core/utils/property_role_resolver.dart';
import 'package:asmita_society/core/widgets/app_skeleton.dart';
import 'package:asmita_society/core/widgets/asmita_animated_refresh.dart';
import 'package:asmita_society/features/auth/bloc/auth_bloc.dart';
import 'package:asmita_society/features/auth/bloc/auth_event.dart';
import 'package:asmita_society/features/auth/bloc/auth_state.dart';
import 'package:asmita_society/features/auth/presentation/login_screen.dart';
import 'package:asmita_society/features/visitor_management/bloc/visitor_bloc.dart';
import 'package:asmita_society/features/visitor_management/bloc/visitor_event.dart';
import 'package:asmita_society/features/visitor_management/presentation/screens/department_delegation_screen.dart';
import 'package:asmita_society/features/visitor_management/presentation/widgets/invite_team_member_sheet.dart';
import 'package:asmita_society/features/dashboard/presentation/screens/industrial_directory_screen.dart';

import 'committee_members_screen.dart';
import 'documents_screen.dart';
import 'family_members_screen.dart';
import 'tenants_screen.dart';
import 'history_requests_screen.dart';
import 'help_support_screen.dart';
import 'pets_screen.dart';
import 'profile_screen.dart';
import 'rules_screen.dart';
import 'settings_screen.dart';
import 'vehicles_screen.dart';

class MenuScreen extends StatelessWidget {
  final String userRole;
  final void Function(int index)? onNavigateToTab;
  final AsmitaPropertyType? propertyType;

  const MenuScreen({
    super.key,
    required this.userRole,
    this.onNavigateToTab,
    this.propertyType,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        if (authState is AuthLoading || authState is AuthInitial) {
          return _buildMenuSkeleton(context);
        }

        String resolvedRole = userRole;
        final currentUser = authState is AuthAuthenticated ? authState.user : null;
        if (currentUser != null) {
          if (userRole.isEmpty ||
              userRole == 'resident' ||
              userRole.toLowerCase() == currentUser.primaryRole.toLowerCase() ||
              userRole.toLowerCase() == currentUser.systemRole?.toLowerCase()) {
            final pRole = currentUser.primaryRole.trim();
            if (pRole.isNotEmpty && pRole.toLowerCase() != 'resident') {
              resolvedRole = pRole;
            } else if (currentUser.systemRole?.isNotEmpty == true) {
              resolvedRole = currentUser.systemRole!;
            } else if (pRole.isNotEmpty) {
              resolvedRole = pRole;
            }
          }
        }

        final isIndustrialProperty = propertyType == AsmitaPropertyType.industrial ||
            propertyType == AsmitaPropertyType.commercial ||
            PropertyRoleResolver.isIndustrialContext(currentUser, propertyType: currentUser?.propertyType);

        final normalized = PropertyRoleResolver.normalizeRole(
          resolvedRole,
          scope: currentUser?.roleScope,
          power: currentUser?.rolePower,
          isIndustrial: isIndustrialProperty,
        );
        final isIndustrial = isIndustrialProperty ||
            (propertyType == null &&
                (normalized == 'director' ||
                    normalized == 'employee' ||
                    normalized == 'receptionist' ||
                    normalized == 'facility'));
        final isGuard = normalized == 'guard';

        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          appBar: AppBar(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            elevation: 0,
            automaticallyImplyLeading: false,
            title: Text(
              'Menu',
              style: textTheme.titleLarge?.copyWith(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                fontFamily: 'Montserrat',
              ),
            ),
            centerTitle: true,
          ),
          body: CustomScrollView(
            physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
            slivers: [
              AsmitaAnimatedRefresh(
                onRefresh: () async {
                  await Future.delayed(const Duration(milliseconds: 600));
                },
              ),
              SliverPadding(
                padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 12.0, bottom: 140.0),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Top User Profile Card tailored to property context
                      _buildProfileCard(context, normalized: normalized, isIndustrial: isIndustrial, isGuard: isGuard),
                      const SizedBox(height: 24),

                      // Section 1: Role-Specific Operational / Household Group
                      if (isIndustrial) ...[
                        _buildMenuSection(
                          context,
                          title: _getIndustrialSectionTitle(normalized),
                          items: [
                            if (PropertyRoleResolver.canDelegate(currentUser, role: resolvedRole))
                              _buildMenuItem(context, Icons.swap_horiz_rounded, 'Department Delegation'),
                            _buildMenuItem(context, Icons.group_add_rounded, 'Invite Team'),
                            if (PropertyRoleResolver.canManageVehicles(currentUser, role: resolvedRole))
                              _buildMenuItem(context, Icons.directions_car_filled_outlined, 'Workplace Vehicles'),
                            _buildMenuItem(context, Icons.contact_phone_outlined, 'Campus Directory & Hotlines'),
                            _buildMenuItem(context, Icons.notifications_active_outlined, 'Notification & Sound Alerts'),
                            _buildMenuItem(context, Icons.fingerprint_rounded, 'Security & Biometric Access'),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildMenuSection(
                          context,
                          title: 'Company & Compliance',
                          items: [
                            _buildMenuItem(context, Icons.gavel_rounded, 'Rules and Compliance'),
                            _buildMenuItem(context, Icons.description_outlined, 'Company Policies'),
                          ],
                        ),
                        const SizedBox(height: 16),
                      ] else if (isGuard) ...[
                        _buildMenuSection(
                          context,
                          title: 'Guard Settings',
                          items: [
                            _buildMenuItem(context, Icons.notifications_active_outlined, 'Guard Shift & Audio Alerts'),
                            _buildMenuItem(context, Icons.security_rounded, 'Gate Rules & Safety Protocols'),
                            _buildMenuItem(context, Icons.emergency_rounded, 'Campus Emergency Hotline'),
                          ],
                        ),
                        const SizedBox(height: 16),
                      ] else ...[
                        // Residential (Owner / Tenant)
                        _buildMenuSection(
                          context,
                          title: 'My Household',
                          items: [
                            _buildMenuItem(context, Icons.people_outline_rounded, 'Family Members'),
                            if (PropertyRoleResolver.canManageMembers(currentUser, role: resolvedRole))
                              _buildMenuItem(context, Icons.group_add_outlined, 'Tenants'),
                            if (normalized == 'tenant')
                              _buildMenuItem(context, Icons.security_rounded, 'Access Requests'),
                            if (PropertyRoleResolver.canManageVehicles(currentUser, role: resolvedRole))
                              _buildMenuItem(context, Icons.directions_car_filled_outlined, 'Vehicles'),
                            _buildMenuItem(context, Icons.pets_rounded, 'Pets'),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildMenuSection(
                          context,
                          title: 'Society Info',
                          items: [
                            _buildMenuItem(context, Icons.contact_page_outlined, 'Committee Members'),
                            _buildMenuItem(context, Icons.gavel_rounded, 'Rules & Regulations'),
                            _buildMenuItem(context, Icons.description_outlined, 'Important Documents'),
                          ],
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Universal Application Settings Section
                      _buildMenuSection(
                        context,
                        title: 'Application',
                        items: [
                          _buildMenuItem(context, Icons.settings_outlined, 'Settings'),
                          _buildMenuItem(context, Icons.help_outline_rounded, 'Help & Support'),
                          _buildMenuItem(
                            context,
                            Icons.logout_rounded,
                            'Logout',
                            isDestructive: true,
                            isIndustrial: isIndustrial,
                            isGuard: isGuard,
                          ),
                        ],
                      ),
                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _getIndustrialSectionTitle(String normalizedRole) {
    switch (normalizedRole) {
      case 'director':
        return 'Executive Settings';
      case 'receptionist':
        return 'Front Desk Settings';
      case 'facility':
        return 'Facility Operations Settings';
      case 'employee':
      default:
        return 'Workplace Settings';
    }
  }

  Widget _buildProfileCard(
    BuildContext context, {
    required String normalized,
    required bool isIndustrial,
    required bool isGuard,
  }) {
    final textTheme = Theme.of(context).textTheme;
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => ProfileScreen(onNavigateToTab: onNavigateToTab)),
        );
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Theme.of(context).dividerColor, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: BlocBuilder<AuthBloc, AuthState>(
          builder: (context, authState) {
            String name = 'Loading...';
            String initials = '--';
            String roleText = userRole.toUpperCase();

            if (authState is AuthAuthenticated) {
              final user = authState.user;
              name = user.fullName.isNotEmpty ? user.fullName : 'User';

              final parts = name.split(' ').where((s) => s.isNotEmpty).toList();
              if (parts.length > 1) {
                initials = '${parts[0][0]}${parts[1][0]}'.toUpperCase();
              } else if (parts.isNotEmpty) {
                initials = parts[0][0].toUpperCase();
              }

              if (isGuard) {
                roleText = 'Gate 1 • SECURITY CONTROL';
              } else if (isIndustrial) {
                if (user.flatMappings.isNotEmpty) {
                  final flat = user.flatMappings.first;
                  final tower = flat.towerName.isNotEmpty ? '${flat.towerName} • ' : '';
                  if (normalized == 'director') {
                    roleText = 'Executive Suite $tower${flat.flatNumber} • DIRECTOR';
                  } else if (normalized == 'receptionist') {
                    roleText = 'Front Desk $tower${flat.flatNumber} • RECEPTIONIST';
                  } else if (normalized == 'facility') {
                    roleText = 'Logistics Dock $tower${flat.flatNumber} • FACILITY';
                  } else {
                    roleText = 'Workplace $tower${flat.flatNumber} • ${userRole.toUpperCase()}';
                  }
                } else {
                  if (normalized == 'director') {
                    roleText = 'Executive HQ • DIRECTOR';
                  } else if (normalized == 'receptionist') {
                    roleText = 'Visitor Front Desk • RECEPTIONIST';
                  } else if (normalized == 'facility') {
                    roleText = 'Facility & Logistics • FACILITY';
                  } else {
                    roleText = 'Corporate Desk • ${userRole.toUpperCase()}';
                  }
                }
              } else {
                // Residential
                if (user.flatMappings.isNotEmpty) {
                  final flat = user.flatMappings.first;
                  final tower = flat.towerName.isNotEmpty ? '${flat.towerName}-' : '';
                  roleText = 'Flat $tower${flat.flatNumber} • ${userRole.toUpperCase()}';
                }
              }
            }

            return Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  child: Text(
                    initials,
                    style: textTheme.titleLarge?.copyWith(
                      color: Theme.of(context).colorScheme.surface,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Montserrat',
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: textTheme.titleLarge?.copyWith(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'Montserrat',
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        roleText,
                        style: textTheme.bodyMedium?.copyWith(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 16,
                  color: Theme.of(context).textTheme.bodyMedium?.color,
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildMenuSection(BuildContext context, {required String title, required List<Widget> items}) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 8),
          child: Text(
            title,
            style: textTheme.titleLarge?.copyWith(
              fontSize: 13,
              color: Theme.of(context).textTheme.bodyMedium?.color,
              fontWeight: FontWeight.w700,
              fontFamily: 'Montserrat',
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Theme.of(context).dividerColor, width: 1.5),
          ),
          child: Column(
            children: items,
          ),
        ),
      ],
    );
  }

  Widget _buildMenuItem(
    BuildContext context,
    IconData icon,
    String title, {
    bool isDestructive = false,
    bool isIndustrial = false,
    bool isGuard = false,
  }) {
    final textTheme = Theme.of(context).textTheme;
    final color = isDestructive ? AsmitaPalette.actionRed : Theme.of(context).colorScheme.primary;

    return InkWell(
      onTap: () {
        if (isDestructive && title == 'Logout') {
          final logoutScopeMessage = isIndustrial
              ? 'Are you sure you want to logout? You will need to sign in again to access corporate campus operations.'
              : (isGuard
                  ? 'Are you sure you want to logout? You will need to sign in again to resume security gate operations.'
                  : 'Are you sure you want to logout? You will need to sign in again to access society features.');

          bool isLoggingOut = false;

          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (dialogContext) {
              return StatefulBuilder(
                builder: (context, setDialogState) {
                  return PopScope(
                    canPop: !isLoggingOut,
                    child: AlertDialog(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      title: const Text(
                        'Logout',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      content: Text(
                        logoutScopeMessage,
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 14,
                          color: Theme.of(context).textTheme.bodyLarge?.color,
                        ),
                      ),
                      actions: [
                        OutlinedButton(
                          onPressed: isLoggingOut
                              ? null
                              : () => Navigator.of(dialogContext).pop(),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: Theme.of(context).dividerColor),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: Text(
                            'Cancel',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        ElevatedButton(
                          onPressed: isLoggingOut
                              ? null
                              : () async {
                                  setDialogState(() {
                                    isLoggingOut = true;
                                  });

                                  final authBloc = context.read<AuthBloc>();
                                  context.read<VisitorBloc>().add(ClearVisitorHistory());
                                  authBloc.add(const AuthLogoutRequested());

                                  // Wait for AuthUnauthenticated or timeout fallback
                                  try {
                                    await authBloc.stream
                                        .firstWhere((state) => state is AuthUnauthenticated)
                                        .timeout(const Duration(seconds: 4));
                                  } catch (_) {
                                    // Proceed anyway after timeout
                                  }

                                  if (dialogContext.mounted) {
                                    Navigator.of(dialogContext, rootNavigator: true).pop();
                                  }

                                  if (context.mounted) {
                                    Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
                                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                                      (route) => false,
                                    );
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).colorScheme.primary,
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: isLoggingOut
                              ? SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: Center(
                                    child: AsmitaSkeleton(
                                      isLoading: true,
                                      child: AsmitaSkeleton.circle(size: 16),
                                    ),
                                  ),
                                )
                              : Text(
                                  'Logout',
                                  style: TextStyle(
                                    color: Theme.of(context).colorScheme.surface,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          );
          return;
        }

        Widget screen;
        switch (title) {
          case 'Committee Members':
            screen = CommitteeMembersScreen(onNavigateToTab: onNavigateToTab);
            break;
          case 'Rules & Regulations':
          case 'Rules and Compliance':
          case 'Workplace Rules & Compliance':
          case 'Gate Rules & Safety Protocols':
            screen = const RulesScreen();
            break;
          case 'Important Documents':
          case 'Policies & Documents':
          case 'Policies & Corporate Documents':
          case 'Company Policies':
            screen = const DocumentsScreen();
            break;
          case 'Family Members':
            screen = FamilyMembersScreen(onNavigateToTab: onNavigateToTab);
            break;
          case 'Tenants':
            screen = TenantsScreen(onNavigateToTab: onNavigateToTab);
            break;
          case 'Vehicles':
          case 'Workplace Vehicles':
            screen = VehiclesScreen(onNavigateToTab: onNavigateToTab);
            break;
          case 'Pets':
            screen = PetsScreen(onNavigateToTab: onNavigateToTab);
            break;
          case 'Access Requests':
            screen = const HistoryRequestsScreen();
            break;
          case 'Department Delegation':
            final authState = context.read<AuthBloc>().state;
            final user = authState is AuthAuthenticated ? authState.user : null;
            screen = DepartmentDelegationScreen(
              departmentId: user?.departmentId,
              departmentName: user?.departmentName ?? 'General HQ',
            );
            break;
          case 'Invite Team':
            showInviteTeamMemberSheet(context);
            return;
          case 'Campus Emergency Hotline':
          case 'Campus Directory & Hotlines':
          case 'Campus Emergency Protocols':
          case 'Emergency Contacts':
            screen = const IndustrialDirectoryScreen();
            break;
          case 'Notification & Sound Alerts':
          case 'Guard Shift & Audio Alerts':
          case 'Security & Biometric Access':
          case 'Settings':
            screen = const SettingsScreen();
            break;
          case 'Help & Support':
            screen = const HelpSupportScreen();
            break;
          default:
            return;
        }

        Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
      },
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: textTheme.bodyLarge?.copyWith(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDestructive ? color : textTheme.bodyLarge?.color,
                ),
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 14,
              color: isDestructive ? color.withValues(alpha: 0.5) : textTheme.bodyMedium?.color,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuSkeleton(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text(
          'Menu',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            fontFamily: 'Montserrat',
          ),
        ),
        centerTitle: true,
      ),
      body: AsmitaSkeleton(
        isLoading: true,
        child: SingleChildScrollView(
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 12.0, bottom: 140.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile Card Skeleton
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Theme.of(context).dividerColor,
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    AsmitaSkeleton.circle(size: 56),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AsmitaSkeleton.text(width: 140, height: 16, borderRadius: 4),
                          const SizedBox(height: 8),
                          AsmitaSkeleton.pill(width: 90, height: 20),
                        ],
                      ),
                    ),
                    AsmitaSkeleton.bone(width: 16, height: 16, borderRadius: 3),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Section 1: Property / Management (4 items)
              AsmitaSkeleton.text(width: 120, height: 14, borderRadius: 4),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Theme.of(context).dividerColor.withValues(alpha: 0.6),
                  ),
                ),
                child: Column(
                  children: List.generate(
                    4,
                    (index) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        border: index < 3
                            ? Border(
                                bottom: BorderSide(
                                  color: Theme.of(context).dividerColor,
                                ),
                              )
                            : null,
                      ),
                      child: Row(
                        children: [
                          AsmitaSkeleton.circle(size: 24),
                          const SizedBox(width: 16),
                          Expanded(
                            child: AsmitaSkeleton.text(width: 130, height: 14, borderRadius: 4),
                          ),
                          AsmitaSkeleton.bone(width: 14, height: 14, borderRadius: 3),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Section 2: Society Info (3 items)
              AsmitaSkeleton.text(width: 100, height: 14, borderRadius: 4),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Theme.of(context).dividerColor.withValues(alpha: 0.6),
                  ),
                ),
                child: Column(
                  children: List.generate(
                    3,
                    (index) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        border: index < 2
                            ? Border(
                                bottom: BorderSide(
                                  color: Theme.of(context).dividerColor,
                                ),
                              )
                            : null,
                      ),
                      child: Row(
                        children: [
                          AsmitaSkeleton.circle(size: 24),
                          const SizedBox(width: 16),
                          Expanded(
                            child: AsmitaSkeleton.text(width: 120, height: 14, borderRadius: 4),
                          ),
                          AsmitaSkeleton.bone(width: 14, height: 14, borderRadius: 3),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
