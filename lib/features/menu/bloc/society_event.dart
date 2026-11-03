import 'package:equatable/equatable.dart';

abstract class SocietyEvent extends Equatable {
  const SocietyEvent();
  @override
  List<Object?> get props => [];
}

class LoadSocietyData extends SocietyEvent {
  final bool showLoading;
  const LoadSocietyData({this.showLoading = true});
  @override
  List<Object?> get props => [showLoading];
}
