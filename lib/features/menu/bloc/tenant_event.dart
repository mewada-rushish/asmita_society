import 'package:equatable/equatable.dart';

abstract class TenantEvent extends Equatable {
  const TenantEvent();
  @override
  List<Object?> get props => [];
}

class LoadTenant extends TenantEvent {
  final bool showLoading;
  const LoadTenant({this.showLoading = true});
  @override
  List<Object?> get props => [showLoading];
}
