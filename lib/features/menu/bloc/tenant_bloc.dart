import 'package:flutter_bloc/flutter_bloc.dart';
import '../data/repositories/tenant_repository.dart';
import 'tenant_event.dart';
import 'tenant_state.dart';

class TenantBloc extends Bloc<TenantEvent, TenantState> {
  final TenantRepository repository;

  TenantBloc({required this.repository}) : super(TenantInitial()) {
    on<LoadTenant>(_onLoadTenant);
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
}
