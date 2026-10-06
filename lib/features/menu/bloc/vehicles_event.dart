import 'package:equatable/equatable.dart';

abstract class VehiclesEvent extends Equatable {
  const VehiclesEvent();
  @override
  List<Object?> get props => [];
}

class LoadVehicles extends VehiclesEvent {
  final bool showLoading;
  const LoadVehicles({this.showLoading = true});
  @override
  List<Object?> get props => [showLoading];
}

class AddVehicle extends VehiclesEvent {
  final String type;
  final String makeModel;
  final String licensePlate;
  final int flatId;
  final String? parkingSlot;

  const AddVehicle({
    required this.type,
    required this.makeModel,
    required this.licensePlate,
    required this.flatId,
    this.parkingSlot,
  });

  @override
  List<Object?> get props => [type, makeModel, licensePlate, flatId, parkingSlot];
}

class UpdateVehicle extends VehiclesEvent {
  final int id;
  final String type;
  final String makeModel;
  final String licensePlate;
  final int? flatId;
  final String? parkingSlot;

  const UpdateVehicle({
    required this.id,
    required this.type,
    required this.makeModel,
    required this.licensePlate,
    this.flatId,
    this.parkingSlot,
  });

  @override
  List<Object?> get props => [id, type, makeModel, licensePlate, flatId, parkingSlot];
}

class DeleteVehicle extends VehiclesEvent {
  final int id;
  const DeleteVehicle(this.id);
  @override
  List<Object?> get props => [id];
}
