import 'package:equatable/equatable.dart';

abstract class GuardGateEvent extends Equatable {
  const GuardGateEvent();

  @override
  List<Object?> get props => [];
}

class LoadExpectedInvites extends GuardGateEvent {}

class LoadGuardHistory extends GuardGateEvent {}

class LoadCheckedInVisitors extends GuardGateEvent {}

class CheckOutVisitor extends GuardGateEvent {
  final String id;
  final bool isPreApproved;
  final String? inviteGuestId;

  const CheckOutVisitor({required this.id, required this.isPreApproved, this.inviteGuestId});

  @override
  List<Object?> get props => [id, isPreApproved, inviteGuestId];
}

class SearchInviteByCode extends GuardGateEvent {
  final String code;

  const SearchInviteByCode(this.code);

  @override
  List<Object?> get props => [code];
}

class CheckInPreApprovedVisitor extends GuardGateEvent {
  final String inviteId;

  const CheckInPreApprovedVisitor(this.inviteId);

  @override
  List<Object?> get props => [inviteId];
}

class SubmitWalkInVisitor extends GuardGateEvent {
  final List<Map<String, dynamic>> payloads;

  const SubmitWalkInVisitor(this.payloads);

  @override
  List<Object?> get props => [payloads];
}
