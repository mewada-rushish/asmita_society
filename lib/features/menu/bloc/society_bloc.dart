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
