import 'package:flutter/material.dart';
import 'package:asmita_society/core/constants/design_system.dart';

/// A standardized text field widget for the Asmita Society app.
class AsmitaTextField extends StatelessWidget {
  
  final String label;
  final String hint;
  final IconData icon;
  final TextEditingController? controller;
  final TextInputType? keyboardType;

  const AsmitaTextField({
    super.key,
    required this.label,
    required this.hint,
    required this.icon,
    this.controller,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: textTheme.bodyMedium?.copyWith(fontSize: 12, fontWeight: FontWeight.w600, color: AsmitaPalette.textDark)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          style: textTheme.bodyLarge?.copyWith(fontSize: 14),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: AsmitaPalette.textLight.withValues(alpha: 0.6), fontSize: 14),
            prefixIcon: Icon(icon, color: AsmitaPalette.textLight, size: 20),
            filled: true,
            fillColor: AsmitaPalette.systemBG,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AsmitaPalette.deepNavy, width: 1.5)),
          ),
        ),
      ],
    );
  }
}