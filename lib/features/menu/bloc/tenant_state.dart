import 'package:equatable/equatable.dart';
import '../data/models/tenant_model.dart';

abstract class TenantState extends Equatable {
  const TenantState();
  @override
  List<Object?> get props => [];
}

class TenantInitial extends TenantState {}

class TenantLoading extends TenantState {}

class TenantLoaded extends TenantState {
  final List<TenantModel> items;
  const TenantLoaded(this.items);
  @override
  List<Object?> get props => [items];
}

class TenantError extends TenantState {
  final String message;
  const TenantError(this.message);
  @override
  List<Object?> get props => [message];
}
