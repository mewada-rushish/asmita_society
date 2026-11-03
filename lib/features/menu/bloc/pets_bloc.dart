import 'package:flutter_bloc/flutter_bloc.dart';
import '../data/repositories/pets_repository.dart';
import 'pets_event.dart';
import 'pets_state.dart';

class PetsBloc extends Bloc<PetsEvent, PetsState> {
  final PetsRepository repository;

  PetsBloc({required this.repository}) : super(PetsInitial()) {
    on<LoadPets>(_onLoadPets);
    on<AddPet>(_onAddPet);
    on<UpdatePet>(_onUpdatePet);
    on<DeletePet>(_onDeletePet);
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

  Future<void> _onAddPet(AddPet event, Emitter<PetsState> emit) async {
    try {
      final success = await repository.addPet(
        name: event.name,
        breed: event.breed,
        isVaccinated: event.isVaccinated,
        imageFile: event.imageFile,
      );
      if (success != null) add(const LoadPets(showLoading: false));
    } catch (_) {}
  }

  Future<void> _onUpdatePet(UpdatePet event, Emitter<PetsState> emit) async {
    try {
      final success = await repository.updatePet(
        event.id,
        name: event.name,
        breed: event.breed,
        isVaccinated: event.isVaccinated,
        imageFile: event.imageFile,
      );
      if (success) add(const LoadPets(showLoading: false));
    } catch (_) {}
  }

  Future<void> _onDeletePet(DeletePet event, Emitter<PetsState> emit) async {
    try {
      final success = await repository.deletePet(event.id);
      if (success) add(const LoadPets(showLoading: false));
    } catch (_) {}
  }
}
