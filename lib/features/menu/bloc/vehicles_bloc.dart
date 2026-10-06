import 'package:flutter_bloc/flutter_bloc.dart';
import '../data/repositories/vehicles_repository.dart';
import 'vehicles_event.dart';
import 'vehicles_state.dart';

class VehiclesBloc extends Bloc<VehiclesEvent, VehiclesState> {
  final VehiclesRepository repository;

  VehiclesBloc({required this.repository}) : super(VehiclesInitial()) {
    on<LoadVehicles>(_onLoadVehicles);
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
}
