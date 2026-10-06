import 'package:equatable/equatable.dart';

abstract class FamilyEvent extends Equatable {
  const FamilyEvent();
  @override
  List<Object?> get props => [];
}

class LoadFamily extends FamilyEvent {
  final bool showLoading;
  const LoadFamily({this.showLoading = true});
  @override
  List<Object?> get props => [showLoading];
}
