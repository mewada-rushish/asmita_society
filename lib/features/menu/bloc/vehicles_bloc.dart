import 'package:flutter_bloc/flutter_bloc.dart';
import '../data/repositories/vehicles_repository.dart';
import 'vehicles_event.dart';
import 'vehicles_state.dart';

class VehiclesBloc extends Bloc<VehiclesEvent, VehiclesState> {
  final VehiclesRepository repository;

  VehiclesBloc({required this.repository}) : super(VehiclesInitial()) {
    on<LoadVehicles>(_onLoadVehicles);
    on<AddVehicle>(_onAddVehicle);
    on<UpdateVehicle>(_onUpdateVehicle);
    on<DeleteVehicle>(_onDeleteVehicle);
  }

  Future<void> _onLoadVehicles(LoadVehicles event, Emitter<VehiclesState> emit) async {
    if (event.showLoading) emit(VehiclesLoading());
    try {
      final items = await repository.getVehicles();
      emit(VehiclesLoaded(items));
    } catch (e) {
      emit(VehiclesError(e.toString()));
    }
  }

  Future<void> _onAddVehicle(AddVehicle event, Emitter<VehiclesState> emit) async {
    try {
      final success = await repository.addVehicle(
        type: event.type,
        makeModel: event.makeModel,
        licensePlate: event.licensePlate,
        flatId: event.flatId,
        parkingSlot: event.parkingSlot,
      );
      if (success != null) add(const LoadVehicles(showLoading: false));
    } catch (_) {}
  }

  Future<void> _onUpdateVehicle(UpdateVehicle event, Emitter<VehiclesState> emit) async {
    try {
      final success = await repository.updateVehicle(
        event.id,
        type: event.type,
        makeModel: event.makeModel,
        licensePlate: event.licensePlate,
        flatId: event.flatId,
        parkingSlot: event.parkingSlot,
      );
      if (success) add(const LoadVehicles(showLoading: false));
    } catch (_) {}
  }

  Future<void> _onDeleteVehicle(DeleteVehicle event, Emitter<VehiclesState> emit) async {
    try {
      final success = await repository.deleteVehicle(event.id);
      if (success) add(const LoadVehicles(showLoading: false));
    } catch (_) {}
  }
}
