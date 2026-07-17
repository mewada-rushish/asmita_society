import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:asmita_society/core/constants/design_system.dart';
import 'package:asmita_society/features/dashboard/presentation/screens/search_screen.dart';
import 'package:asmita_society/features/auth/bloc/auth_bloc.dart';
import 'package:asmita_society/features/auth/bloc/auth_state.dart';

class AsmitaPrimaryHeader extends StatelessWidget {
  final String? title;
  final String? subtitle;
  final String? userInitials;
  final VoidCallback? onSearchPressed;
  final VoidCallback? onChatPressed;

  const AsmitaPrimaryHeader({
    super.key,
    this.title,
    this.subtitle,
    this.userInitials,
    this.onSearchPressed,
    this.onChatPressed,
  });

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.viewPaddingOf(context).top;
    final textTheme = Theme.of(context).textTheme;

    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        String displayTitle = title ?? '';
        String displaySubtitle = subtitle ?? '';
        String displayInitials = userInitials ?? 'U';

        if (authState is AuthAuthenticated) {
          final user = authState.user;
          if (userInitials == null && user.fullName.isNotEmpty) {
            displayInitials = user.fullName.trim().substring(0, 1).toUpperCase();
          }
          
          if (user.societyName?.isNotEmpty == true) {
            displayTitle = user.societyName!;
          }

          if (user.flatMappings.isNotEmpty) {
            final mapping = user.flatMappings.first;
            
            String wingText = mapping.towerName.trim();
            String flatNoText = mapping.flatNumber.trim();
            
            if (wingText.isNotEmpty && flatNoText.isNotEmpty) {
              displaySubtitle = '$wingText - $flatNoText';
            } else if (flatNoText.isNotEmpty) {
              displaySubtitle = flatNoText;
            } else if (wingText.isNotEmpty) {
              displaySubtitle = wingText;
            }
          }
        }

        return Container(
          color: AsmitaPalette.systemBG,
          padding: EdgeInsets.only(
            top: topPadding > 0 ? topPadding + 8 : 24, 
            bottom: 12, 
            left: 16, 
            right: 16
          ),
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        displayTitle, 
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.titleLarge?.copyWith(fontSize: 16, fontWeight: FontWeight.w700),
                      ),
                    ),
                    const SizedBox(width: 2),
                    Icon(Icons.keyboard_arrow_down_rounded, color: AsmitaPalette.deepNavy.withValues(alpha: 0.8), size: 18),
                  ],
                ),
                Text(
                  displaySubtitle, 
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.bodyMedium?.copyWith(
                    fontSize: 11, 
                    fontWeight: FontWeight.w600,
                    color: displaySubtitle.contains('Tenant') ? AsmitaPalette.actionRed : AsmitaPalette.textLight,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
                icon: const Icon(Icons.search_rounded, color: AsmitaPalette.deepNavy, size: 24),
                onPressed: onSearchPressed ?? () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AsmitaSearchScreen())),
              ),
              IconButton(icon: const Icon(Icons.chat_bubble_outline_rounded, color: AsmitaPalette.deepNavy, size: 22), onPressed: onChatPressed),
              const SizedBox(width: 4),
              CircleAvatar(
                radius: 16,
                backgroundColor: AsmitaPalette.deepNavy,
                child: Text(displayInitials, style: textTheme.titleLarge?.copyWith(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        );
      },
    );
  }
}