import 'package:flutter_bloc/flutter_bloc.dart';
import '../data/repositories/family_repository.dart';
import 'family_event.dart';
import 'family_state.dart';

class FamilyBloc extends Bloc<FamilyEvent, FamilyState> {
  final FamilyRepository repository;

  FamilyBloc({required this.repository}) : super(FamilyInitial()) {
    on<LoadFamily>(_onLoadFamily);
    on<AddFamilyMember>(_onAddFamilyMember);
    on<UpdateFamilyMember>(_onUpdateFamilyMember);
    on<DeleteFamilyMember>(_onDeleteFamilyMember);
  }

  Future<void> _onLoadFamily(LoadFamily event, Emitter<FamilyState> emit) async {
    if (event.showLoading) emit(FamilyLoading());
    try {
      final items = await repository.getFamilyMembers();
      emit(FamilyLoaded(items));
    } catch (e) {
      emit(FamilyError(e.toString()));
    }
  }

  Future<void> _onAddFamilyMember(AddFamilyMember event, Emitter<FamilyState> emit) async {
    try {
      final success = await repository.addFamilyMember(
        name: event.name,
        relationship: event.relationship,
        contactNumber: event.contactNumber,
        isEmergencyContact: event.isEmergencyContact,
      );
      if (success != null) add(const LoadFamily(showLoading: false));
    } catch (_) {}
  }

  Future<void> _onUpdateFamilyMember(UpdateFamilyMember event, Emitter<FamilyState> emit) async {
    try {
      final success = await repository.updateFamilyMember(
        event.id,
        name: event.name,
        relationship: event.relationship,
        contactNumber: event.contactNumber,
        isEmergencyContact: event.isEmergencyContact,
      );
      if (success) add(const LoadFamily(showLoading: false));
    } catch (_) {}
  }

  Future<void> _onDeleteFamilyMember(DeleteFamilyMember event, Emitter<FamilyState> emit) async {
    try {
      final success = await repository.deleteFamilyMember(event.id);
      if (success) add(const LoadFamily(showLoading: false));
    } catch (_) {}
  }
}
