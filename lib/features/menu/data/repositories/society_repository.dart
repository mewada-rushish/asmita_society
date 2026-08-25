import 'package:dio/dio.dart';
import '../models/committee_member_model.dart';
import '../models/society_rule_model.dart';
import '../models/society_document_model.dart';
import 'package:asmita_society/core/config/env_config.dart';
import 'package:flutter/foundation.dart';

class SocietyRepository {
  final Dio dio;

  SocietyRepository({required this.dio});

  Future<List<CommitteeMemberModel>> getCommitteeMembers() async {
    try {
      final response = await dio.get(EnvConfig.committeeMembers);
      if (response.statusCode == 200 && response.data != null) {
        final List<dynamic> rawList = response.data;
        return rawList.map((e) => CommitteeMemberModel.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching committee members: $e');
      return [];
    }
  }

  Future<List<SocietyRuleModel>> getRules() async {
    try {
      final response = await dio.get(EnvConfig.societyRules);
      if (response.statusCode == 200 && response.data != null) {
        final List<dynamic> rawList = response.data;
        return rawList.map((e) => SocietyRuleModel.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching society rules: $e');
      return [];
    }
  }

  Future<List<SocietyDocumentModel>> getDocuments() async {
    try {
      final response = await dio.get(EnvConfig.societyDocuments);
      if (response.statusCode == 200 && response.data != null) {
        final List<dynamic> rawList = response.data;
        return rawList.map((e) => SocietyDocumentModel.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching society documents: $e');
      return [];
    }
  }
}
