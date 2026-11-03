import 'dart:io';
import 'package:equatable/equatable.dart';

abstract class PetsEvent extends Equatable {
  const PetsEvent();
  @override
  List<Object?> get props => [];
}

class LoadPets extends PetsEvent {
  final bool showLoading;
  const LoadPets({this.showLoading = true});
  @override
  List<Object?> get props => [showLoading];
}

class AddPet extends PetsEvent {
  final String name;
  final String breed;
  final bool isVaccinated;
  final File imageFile;

  const AddPet({
    required this.name,
    required this.breed,
    required this.isVaccinated,
    required this.imageFile,
  });

  @override
  List<Object?> get props => [name, breed, isVaccinated, imageFile];
}

class UpdatePet extends PetsEvent {
  final int id;
  final String name;
  final String breed;
  final bool isVaccinated;
  final File? imageFile;

  const UpdatePet({
    required this.id,
    required this.name,
    required this.breed,
    required this.isVaccinated,
    this.imageFile,
  });

  @override
  List<Object?> get props => [id, name, breed, isVaccinated, imageFile];
}

class DeletePet extends PetsEvent {
  final int id;
  const DeletePet(this.id);
  @override
  List<Object?> get props => [id];
}
