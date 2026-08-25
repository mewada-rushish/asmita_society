import 'package:dio/dio.dart';
import '../models/pet_model.dart';
import 'package:asmita_society/core/config/env_config.dart';
import 'package:flutter/foundation.dart';

class PetsRepository {
  final Dio dio;

  PetsRepository({required this.dio});

  Future<List<PetModel>> getPets() async {
    try {
      final response = await dio.get(EnvConfig.userPets);
      if (response.statusCode == 200 && response.data != null) {
        final List<dynamic> rawList = response.data;
        return rawList.map((e) => PetModel.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching pets: $e');
      return [];
    }
  }

  Future<PetModel?> addPet({
    required String name,
    required String breed,
    bool isVaccinated = false,
  }) async {
    try {
      final response = await dio.post(
        EnvConfig.userPets,
        data: {
          'name': name,
          'breed': breed,
          'is_vaccinated': isVaccinated,
        },
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return PetModel.fromJson(response.data);
      }
      return null;
    } catch (e) {
      debugPrint('Error adding pet: $e');
      return null;
    }
  }

  Future<bool> updatePet(int id, {
    required String name,
    required String breed,
    required bool isVaccinated,
  }) async {
    try {
      final response = await dio.put(
        '${EnvConfig.userPets}/$id',
        data: {
          'name': name,
          'breed': breed,
          'is_vaccinated': isVaccinated,
        },
      );
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Error updating pet: $e');
      return false;
    }
  }

  Future<bool> deletePet(int id) async {
    try {
      final response = await dio.delete('${EnvConfig.userPets}/$id');
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Error deleting pet: $e');
      return false;
    }
  }
}
