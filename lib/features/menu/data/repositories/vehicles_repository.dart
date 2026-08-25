import 'package:dio/dio.dart';
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
        return rawList.map((e) => VehicleModel.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching vehicles: $e');
      return [];
    }
  }

  Future<VehicleModel?> addVehicle({
    required String type,
    required String makeModel,
    required String licensePlate,
    String? parkingSlot,
  }) async {
    try {
      final response = await dio.post(
        EnvConfig.userVehicles,
        data: {
          'type': type,
          'make_model': makeModel,
          'license_plate': licensePlate,
          'parking_slot': parkingSlot,
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
  }) async {
    try {
      final response = await dio.put(
        '${EnvConfig.userVehicles}/$id',
        data: {
          'type': type,
          'make_model': makeModel,
          'license_plate': licensePlate,
          'parking_slot': parkingSlot,
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
}
