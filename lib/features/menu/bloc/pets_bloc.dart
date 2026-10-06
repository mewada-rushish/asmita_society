import 'package:flutter_bloc/flutter_bloc.dart';
import '../data/repositories/pets_repository.dart';
import 'pets_event.dart';
import 'pets_state.dart';

class PetsBloc extends Bloc<PetsEvent, PetsState> {
  final PetsRepository repository;

  PetsBloc({required this.repository}) : super(PetsInitial()) {
    on<LoadPets>(_onLoadPets);
  }

  Future<void> _onLoadPets(LoadPets event, Emitter<PetsState> emit) async {
    if (event.showLoading) emit(PetsLoading());
    try {
      final items = await repository.getPets();
      emit(PetsLoaded(items));
    } catch (e) {
      emit(PetsError(e.toString()));
    }
  }
}
