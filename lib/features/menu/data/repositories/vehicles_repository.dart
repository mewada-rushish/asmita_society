import 'package:dio/dio.dart';
import 'package:hive/hive.dart';
import '../models/vehicle_model.dart';
import 'package:asmita_society/core/config/env_config.dart';
import 'package:flutter/foundation.dart';

class VehiclesRepository {
  final Dio dio;

  VehiclesRepository({required this.dio});

  Future<List<VehicleModel>> getVehicles() async {
    try {
      final response = await dio.get(EnvConfig.userVehicles);
      if (response.statusCode == 200 && response.data != null) {
        final List<dynamic> rawList = response.data;
        final vehicles = rawList.map((e) => VehicleModel.fromJson(e)).toList();
        saveToCache(vehicles);
        return vehicles;
      }
      return getCachedVehicles();
    } catch (e) {
      debugPrint('Error fetching vehicles: $e');
      return getCachedVehicles();
    }
  }

  List<VehicleModel> getCachedVehicles() {
    final cached = Hive.box('app_cache').get('vehicles');
    if (cached != null) {
      try {
        final List<dynamic> rawList = cached;
        return rawList.map((e) => VehicleModel.fromJson(Map<String, dynamic>.from(e))).toList();
      } catch (e) {
        debugPrint('Error parsing cached vehicles: $e');
      }
    }
    return [];
  }

  void saveToCache(List<VehicleModel> vehicles) {
    Hive.box('app_cache').put('vehicles', vehicles.map((e) => e.toJson()).toList());
  }

  Future<VehicleModel?> addVehicle({
    required String type,
    required String makeModel,
    required String licensePlate,
    String? parkingSlot,
    required int flatId,
  }) async {
    try {
      final response = await dio.post(
        EnvConfig.userVehicles,
        data: {
          'type': type,
          'make_model': makeModel,
          'license_plate': licensePlate,
          'parking_slot': parkingSlot,
          'flat_id': flatId,
        },
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return VehicleModel.fromJson(response.data);
      }
      return null;
    } catch (e) {
      debugPrint('Error adding vehicle: $e');
      return null;
    }
  }

  Future<bool> updateVehicle(int id, {
    required String type,
    required String makeModel,
    required String licensePlate,
    String? parkingSlot,
    int? flatId,
  }) async {
    try {
      final response = await dio.put(
        '${EnvConfig.userVehicles}/$id',
        data: {
          'type': type,
          'make_model': makeModel,
          'license_plate': licensePlate,
          'parking_slot': parkingSlot,
          'flat_id': flatId,
        },
      );
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Error updating vehicle: $e');
      return false;
    }
  }

  Future<bool> deleteVehicle(int id) async {
    try {
      final response = await dio.delete('${EnvConfig.userVehicles}/$id');
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Error deleting vehicle: $e');
      return false;
    }
  }

  Future<List<String>> getParkingSlots() async {
    try {
      final response = await dio.get(EnvConfig.parkingSlots);
      if (response.statusCode == 200 && response.data != null && response.data['slots'] != null) {
        final List<dynamic> slotsData = response.data['slots'];
        return slotsData.map((e) => e['slot_code']?.toString() ?? '').where((s) => s.isNotEmpty).toList();
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching parking slots: ');
      return [];
    }
  }
}
