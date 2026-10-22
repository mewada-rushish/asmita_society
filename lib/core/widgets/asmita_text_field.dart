import 'package:flutter/material.dart';
import 'package:asmita_society/core/constants/design_system.dart';

/// A standardized text field widget for the Asmita Society app.
class AsmitaTextField extends StatelessWidget {
  final String label;
  final String hint;
  final IconData? icon;
  final TextEditingController? controller;
  final TextInputType? keyboardType;
  final bool readOnly;
  final int? maxLength;
  final int? maxLines;
  final int? minLines;
  final TextCapitalization textCapitalization;
  final ValueChanged<String>? onChanged;
  final FormFieldValidator<String>? validator;

  const AsmitaTextField({
    super.key,
    required this.label,
    required this.hint,
    this.icon,
    this.controller,
    this.keyboardType,
    this.readOnly = false,
    this.maxLength,
    this.maxLines = 1,
    this.minLines,
    this.textCapitalization = TextCapitalization.none,
    this.onChanged,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final labelColor =
        isDark ? AsmitaPalette.textDarkModeMain : AsmitaPalette.textDark;
    final fillColor =
        isDark ? AsmitaPalette.surfaceDark : AsmitaPalette.systemBG;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: textTheme.bodyMedium?.copyWith(
            fontFamily: 'Montserrat',
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: labelColor,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          readOnly: readOnly,
          maxLength: maxLength,
          maxLines: maxLines,
          minLines: minLines,
          textCapitalization: textCapitalization,
          onChanged: onChanged,
          validator: validator,
          style: textTheme.bodyLarge?.copyWith(
            fontFamily: 'Poppins',
            fontSize: 14,
            color: isDark
                ? AsmitaPalette.textDarkModeMain
                : AsmitaPalette.textDark,
          ),
          decoration: InputDecoration(
            counterText: '',
            hintText: hint,
            hintStyle: TextStyle(
              fontFamily: 'Poppins',
              color: isDark
                  ? AsmitaPalette.textDarkModeMuted
                  : AsmitaPalette.textLight.withValues(alpha: 0.6),
              fontSize: 14,
            ),
            prefixIcon: icon != null
                ? Icon(
                    icon,
                    color: isDark
                        ? AsmitaPalette.textDarkModeMuted
                        : AsmitaPalette.textLight,
                    size: 20,
                  )
                : null,
            filled: true,
            fillColor: fillColor,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Theme.of(context).dividerColor,
                width: 1,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Theme.of(context).dividerColor,
                width: 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: AsmitaPalette.deepNavy,
                width: 1.5,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: AsmitaPalette.actionRed,
                width: 1.5,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),
          ),
        ),
      ],
    );
  }
}