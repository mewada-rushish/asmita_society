import 'package:equatable/equatable.dart';
import 'package:asmita_society/features/dashboard/data/models/quick_action_registry.dart';

abstract class QuickActionsState extends Equatable {
  const QuickActionsState();

  @override
  List<Object> get props => [];
}

class QuickActionsLoading extends QuickActionsState {}

class QuickActionsLoaded extends QuickActionsState {
  final List<QuickActionType> selectedActions;

  const QuickActionsLoaded(this.selectedActions);

  @override
  List<Object> get props => [selectedActions];
}

class QuickActionsError extends QuickActionsState {
  final String message;

  const QuickActionsError(this.message);

  @override
  List<Object> get props => [message];
}
