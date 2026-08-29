import 'dart:async';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/family_repository.dart';
import '../../data/models/family_member_model.dart';
import 'package:asmita_society/core/network/dio_client.dart';
import 'package:asmita_society/core/security/secure_storage_service.dart';

final familyRepositoryProvider = Provider<FamilyRepository>((ref) {
  return FamilyRepository(
    dio: AsmitaDioClient(SecureStorageService()).dio,
  );
});

final familyProvider = AsyncNotifierProvider<FamilyNotifier, List<FamilyMemberModel>>(() {
  return FamilyNotifier();
});

class FamilyNotifier extends AsyncNotifier<List<FamilyMemberModel>> {
  FamilyRepository get _repository => ref.read(familyRepositoryProvider);

  @override
  FutureOr<List<FamilyMemberModel>> build() async {
    final cached = _repository.getCachedFamilyMembers();
    if (cached.isNotEmpty) {
      Future.microtask(() => fetchMembers(showLoading: false));
      return _injectPrimary(cached);
    }
    return _fetchNetworkAndInject();
  }

  Future<void> fetchMembers({bool showLoading = true}) async {
    if (showLoading) {
      state = const AsyncValue.loading();
    }
    try {
      final members = await _fetchNetworkAndInject();
      state = AsyncValue.data(members);
    } catch (e, stackTrace) {
      if (showLoading) {
        state = AsyncValue.error(e, stackTrace);
      }
    }
  }

  Future<List<FamilyMemberModel>> _fetchNetworkAndInject() async {
    final members = await _repository.getFamilyMembers();
    final injected = await _injectPrimary(members);
    _repository.saveToCache(injected);
    return injected;
  }

  Future<List<FamilyMemberModel>> _injectPrimary(List<FamilyMemberModel> members) async {
    final secureStorage = SecureStorageService();
    final userProfileJsonStr = await secureStorage.read(key: 'user_profile');
    FamilyMemberModel? primaryMember;
    
    if (userProfileJsonStr != null) {
      try {
        final profileMap = jsonDecode(userProfileJsonStr);
        primaryMember = FamilyMemberModel(
          id: -1, // Use -1 to identify primary member in UI
          name: profileMap['full_name'] ?? 'Primary Member',
          relationship: 'Primary',
          contactNumber: profileMap['mobile_number'],
          isEmergencyContact: true,
          avatarUrl: profileMap['profile_picture_url'],
        );
      } catch (e) {
        // Handle json decode error silently
      }
    }

    if (primaryMember != null) {
      return [primaryMember, ...members];
    }
    return members;
  }

  Future<bool> addMember({
    required String name,
    required String relationship,
    String? contactNumber,
    bool isEmergencyContact = false,
  }) async {
    final newMember = await _repository.addFamilyMember(
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
    final success = await _repository.updateFamilyMember(
      id,
      name: name,
      relationship: relationship,
      contactNumber: contactNumber,
      isEmergencyContact: isEmergencyContact,
    );
    if (success && state.value != null) {
      final updatedList = state.value!.map((m) {
        if (m.id == id) {
          return FamilyMemberModel(
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
    final success = await _repository.deleteFamilyMember(id);
    if (success && state.value != null) {
      final updatedList = state.value!.where((m) => m.id != id).toList();
      state = AsyncValue.data(updatedList);
      _repository.saveToCache(updatedList);
    }
    return success;
  }
}
