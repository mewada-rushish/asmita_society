import 'dart:async';
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
    return _repository.getFamilyMembers();
  }

  Future<void> fetchMembers() async {
    state = const AsyncValue.loading();
    try {
      final members = await _repository.getFamilyMembers();
      state = AsyncValue.data(members);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  Future<bool> addMember({
    required String name,
    required String relationship,
    bool isEmergencyContact = false,
  }) async {
    final newMember = await _repository.addFamilyMember(
      name: name,
      relationship: relationship,
      isEmergencyContact: isEmergencyContact,
    );
    if (newMember != null) {
      if (state.value != null) {
        state = AsyncValue.data([...state.value!, newMember]);
      } else {
        state = AsyncValue.data([newMember]);
      }
      return true;
    }
    return false;
  }

  Future<bool> updateMember(int id, {
    required String name,
    required String relationship,
    required bool isEmergencyContact,
  }) async {
    final success = await _repository.updateFamilyMember(
      id,
      name: name,
      relationship: relationship,
      isEmergencyContact: isEmergencyContact,
    );
    if (success && state.value != null) {
      final updatedList = state.value!.map((m) {
        if (m.id == id) {
          return FamilyMemberModel(
            id: m.id,
            name: name,
            relationship: relationship,
            isEmergencyContact: isEmergencyContact,
            avatarUrl: m.avatarUrl,
          );
        }
        return m;
      }).toList();
      state = AsyncValue.data(updatedList);
    }
    return success;
  }

  Future<bool> deleteMember(int id) async {
    final success = await _repository.deleteFamilyMember(id);
    if (success && state.value != null) {
      final updatedList = state.value!.where((m) => m.id != id).toList();
      state = AsyncValue.data(updatedList);
    }
    return success;
  }
}
