import 'package:equatable/equatable.dart';

abstract class FamilyEvent extends Equatable {
  const FamilyEvent();
  @override
  List<Object?> get props => [];
}

class LoadFamily extends FamilyEvent {
  final bool showLoading;
  const LoadFamily({this.showLoading = true});
  @override
  List<Object?> get props => [showLoading];
}

class AddFamilyMember extends FamilyEvent {
  final String name;
  final String relationship;
  final String? contactNumber;
  final bool isEmergencyContact;

  const AddFamilyMember({
    required this.name,
    required this.relationship,
    this.contactNumber,
    required this.isEmergencyContact,
  });

  @override
  List<Object?> get props => [name, relationship, contactNumber, isEmergencyContact];
}

class UpdateFamilyMember extends FamilyEvent {
  final int id;
  final String name;
  final String relationship;
  final String? contactNumber;
  final bool isEmergencyContact;

  const UpdateFamilyMember({
    required this.id,
    required this.name,
    required this.relationship,
    this.contactNumber,
    required this.isEmergencyContact,
  });

  @override
  List<Object?> get props => [id, name, relationship, contactNumber, isEmergencyContact];
}

class DeleteFamilyMember extends FamilyEvent {
  final int id;
  const DeleteFamilyMember(this.id);
  @override
  List<Object?> get props => [id];
}
