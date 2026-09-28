import 'package:equatable/equatable.dart';
abstract class VisitorEvent extends Equatable {
  const VisitorEvent();

  @override
  List<Object?> get props => [];
}

<<<<<<< HEAD
class LoadMyHistory extends VisitorEvent {
  final int residentId;
  final bool isRefresh;
  const LoadMyHistory({required this.residentId, this.isRefresh = false});

  @override
  List<Object?> get props => [residentId, isRefresh];
=======
class ClearVisitorHistory extends VisitorEvent {}

class LoadMyHistory extends VisitorEvent {
  final int residentId;
  final bool isRefresh;
  final String? status;
  final DateTime? startDate;
  final DateTime? endDate;
  final int? visitorTypeId;

  const LoadMyHistory({
    required this.residentId, 
    this.isRefresh = false,
    this.status,
    this.startDate,
    this.endDate,
    this.visitorTypeId,
  });

  @override
  List<Object?> get props => [residentId, isRefresh, status, startDate, endDate, visitorTypeId];
>>>>>>> 8e14b7ab5ec9ba6ee223925910b776c044e433df
}

class CreatePreApprovedInviteEvent extends VisitorEvent {
  final Map<String, dynamic> payload;

  const CreatePreApprovedInviteEvent({required this.payload});

  @override
  List<Object?> get props => [payload];
}
