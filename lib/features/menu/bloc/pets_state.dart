import 'package:equatable/equatable.dart';
import '../data/models/pet_model.dart';

abstract class PetsState extends Equatable {
  const PetsState();
  @override
  List<Object?> get props => [];
}

class PetsInitial extends PetsState {}

class PetsLoading extends PetsState {}

class PetsLoaded extends PetsState {
  final List<PetModel> items;
  const PetsLoaded(this.items);
  @override
  List<Object?> get props => [items];
}

class PetsError extends PetsState {
  final String message;
  const PetsError(this.message);
  @override
  List<Object?> get props => [message];
}
