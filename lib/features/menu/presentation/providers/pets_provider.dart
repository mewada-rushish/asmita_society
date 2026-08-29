import 'dart:async';
import 'dart:io';
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
    final cached = _repository.getCachedPets();
    if (cached.isNotEmpty) {
      Future.microtask(() => fetchPets(showLoading: false));
      return cached;
    }
    return _repository.getPets();
  }

  Future<void> fetchPets({bool showLoading = true}) async {
    if (showLoading) {
      state = const AsyncValue.loading();
    }
    try {
      final pets = await _repository.getPets();
      state = AsyncValue.data(pets);
    } catch (e, stackTrace) {
      if (showLoading) {
        state = AsyncValue.error(e, stackTrace);
      }
    }
  }

  Future<bool> addPet({
    required String name,
    required String breed,
    bool isVaccinated = false,
    required File imageFile,
  }) async {
    final newPet = await _repository.addPet(
      name: name,
      breed: breed,
      isVaccinated: isVaccinated,
      imageFile: imageFile,
    );
    if (newPet != null) {
      if (state.value != null) {
        final updatedList = [...state.value!, newPet];
        state = AsyncValue.data(updatedList);
        _repository.saveToCache(updatedList);
      } else {
        state = AsyncValue.data([newPet]);
        _repository.saveToCache([newPet]);
      }
      return true;
    }
    return false;
  }

  Future<bool> updatePet(int id, {
    required String name,
    required String breed,
    required bool isVaccinated,
    File? imageFile,
  }) async {
    final success = await _repository.updatePet(
      id,
      name: name,
      breed: breed,
      isVaccinated: isVaccinated,
      imageFile: imageFile,
    );
    if (success) {
      // Refetch to get the updated avatarUrl from server or we could manually update it if we had the url.
      // Easiest is to re-fetch the list, which will automatically update cache.
      fetchPets(showLoading: false);
    }
    return success;
  }

  Future<bool> deletePet(int id) async {
    final success = await _repository.deletePet(id);
    if (success && state.value != null) {
      final updatedList = state.value!.where((p) => p.id != id).toList();
      state = AsyncValue.data(updatedList);
      _repository.saveToCache(updatedList);
    }
    return success;
  }
}
