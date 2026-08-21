import 'package:equatable/equatable.dart';

abstract class DailyHelpEvent extends Equatable {
  const DailyHelpEvent();

  @override
  List<Object?> get props => [];
}

class FetchDailyHelp extends DailyHelpEvent {
  final int? societyId;

  const FetchDailyHelp({this.societyId});

  @override
  List<Object?> get props => [societyId];
}

class AddDailyHelp extends DailyHelpEvent {
  final int? societyId;
  final String name;
  final String phone;
  final String role;

  const AddDailyHelp({
    this.societyId,
    required this.name,
    required this.phone,
    required this.role,
  });

  @override
  List<Object?> get props => [societyId, name, phone, role];
}
