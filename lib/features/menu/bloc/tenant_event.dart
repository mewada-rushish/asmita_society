import 'package:equatable/equatable.dart';

abstract class TenantEvent extends Equatable {
  const TenantEvent();
  @override
  List<Object?> get props => [];
}

class LoadTenant extends TenantEvent {
  final bool showLoading;
  const LoadTenant({this.showLoading = true});
  @override
  List<Object?> get props => [showLoading];
}
class AddTenant extends TenantEvent {
  final String name;
  final String relationship;
  final String? contactNumber;
  final bool isEmergencyContact;

  const AddTenant({
    required this.name,
    required this.relationship,
    this.contactNumber,
    required this.isEmergencyContact,
  });

  @override
  List<Object?> get props => [name, relationship, contactNumber, isEmergencyContact];
}

class UpdateTenant extends TenantEvent {
  final int id;
  final String name;
  final String relationship;
  final String? contactNumber;
  final bool isEmergencyContact;

  const UpdateTenant({
    required this.id,
    required this.name,
    required this.relationship,
    this.contactNumber,
    required this.isEmergencyContact,
  });

  @override
  List<Object?> get props => [id, name, relationship, contactNumber, isEmergencyContact];
}

class DeleteTenant extends TenantEvent {
  final int id;
  const DeleteTenant(this.id);
  @override
  List<Object?> get props => [id];
}

class RequestTenantHistoryAccess extends TenantEvent {
  final int id;
  const RequestTenantHistoryAccess(this.id);
  @override
  List<Object?> get props => [id];
}
