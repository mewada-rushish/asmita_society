import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:asmita_society/features/dashboard/data/models/quick_action_registry.dart';
import 'package:asmita_society/features/dashboard/bloc/quick_actions/quick_actions_bloc.dart';
import 'package:asmita_society/features/dashboard/bloc/quick_actions/quick_actions_state.dart';
import 'package:asmita_society/core/widgets/asmita_toast.dart';

class CustomiseQuickActionsSheet extends StatefulWidget {
  const CustomiseQuickActionsSheet({super.key});

  @override
  State<CustomiseQuickActionsSheet> createState() => _CustomiseQuickActionsSheetState();
}

class _CustomiseQuickActionsSheetState extends State<CustomiseQuickActionsSheet> {
  List<QuickActionType> _selectedActions = [];
  List<QuickActionType> _unselectedActions = [];
  static const int _maxSelection = 7;

  @override
  void initState() {
    super.initState();
    final state = context.read<QuickActionsBloc>().state;
    if (state is QuickActionsLoaded) {
      _selectedActions = List.from(state.selectedActions);
    } else {
      _selectedActions = List.from(QuickActionRegistry.defaultActions);
    }
    _unselectedActions = QuickActionRegistry.allActions.keys
        .where((type) => !_selectedActions.contains(type))
        .toList();
  }

  void _save() {
    context.read<QuickActionsBloc>().add(SaveQuickActions(_selectedActions));
    Navigator.pop(context);
    AsmitaToast.show(context, message: 'Customization saved successfully', type: AsmitaToastType.success);
  }

  void _toggleSelection(QuickActionType type) {
    setState(() {
      if (_selectedActions.contains(type)) {
        _selectedActions.remove(type);
        _unselectedActions.add(type);
      } else {
        if (_selectedActions.length < _maxSelection) {
          _unselectedActions.remove(type);
          _selectedActions.add(type);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('You can only select up to $_maxSelection actions.')),
          );
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
                  Expanded(
                    child: CustomScrollView(
                      slivers: [
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: Text(
                              'Selected (${_selectedActions.length}/$_maxSelection)',
                              style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),

                        SliverReorderableList(
                          itemCount: _selectedActions.length,
                          itemBuilder: (context, index) {
                            final type = _selectedActions[index];
                            final meta = QuickActionRegistry.allActions[type]!;
                            return _buildActionTile(meta, true, index, Key(type.toString()));
                          },
                          onReorderItem: (oldIndex, newIndex) {
                            setState(() {
                              final item = _selectedActions.removeAt(oldIndex);
                              _selectedActions.insert(newIndex, item);
                            });
                          },
                        ),
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.only(top: 16.0, bottom: 8.0),
                            child: Text(
                              'More Actions',
                              style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),
                        SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final type = _unselectedActions[index];
                              final meta = QuickActionRegistry.allActions[type]!;
                              return _buildActionTile(meta, false, null, Key(type.toString()));
                            },
                            childCount: _unselectedActions.length,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Theme.of(context).colorScheme.onPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Save Configuration', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
        ],
    );
  }

  Widget _buildActionTile(QuickActionMetadata meta, bool isSelected, int? index, Key key) {
    return Container(
      key: key,
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).dividerColor, width: 1),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: ListTile(
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: meta.iconColor ?? Theme.of(context).colorScheme.primary,
              shape: BoxShape.circle,
            ),
            child: Icon(
              meta.icon,
              color: Theme.of(context).brightness == Brightness.dark ? Colors.black : Colors.white,
              size: 20,
            ),
          ),
          title: Text(meta.label),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: Icon(
                  isSelected ? Icons.remove_circle_outline : Icons.add_circle_outline,
                  color: isSelected ? Theme.of(context).colorScheme.error : Colors.green,
                ),
                onPressed: () => _toggleSelection(meta.type),
              ),
              if (isSelected && index != null) 
                ReorderableDragStartListener(
                  index: index,
                  child: const Icon(Icons.drag_handle, color: Colors.grey),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
