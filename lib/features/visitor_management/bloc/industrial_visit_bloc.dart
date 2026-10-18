import 'package:flutter_bloc/flutter_bloc.dart';
import '../data/repositories/industrial_visit_repository.dart';
import 'industrial_visit_event.dart';
import 'industrial_visit_state.dart';

class IndustrialVisitBloc extends Bloc<IndustrialVisitEvent, IndustrialVisitState> {
  final IndustrialVisitRepository repository;

  IndustrialVisitBloc({required this.repository}) : super(const IndustrialVisitState()) {
    on<LoadIndustrialVisits>(_onLoadIndustrialVisits);
    on<DecideVisitEvent>(_onDecideVisit);
    on<AcknowledgeVisitEvent>(_onAcknowledgeVisit);
    on<CheckInPassEvent>(_onCheckInPass);
    on<CheckOutPassEvent>(_onCheckOutPass);
    on<OverrideVisitEvent>(_onOverrideVisit);
    on<CreateVehicleDraftEvent>(_onCreateVehicleDraft);
    on<CreateDeliveryIntakeEvent>(_onCreateDeliveryIntake);
    on<ConfirmDeliveryHandoverEvent>(_onConfirmDeliveryHandover);
    on<ClockInDutyEvent>(_onClockInDuty);
    on<ClockOutDutyEvent>(_onClockOutDuty);
  }

  Future<void> _onLoadIndustrialVisits(
    LoadIndustrialVisits event,
    Emitter<IndustrialVisitState> emit,
  ) async {
    emit(state.copyWith(status: IndustrialVisitBlocStatus.loading));
    try {
      final visits = await repository.getVisits(
        status: event.status,
        arrivalMode: event.arrivalMode,
        departmentId: event.departmentId,
        hostUserId: event.hostUserId,
      );
      emit(state.copyWith(
        status: IndustrialVisitBlocStatus.loaded,
        visits: visits,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: IndustrialVisitBlocStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onDecideVisit(
    DecideVisitEvent event,
    Emitter<IndustrialVisitState> emit,
  ) async {
    emit(state.copyWith(status: IndustrialVisitBlocStatus.loading));
    try {
      final res = await repository.handleVisitAction(
        event.visitId,
        action: event.action,
        assignedUserId: event.assignedUserId,
        cabinId: event.cabinId,
        deskId: event.deskId,
        rejectionReason: event.rejectionReason,
      );
      final msg = res['message']?.toString() ?? 'Visit decided successfully';
      
      // Refresh list after decision
      final updatedVisits = await repository.getVisits();
      emit(state.copyWith(
        status: IndustrialVisitBlocStatus.actionSuccess,
        successMessage: msg,
        visits: updatedVisits,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: IndustrialVisitBlocStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onAcknowledgeVisit(
    AcknowledgeVisitEvent event,
    Emitter<IndustrialVisitState> emit,
  ) async {
    try {
      await repository.acknowledgeVisit(event.visitId);
      final updatedVisits = await repository.getVisits();
      emit(state.copyWith(
        status: IndustrialVisitBlocStatus.actionSuccess,
        successMessage: 'Visit acknowledged. Escalation grace period activated.',
        visits: updatedVisits,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: IndustrialVisitBlocStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onCheckInPass(
    CheckInPassEvent event,
    Emitter<IndustrialVisitState> emit,
  ) async {
    emit(state.copyWith(status: IndustrialVisitBlocStatus.loading));
    try {
      final updated = await repository.checkInPass(
        visitId: event.visitId,
        gateId: event.gateId,
        passCode: event.passCode,
      );
      final updatedVisits = await repository.getVisits();
      emit(state.copyWith(
        status: IndustrialVisitBlocStatus.actionSuccess,
        successMessage: 'Pass checked in successfully.',
        lastActionVisit: updated,
        visits: updatedVisits,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: IndustrialVisitBlocStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onCheckOutPass(
    CheckOutPassEvent event,
    Emitter<IndustrialVisitState> emit,
  ) async {
    emit(state.copyWith(status: IndustrialVisitBlocStatus.loading));
    try {
      final updated = await repository.checkOutPass(
        visitId: event.visitId,
        gateId: event.gateId,
      );
      final updatedVisits = await repository.getVisits();
      emit(state.copyWith(
        status: IndustrialVisitBlocStatus.actionSuccess,
        successMessage: 'Pass checked out successfully.',
        lastActionVisit: updated,
        visits: updatedVisits,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: IndustrialVisitBlocStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onOverrideVisit(
    OverrideVisitEvent event,
    Emitter<IndustrialVisitState> emit,
  ) async {
    emit(state.copyWith(status: IndustrialVisitBlocStatus.loading));
    try {
      final updated = await repository.overrideVisit(
        event.visitId,
        overrideReason: event.overrideReason,
        photoBase64: event.photoBase64,
      );
      final updatedVisits = await repository.getVisits();
      emit(state.copyWith(
        status: IndustrialVisitBlocStatus.actionSuccess,
        successMessage: 'Guard override approved.',
        lastActionVisit: updated,
        visits: updatedVisits,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: IndustrialVisitBlocStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onCreateVehicleDraft(
    CreateVehicleDraftEvent event,
    Emitter<IndustrialVisitState> emit,
  ) async {
    emit(state.copyWith(status: IndustrialVisitBlocStatus.loading));
    try {
      final draftRes = await repository.createVehicleDraft(
        vehicleNumber: event.vehicleNumber,
        visitorName: event.visitorName,
        gateId: event.gateId,
      );
      emit(state.copyWith(
        status: IndustrialVisitBlocStatus.actionSuccess,
        successMessage: 'Vehicle draft slip generated.',
        lastCreatedDraft: draftRes['draft'] as Map<String, dynamic>?,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: IndustrialVisitBlocStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onCreateDeliveryIntake(
    CreateDeliveryIntakeEvent event,
    Emitter<IndustrialVisitState> emit,
  ) async {
    emit(state.copyWith(status: IndustrialVisitBlocStatus.loading));
    try {
      final visit = await repository.createDeliveryVisit(
        deliveryCompany: event.deliveryCompany,
        recipientName: event.recipientName,
        recipientUserId: event.recipientUserId,
        photoBase64: event.photoBase64,
        gateId: event.gateId,
      );
      final updatedVisits = await repository.getVisits();
      emit(state.copyWith(
        status: IndustrialVisitBlocStatus.actionSuccess,
        successMessage: 'Delivery intake logged at Gate ${event.gateId}.',
        lastActionVisit: visit,
        visits: updatedVisits,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: IndustrialVisitBlocStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onConfirmDeliveryHandover(
    ConfirmDeliveryHandoverEvent event,
    Emitter<IndustrialVisitState> emit,
  ) async {
    emit(state.copyWith(status: IndustrialVisitBlocStatus.loading));
    try {
      final visit = await repository.confirmDeliveryHandover(event.visitId);
      final updatedVisits = await repository.getVisits();
      emit(state.copyWith(
        status: IndustrialVisitBlocStatus.actionSuccess,
        successMessage: 'Delivery handover confirmed. Status is COLLECTED.',
        lastActionVisit: visit,
        visits: updatedVisits,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: IndustrialVisitBlocStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onClockInDuty(
    ClockInDutyEvent event,
    Emitter<IndustrialVisitState> emit,
  ) async {
    emit(state.copyWith(status: IndustrialVisitBlocStatus.loading));
    try {
      await repository.clockInDuty(gateId: event.gateId);
      emit(state.copyWith(
        status: IndustrialVisitBlocStatus.actionSuccess,
        activeGateId: event.gateId,
        isDutyActive: true,
        successMessage: 'Clocked in at Gate ${event.gateId}.',
      ));
    } catch (e) {
      emit(state.copyWith(
        status: IndustrialVisitBlocStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onClockOutDuty(
    ClockOutDutyEvent event,
    Emitter<IndustrialVisitState> emit,
  ) async {
    emit(state.copyWith(status: IndustrialVisitBlocStatus.loading));
    try {
      await repository.clockOutDuty();
      emit(state.copyWith(
        status: IndustrialVisitBlocStatus.actionSuccess,
        activeGateId: null,
        isDutyActive: false,
        successMessage: 'Clocked out from guard duty.',
      ));
    } catch (e) {
      emit(state.copyWith(
        status: IndustrialVisitBlocStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }
}
