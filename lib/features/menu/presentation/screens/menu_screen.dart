import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:asmita_society/core/constants/design_system.dart';
import 'package:asmita_society/features/auth/bloc/auth_bloc.dart';
import 'package:asmita_society/features/auth/bloc/auth_event.dart';
import 'package:asmita_society/core/widgets/asmita_animated_refresh.dart';

import 'committee_members_screen.dart';
import 'documents_screen.dart';
import 'family_members_screen.dart';
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
      backgroundColor: AsmitaPalette.systemBG,
      appBar: AppBar(
        backgroundColor: AsmitaPalette.systemBG,
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
            padding: const EdgeInsets.all(16.0),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
            _buildProfileCard(context),
            const SizedBox(height: 24),
            _buildMenuSection(
              context,
              title: 'My Household',
              items: [
                _buildMenuItem(context, Icons.people_outline_rounded, 'Family Members'),
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
        // We'll import the profile screen later, but since it's already in the same directory, we can navigate
        Navigator.pop(context); // Close the tab
        if (onNavigateToTab != null) onNavigateToTab!(4); // Dummy index just to trigger rebuild or we can navigate directly
        // Wait, navigating from a tab means we just push on top of it.
        Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen()));
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AsmitaPalette.borderGrey, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: AsmitaPalette.deepNavy,
            child: Text(
              'RM', 
              style: textTheme.titleLarge?.copyWith(color: Colors.white, fontSize: 18)
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Rushish Mewada', style: textTheme.titleLarge?.copyWith(fontSize: 16, fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text('Flat A-402 • ${userRole.toUpperCase()}', style: textTheme.bodyMedium?.copyWith(fontSize: 11, fontWeight: FontWeight.w700, color: AsmitaPalette.actionRed)),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: AsmitaPalette.textLight),
        ],
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
          child: Text(title, style: textTheme.titleLarge?.copyWith(fontSize: 13, color: AsmitaPalette.textLight, fontWeight: FontWeight.w700)),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AsmitaPalette.borderGrey, width: 1.5),
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
    final color = isDestructive ? AsmitaPalette.actionRed : AsmitaPalette.deepNavy;
    
    return InkWell(
      onTap: () {
        if (isDestructive && title == 'Logout') {
          context.read<AuthBloc>().add(AuthLogoutRequested());
          return;
        }
        
        Widget screen;
        switch (title) {
          case 'Committee Members': screen = const CommitteeMembersScreen(); break;
          case 'Rules & Regulations': screen = const RulesScreen(); break;
          case 'Important Documents': screen = const DocumentsScreen(); break;
          case 'Family Members': screen = FamilyMembersScreen(onNavigateToTab: onNavigateToTab); break;
          case 'Vehicles': screen = const VehiclesScreen(); break;
          case 'Pets': screen = const PetsScreen(); break;
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
                  color: isDestructive ? AsmitaPalette.actionRed : AsmitaPalette.textDark,
                ),
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded, size: 14, color: isDestructive ? AsmitaPalette.actionRed.withValues(alpha: 0.5) : AsmitaPalette.textLight),
          ],
        ),
      ),
    );
  }
}