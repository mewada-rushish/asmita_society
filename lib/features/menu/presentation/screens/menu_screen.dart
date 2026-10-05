import 'package:flutter/material.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:asmita_society/features/auth/bloc/auth_bloc.dart';
import 'package:asmita_society/features/auth/bloc/auth_event.dart';
import 'package:asmita_society/features/auth/bloc/auth_state.dart';
import 'package:asmita_society/core/widgets/asmita_animated_refresh.dart';
import 'package:asmita_society/core/widgets/asmita_dialog.dart';
import 'package:asmita_society/features/visitor_management/bloc/visitor_bloc.dart';
import 'package:asmita_society/features/visitor_management/bloc/visitor_event.dart';

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

  const MenuScreen({super.key, required this.userRole, this.onNavigateToTab});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        automaticallyImplyLeading: false, // Root tab, no back button
        title: Text(
          'Menu',
          style: textTheme.titleLarge?.copyWith(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
      ),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
        slivers: [
          AsmitaAnimatedRefresh(
            onRefresh: () async {
              // Simulating menu refresh logic if dynamic data was fetched here
              await Future.delayed(const Duration(milliseconds: 800));
            },
          ),
          SliverPadding(
            padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 16.0, bottom: 160.0),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
            _buildProfileCard(context),
            const SizedBox(height: 24),
            if (userRole.toLowerCase() != 'guard') ...[
              _buildMenuSection(
                context,
                title: 'My Household',
                items: [
                  _buildMenuItem(context, Icons.people_outline_rounded, 'Family Members'),
                  if (userRole.toLowerCase() != 'tenant')
                    _buildMenuItem(context, Icons.group_add_outlined, 'Tenants'),
                  if (userRole.toLowerCase() == 'tenant')
                    _buildMenuItem(context, Icons.security_rounded, 'Access Requests'),
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
            _buildMenuSection(
              context,
              title: 'Application',
              items: [
                _buildMenuItem(context, Icons.settings_outlined, 'Settings'),
                _buildMenuItem(context, Icons.help_outline_rounded, 'Help & Support'),
                _buildMenuItem(context, Icons.logout_rounded, 'Logout', isDestructive: true),
              ],
            ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    ],
  ),
);
  }

  Widget _buildProfileCard(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return InkWell(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => ProfileScreen(onNavigateToTab: onNavigateToTab)));
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
            
            if (userRole.toLowerCase() != 'guard') {
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
                  style: textTheme.titleLarge?.copyWith(color: Theme.of(context).colorScheme.surface, fontSize: 18)
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: textTheme.titleLarge?.copyWith(fontSize: 16, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Text(
                      roleText,
                      style: textTheme.bodyMedium?.copyWith(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Theme.of(context).colorScheme.primary),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Theme.of(context).textTheme.bodyMedium?.color),
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
          child: Text(title, style: textTheme.titleLarge?.copyWith(fontSize: 13, color: Theme.of(context).textTheme.bodyMedium?.color, fontWeight: FontWeight.w700)),
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

  Widget _buildMenuItem(BuildContext context, IconData icon, String title, {bool isDestructive = false}) {
    final textTheme = Theme.of(context).textTheme;
    final color = isDestructive ? Theme.of(context).colorScheme.error : Theme.of(context).colorScheme.primary;
    return InkWell(
      onTap: () {
        if (isDestructive && title == 'Logout') {
          AsmitaDialog.show(
            context: context,
            title: 'Logout',
            content: Text(
              'Are you sure you want to logout? You will need to sign in again to access society features.',
              style: TextStyle(fontFamily: 'Poppins', fontSize: 14, color: Theme.of(context).textTheme.bodyLarge?.color),
            ),
            actions: [
              OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: Theme.of(context).dividerColor),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: Text('Cancel', style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w600)),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  context.read<VisitorBloc>().add(ClearVisitorHistory());
                  context.read<AuthBloc>().add(AuthLogoutRequested());
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: Text('Logout', style: TextStyle(color: Theme.of(context).colorScheme.surface, fontWeight: FontWeight.w600)),
              ),
            ],
          );
          return;
        }
        
        Widget screen;
        switch (title) {
          case 'Committee Members': screen = CommitteeMembersScreen(onNavigateToTab: onNavigateToTab); break;
          case 'Rules & Regulations': screen = const RulesScreen(); break;
          case 'Important Documents': screen = const DocumentsScreen(); break;
          case 'Family Members': screen = FamilyMembersScreen(onNavigateToTab: onNavigateToTab); break;
          case 'Tenants': screen = TenantsScreen(onNavigateToTab: onNavigateToTab); break;
          case 'Vehicles': screen = VehiclesScreen(onNavigateToTab: onNavigateToTab); break;
          case 'Pets': screen = PetsScreen(onNavigateToTab: onNavigateToTab); break;
          case 'Access Requests': screen = const HistoryRequestsScreen(); break;
          case 'Settings': screen = const SettingsScreen(); break;
          case 'Help & Support': screen = const HelpSupportScreen(); break;
          default: return;
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
            Icon(Icons.arrow_forward_ios_rounded, size: 14, color: isDestructive ? color.withValues(alpha: 0.5) : textTheme.bodyMedium?.color),
          ],
        ),
      ),
    );
  }
}
