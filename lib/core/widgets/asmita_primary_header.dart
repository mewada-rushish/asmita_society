import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:asmita_society/core/constants/design_system.dart';
import 'package:asmita_society/core/widgets/asmita_bottom_sheet.dart';
import 'package:asmita_society/core/widgets/asmita_toast.dart';
import 'package:asmita_society/core/utils/property_role_resolver.dart';
import 'package:asmita_society/features/dashboard/presentation/screens/search_screen.dart';
import 'package:asmita_society/features/auth/presentation/add_property_screen.dart';
import 'package:asmita_society/features/auth/bloc/auth_bloc.dart';
import 'package:asmita_society/features/auth/bloc/auth_state.dart';
import 'package:asmita_society/features/auth/data/models/user_model.dart';

/// Universal, Property-Consistent Header for AsmitA
/// 
/// Automatically tailors branding, titles, and trailing action elements based on
/// the corresponding property archetype:
/// - Residential: Flat info, Search, Community Chat, Profile Avatar
/// - Industrial/Commercial: Complex/HQ, Cabin/Desk, Search, Campus Hotlines, Profile Avatar
/// - Guard/Security: Gate info, Gate History, QR Scanner, Profile Avatar
class AsmitaPrimaryHeader extends StatelessWidget {
  final String userInitials;
  final VoidCallback? onSearchPressed;
  final VoidCallback? onChatPressed;
  final VoidCallback? onHotlinePressed;
  final VoidCallback? onHistoryPressed;
  final VoidCallback? onScannerPressed;
  final bool showBackButton;
  final Color? backgroundColor;
  final double bottomPadding;
  final String? subtitleOverride;
  final Widget? trailingActions;
  final Widget? extraAction;
  final bool allowPropertySwitching;
  final VoidCallback? onProfilePressed;
  final AsmitaPropertyType? propertyType;

  const AsmitaPrimaryHeader({
    super.key,
    this.userInitials = 'RM',
    this.onSearchPressed,
    this.onChatPressed,
    this.onHotlinePressed,
    this.onHistoryPressed,
    this.onScannerPressed,
    this.showBackButton = false,
    this.backgroundColor,
    this.bottomPadding = 12.0,
    this.subtitleOverride,
    this.trailingActions,
    this.extraAction,
    this.allowPropertySwitching = true,
    this.onProfilePressed,
    this.propertyType,
  });

  void _showCampusHotlinesSheet(BuildContext context) {
    showAsmitaBottomSheet(
      context: context,
      title: 'Campus Hotlines & Support',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHotlineTile(
            context,
            icon: Icons.support_agent_rounded,
            title: 'Floor 8 Reception Desk',
            subtitle: 'Ext: 101 • Dedicated Executive & Visitor Desk',
            onCall: () {
              Navigator.pop(context);
              AsmitaToast.show(
                context,
                message: 'Connecting to Reception (Ext 101)...',
                type: AsmitaToastType.info,
              );
            },
          ),
          const SizedBox(height: 8),
          _buildHotlineTile(
            context,
            icon: Icons.shield_outlined,
            title: 'Gate 1 Security Control',
            subtitle: 'Ext: 104 • Main Entrance & Vehicle Dock',
            onCall: () {
              Navigator.pop(context);
              AsmitaToast.show(
                context,
                message: 'Connecting to Gate 1 Control (Ext 104)...',
                type: AsmitaToastType.info,
              );
            },
          ),
          const SizedBox(height: 8),
          _buildHotlineTile(
            context,
            icon: Icons.local_hospital_outlined,
            title: 'Campus Emergency Response',
            subtitle: 'Ext: 999 • Rapid Response Team',
            onCall: () {
              Navigator.pop(context);
              AsmitaToast.show(
                context,
                message: 'Connecting to Emergency Response (Ext 999)...',
                type: AsmitaToastType.info,
              );
            },
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildHotlineTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onCall,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AsmitaPalette.deepNavy.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AsmitaPalette.deepNavy, size: 22),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(fontSize: 11, color: AsmitaPalette.textLight),
        ),
        trailing: ElevatedButton.icon(
          onPressed: onCall,
          icon: const Icon(Icons.phone, size: 14),
          label: const Text('Call', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
          style: ElevatedButton.styleFrom(
            backgroundColor: AsmitaPalette.deepNavy,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
      ),
    );
  }

  void _showPropertiesBottomSheet(
    BuildContext context,
    UserModel user, {
    required bool isIndustrial,
  }) {
    showAsmitaBottomSheet(
      context: context,
      title: isIndustrial ? 'Campus & Office Locations' : 'Your Properties',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainer,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Theme.of(context).dividerColor),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  if (user.flatMappings.isEmpty)
                    ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      leading: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Theme.of(context).scaffoldBackgroundColor,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          isIndustrial ? Icons.corporate_fare_rounded : Icons.apartment_rounded,
                          color: Theme.of(context).colorScheme.primary,
                          size: 20,
                        ),
                      ),
                      title: Text(
                        user.societyName ?? (isIndustrial ? 'AsmitA Corporate HQ' : 'AsmitA Society'),
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                      ),
                      subtitle: Text(
                        isIndustrial ? 'Main Operations Campus' : 'Primary Residence',
                        style: TextStyle(
                          fontSize: 13,
                          color: Theme.of(context).textTheme.bodySmall?.color,
                        ),
                      ),
                      trailing: const Icon(Icons.check_circle_rounded, color: Colors.green, size: 22),
                      onTap: () => Navigator.pop(context),
                    )
                  else
                    for (int i = 0; i < user.flatMappings.length; i++) ...[
                      ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 4,
                        ),
                        leading: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Theme.of(context).scaffoldBackgroundColor,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            isIndustrial ? Icons.corporate_fare_rounded : Icons.apartment_rounded,
                            color: Theme.of(context).colorScheme.primary,
                            size: 20,
                          ),
                        ),
                        title: Text(
                          '${user.flatMappings[i].towerName} - ${user.flatMappings[i].flatNumber}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                        subtitle: Text(
                          user.societyName ?? 'AsmitA Complex',
                          style: TextStyle(
                            fontSize: 13,
                            color: Theme.of(context).textTheme.bodySmall?.color,
                          ),
                        ),
                        trailing: i == 0
                            ? const Icon(
                                Icons.check_circle_rounded,
                                color: Colors.green,
                                size: 22,
                              )
                            : null,
                        onTap: () => Navigator.pop(context),
                      ),
                      if (i < user.flatMappings.length - 1)
                        Divider(
                          height: 1,
                          indent: 64,
                          color: Theme.of(context).dividerColor,
                        ),
                    ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Center(
            child: InkWell(
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AddPropertyScreen()),
                );
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.add_rounded,
                        color: Theme.of(context).colorScheme.primary,
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      isIndustrial ? 'Add Campus Location' : 'Add Another Flat',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.viewPaddingOf(context).top;
    final textTheme = Theme.of(context).textTheme;

    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        String? role;
        String societyName = 'AsmitA Society';
        String flatDetails = 'A Wing - 101';
        String initials = userInitials;

        if (authState is AuthAuthenticated) {
          final user = authState.user;
          role = user.systemRole?.isNotEmpty == true ? user.systemRole : user.primaryRole;

          if (user.societyName != null && user.societyName!.isNotEmpty) {
            societyName = user.societyName!;
          }

          if (subtitleOverride != null) {
            flatDetails = subtitleOverride!;
          } else if (user.flatMappings.isNotEmpty) {
            final mapping = user.flatMappings.first;
            flatDetails = '${mapping.towerName} - ${mapping.flatNumber}';
          } else if (user.systemRole?.isNotEmpty == true || user.primaryRole.isNotEmpty) {
            flatDetails = user.systemRole?.isNotEmpty == true
                ? user.systemRole!
                : user.primaryRole;
            if (flatDetails.isNotEmpty) {
              flatDetails = flatDetails.substring(0, 1).toUpperCase() +
                  flatDetails.substring(1).toLowerCase();
            }
          }

          if (user.fullName.isNotEmpty) {
            final parts = user.fullName.split(' ').where((s) => s.isNotEmpty).toList();
            if (parts.length > 1) {
              initials = '${parts[0][0]}${parts[1][0]}'.toUpperCase();
            } else if (parts.isNotEmpty) {
              initials = parts[0][0].toUpperCase();
            }
          }
        }

        final normalizedRole = PropertyRoleResolver.normalizeRole(role);
        final isIndustrial = propertyType == AsmitaPropertyType.industrial ||
            propertyType == AsmitaPropertyType.commercial ||
            (propertyType == null &&
                (normalizedRole == 'director' ||
                    normalizedRole == 'employee' ||
                    normalizedRole == 'receptionist' ||
                    normalizedRole == 'facility'));
        final isGuard = normalizedRole == 'guard';

        // Override default fallbacks when in Industrial / Guard context
        if (societyName == 'AsmitA Society') {
          if (isIndustrial) {
            societyName = 'AsmitA Corporate HQ';
          } else if (isGuard) {
            societyName = 'Gate 1 • Security Control';
          }
        }

        if (subtitleOverride == null) {
          if (isGuard) {
            flatDetails = 'Campus Security • On Duty';
          } else if (normalizedRole == 'director') {
            flatDetails = 'Executive Office • 8th Floor';
          } else if (normalizedRole == 'employee') {
            flatDetails = 'Corporate Host Desk';
          } else if (normalizedRole == 'receptionist') {
            flatDetails = 'Front Desk • Ground Floor';
          } else if (normalizedRole == 'facility') {
            flatDetails = 'Facility & Logistics Dock';
          }
        }

        final isDark = Theme.of(context).brightness == Brightness.dark;

        // Dynamic branding badge matching property type
        final IconData brandingIcon;
        final Color brandingColor;
        if (isGuard) {
          brandingIcon = Icons.shield_outlined;
          brandingColor = AsmitaPalette.deepNavy;
        } else if (isIndustrial) {
          brandingIcon = Icons.corporate_fare_rounded;
          brandingColor = AsmitaPalette.deepNavy;
        } else {
          brandingIcon = Icons.apartment_rounded;
          brandingColor = AsmitaPalette.actionRed;
        }

        Widget headerContent = Container(
          padding: EdgeInsets.fromLTRB(
            16,
            topPadding > 0 ? topPadding + 10 : 22,
            16,
            12,
          ),
          decoration: BoxDecoration(
            color: isDark
                ? Theme.of(context).colorScheme.surface.withValues(alpha: 0.75)
                : Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(
              bottom: Radius.circular(24),
            ),
            border: isDark
                ? Border.all(color: Colors.white.withValues(alpha: 0.15), width: 1.0)
                : null,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48),
            child: Row(
              children: [
                if (showBackButton)
                  Padding(
                    padding: const EdgeInsets.only(right: 12.0),
                    child: InkWell(
                      onTap: () => Navigator.pop(context),
                      borderRadius: BorderRadius.circular(20),
                      child: const Padding(
                        padding: EdgeInsets.all(4.0),
                        child: Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: AsmitaPalette.deepNavy,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Theme.of(context).dividerColor.withValues(alpha: 0.6),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Icon(
                            brandingIcon,
                            color: brandingColor,
                            size: 20,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: InkWell(
                          onTap: allowPropertySwitching
                              ? () {
                                  if (authState is AuthAuthenticated) {
                                    _showPropertiesBottomSheet(
                                      context,
                                      authState.user,
                                      isIndustrial: isIndustrial,
                                    );
                                  }
                                }
                              : null,
                          borderRadius: BorderRadius.circular(4),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Flexible(
                                    child: Text(
                                      societyName,
                                      style: textTheme.titleLarge?.copyWith(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w800,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (allowPropertySwitching) ...[
                                    const SizedBox(width: 2),
                                    Icon(
                                      Icons.keyboard_arrow_down_rounded,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface
                                          .withValues(alpha: 0.8),
                                      size: 18,
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                flatDetails,
                                style: textTheme.bodyMedium?.copyWith(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w400,
                                  color: AsmitaPalette.textLight,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Consistent Trailing Actions tailored to Property Type
                if (trailingActions != null)
                  trailingActions!
                else ...[
                  if (extraAction != null) ...[
                    extraAction!,
                    const SizedBox(width: 4),
                  ],
                  if (isGuard) ...[
                    // Security / Guard Actions: 1. Gate Records History, 2. QR Scanner
                    InkWell(
                      onTap: onHistoryPressed ?? () {},
                      borderRadius: BorderRadius.circular(20),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Icon(
                          Icons.history_rounded,
                          color: Theme.of(context).iconTheme.color,
                          size: 24,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    InkWell(
                      onTap: onScannerPressed ?? () {},
                      borderRadius: BorderRadius.circular(20),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Icon(
                          Icons.qr_code_scanner_rounded,
                          color: Theme.of(context).iconTheme.color,
                          size: 24,
                        ),
                      ),
                    ),
                  ] else if (isIndustrial) ...[
                    // Industrial / Corporate Actions: 1. Search, 2. Campus Hotlines
                    InkWell(
                      onTap: onSearchPressed ??
                          () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const AsmitaSearchScreen(),
                                ),
                              ),
                      borderRadius: BorderRadius.circular(20),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Icon(
                          Icons.search_rounded,
                          color: Theme.of(context).iconTheme.color,
                          size: 24,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    InkWell(
                      onTap: onHotlinePressed ?? () => _showCampusHotlinesSheet(context),
                      borderRadius: BorderRadius.circular(20),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Icon(
                          Icons.support_agent_rounded,
                          color: Theme.of(context).iconTheme.color,
                          size: 24,
                        ),
                      ),
                    ),
                  ] else ...[
                    // Residential Actions: 1. Search, 2. Community Chat
                    InkWell(
                      onTap: onSearchPressed ??
                          () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const AsmitaSearchScreen(),
                                ),
                              ),
                      borderRadius: BorderRadius.circular(20),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Icon(
                          Icons.search_rounded,
                          color: Theme.of(context).iconTheme.color,
                          size: 24,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    InkWell(
                      onTap: onChatPressed,
                      borderRadius: BorderRadius.circular(20),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Icon(
                          Icons.chat_bubble_outline_rounded,
                          color: Theme.of(context).iconTheme.color,
                          size: 24,
                        ),
                      ),
                    ),
                  ],
                ],

                const SizedBox(width: 10),
                GestureDetector(
                  onTap: onProfilePressed,
                  child: CircleAvatar(
                    radius: 17,
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    child: Text(
                      initials,
                      style: textTheme.titleLarge?.copyWith(
                        color: Theme.of(context).colorScheme.onPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );

        if (isDark) {
          headerContent = ClipRRect(
            borderRadius: const BorderRadius.vertical(
              bottom: Radius.circular(24),
            ),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: headerContent,
            ),
          );
        }

        return Container(
          color: backgroundColor ?? Colors.transparent,
          padding: EdgeInsets.only(bottom: bottomPadding),
          child: headerContent,
        );
      },
    );
  }
}
