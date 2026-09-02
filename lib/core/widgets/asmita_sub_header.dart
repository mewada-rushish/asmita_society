import 'package:flutter/material.dart';
import 'package:asmita_society/core/constants/design_system.dart';

class AsmitaSubHeader extends StatelessWidget {
  final String title;
  final Widget? trailing;
  final VoidCallback? onBackPressed;

  const AsmitaSubHeader({
    super.key,
    required this.title,
    this.trailing,
    this.onBackPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 24.0, right: 24.0, top: 16.0, bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          GestureDetector(
            onTap: onBackPressed ?? () => Navigator.pop(context),
            behavior: HitTestBehavior.opaque,
            child: const Padding(
              padding: EdgeInsets.only(right: 12.0, top: 4.0, bottom: 4.0),
              child: Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 18,
                color: AsmitaPalette.deepNavy,
              ),
            ),
          ),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontFamily: 'Montserrat',
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AsmitaPalette.deepNavy,
              ),
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}
