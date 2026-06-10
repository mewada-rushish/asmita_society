import 'package:flutter/material.dart';
import 'package:asmita_society/core/constants/design_system.dart';

class AsmitaPrimaryHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final String userInitials;

  const AsmitaPrimaryHeader({
    super.key,
    this.title = 'Siddhi CHS 34',
    this.subtitle = 'Premium Mode',
    this.userInitials = 'RM',
  });

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.viewPaddingOf(context).top;
    final textTheme = Theme.of(context).textTheme;

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
                    Text(title, style: textTheme.titleLarge?.copyWith(fontSize: 16, fontWeight: FontWeight.w700)),
                    const SizedBox(width: 2),
                    Icon(Icons.keyboard_arrow_down_rounded, color: AsmitaPalette.deepNavy.withValues(alpha: 0.8), size: 18),
                  ],
                ),
                Text(
                  subtitle, 
                  style: textTheme.bodyMedium?.copyWith(
                    fontSize: 11, 
                    fontWeight: FontWeight.w600,
                    color: subtitle.contains('Tenant') ? AsmitaPalette.actionRed : AsmitaPalette.textLight,
                  ),
                ),
              ],
            ),
          ),
          IconButton(icon: const Icon(Icons.search_rounded, color: AsmitaPalette.deepNavy, size: 24), onPressed: () {}),
          IconButton(icon: const Icon(Icons.chat_bubble_outline_rounded, color: AsmitaPalette.deepNavy, size: 22), onPressed: () {}),
          const SizedBox(width: 4),
          CircleAvatar(
            radius: 16,
            backgroundColor: AsmitaPalette.deepNavy,
            child: Text(userInitials, style: textTheme.titleLarge?.copyWith(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}