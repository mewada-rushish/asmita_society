import 'package:flutter/material.dart';
import 'package:asmita_society/core/constants/design_system.dart';
import 'asmita_bottom_sheet.dart';

/// Item representation for [AsmitaSelectField] and [AsmitaChoiceChips].
class AsmitaSelectItem<T> {
  final T value;
  final String label;
  final String? subtitle;
  final IconData? icon;
  final Color? iconColor;

  const AsmitaSelectItem({
    required this.value,
    required this.label,
    this.subtitle,
    this.icon,
    this.iconColor,
  });
}

/// An elegant modal-picker select field styled to match the AsmitA Design System.
/// Replaces standard rectangular [DropdownButton] / [DropdownButtonFormField].
class AsmitaSelectField<T> extends StatelessWidget {
  final String? label;
  final String hint;
  final T? value;
  final List<AsmitaSelectItem<T>> items;
  final ValueChanged<T?>? onChanged;
  final IconData? prefixIcon;
  final String? sheetTitle;
  final String? sheetSubtitle;
  final bool enabled;
  final bool? showSearch;
  final String? errorText;

  const AsmitaSelectField({
    super.key,
    this.label,
    this.hint = 'Select an option',
    required this.value,
    required this.items,
    this.onChanged,
    this.prefixIcon,
    this.sheetTitle,
    this.sheetSubtitle,
    this.enabled = true,
    this.showSearch,
    this.errorText,
  });

  AsmitaSelectItem<T>? get _selectedItem {
    try {
      return items.firstWhere((item) => item.value == value);
    } catch (_) {
      return null;
    }
  }

  void _openSelectionSheet(BuildContext context) {
    if (!enabled || onChanged == null) return;

    final shouldShowSearch = showSearch ?? (items.length > 6);
    final effectiveTitle = sheetTitle ??
        (label != null
            ? (label!.trim().toLowerCase().startsWith('select ')
                ? label!
                : 'Select $label')
            : 'Select Option');

    showAsmitaBottomSheet<void>(
      context: context,
      title: effectiveTitle,
      subtitle: sheetSubtitle,
      contentPadding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: _SelectSheetContent<T>(
        items: items,
        selectedValue: value,
        showSearch: shouldShowSearch,
        onSelected: (selected) {
          onChanged!(selected);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final selected = _selectedItem;

    final bgColor = isDark ? AsmitaPalette.surfaceDark : AsmitaPalette.systemBG;
    final borderColor = errorText != null
        ? AsmitaPalette.actionRed
        : (isDark ? AsmitaPalette.borderGreyDark : AsmitaPalette.borderGrey);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label != null) ...[
          Text(
            label!,
            style: textTheme.bodyMedium?.copyWith(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isDark ? AsmitaPalette.textDarkModeMuted : AsmitaPalette.textDark,
            ),
          ),
          const SizedBox(height: 8),
        ],
        Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            onTap: enabled ? () => _openSelectionSheet(context) : null,
            borderRadius: BorderRadius.circular(12),
            splashColor: AsmitaPalette.deepNavy.withValues(alpha: 0.08),
            highlightColor: AsmitaPalette.deepNavy.withValues(alpha: 0.04),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
              decoration: BoxDecoration(
                color: enabled ? bgColor : bgColor.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: borderColor, width: 1.2),
              ),
              child: Row(
                children: [
                  if (prefixIcon != null) ...[
                    Icon(
                      prefixIcon,
                      size: 20,
                      color: enabled ? AsmitaPalette.deepNavy : AsmitaPalette.textLight,
                    ),
                    const SizedBox(width: 10),
                  ] else if (selected?.icon != null) ...[
                    Icon(
                      selected!.icon,
                      size: 20,
                      color: selected.iconColor ?? AsmitaPalette.deepNavy,
                    ),
                    const SizedBox(width: 10),
                  ],
                  Expanded(
                    child: Text(
                      selected?.label ?? hint,
                      style: textTheme.bodyLarge?.copyWith(
                        fontSize: 14,
                        fontWeight: selected != null ? FontWeight.w500 : FontWeight.normal,
                        color: selected != null
                            ? (isDark ? AsmitaPalette.textDarkModeMain : AsmitaPalette.textDark)
                            : (isDark
                                ? AsmitaPalette.textDarkModeMuted.withValues(alpha: 0.6)
                                : AsmitaPalette.textLight.withValues(alpha: 0.7)),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: enabled
                          ? AsmitaPalette.deepNavy.withValues(alpha: 0.08)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: 20,
                      color: enabled ? AsmitaPalette.deepNavy : AsmitaPalette.textLight,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (errorText != null) ...[
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Text(
              errorText!,
              style: textTheme.bodySmall?.copyWith(
                color: AsmitaPalette.actionRed,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// The bottom sheet list picker content for [AsmitaSelectField], rendered inside [AsmitaBottomSheet].
class _SelectSheetContent<T> extends StatefulWidget {
  final List<AsmitaSelectItem<T>> items;
  final T? selectedValue;
  final bool showSearch;
  final ValueChanged<T> onSelected;

  const _SelectSheetContent({
    required this.items,
    required this.selectedValue,
    required this.showSearch,
    required this.onSelected,
  });

  @override
  State<_SelectSheetContent<T>> createState() => _SelectSheetContentState<T>();
}

class _SelectSheetContentState<T> extends State<_SelectSheetContent<T>> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final filteredItems = _searchQuery.isEmpty
        ? widget.items
        : widget.items.where((i) {
            final matchLabel = i.label.toLowerCase().contains(_searchQuery.toLowerCase());
            final matchSub = (i.subtitle ?? '').toLowerCase().contains(_searchQuery.toLowerCase());
            return matchLabel || matchSub;
          }).toList();

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.showSearch) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (val) => setState(() => _searchQuery = val.trim()),
              style: TextStyle(
                fontFamily: 'Montserrat',
                fontSize: 13,
                color: isDark ? AsmitaPalette.textDarkModeMain : AsmitaPalette.textDark,
              ),
              decoration: InputDecoration(
                hintText: 'Search...',
                hintStyle: TextStyle(
                  fontFamily: 'Montserrat',
                  color: isDark ? AsmitaPalette.textDarkModeMuted : AsmitaPalette.textLight,
                  fontSize: 13,
                ),
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  size: 20,
                  color: AsmitaPalette.deepNavy,
                ),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                filled: true,
                fillColor: isDark ? AsmitaPalette.surfaceDark : AsmitaPalette.surfaceLight,
                contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: isDark ? AsmitaPalette.borderGreyDark : AsmitaPalette.borderGrey,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: isDark ? AsmitaPalette.borderGreyDark : AsmitaPalette.borderGrey,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: AsmitaPalette.deepNavy,
                    width: 1.5,
                  ),
                ),
              ),
            ),
          ),
        ],
        Flexible(
          child: filteredItems.isEmpty
              ? Padding(
                  padding: const EdgeInsets.symmetric(vertical: 28),
                  child: Center(
                    child: Text(
                      'No matching options',
                      style: TextStyle(
                        fontFamily: 'Montserrat',
                        color: isDark ? AsmitaPalette.textDarkModeMuted : AsmitaPalette.textLight,
                        fontSize: 13,
                      ),
                    ),
                  ),
                )
              : ListView.separated(
                  shrinkWrap: true,
                  physics: const ClampingScrollPhysics(),
                  padding: EdgeInsets.zero,
                  itemCount: filteredItems.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final item = filteredItems[index];
                    final isSelected = item.value == widget.selectedValue;

                    return Material(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(14),
                      child: InkWell(
                        onTap: () {
                          Navigator.of(context).pop();
                          widget.onSelected(item.value);
                        },
                        borderRadius: BorderRadius.circular(14),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AsmitaPalette.deepNavy.withValues(alpha: isDark ? 0.2 : 0.08)
                                : (isDark
                                    ? AsmitaPalette.surfaceDark
                                    : Theme.of(context).colorScheme.surface),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isSelected
                                  ? AsmitaPalette.deepNavy
                                  : (isDark ? AsmitaPalette.borderGreyDark : AsmitaPalette.borderGrey.withValues(alpha: 0.8)),
                              width: isSelected ? 1.5 : 1.0,
                            ),
                          ),
                          child: Row(
                            children: [
                              if (item.icon != null) ...[
                                Container(
                                  width: 38,
                                  height: 38,
                                  decoration: BoxDecoration(
                                    color: (item.iconColor ?? AsmitaPalette.deepNavy)
                                        .withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(
                                    item.icon,
                                    size: 20,
                                    color: item.iconColor ?? AsmitaPalette.deepNavy,
                                  ),
                                ),
                                const SizedBox(width: 12),
                              ],
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.label,
                                      style: TextStyle(
                                        fontFamily: 'Montserrat',
                                        fontSize: 14,
                                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                                        color: isSelected
                                            ? (isDark ? AsmitaPalette.deepNavyDark : AsmitaPalette.deepNavy)
                                            : (isDark ? AsmitaPalette.textDarkModeMain : AsmitaPalette.textDark),
                                      ),
                                    ),
                                    if (item.subtitle != null) ...[
                                      const SizedBox(height: 2),
                                      Text(
                                        item.subtitle!,
                                        style: TextStyle(
                                          fontFamily: 'Montserrat',
                                          fontSize: 11,
                                          color: isDark ? AsmitaPalette.textDarkModeMuted : AsmitaPalette.textLight,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              if (isSelected)
                                Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: const BoxDecoration(
                                    color: AsmitaPalette.deepNavy,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.check,
                                    size: 14,
                                    color: Colors.white,
                                  ),
                                )
                              else
                                Container(
                                  width: 18,
                                  height: 18,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: isDark ? AsmitaPalette.borderGreyDark : AsmitaPalette.borderGrey,
                                      width: 1.5,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

/// An elegant inline pill / choice chips component for compact options (3–6 items).
class AsmitaChoiceChips<T> extends StatelessWidget {
  final String? label;
  final List<AsmitaSelectItem<T>> items;
  final T selectedValue;
  final ValueChanged<T> onSelected;

  const AsmitaChoiceChips({
    super.key,
    this.label,
    required this.items,
    required this.selectedValue,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label != null) ...[
          Text(
            label!,
            style: TextStyle(
              fontFamily: 'Montserrat',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isDark ? AsmitaPalette.textDarkModeMuted : AsmitaPalette.textDark,
            ),
          ),
          const SizedBox(height: 8),
        ],
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: items.map((item) {
            final isSelected = item.value == selectedValue;
            final itemColor = item.iconColor ?? AsmitaPalette.deepNavy;

            return Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(20),
              child: InkWell(
                onTap: () => onSelected(item.value),
                borderRadius: BorderRadius.circular(20),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AsmitaPalette.deepNavy
                        : (isDark ? AsmitaPalette.surfaceDark : AsmitaPalette.systemBG),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected
                          ? AsmitaPalette.deepNavy
                          : (isDark ? AsmitaPalette.borderGreyDark : AsmitaPalette.borderGrey),
                      width: 1.2,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: AsmitaPalette.deepNavy.withValues(alpha: 0.25),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (item.icon != null) ...[
                        Icon(
                          item.icon,
                          size: 15,
                          color: isSelected ? Colors.white : itemColor,
                        ),
                        const SizedBox(width: 6),
                      ],
                      Text(
                        item.label,
                        style: TextStyle(
                          fontFamily: 'Montserrat',
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                          color: isSelected
                              ? Colors.white
                              : (isDark ? AsmitaPalette.textDarkModeMain : AsmitaPalette.textDark),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
