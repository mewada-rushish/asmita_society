import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:asmita_society/core/constants/design_system.dart';
import 'package:asmita_society/core/widgets/asmita_bottom_sheet.dart';
import 'package:asmita_society/features/dashboard/presentation/screens/search_screen.dart';
import 'package:asmita_society/features/auth/presentation/add_property_screen.dart';
import 'package:asmita_society/features/auth/bloc/auth_bloc.dart';
import 'package:asmita_society/features/auth/bloc/auth_state.dart';
import 'package:asmita_society/features/auth/data/models/user_model.dart';

class AsmitaPrimaryHeader extends StatelessWidget {
  final String userInitials;
  final VoidCallback? onSearchPressed;
  final VoidCallback? onChatPressed;
  final bool showBackButton;
  final Color? backgroundColor;

  const AsmitaPrimaryHeader({
    super.key,
    this.userInitials = 'RM',
    this.onSearchPressed,
    this.onChatPressed,
    this.showBackButton = false,
    this.backgroundColor,
  });

  void _showPropertiesBottomSheet(BuildContext context, UserModel user) {
    showAsmitaBottomSheet(
      context: context,
      title: 'Your Properties',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AsmitaPalette.borderGrey),
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
                    const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text('No properties found.', style: TextStyle(color: Colors.grey)),
                    ),
                for (int i = 0; i < user.flatMappings.length; i++) ...[
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AsmitaPalette.systemBG,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.apartment_rounded, color: AsmitaPalette.deepNavy, size: 20),
                    ),
                    title: Text(
                      '${user.flatMappings[i].towerName} - ${user.flatMappings[i].flatNumber}', 
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                    ),
                    subtitle: Text(
                      user.societyName ?? 'AsmitA Society', 
                      style: const TextStyle(fontSize: 13, color: Colors.grey),
                    ),
                    trailing: i == 0 ? const Icon(Icons.check_circle_rounded, color: Colors.green, size: 22) : null,
                    onTap: () => Navigator.pop(context),
                  ),
                  if (i < user.flatMappings.length - 1)
                    const Divider(height: 1, indent: 64, color: AsmitaPalette.borderGrey),
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
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: AsmitaPalette.deepNavy,
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
                      child: const Icon(Icons.add_rounded, color: AsmitaPalette.deepNavy, size: 16),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Add Another Property',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        color: Colors.white,
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
        String societyName = 'AsmitA Society';
        String flatDetails = 'A Wing - 101';
        String initials = userInitials;

        if (authState is AuthAuthenticated) {
          final user = authState.user;
          if (user.societyName != null && user.societyName!.isNotEmpty) {
            societyName = user.societyName!;
          }
          if (user.flatMappings.isNotEmpty) {
            final mapping = user.flatMappings.first;
            flatDetails = '${mapping.towerName} - ${mapping.flatNumber}';
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

        return Container(
          color: backgroundColor ?? AsmitaPalette.systemBG,
          padding: const EdgeInsets.only(bottom: 12),
          child: Container(
            padding: EdgeInsets.fromLTRB(16, topPadding > 0 ? topPadding + 12 : 24, 16, 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
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
                    child: Icon(Icons.arrow_back_ios_new_rounded, color: AsmitaPalette.deepNavy, size: 20),
                  ),
                ),
              ),
            Expanded(
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                  child: const Center(child: Icon(Icons.blur_on_rounded, color: AsmitaPalette.actionRed, size: 20)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: InkWell(
                    onTap: () {
                      if (authState is AuthAuthenticated) {
                        _showPropertiesBottomSheet(context, authState.user);
                      }
                    },
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
                                style: textTheme.titleLarge?.copyWith(fontSize: 16, fontWeight: FontWeight.w800),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 2),
                            Icon(Icons.keyboard_arrow_down_rounded, color: AsmitaPalette.deepNavy.withValues(alpha: 0.8), size: 18),
                          ],
                        ),
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
          InkWell(
            onTap: onSearchPressed ?? () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AsmitaSearchScreen())),
            borderRadius: BorderRadius.circular(20),
            child: const Padding(
              padding: EdgeInsets.all(8.0),
              child: Icon(Icons.search_rounded, color: AsmitaPalette.deepNavy, size: 24),
            ),
          ),
          const SizedBox(width: 4),
          InkWell(
            onTap: onChatPressed,
            borderRadius: BorderRadius.circular(20),
            child: const Padding(
              padding: EdgeInsets.all(8.0),
              child: Icon(Icons.chat_bubble_outline_rounded, color: AsmitaPalette.deepNavy, size: 24),
            ),
          ),
          const SizedBox(width: 12),
          CircleAvatar(
            radius: 17,
            backgroundColor: AsmitaPalette.deepNavy,
            child: Text(initials, style: textTheme.titleLarge?.copyWith(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
          ),
              ],
            ),
          ),
        );
      },
    );
  }
}