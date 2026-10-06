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
