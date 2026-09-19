import 'package:flutter_bloc/flutter_bloc.dart';
import '../data/repositories/guard_gate_repository.dart';
import 'guard_gate_event.dart';
import 'guard_gate_state.dart';

class GuardGateBloc extends Bloc<GuardGateEvent, GuardGateState> {
  final GuardGateRepository repository;

  GuardGateBloc({required this.repository}) : super(const GuardGateState()) {
    on<LoadExpectedInvites>((event, emit) async {
      emit(state.copyWith(status: GuardGateStatus.loading));
      try {
        final expected = await repository.getExpectedInvites();
        emit(state.copyWith(
          status: GuardGateStatus.loaded,
          expectedInvites: expected,
        ));
      } catch (e) {
        emit(state.copyWith(
          status: GuardGateStatus.error,
          errorMessage: e.toString(),
        ));
      }
    });

    on<LoadGuardHistory>((event, emit) async {
      emit(state.copyWith(status: GuardGateStatus.loading));
      try {
        final history = await repository.getGuardHistory();
        emit(state.copyWith(
          status: GuardGateStatus.loaded,
          historyRecords: history,
        ));
      } catch (e) {
        emit(state.copyWith(
          status: GuardGateStatus.error,
          errorMessage: e.toString(),
        ));
      }
    });

    on<SearchInviteByCode>((event, emit) async {
      emit(state.copyWith(isSubmitting: true, searchResult: null));
      try {
        final result = await repository.searchInvite(event.code);
        emit(state.copyWith(
          status: GuardGateStatus.success,
          isSubmitting: false,
          searchResult: result,
        ));
      } catch (e) {
        emit(state.copyWith(
          status: GuardGateStatus.error,
          isSubmitting: false,
          errorMessage: e.toString(),
        ));
      }
    });

    on<CheckInPreApprovedVisitor>((event, emit) async {
      emit(state.copyWith(isSubmitting: true));
      try {
        await repository.checkInPreApproved(event.inviteId);
        emit(state.copyWith(
          status: GuardGateStatus.success,
          isSubmitting: false,
          // Clear search result on successful check-in
          searchResult: null,
        ));
        // Reload expected invites
        add(LoadExpectedInvites());
      } catch (e) {
        emit(state.copyWith(
          status: GuardGateStatus.error,
          isSubmitting: false,
          errorMessage: e.toString(),
        ));
      }
    });

    on<SubmitWalkInVisitor>((event, emit) async {
      emit(state.copyWith(isSubmitting: true));
      try {
        await repository.submitWalkInVisitor(event.payload);
        emit(state.copyWith(
          status: GuardGateStatus.success,
          isSubmitting: false,
        ));
      } catch (e) {
        emit(state.copyWith(
          status: GuardGateStatus.error,
          isSubmitting: false,
          errorMessage: e.toString(),
        ));
      }
    });
  }
}
