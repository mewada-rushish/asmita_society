import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/pets_repository.dart';
import '../../data/models/pet_model.dart';
import 'package:asmita_society/core/network/dio_client.dart';
import 'package:asmita_society/core/security/secure_storage_service.dart';

final petsRepositoryProvider = Provider<PetsRepository>((ref) {
  return PetsRepository(
    dio: AsmitaDioClient(SecureStorageService()).dio,
  );
});

final petsProvider = AsyncNotifierProvider<PetsNotifier, List<PetModel>>(() {
  return PetsNotifier();
});

class PetsNotifier extends AsyncNotifier<List<PetModel>> {
  PetsRepository get _repository => ref.read(petsRepositoryProvider);

  @override
  FutureOr<List<PetModel>> build() async {
    return _repository.getPets();
  }

  Future<void> fetchPets() async {
    state = const AsyncValue.loading();
    try {
      final pets = await _repository.getPets();
      state = AsyncValue.data(pets);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  Future<bool> addPet({
    required String name,
    required String breed,
    bool isVaccinated = false,
  }) async {
    final newPet = await _repository.addPet(
      name: name,
      breed: breed,
      isVaccinated: isVaccinated,
    );
    if (newPet != null) {
      if (state.value != null) {
        state = AsyncValue.data([...state.value!, newPet]);
      } else {
        state = AsyncValue.data([newPet]);
      }
      return true;
    }
    return false;
  }

  Future<bool> updatePet(int id, {
    required String name,
    required String breed,
    required bool isVaccinated,
  }) async {
    final success = await _repository.updatePet(
      id,
      name: name,
      breed: breed,
      isVaccinated: isVaccinated,
    );
    if (success && state.value != null) {
      final updatedList = state.value!.map((p) {
        if (p.id == id) {
          return PetModel(
            id: p.id,
            name: name,
            breed: breed,
            isVaccinated: isVaccinated,
          );
        }
        return p;
      }).toList();
      state = AsyncValue.data(updatedList);
    }
    return success;
  }

  Future<bool> deletePet(int id) async {
    final success = await _repository.deletePet(id);
    if (success && state.value != null) {
      final updatedList = state.value!.where((p) => p.id != id).toList();
      state = AsyncValue.data(updatedList);
    }
    return success;
  }
}
