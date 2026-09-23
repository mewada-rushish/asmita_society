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
        final history = await repository.getGuardHistory();
        
        final Set<String> checkedInInviteIds = {};
        for (var log in history) {
          if (log['record_type'] == 'PRE_APPROVED') {
            final inviteId = log['invite_id']?.toString() ?? log['pre_approved_invite_id']?.toString();
            if (inviteId != null) checkedInInviteIds.add(inviteId);
          }
        }
        
        final Map<String, dynamic> uniqueExpected = {};
        for (var item in expected) {
          if (item is Map<String, dynamic>) {
            final status = item['status']?.toString().toUpperCase();
            final id = item['id']?.toString() ?? item.hashCode.toString();
            if (status != 'CHECKED_IN' && status != 'CANCELLED' && status != 'REJECTED' && !checkedInInviteIds.contains(id)) {
              uniqueExpected[id] = item;
            }
          }
        }
        
        emit(state.copyWith(
          status: GuardGateStatus.loaded,
          expectedInvites: uniqueExpected.values.toList(),
        ));
      } catch (e) {
        emit(state.copyWith(
          status: GuardGateStatus.error,
          errorMessage: e.toString(),
          clearMessages: true,
        ));
      }
    });

    on<LoadCheckedInVisitors>((event, emit) async {
      emit(state.copyWith(status: GuardGateStatus.loading));
      try {
        final history = await repository.getGuardHistory();
        final Map<String, dynamic> activeVisitors = {};
        
        for (var record in history) {
          final isPreApproved = record['record_type'] == 'PRE_APPROVED';
          final id = record['id']?.toString();
          final inviteId = record['invite_id']?.toString() ?? record['pre_approved_invite_id']?.toString();
          
          final identifier = isPreApproved ? (inviteId ?? id) : id;
          if (identifier == null) continue;
          
          final checkoutAt = record['checkout_at'] ?? record['checked_out_at'] ?? record['check_out_time'] ?? record['exit_time'];
          final action = record['action']?.toString().toUpperCase() ?? record['status']?.toString().toUpperCase() ?? record['entry_status']?.toString().toUpperCase();
          final isCheckedOut = checkoutAt != null || action == 'CHECK_OUT' || action == 'CHECKED_OUT' || action == 'EXIT';
          
          if (!activeVisitors.containsKey(identifier)) {
            if (!isCheckedOut) {
              activeVisitors[identifier] = record;
            } else {
              activeVisitors[identifier] = null; // Mark as resolved (checked out)
            }
          }
        }
        
        final checkedIn = activeVisitors.values.where((v) => v != null).toList();
        
        emit(state.copyWith(
          status: GuardGateStatus.loaded,
          checkedInVisitors: checkedIn,
        ));
      } catch (e) {
        emit(state.copyWith(
          status: GuardGateStatus.error,
          errorMessage: e.toString(),
          clearMessages: true,
        ));
      }
    });

    on<CheckOutVisitor>((event, emit) async {
      emit(state.copyWith(isSubmitting: true, submittingVisitorId: event.id, clearMessages: true));
      try {
        await repository.checkOutVisitor(event.id, isPreApproved: event.isPreApproved, inviteGuestId: event.inviteGuestId);
        emit(state.copyWith(
          status: GuardGateStatus.success,
          isSubmitting: false,
          successMessage: 'Check-out successful!',
        ));
        // Reload lists
        add(LoadCheckedInVisitors());
        add(LoadGuardHistory());
      } catch (e) {
        emit(state.copyWith(
          status: GuardGateStatus.error,
          isSubmitting: false,
          errorMessage: e.toString(),
          clearMessages: true,
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
          clearMessages: true,
        ));
      }
    });

    on<SearchInviteByCode>((event, emit) async {
      emit(state.copyWith(isSubmitting: true, clearMessages: true));
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
          clearMessages: true,
        ));
      }
    });

    on<CheckInPreApprovedVisitor>((event, emit) async {
      emit(state.copyWith(isSubmitting: true, clearMessages: true));
      try {
        await repository.checkInPreApproved(event.inviteId);
        emit(state.copyWith(
          status: GuardGateStatus.success,
          isSubmitting: false,
          successMessage: 'Check-in successful!',
          clearMessages: true, // clear searchResult
        ));
        // Reload expected invites and history
        add(LoadExpectedInvites());
        add(LoadGuardHistory());
        add(LoadCheckedInVisitors());
      } catch (e) {
        emit(state.copyWith(
          status: GuardGateStatus.error,
          isSubmitting: false,
          errorMessage: e.toString(),
          clearMessages: true,
        ));
      }
    });

    on<SubmitWalkInVisitor>((event, emit) async {
      emit(state.copyWith(isSubmitting: true, clearMessages: true));
      try {
        await repository.submitWalkInVisitor(event.payload);
        emit(state.copyWith(
          status: GuardGateStatus.success,
          isSubmitting: false,
          successMessage: 'Walk-in visitor logged successfully!',
        ));
        // Reload history and expected lists
        add(LoadGuardHistory());
        add(LoadCheckedInVisitors());
      } catch (e) {
        emit(state.copyWith(
          status: GuardGateStatus.error,
          isSubmitting: false,
          errorMessage: e.toString(),
          clearMessages: true,
        ));
      }
    });
  }
}
