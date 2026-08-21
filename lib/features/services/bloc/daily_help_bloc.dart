import 'package:flutter_bloc/flutter_bloc.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../auth/bloc/auth_state.dart';
import '../data/repositories/daily_help_repository.dart';
import '../data/models/daily_help_model.dart';
import 'daily_help_event.dart';
import 'daily_help_state.dart';

class DailyHelpBloc extends Bloc<DailyHelpEvent, DailyHelpState> {
  final DailyHelpRepository repository;
  final AuthBloc authBloc;

  DailyHelpBloc({required this.repository, required this.authBloc}) : super(const DailyHelpState()) {
    on<FetchDailyHelp>(_onFetchDailyHelp);
    on<AddDailyHelp>(_onAddDailyHelp);
  }

  int? get _societyId {
    final state = authBloc.state;
    if (state is AuthAuthenticated) {
      return state.user.societyId;
    }
    return null;
  }

  Future<void> _onFetchDailyHelp(FetchDailyHelp event, Emitter<DailyHelpState> emit) async {
    emit(state.copyWith(status: DailyHelpStatus.loading));
    try {
      final societyId = event.societyId ?? _societyId;
      final list = await repository.getDailyHelpList(societyId: societyId);
      emit(state.copyWith(status: DailyHelpStatus.loaded, dailyHelpList: list, errorMessage: null));
    } catch (e) {
      emit(state.copyWith(status: DailyHelpStatus.error, errorMessage: e.toString()));
    }
  }

  Future<void> _onAddDailyHelp(AddDailyHelp event, Emitter<DailyHelpState> emit) async {
    // Keep current list but show some loading indicator if we want, or just wait.
    // For now, we don't change state to loading to avoid clearing the list UI.
    try {
      final societyId = event.societyId ?? _societyId;
      if (societyId == null) throw Exception("Society ID not found");

      final newProvider = await repository.addDailyHelpProvider(
        societyId: societyId,
        name: event.name,
        phone: event.phone,
        role: event.role,
      );

      final updatedList = List<DailyHelpModel>.from(state.dailyHelpList)..add(newProvider);
      emit(state.copyWith(status: DailyHelpStatus.loaded, dailyHelpList: updatedList, errorMessage: null));
    } catch (e) {
      // Could emit an error state briefly, but let's just let it fail silently or use a toast from UI.
      // We will emit error state so UI can react.
      emit(state.copyWith(status: DailyHelpStatus.error, errorMessage: e.toString()));
    }
  }
}
