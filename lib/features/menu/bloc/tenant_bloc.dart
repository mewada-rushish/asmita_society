import 'package:flutter_bloc/flutter_bloc.dart';
import '../data/repositories/tenant_repository.dart';
import 'tenant_event.dart';
import 'tenant_state.dart';

class TenantBloc extends Bloc<TenantEvent, TenantState> {
  final TenantRepository repository;

  TenantBloc({required this.repository}) : super(TenantInitial()) {
        on<LoadTenant>(_onLoadTenant);
    on<AddTenant>(_onAddTenant);
    on<UpdateTenant>(_onUpdateTenant);
    on<DeleteTenant>(_onDeleteTenant);
    on<RequestTenantHistoryAccess>(_onRequestHistory);

  }

  Future<void> _onLoadTenant(LoadTenant event, Emitter<TenantState> emit) async {
    if (event.showLoading) emit(TenantLoading());
    try {
      final items = await repository.getTenants();
      emit(TenantLoaded(items));
    } catch (e) {
      emit(TenantError(e.toString()));
    }
  }
  Future<void> _onAddTenant(AddTenant event, Emitter<TenantState> emit) async {
    try {
      final success = await repository.addTenant(
        name: event.name,
        relationship: event.relationship,
        contactNumber: event.contactNumber,
        isEmergencyContact: event.isEmergencyContact,
      );
      if (success != null) add(const LoadTenant(showLoading: false));
    } catch (_) {}
  }

  Future<void> _onUpdateTenant(UpdateTenant event, Emitter<TenantState> emit) async {
    try {
      final success = await repository.updateTenant(
        event.id,
        name: event.name,
        relationship: event.relationship,
        contactNumber: event.contactNumber,
        isEmergencyContact: event.isEmergencyContact,
      );
      if (success) add(const LoadTenant(showLoading: false));
    } catch (_) {}
  }

  Future<void> _onDeleteTenant(DeleteTenant event, Emitter<TenantState> emit) async {
    try {
      final success = await repository.deleteTenant(event.id);
      if (success) add(const LoadTenant(showLoading: false));
    } catch (_) {}
  }

  Future<void> _onRequestHistory(RequestTenantHistoryAccess event, Emitter<TenantState> emit) async {
    try {
      final success = await repository.requestHistoryAccess(event.id);
      if (success) add(const LoadTenant(showLoading: false));
    } catch (_) {}
  }
}
