import 'package:equatable/equatable.dart';
abstract class VisitorEvent extends Equatable {
  const VisitorEvent();

  @override
  List<Object?> get props => [];
}

class LoadMyHistory extends VisitorEvent {
  final int residentId;
  final bool isRefresh;
  const LoadMyHistory({required this.residentId, this.isRefresh = false});

  @override
  List<Object?> get props => [residentId, isRefresh];
}

class CreatePreApprovedInviteEvent extends VisitorEvent {
  final Map<String, dynamic> payload;

  const CreatePreApprovedInviteEvent({required this.payload});

  @override
  List<Object?> get props => [payload];
}
