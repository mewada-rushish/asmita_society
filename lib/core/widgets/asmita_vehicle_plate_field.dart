import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/design_system.dart';

/// A specialized 2:2:2:4 Indian Vehicle Number Plate box input widget.
///
/// Designed to follow the standard Indian HSRP (High Security Registration Plate) format:
/// - Box 1 (2 chars): State code (e.g. MH, DL, KA)
/// - Box 2 (2 chars): RTO / District code (e.g. 02, 04, 12)
/// - Box 3 (2 chars): Series code (e.g. AB, CD, AZ)
/// - Box 4 (4 chars): Registration number (e.g. 1234)
///
/// Supports automatic focus traversal, backspace backwards navigation,
/// paste parsing of full plates, and two-way sync with [controller].
class AsmitaIndianVehiclePlateField extends StatefulWidget {
  final String label;
  final TextEditingController controller;
  final ValueChanged<String>? onChanged;
  final bool isRequired;
  final bool showIndBadge;
  final Color? fillColor;

  const AsmitaIndianVehiclePlateField({
    super.key,
    required this.controller,
    this.label = 'Cab / Vehicle Registration Number',
    this.onChanged,
    this.isRequired = false,
    this.showIndBadge = true,
    this.fillColor,
  });

  @override
  State<AsmitaIndianVehiclePlateField> createState() =>
      _AsmitaIndianVehiclePlateFieldState();
}

class _AsmitaIndianVehiclePlateFieldState
    extends State<AsmitaIndianVehiclePlateField> {
  late final TextEditingController _box1Ctrl;
  late final TextEditingController _box2Ctrl;
  late final TextEditingController _box3Ctrl;
  late final TextEditingController _box4Ctrl;

  late final FocusNode _box1Focus;
  late final FocusNode _box2Focus;
  late final FocusNode _box3Focus;
  late final FocusNode _box4Focus;

  bool _isInternalUpdating = false;

  @override
  void initState() {
    super.initState();
    _box1Ctrl = TextEditingController();
    _box2Ctrl = TextEditingController();
    _box3Ctrl = TextEditingController();
    _box4Ctrl = TextEditingController();

    _box1Focus = FocusNode();
    _box2Focus = FocusNode();
    _box3Focus = FocusNode();
    _box4Focus = FocusNode();

    // Attach backspace detection when a box is already empty
    _box2Focus.onKeyEvent = (node, event) {
      if (event is KeyDownEvent &&
          event.logicalKey == LogicalKeyboardKey.backspace &&
          _box2Ctrl.text.isEmpty) {
        _box1Focus.requestFocus();
        _box1Ctrl.selection = TextSelection.fromPosition(
          TextPosition(offset: _box1Ctrl.text.length),
        );
        return KeyEventResult.handled;
      }
      return KeyEventResult.ignored;
    };

    _box3Focus.onKeyEvent = (node, event) {
      if (event is KeyDownEvent &&
          event.logicalKey == LogicalKeyboardKey.backspace &&
          _box3Ctrl.text.isEmpty) {
        _box2Focus.requestFocus();
        _box2Ctrl.selection = TextSelection.fromPosition(
          TextPosition(offset: _box2Ctrl.text.length),
        );
        return KeyEventResult.handled;
      }
      return KeyEventResult.ignored;
    };

    _box4Focus.onKeyEvent = (node, event) {
      if (event is KeyDownEvent &&
          event.logicalKey == LogicalKeyboardKey.backspace &&
          _box4Ctrl.text.isEmpty) {
        _box3Focus.requestFocus();
        _box3Ctrl.selection = TextSelection.fromPosition(
          TextPosition(offset: _box3Ctrl.text.length),
        );
        return KeyEventResult.handled;
      }
      return KeyEventResult.ignored;
    };

    _syncFromParent();
    widget.controller.addListener(_onParentControllerChanged);
  }

  @override
  void didUpdateWidget(covariant AsmitaIndianVehiclePlateField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onParentControllerChanged);
      widget.controller.addListener(_onParentControllerChanged);
      _syncFromParent();
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onParentControllerChanged);
    _box1Ctrl.dispose();
    _box2Ctrl.dispose();
    _box3Ctrl.dispose();
    _box4Ctrl.dispose();
    _box1Focus.dispose();
    _box2Focus.dispose();
    _box3Focus.dispose();
    _box4Focus.dispose();
    super.dispose();
  }

  void _onParentControllerChanged() {
    if (_isInternalUpdating) return;
    _syncFromParent();
  }

  void _syncFromParent() {
    final parentText = widget.controller.text.trim().toUpperCase();
    final currentCombined = [
      _box1Ctrl.text.trim().toUpperCase(),
      _box2Ctrl.text.trim().toUpperCase(),
      _box3Ctrl.text.trim().toUpperCase(),
      _box4Ctrl.text.trim().toUpperCase(),
    ].where((s) => s.isNotEmpty).join(' ');

    if (parentText == currentCombined) return;

    if (parentText.isEmpty) {
      _box1Ctrl.clear();
      _box2Ctrl.clear();
      _box3Ctrl.clear();
      _box4Ctrl.clear();
      return;
    }

    // Try space/dash splitting first
    final rawParts = parentText
        .split(RegExp(r'[\s\-]+'))
        .where((s) => s.isNotEmpty)
        .toList();

    if (rawParts.length >= 4) {
      _box1Ctrl.text = _truncate(rawParts[0], 2);
      _box2Ctrl.text = _truncate(rawParts[1], 2);
      _box3Ctrl.text = _truncate(rawParts[2], 2);
      _box4Ctrl.text = _truncate(rawParts.sublist(3).join(''), 4);
    } else if (rawParts.length == 3) {
      _box1Ctrl.text = _truncate(rawParts[0], 2);
      _box2Ctrl.text = _truncate(rawParts[1], 2);
      // If 3 parts, check if the 3rd part is digits (4) or series + digits
      final p3 = rawParts[2];
      if (p3.length > 4) {
        _box3Ctrl.text = _truncate(p3.substring(0, 2), 2);
        _box4Ctrl.text = _truncate(p3.substring(2), 4);
      } else {
        // e.g. MH 04 1234 without series
        _box3Ctrl.clear();
        _box4Ctrl.text = _truncate(p3, 4);
      }
    } else if (rawParts.length == 2) {
      _box1Ctrl.text = _truncate(rawParts[0], 2);
      _box2Ctrl.text = _truncate(rawParts[1], 2);
      _box3Ctrl.clear();
      _box4Ctrl.clear();
    } else {
      // Contiguous string (e.g. MH04AB1234 or MH041234)
      final clean = parentText.replaceAll(RegExp(r'[^A-Z0-9]'), '');
      if (clean.length <= 2) {
        _box1Ctrl.text = clean;
        _box2Ctrl.clear();
        _box3Ctrl.clear();
        _box4Ctrl.clear();
      } else if (clean.length <= 4) {
        _box1Ctrl.text = clean.substring(0, 2);
        _box2Ctrl.text = clean.substring(2);
        _box3Ctrl.clear();
        _box4Ctrl.clear();
      } else if (clean.length <= 6) {
        _box1Ctrl.text = clean.substring(0, 2);
        _box2Ctrl.text = clean.substring(2, 4);
        _box3Ctrl.clear();
        _box4Ctrl.text = clean.substring(4);
      } else {
        // Full Indian plate: 2 letters, 2 digits, 2 letters, 4 digits (e.g. MH04AB1234)
        _box1Ctrl.text = clean.substring(0, 2);
        _box2Ctrl.text = clean.substring(2, 4);
        if (clean.length <= 8) {
          // e.g. MH04A1234 or MH041234
          _box3Ctrl.text = clean.substring(4, clean.length - 4 > 0 ? clean.length - 4 : 4);
          _box4Ctrl.text = clean.substring(clean.length > 4 ? clean.length - 4 : 4);
        } else {
          _box3Ctrl.text = clean.substring(4, 6);
          _box4Ctrl.text = clean.substring(6, min(clean.length, 10));
        }
      }
    }
  }

  String _truncate(String s, int maxLen) {
    return s.length > maxLen ? s.substring(0, maxLen) : s;
  }

  void _notifyParent() {
    final p1 = _box1Ctrl.text.trim().toUpperCase();
    final p2 = _box2Ctrl.text.trim().toUpperCase();
    final p3 = _box3Ctrl.text.trim().toUpperCase();
    final p4 = _box4Ctrl.text.trim().toUpperCase();

    final parts = [p1, p2, p3, p4].where((s) => s.isNotEmpty).toList();
    final combined = parts.join(' ');

    _isInternalUpdating = true;
    if (widget.controller.text != combined) {
      widget.controller.text = combined;
    }
    _isInternalUpdating = false;

    widget.onChanged?.call(combined);
  }

  void _handlePasteOverflow(String fullClean) {
    if (fullClean.length <= 2) {
      _box1Ctrl.text = fullClean;
    } else if (fullClean.length <= 4) {
      _box1Ctrl.text = fullClean.substring(0, 2);
      _box2Ctrl.text = fullClean.substring(2);
      _box2Focus.requestFocus();
    } else if (fullClean.length <= 6) {
      _box1Ctrl.text = fullClean.substring(0, 2);
      _box2Ctrl.text = fullClean.substring(2, 4);
      _box3Ctrl.clear();
      _box4Ctrl.text = fullClean.substring(4);
      _box4Focus.requestFocus();
    } else if (fullClean.length <= 8) {
      _box1Ctrl.text = fullClean.substring(0, 2);
      _box2Ctrl.text = fullClean.substring(2, 4);
      _box3Ctrl.clear();
      _box4Ctrl.text = fullClean.substring(4, min(fullClean.length, 8));
      _box4Focus.requestFocus();
    } else {
      _box1Ctrl.text = fullClean.substring(0, 2);
      _box2Ctrl.text = fullClean.substring(2, 4);
      _box3Ctrl.text = fullClean.substring(4, 6);
      _box4Ctrl.text = fullClean.substring(6, min(fullClean.length, 10));
      _box4Focus.requestFocus();
    }
    _notifyParent();
  }

  void _handleBox1Changed(String val) {
    final upper = val.toUpperCase();
    if (val != upper) {
      _box1Ctrl.value = _box1Ctrl.value.copyWith(
        text: upper,
        selection: TextSelection.collapsed(offset: upper.length),
      );
    }
    _notifyParent();
    if (upper.length >= 2) {
      _box2Focus.requestFocus();
    }
  }

  void _handleBox2Changed(String val) {
    final upper = val.toUpperCase();
    if (val != upper) {
      _box2Ctrl.value = _box2Ctrl.value.copyWith(
        text: upper,
        selection: TextSelection.collapsed(offset: upper.length),
      );
    }
    _notifyParent();
    if (upper.length >= 2) {
      _box3Focus.requestFocus();
    }
  }

  void _handleBox3Changed(String val) {
    final upper = val.toUpperCase();
    if (val != upper) {
      _box3Ctrl.value = _box3Ctrl.value.copyWith(
        text: upper,
        selection: TextSelection.collapsed(offset: upper.length),
      );
    }
    _notifyParent();
    if (upper.length >= 2) {
      _box4Focus.requestFocus();
    }
  }

  void _handleBox4Changed(String val) {
    final upper = val.toUpperCase();
    if (val != upper) {
      _box4Ctrl.value = _box4Ctrl.value.copyWith(
        text: upper,
        selection: TextSelection.collapsed(offset: upper.length),
      );
    }
    _notifyParent();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final labelColor =
        isDark ? AsmitaPalette.textDarkModeMain : AsmitaPalette.textDark;
    final effectiveFillColor =
        widget.fillColor ??
        (isDark ? AsmitaPalette.surfaceDark : Colors.white);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label Row with car icon prefix (badge removed per user request)
        Row(
          children: [
            const Icon(
              Icons.directions_car_outlined,
              size: 16,
              color: AsmitaPalette.deepNavy,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                widget.isRequired ? '${widget.label} *' : widget.label,
                style: textTheme.bodyMedium?.copyWith(
                  fontFamily: 'Montserrat',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: labelColor,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Row of 2 : 2 : 2 : 4 inputs
        Row(
          children: [
            // Indian HSRP Blue Stripe Badge
            if (widget.showIndBadge) ...[
              Container(
                width: 32,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFF1E3A8A), // India HSRP Blue
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: Theme.of(context).dividerColor,
                    width: 1,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFFFBBF24), // Ashok Chakra yellow/gold
                      ),
                    ),
                    const SizedBox(height: 3),
                    const Text(
                      'IND',
                      style: TextStyle(
                        fontFamily: 'Montserrat',
                        fontSize: 8.5,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
            ],

            // Box 1: State Code (2 characters, letters only) e.g. "MH"
            Expanded(
              flex: 2,
              child: _buildPlateBox(
                context: context,
                controller: _box1Ctrl,
                focusNode: _box1Focus,
                hint: 'MH',
                maxLength: 2,
                formatters: [
                  _PlatePasteFormatter(onPasteOverflow: _handlePasteOverflow),
                ],
                onChanged: _handleBox1Changed,
                effectiveFillColor: effectiveFillColor,
                isDark: isDark,
              ),
            ),

            const SizedBox(width: 8),

            // Box 2: District / RTO Code (2 characters, digits/alphanumeric) e.g. "04"
            Expanded(
              flex: 2,
              child: _buildPlateBox(
                context: context,
                controller: _box2Ctrl,
                focusNode: _box2Focus,
                hint: '04',
                maxLength: 2,
                formatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9]')),
                  LengthLimitingTextInputFormatter(2),
                ],
                onChanged: _handleBox2Changed,
                effectiveFillColor: effectiveFillColor,
                isDark: isDark,
              ),
            ),

            const SizedBox(width: 8),

            // Box 3: Series Code (2 characters, letters/alphanumeric) e.g. "AB"
            Expanded(
              flex: 2,
              child: _buildPlateBox(
                context: context,
                controller: _box3Ctrl,
                focusNode: _box3Focus,
                hint: 'AB',
                maxLength: 2,
                formatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9]')),
                  LengthLimitingTextInputFormatter(2),
                ],
                onChanged: _handleBox3Changed,
                effectiveFillColor: effectiveFillColor,
                isDark: isDark,
              ),
            ),

            const SizedBox(width: 8),

            // Box 4: Unique Number (4 characters, digits/alphanumeric) e.g. "1234"
            Expanded(
              flex: 4,
              child: _buildPlateBox(
                context: context,
                controller: _box4Ctrl,
                focusNode: _box4Focus,
                hint: '1234',
                maxLength: 4,
                formatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9]')),
                  LengthLimitingTextInputFormatter(4),
                ],
                onChanged: _handleBox4Changed,
                effectiveFillColor: effectiveFillColor,
                isDark: isDark,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPlateBox({
    required BuildContext context,
    required TextEditingController controller,
    required FocusNode focusNode,
    required String hint,
    required int maxLength,
    required List<TextInputFormatter> formatters,
    required ValueChanged<String> onChanged,
    required Color effectiveFillColor,
    required bool isDark,
  }) {
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      keyboardType: TextInputType.text,
      textCapitalization: TextCapitalization.characters,
      textAlign: TextAlign.center,
      style: TextStyle(
        fontFamily: 'Montserrat',
        fontSize: 14.5,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.0,
        color: isDark ? AsmitaPalette.textDarkModeMain : AsmitaPalette.textDark,
      ),
      inputFormatters: formatters,
      onChanged: onChanged,
      decoration: InputDecoration(
        counterText: '',
        hintText: hint,
        hintStyle: TextStyle(
          fontFamily: 'Montserrat',
          fontWeight: FontWeight.w600,
          letterSpacing: 1.0,
          color: isDark
              ? AsmitaPalette.textDarkModeMuted
              : AsmitaPalette.textLight.withValues(alpha: 0.4),
          fontSize: 13.5,
        ),
        filled: true,
        fillColor: effectiveFillColor,
        contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 13),
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
            width: 1.8,
          ),
        ),
      ),
    );
  }
}

class _PlatePasteFormatter extends TextInputFormatter {
  final void Function(String fullText) onPasteOverflow;

  _PlatePasteFormatter({required this.onPasteOverflow});

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final clean =
        newValue.text.replaceAll(RegExp(r'[^A-Za-z0-9]'), '').toUpperCase();
    if (clean.length > 2) {
      onPasteOverflow(clean);
      final truncated = clean.substring(0, 2);
      return TextEditingValue(
        text: truncated,
        selection: TextSelection.collapsed(offset: truncated.length),
      );
    }
    return newValue.copyWith(text: clean);
  }
}
