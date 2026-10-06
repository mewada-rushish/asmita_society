import 'dart:io';

void main() async {
  final familyBloc = File('lib/features/menu/bloc/family_bloc.dart');
  var familyCode = await familyBloc.readAsString();
  familyCode = familyCode.replaceAll('getFamily()', 'getFamilyMembers()');
  await familyBloc.writeAsString(familyCode);

  final tenantBloc = File('lib/features/menu/bloc/tenant_bloc.dart');
  var tenantCode = await tenantBloc.readAsString();
  tenantCode = tenantCode.replaceAll('getTenant()', 'getTenants()');
  await tenantBloc.writeAsString(tenantCode);

  final historyBloc = File('lib/features/menu/bloc/historyrequest_bloc.dart');
  var historyCode = await historyBloc.readAsString();
  historyCode = historyCode.replaceAll('getHistoryRequests()', 'getIncomingRequests()');
  await historyBloc.writeAsString(historyCode);

  final supportState = File('lib/features/menu/bloc/support_state.dart');
  var supportStateCode = await supportState.readAsString();
  supportStateCode = supportStateCode.replaceAll('ticket_model.dart', 'support_ticket_model.dart');
  supportStateCode = supportStateCode.replaceAll('TicketModel', 'SupportTicketModel');
  await supportState.writeAsString(supportStateCode);

  final supportBloc = File('lib/features/menu/bloc/support_bloc.dart');
  var supportBlocCode = await supportBloc.readAsString();
  supportBlocCode = supportBlocCode.replaceAll('SupportTicketModel', 'SupportTicketModel');
  await supportBloc.writeAsString(supportBlocCode);

  // Society Bloc Rewrite
  final societyEvent = File('lib/features/menu/bloc/society_event.dart');
  await societyEvent.writeAsString('''
import 'package:equatable/equatable.dart';

abstract class SocietyEvent extends Equatable {
  const SocietyEvent();
  @override
  List<Object?> get props => [];
}

class LoadSocietyData extends SocietyEvent {
  final bool showLoading;
  const LoadSocietyData({this.showLoading = true});
  @override
  List<Object?> get props => [showLoading];
}
''');

  final societyState = File('lib/features/menu/bloc/society_state.dart');
  await societyState.writeAsString('''
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
''');

  final societyBlocFile = File('lib/features/menu/bloc/society_bloc.dart');
  await societyBlocFile.writeAsString('''
import 'package:flutter_bloc/flutter_bloc.dart';
import '../data/repositories/society_repository.dart';
import 'society_event.dart';
import 'society_state.dart';

class SocietyBloc extends Bloc<SocietyEvent, SocietyState> {
  final SocietyRepository repository;

  SocietyBloc({required this.repository}) : super(SocietyInitial()) {
    on<LoadSocietyData>(_onLoadSocietyData);
  }

  Future<void> _onLoadSocietyData(LoadSocietyData event, Emitter<SocietyState> emit) async {
    if (event.showLoading) emit(SocietyLoading());
    try {
      final committeeMembers = await repository.getCommitteeMembers();
      final rules = await repository.getRules();
      final documents = await repository.getDocuments();
      emit(SocietyLoaded(
        committeeMembers: committeeMembers,
        rules: rules,
        documents: documents,
      ));
    } catch (e) {
      emit(SocietyError(e.toString()));
    }
  }
}
''');

}
