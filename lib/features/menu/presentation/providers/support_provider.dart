import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/support_repository.dart';
import '../../data/models/support_ticket_model.dart';
import 'package:asmita_society/core/network/dio_client.dart';
import 'package:asmita_society/core/security/secure_storage_service.dart';

final supportRepositoryProvider = Provider<SupportRepository>((ref) {
  return SupportRepository(
    dio: AsmitaDioClient(SecureStorageService()).dio,
  );
});

final supportProvider = AsyncNotifierProvider<SupportNotifier, List<SupportTicketModel>>(() {
  return SupportNotifier();
});

class SupportNotifier extends AsyncNotifier<List<SupportTicketModel>> {
  SupportRepository get _repository => ref.read(supportRepositoryProvider);

  @override
  FutureOr<List<SupportTicketModel>> build() async {
    return _repository.getTickets();
  }

  Future<void> fetchTickets() async {
    state = const AsyncValue.loading();
    try {
      final tickets = await _repository.getTickets();
      state = AsyncValue.data(tickets);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  Future<bool> createTicket({
    required String title,
    required String description,
    String? category,
  }) async {
    final newTicket = await _repository.createTicket(
      title: title,
      description: description,
      category: category,
    );
    if (newTicket != null) {
      if (state.value != null) {
        state = AsyncValue.data([newTicket, ...state.value!]);
      } else {
        state = AsyncValue.data([newTicket]);
      }
      return true;
    }
    return false;
  }
}
