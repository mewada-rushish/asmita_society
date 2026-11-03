import 'package:equatable/equatable.dart';
import '../data/models/family_member_model.dart';

abstract class FamilyState extends Equatable {
  const FamilyState();
  @override
  List<Object?> get props => [];
}

class FamilyInitial extends FamilyState {}

class FamilyLoading extends FamilyState {}

class FamilyLoaded extends FamilyState {
  final List<FamilyMemberModel> items;
  const FamilyLoaded(this.items);
  @override
  List<Object?> get props => [items];
}

class FamilyError extends FamilyState {
  final String message;
  const FamilyError(this.message);
  @override
  List<Object?> get props => [message];
}
