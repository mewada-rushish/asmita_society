import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/history_request_repository.dart';
import '../../data/models/history_request_model.dart';
import 'package:asmita_society/core/network/dio_client.dart';
import 'package:asmita_society/core/security/secure_storage_service.dart';

final historyRequestRepositoryProvider = Provider<HistoryRequestRepository>((ref) {
  return HistoryRequestRepository(
    dio: AsmitaDioClient(SecureStorageService()).dio,
  );
});

final historyRequestProvider = AsyncNotifierProvider<HistoryRequestNotifier, List<HistoryRequestModel>>(() {
  return HistoryRequestNotifier();
});

class HistoryRequestNotifier extends AsyncNotifier<List<HistoryRequestModel>> {
  HistoryRequestRepository get _repository => ref.read(historyRequestRepositoryProvider);

  @override
  FutureOr<List<HistoryRequestModel>> build() async {
    return _repository.getIncomingRequests();
  }

  Future<void> fetchRequests() async {
    state = const AsyncValue.loading();
    try {
      final requests = await _repository.getIncomingRequests();
      state = AsyncValue.data(requests);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  Future<bool> approveRequest(int id, DateTime startDate, DateTime endDate) async {
    final success = await _repository.approveRequest(id, startDate, endDate);
    if (success && state.value != null) {
      final updatedList = state.value!.map((r) {
        if (r.id == id) {
          return HistoryRequestModel(
            id: r.id,
            ownerUserId: r.ownerUserId,
            ownerName: r.ownerName,
            status: 'APPROVED',
            createdAt: r.createdAt,
          );
        }
        return r;
      }).toList();
      state = AsyncValue.data(updatedList);
    }
    return success;
  }
}
