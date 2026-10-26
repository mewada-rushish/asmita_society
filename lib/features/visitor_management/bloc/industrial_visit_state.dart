import 'package:equatable/equatable.dart';
import '../data/models/industrial_visit_model.dart';

enum IndustrialVisitBlocStatus { initial, loading, loaded, actionSuccess, error }

class IndustrialVisitState extends Equatable {
  final IndustrialVisitBlocStatus status;
  final List<IndustrialVisitModel> visits;
  final String? successMessage;
  final String? errorMessage;
  final int? activeGateId;
  final bool isDutyActive;
  final Map<String, dynamic>? lastCreatedDraft;
  final IndustrialVisitModel? lastActionVisit;

  const IndustrialVisitState({
    this.status = IndustrialVisitBlocStatus.initial,
    this.visits = const [],
    this.successMessage,
    this.errorMessage,
    this.activeGateId,
    this.isDutyActive = false,
    this.lastCreatedDraft,
    this.lastActionVisit,
  });

  IndustrialVisitState copyWith({
    IndustrialVisitBlocStatus? status,
    List<IndustrialVisitModel>? visits,
    String? successMessage,
    String? errorMessage,
    int? activeGateId,
    bool? isDutyActive,
    Map<String, dynamic>? lastCreatedDraft,
    IndustrialVisitModel? lastActionVisit,
  }) {
    return IndustrialVisitState(
      status: status ?? this.status,
      visits: visits ?? this.visits,
      successMessage: successMessage,
      errorMessage: errorMessage,
      activeGateId: activeGateId ?? this.activeGateId,
      isDutyActive: isDutyActive ?? this.isDutyActive,
      lastCreatedDraft: lastCreatedDraft ?? this.lastCreatedDraft,
      lastActionVisit: lastActionVisit ?? this.lastActionVisit,
    );
  }

  @override
  List<Object?> get props => [
        status,
        visits,
        successMessage,
        errorMessage,
        activeGateId,
        isDutyActive,
        lastCreatedDraft,
        lastActionVisit,
      ];
}
