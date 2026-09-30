import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/tenant_repository.dart';
import '../../data/models/tenant_model.dart';
import 'package:asmita_society/core/network/dio_client.dart';
import 'package:asmita_society/core/security/secure_storage_service.dart';

final tenantRepositoryProvider = Provider<TenantRepository>((ref) {
  return TenantRepository(
    dio: AsmitaDioClient(SecureStorageService()).dio,
  );
});

final tenantProvider = AsyncNotifierProvider<TenantNotifier, List<TenantModel>>(() {
  return TenantNotifier();
});

class TenantNotifier extends AsyncNotifier<List<TenantModel>> {
  TenantRepository get _repository => ref.read(tenantRepositoryProvider);

  @override
  FutureOr<List<TenantModel>> build() async {
    final cached = _repository.getCachedTenants();
    if (cached.isNotEmpty) {
      Future.microtask(() => fetchMembers(showLoading: false));
      return cached;
    }
    return _fetchNetwork();
  }

  Future<void> fetchMembers({bool showLoading = true}) async {
    if (showLoading) {
      state = const AsyncValue.loading();
    }
    try {
      final members = await _fetchNetwork();
      state = AsyncValue.data(members);
    } catch (e, stackTrace) {
      if (showLoading) {
        state = AsyncValue.error(e, stackTrace);
      }
    }
  }

  Future<List<TenantModel>> _fetchNetwork() async {
    final members = await _repository.getTenants();
    _repository.saveToCache(members);
    return members;
  }

  Future<bool> addMember({
    required String name,
    required String relationship,
    String? contactNumber,
    bool isEmergencyContact = false,
  }) async {
    final newMember = await _repository.addTenant(
      name: name,
      relationship: relationship,
      contactNumber: contactNumber,
      isEmergencyContact: isEmergencyContact,
    );
    if (newMember != null) {
      if (state.value != null) {
        final updatedList = [...state.value!, newMember];
        state = AsyncValue.data(updatedList);
        _repository.saveToCache(updatedList);
      }
      return true;
    }
    return false;
  }

  Future<bool> updateMember(int id, {
    required String name,
    required String relationship,
    String? contactNumber,
    required bool isEmergencyContact,
  }) async {
    final success = await _repository.updateTenant(
      id,
      name: name,
      relationship: relationship,
      contactNumber: contactNumber,
      isEmergencyContact: isEmergencyContact,
    );
    if (success && state.value != null) {
      final updatedList = state.value!.map((m) {
        if (m.id == id) {
          return TenantModel(
            id: m.id,
            name: name,
            relationship: relationship,
            contactNumber: contactNumber,
            isEmergencyContact: isEmergencyContact,
            avatarUrl: m.avatarUrl,
          );
        }
        return m;
      }).toList();
      state = AsyncValue.data(updatedList);
      _repository.saveToCache(updatedList);
    }
    return success;
  }

  Future<bool> deleteMember(int id) async {
    final success = await _repository.deleteTenant(id);
    if (success && state.value != null) {
      final updatedList = state.value!.where((m) => m.id != id).toList();
      state = AsyncValue.data(updatedList);
      _repository.saveToCache(updatedList);
    }
    return success;
  }

  Future<bool> requestHistoryAccess(int id) async {
    final success = await _repository.requestHistoryAccess(id);
    if (success && state.value != null) {
      final updatedList = state.value!.map((m) {
        if (m.id == id) {
          return TenantModel(
            id: m.id,
            name: m.name,
            relationship: m.relationship,
            contactNumber: m.contactNumber,
            isEmergencyContact: m.isEmergencyContact,
            avatarUrl: m.avatarUrl,
            historyRequestStatus: 'PENDING',
          );
        }
        return m;
      }).toList();
      state = AsyncValue.data(updatedList);
      _repository.saveToCache(updatedList);
    }
    return success;
  }
}
