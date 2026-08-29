import 'dart:io';
import 'package:dio/dio.dart';
import 'package:hive/hive.dart';
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
        final pets = rawList.map((e) => PetModel.fromJson(e)).toList();
        saveToCache(pets);
        return pets;
      }
      return getCachedPets();
    } catch (e) {
      debugPrint('Error fetching pets: $e');
      return getCachedPets();
    }
  }

  List<PetModel> getCachedPets() {
    final cached = Hive.box('app_cache').get('pets');
    if (cached != null) {
      try {
        final List<dynamic> rawList = cached;
        return rawList.map((e) => PetModel.fromJson(Map<String, dynamic>.from(e))).toList();
      } catch (e) {
        debugPrint('Error parsing cached pets: $e');
      }
    }
    return [];
  }

  void saveToCache(List<PetModel> pets) {
    Hive.box('app_cache').put('pets', pets.map((e) => e.toJson()).toList());
  }

  Future<PetModel?> addPet({
    required String name,
    required String breed,
    bool isVaccinated = false,
    required File imageFile,
  }) async {
    try {
      final formData = FormData.fromMap({
        'name': name,
        'breed': breed,
        'is_vaccinated': isVaccinated,
        'photo': await MultipartFile.fromFile(imageFile.path, filename: imageFile.path.split('/').last),
      });

      final response = await dio.post(
        EnvConfig.userPets,
        data: formData,
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return PetModel.fromJson(response.data);
      }
      return null;
    } catch (e) {
      debugPrint('Error adding pet: ');
      return null;
    }
  }

  Future<bool> updatePet(int id, {
    required String name,
    required String breed,
    required bool isVaccinated,
    File? imageFile,
  }) async {
    try {
      final Map<String, dynamic> dataMap = {
        'name': name,
        'breed': breed,
        'is_vaccinated': isVaccinated,
      };
      if (imageFile != null) {
        dataMap['photo'] = await MultipartFile.fromFile(imageFile.path, filename: imageFile.path.split('/').last);
      }
      final formData = FormData.fromMap(dataMap);

      final response = await dio.put(
        '${EnvConfig.userPets}/$id',
        data: formData,
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
