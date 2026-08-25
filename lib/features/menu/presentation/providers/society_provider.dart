import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/society_repository.dart';
import '../../data/models/committee_member_model.dart';
import '../../data/models/society_rule_model.dart';
import '../../data/models/society_document_model.dart';
import 'package:asmita_society/core/network/dio_client.dart';
import 'package:asmita_society/core/security/secure_storage_service.dart';

final societyRepositoryProvider = Provider<SocietyRepository>((ref) {
  return SocietyRepository(
    dio: AsmitaDioClient(SecureStorageService()).dio,
  );
});

final committeeProvider = FutureProvider<List<CommitteeMemberModel>>((ref) async {
  final repo = ref.read(societyRepositoryProvider);
  return await repo.getCommitteeMembers();
});

final rulesProvider = FutureProvider<List<SocietyRuleModel>>((ref) async {
  final repo = ref.read(societyRepositoryProvider);
  return await repo.getRules();
});

final documentsProvider = FutureProvider<List<SocietyDocumentModel>>((ref) async {
  final repo = ref.read(societyRepositoryProvider);
  return await repo.getDocuments();
});
