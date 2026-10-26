import 'package:flutter/material.dart';
import 'package:asmita_society/core/constants/design_system.dart';

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

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (bottomSheetContext) {
        return _SelectBottomSheet<T>(
          title: sheetTitle ?? (label != null ? 'Select $label' : 'Select Option'),
          subtitle: sheetSubtitle,
          items: items,
          selectedValue: value,
          showSearch: shouldShowSearch,
          onSelected: (selected) {
            Navigator.pop(bottomSheetContext);
            onChanged!(selected);
          },
        );
      },
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

/// The bottom sheet list picker for [AsmitaSelectField].
class _SelectBottomSheet<T> extends StatefulWidget {
  final String title;
  final String? subtitle;
  final List<AsmitaSelectItem<T>> items;
  final T? selectedValue;
  final bool showSearch;
  final ValueChanged<T> onSelected;

  const _SelectBottomSheet({
    required this.title,
    this.subtitle,
    required this.items,
    required this.selectedValue,
    required this.showSearch,
    required this.onSelected,
  });

  @override
  State<_SelectBottomSheet<T>> createState() => _SelectBottomSheetState<T>();
}

class _SelectBottomSheetState<T> extends State<_SelectBottomSheet<T>> {
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
    final surfaceColor = isDark ? AsmitaPalette.surfaceDark : AsmitaPalette.surfaceLight;

    final filteredItems = _searchQuery.isEmpty
        ? widget.items
        : widget.items.where((i) {
            final matchLabel = i.label.toLowerCase().contains(_searchQuery.toLowerCase());
            final matchSub = (i.subtitle ?? '').toLowerCase().contains(_searchQuery.toLowerCase());
            return matchLabel || matchSub;
          }).toList();

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.75,
      ),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Drag Handle
            const SizedBox(height: 12),
            Center(
              child: Container(
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.black12,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            // Header Row
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 12, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.title,
                          style: TextStyle(
                            fontFamily: 'Montserrat',
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: isDark ? AsmitaPalette.textDarkModeMain : AsmitaPalette.textDark,
                          ),
                        ),
                        if (widget.subtitle != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            widget.subtitle!,
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 12,
                              color: isDark ? AsmitaPalette.textDarkModeMuted : AsmitaPalette.textLight,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.close_rounded,
                      color: isDark ? AsmitaPalette.textDarkModeMuted : AsmitaPalette.textLight,
                      size: 22,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            // Search Input if enabled
            if (widget.showSearch) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
                child: TextField(
                  controller: _searchCtrl,
                  onChanged: (val) => setState(() => _searchQuery = val.trim()),
                  style: const TextStyle(fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'Search...',
                    hintStyle: TextStyle(
                      color: isDark ? AsmitaPalette.textDarkModeMuted : AsmitaPalette.textLight,
                      fontSize: 13,
                    ),
                    prefixIcon: const Icon(Icons.search_rounded, size: 20, color: AsmitaPalette.deepNavy),
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
                    fillColor: isDark ? AsmitaPalette.systemBGDark : AsmitaPalette.systemBG,
                    contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
            ],
            const Divider(height: 12, thickness: 0.8),
            // Options List
            Flexible(
              child: filteredItems.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.symmetric(vertical: 36),
                      child: Center(
                        child: Text(
                          'No matching options',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            color: isDark ? AsmitaPalette.textDarkModeMuted : AsmitaPalette.textLight,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    )
                  : ListView.separated(
                      shrinkWrap: true,
                      padding: const EdgeInsets.fromLTRB(16, 6, 16, 20),
                      itemCount: filteredItems.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 6),
                      itemBuilder: (context, index) {
                        final item = filteredItems[index];
                        final isSelected = item.value == widget.selectedValue;

                        return Material(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                          child: InkWell(
                            onTap: () => widget.onSelected(item.value),
                            borderRadius: BorderRadius.circular(12),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AsmitaPalette.deepNavy.withValues(alpha: isDark ? 0.2 : 0.08)
                                    : (isDark ? AsmitaPalette.systemBGDark.withValues(alpha: 0.4) : AsmitaPalette.systemBG.withValues(alpha: 0.5)),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected
                                      ? AsmitaPalette.deepNavy
                                      : (isDark ? AsmitaPalette.borderGreyDark : AsmitaPalette.borderGrey),
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
                                              fontFamily: 'Poppins',
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
        ),
      ),
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
