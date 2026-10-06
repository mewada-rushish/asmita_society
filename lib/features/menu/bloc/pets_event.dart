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
