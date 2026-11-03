import 'package:equatable/equatable.dart';
import '../data/models/vehicle_model.dart';

abstract class VehiclesState extends Equatable {
  const VehiclesState();
  @override
  List<Object?> get props => [];
}

class VehiclesInitial extends VehiclesState {}

class VehiclesLoading extends VehiclesState {}

class VehiclesLoaded extends VehiclesState {
  final List<VehicleModel> items;
  const VehiclesLoaded(this.items);
  @override
  List<Object?> get props => [items];
}

class VehiclesError extends VehiclesState {
  final String message;
  const VehiclesError(this.message);
  @override
  List<Object?> get props => [message];
}
