import 'package:equatable/equatable.dart';
import '../data/models/committee_member_model.dart';
import '../data/models/society_rule_model.dart';
import '../data/models/society_document_model.dart';

abstract class SocietyState extends Equatable {
  const SocietyState();
  @override
  List<Object?> get props => [];
}

class SocietyInitial extends SocietyState {}

class SocietyLoading extends SocietyState {}

class SocietyLoaded extends SocietyState {
  final List<CommitteeMemberModel> committeeMembers;
  final List<SocietyRuleModel> rules;
  final List<SocietyDocumentModel> documents;
  
  const SocietyLoaded({
    required this.committeeMembers,
    required this.rules,
    required this.documents,
  });
  
  @override
  List<Object?> get props => [committeeMembers, rules, documents];
}

class SocietyError extends SocietyState {
  final String message;
  const SocietyError(this.message);
  @override
  List<Object?> get props => [message];
}
