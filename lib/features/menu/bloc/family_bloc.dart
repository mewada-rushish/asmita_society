import 'package:flutter_bloc/flutter_bloc.dart';
import '../data/repositories/family_repository.dart';
import 'family_event.dart';
import 'family_state.dart';

class FamilyBloc extends Bloc<FamilyEvent, FamilyState> {
  final FamilyRepository repository;

  FamilyBloc({required this.repository}) : super(FamilyInitial()) {
    on<LoadFamily>(_onLoadFamily);
  }

  Future<void> _onLoadFamily(LoadFamily event, Emitter<FamilyState> emit) async {
    if (event.showLoading) emit(FamilyLoading());
    try {
      final items = await repository.getFamilyMembers();
      emit(FamilyLoaded(items));
    } catch (e) {
      emit(FamilyError(e.toString()));
    }
  }
}
