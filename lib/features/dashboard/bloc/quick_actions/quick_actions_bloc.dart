import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive/hive.dart';
import 'package:asmita_society/features/dashboard/data/models/quick_action_registry.dart';
import 'quick_actions_state.dart';

abstract class QuickActionsEvent {}

class LoadQuickActions extends QuickActionsEvent {}

class SaveQuickActions extends QuickActionsEvent {
  final List<QuickActionType> actions;
  SaveQuickActions(this.actions);
}

class QuickActionsBloc extends Bloc<QuickActionsEvent, QuickActionsState> {
  final Box _cacheBox;
  static const String _storageKey = 'saved_quick_actions';

  QuickActionsBloc({Box? cacheBox})
      : _cacheBox = cacheBox ?? Hive.box('app_cache'),
        super(QuickActionsLoading()) {
    on<LoadQuickActions>(_onLoadQuickActions);
    on<SaveQuickActions>(_onSaveQuickActions);
  }

  void _onLoadQuickActions(LoadQuickActions event, Emitter<QuickActionsState> emit) {
    try {
      final savedData = _cacheBox.get(_storageKey) as List<dynamic>?;
      
      if (savedData == null || savedData.isEmpty) {
        emit(const QuickActionsLoaded(QuickActionRegistry.defaultActions));
      } else {
        final parsedActions = savedData.map((e) {
          try {
            return QuickActionType.values.firstWhere((type) => type.toString() == e);
          } catch (_) {
            return null;
          }
        }).where((e) => e != null).cast<QuickActionType>().toList();
        
        if (parsedActions.isEmpty) {
          emit(const QuickActionsLoaded(QuickActionRegistry.defaultActions));
        } else {
          emit(QuickActionsLoaded(parsedActions));
        }
      }
    } catch (e) {
      emit(QuickActionsLoaded(QuickActionRegistry.defaultActions));
    }
  }

  void _onSaveQuickActions(SaveQuickActions event, Emitter<QuickActionsState> emit) async {
    try {
      final stringList = event.actions.map((e) => e.toString()).toList();
      await _cacheBox.put(_storageKey, stringList);
      emit(QuickActionsLoaded(event.actions));
    } catch (e) {
      emit(QuickActionsError("Failed to save quick actions"));
    }
  }
}
