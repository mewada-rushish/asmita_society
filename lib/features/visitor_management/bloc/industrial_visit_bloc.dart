import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../data/models/industrial_visit_model.dart';
import '../data/repositories/industrial_visit_repository.dart';
import 'industrial_visit_event.dart';
import 'industrial_visit_state.dart';
import '../../../core/security/secure_storage_service.dart';
import '../../../core/services/incoming_visitor_service.dart';
import '../../../core/utils/property_role_resolver.dart';

class IndustrialVisitBloc extends Bloc<IndustrialVisitEvent, IndustrialVisitState> {
  final IndustrialVisitRepository repository;
  bool _isFetchingVisits = false;
  DateTime? _lastVisitsFetchAt;
  DateTime? _visitsRateLimitedUntil;

  IndustrialVisitBloc({required this.repository}) : super(const IndustrialVisitState()) {
    on<LoadIndustrialVisits>(_onLoadIndustrialVisits);
    on<DecideVisitEvent>(_onDecideVisit);
    on<AcknowledgeVisitEvent>(_onAcknowledgeVisit);
    on<CheckInPassEvent>(_onCheckInPass);
    on<SendToLobbyEvent>(_onSendToLobby);
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
    final now = DateTime.now();
    if (_visitsRateLimitedUntil != null && now.isBefore(_visitsRateLimitedUntil!)) {
      return;
    }
    if (event.isSilent) {
      final lifecycle = WidgetsBinding.instance.lifecycleState;
      if (lifecycle != null && lifecycle != AppLifecycleState.resumed) {
        return;
      }
      if (_isFetchingVisits) {
        return;
      }
      if (_lastVisitsFetchAt != null &&
          now.difference(_lastVisitsFetchAt!) < const Duration(seconds: 10)) {
        return;
      }
    }

    _isFetchingVisits = true;
    if (!event.isSilent && state.visits.isEmpty) {
      emit(state.copyWith(status: IndustrialVisitBlocStatus.loading));
    }
    try {
      final visits = await repository.getVisits(
        status: event.status,
        arrivalMode: event.arrivalMode,
        departmentId: event.departmentId,
        hostUserId: event.hostUserId,
      );
      _lastVisitsFetchAt = DateTime.now();
      _visitsRateLimitedUntil = null;
      emit(state.copyWith(
        status: IndustrialVisitBlocStatus.loaded,
        visits: visits,
      ));

      // Foreground In-App Detection:
      // Only alert active PTM / host approver (never front desk receptionists, guards, or non-hosts)
      try {
        final currentUserId = await SecureStorageService().getUserId();
        final currentUserRole = await SecureStorageService().getUserRole();
        final normalizedRole = PropertyRoleResolver.normalizeRole(currentUserRole, isIndustrial: true);
        final isStaffDesk = normalizedRole == 'receptionist' || normalizedRole == 'guard' || normalizedRole == 'facility';

        if (!isStaffDesk && currentUserId != null) {
          for (final v in visits) {
            if (v.isPending && !v.isPreApproved && v.id > 0) {
              final isTargetHost = v.hostUserId == currentUserId || v.assignedToUserId == currentUserId;
              if (isTargetHost) {
                final payload = {
                  'visit_id': v.id.toString(),
                  'visitor_name': v.cleanVisitorName,
                  'department': v.departmentName ?? 'Department',
                  'floor': v.floor ?? '',
                  'purpose': v.cleanPurpose,
                  'vehicle_number': v.vehicleNumber ?? '',
                  'photo_url': v.visitorPhotoUrl ?? '',
                  'status': v.status.apiValue,
                  'requires_approval': 'true',
                  'event': 'VISITOR_ARRIVAL',
                  'host_user_id': currentUserId.toString(),
                };
                IncomingVisitorService.onIncomingCallReceived(payload);
                break; // present top pending arrival for this host
              }
            }
          }
        }
      } catch (e) {
        debugPrint('[IndustrialVisitBloc] In-app foreground alert check failed: $e');
      }
    } catch (e) {
      if (e is DioException && e.response?.statusCode == 429) {
        final retryAfterHeader = e.response?.headers.value('retry-after');
        final retrySeconds = int.tryParse(retryAfterHeader ?? '') ?? 60;
        _visitsRateLimitedUntil = DateTime.now().add(
          Duration(seconds: retrySeconds.clamp(15, 300)),
        );
        if (event.isSilent && state.visits.isNotEmpty) {
          return;
        }
      }
      emit(state.copyWith(
        status: IndustrialVisitBlocStatus.error,
        errorMessage: _parseError(e),
      ));
    } finally {
      _isFetchingVisits = false;
    }
  }

  Future<void> _onDecideVisit(
    DecideVisitEvent event,
    Emitter<IndustrialVisitState> emit,
  ) async {
    final normalizedAction = event.action.toUpperCase() == 'DENY' ? 'REJECT' : event.action.toUpperCase();

    // Immediate optimistic update so card status changes with 0ms lag
    final optimisticStatus = normalizedAction == 'APPROVE'
        ? IndustrialVisitStatus.approved
        : (normalizedAction == 'REJECT' ? IndustrialVisitStatus.rejected : null);

    if (optimisticStatus != null) {
      final optimisticVisits = state.visits.map((v) {
        if (v.id == event.visitId) {
          return v.copyWith(status: optimisticStatus);
        }
        return v;
      }).toList();
      emit(state.copyWith(
        status: IndustrialVisitBlocStatus.loading,
        visits: optimisticVisits,
      ));
    } else {
      emit(state.copyWith(status: IndustrialVisitBlocStatus.loading));
    }

    try {
      final res = await repository.handleVisitAction(
        event.visitId,
        action: normalizedAction,
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
      final refreshedVisits = await repository.getVisits().catchError((_) => state.visits);
      emit(state.copyWith(
        status: IndustrialVisitBlocStatus.error,
        errorMessage: _parseError(e),
        visits: refreshedVisits,
      ));
    }
  }

  Future<void> _onAcknowledgeVisit(
    AcknowledgeVisitEvent event,
    Emitter<IndustrialVisitState> emit,
  ) async {
    // Immediate optimistic update
    final optimisticVisits = state.visits.map((v) {
      if (v.id == event.visitId) {
        return v.copyWith(isAcknowledged: true);
      }
      return v;
    }).toList();
    emit(state.copyWith(visits: optimisticVisits));

    try {
      await repository.acknowledgeVisit(event.visitId);
      final updatedVisits = await repository.getVisits();
      emit(state.copyWith(
        status: IndustrialVisitBlocStatus.actionSuccess,
        successMessage: 'Visit acknowledged. Escalation grace period activated.',
        visits: updatedVisits,
      ));
    } catch (e) {
      final refreshedVisits = await repository.getVisits().catchError((_) => state.visits);
      emit(state.copyWith(
        status: IndustrialVisitBlocStatus.error,
        errorMessage: _parseError(e),
        visits: refreshedVisits,
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
        errorMessage: _parseError(e),
      ));
    }
  }

  Future<void> _onSendToLobby(
    SendToLobbyEvent event,
    Emitter<IndustrialVisitState> emit,
  ) async {
    emit(state.copyWith(status: IndustrialVisitBlocStatus.loading));
    try {
      final updated = await repository.sendToLobby(
        visitId: event.visitId,
        floor: event.floor,
      );
      final updatedVisits = await repository.getVisits();
      emit(state.copyWith(
        status: IndustrialVisitBlocStatus.actionSuccess,
        successMessage: 'Visitor directed to lobby queue.',
        lastActionVisit: updated,
        visits: updatedVisits,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: IndustrialVisitBlocStatus.error,
        errorMessage: _parseError(e),
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
        errorMessage: _parseError(e),
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
        errorMessage: _parseError(e),
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
        errorMessage: _parseError(e),
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
        errorMessage: _parseError(e),
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
        errorMessage: _parseError(e),
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
        errorMessage: _parseError(e),
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
        errorMessage: _parseError(e),
      ));
    }
  }

  String _parseError(dynamic e) {
    if (e is DioException) {
      return e.message ?? e.error?.toString() ?? 'Operation failed';
    }
    return e.toString().replaceAll('Exception: ', '');
  }
}
