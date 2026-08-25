import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/vehicles_repository.dart';
import '../../data/models/vehicle_model.dart';
import 'package:asmita_society/core/network/dio_client.dart';
import 'package:asmita_society/core/security/secure_storage_service.dart';

final vehiclesRepositoryProvider = Provider<VehiclesRepository>((ref) {
  return VehiclesRepository(
    dio: AsmitaDioClient(SecureStorageService()).dio,
  );
});

final vehiclesProvider = AsyncNotifierProvider<VehiclesNotifier, List<VehicleModel>>(() {
  return VehiclesNotifier();
});

class VehiclesNotifier extends AsyncNotifier<List<VehicleModel>> {
  VehiclesRepository get _repository => ref.read(vehiclesRepositoryProvider);

  @override
  FutureOr<List<VehicleModel>> build() async {
    return _repository.getVehicles();
  }

  Future<void> fetchVehicles() async {
    state = const AsyncValue.loading();
    try {
      final vehicles = await _repository.getVehicles();
      state = AsyncValue.data(vehicles);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  Future<bool> addVehicle({
    required String type,
    required String makeModel,
    required String licensePlate,
    String? parkingSlot,
  }) async {
    final newVehicle = await _repository.addVehicle(
      type: type,
      makeModel: makeModel,
      licensePlate: licensePlate,
      parkingSlot: parkingSlot,
    );
    if (newVehicle != null) {
      if (state.value != null) {
        state = AsyncValue.data([...state.value!, newVehicle]);
      } else {
        state = AsyncValue.data([newVehicle]);
      }
      return true;
    }
    return false;
  }

  Future<bool> updateVehicle(int id, {
    required String type,
    required String makeModel,
    required String licensePlate,
    String? parkingSlot,
  }) async {
    final success = await _repository.updateVehicle(
      id,
      type: type,
      makeModel: makeModel,
      licensePlate: licensePlate,
      parkingSlot: parkingSlot,
    );
    if (success && state.value != null) {
      final updatedList = state.value!.map((v) {
        if (v.id == id) {
          return VehicleModel(
            id: v.id,
            type: type,
            makeModel: makeModel,
            licensePlate: licensePlate,
            parkingSlot: parkingSlot,
          );
        }
        return v;
      }).toList();
      state = AsyncValue.data(updatedList);
    }
    return success;
  }

  Future<bool> deleteVehicle(int id) async {
    final success = await _repository.deleteVehicle(id);
    if (success && state.value != null) {
      final updatedList = state.value!.where((v) => v.id != id).toList();
      state = AsyncValue.data(updatedList);
    }
    return success;
  }
}
