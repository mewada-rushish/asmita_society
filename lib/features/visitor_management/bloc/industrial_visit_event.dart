import 'package:equatable/equatable.dart';

abstract class IndustrialVisitEvent extends Equatable {
  const IndustrialVisitEvent();

  @override
  List<Object?> get props => [];
}

class LoadIndustrialVisits extends IndustrialVisitEvent {
  final String? status;
  final String? arrivalMode;
  final int? departmentId;
  final int? hostUserId;

  const LoadIndustrialVisits({
    this.status,
    this.arrivalMode,
    this.departmentId,
    this.hostUserId,
  });

  @override
  List<Object?> get props => [status, arrivalMode, departmentId, hostUserId];
}

class DecideVisitEvent extends IndustrialVisitEvent {
  final int visitId;
  final String action; // APPROVE, REJECT, ASSIGN, REASSIGN, COLLECT_AT_GATE, ALLOW_IN
  final int? assignedUserId;
  final int? cabinId;
  final int? deskId;
  final String? rejectionReason;

  const DecideVisitEvent({
    required this.visitId,
    required this.action,
    this.assignedUserId,
    this.cabinId,
    this.deskId,
    this.rejectionReason,
  });

  @override
  List<Object?> get props => [visitId, action, assignedUserId, cabinId, deskId, rejectionReason];
}

class AcknowledgeVisitEvent extends IndustrialVisitEvent {
  final int visitId;

  const AcknowledgeVisitEvent(this.visitId);

  @override
  List<Object?> get props => [visitId];
}

class CheckInPassEvent extends IndustrialVisitEvent {
  final int visitId;
  final int gateId;
  final String? passCode;

  const CheckInPassEvent({
    required this.visitId,
    required this.gateId,
    this.passCode,
  });

  @override
  List<Object?> get props => [visitId, gateId, passCode];
}

class CheckOutPassEvent extends IndustrialVisitEvent {
  final int visitId;
  final int gateId;

  const CheckOutPassEvent({
    required this.visitId,
    required this.gateId,
  });

  @override
  List<Object?> get props => [visitId, gateId];
}

class OverrideVisitEvent extends IndustrialVisitEvent {
  final int visitId;
  final String overrideReason;
  final String? photoBase64;

  const OverrideVisitEvent({
    required this.visitId,
    required this.overrideReason,
    this.photoBase64,
  });

  @override
  List<Object?> get props => [visitId, overrideReason, photoBase64];
}

class CreateVehicleDraftEvent extends IndustrialVisitEvent {
  final String vehicleNumber;
  final String visitorName;
  final int gateId;

  const CreateVehicleDraftEvent({
    required this.vehicleNumber,
    required this.visitorName,
    required this.gateId,
  });

  @override
  List<Object?> get props => [vehicleNumber, visitorName, gateId];
}

class CreateDeliveryIntakeEvent extends IndustrialVisitEvent {
  final String deliveryCompany;
  final String recipientName;
  final int? recipientUserId;
  final String? photoBase64;
  final int gateId;

  const CreateDeliveryIntakeEvent({
    required this.deliveryCompany,
    required this.recipientName,
    this.recipientUserId,
    this.photoBase64,
    this.gateId = 1,
  });

  @override
  List<Object?> get props => [deliveryCompany, recipientName, recipientUserId, photoBase64, gateId];
}

class ConfirmDeliveryHandoverEvent extends IndustrialVisitEvent {
  final int visitId;

  const ConfirmDeliveryHandoverEvent(this.visitId);

  @override
  List<Object?> get props => [visitId];
}

class ClockInDutyEvent extends IndustrialVisitEvent {
  final int gateId;

  const ClockInDutyEvent(this.gateId);

  @override
  List<Object?> get props => [gateId];
}

class ClockOutDutyEvent extends IndustrialVisitEvent {
  const ClockOutDutyEvent();
}
