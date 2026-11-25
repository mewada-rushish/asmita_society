import 'package:dio/dio.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/network/dio_client.dart';

class HrRepository {
  final Dio _dio = sl<AsmitaDioClient>().dio;

  Future<Map<String, dynamic>> getSummary(int societyId) async {
    final res = await _dio.get('/app-api/hr/summary', queryParameters: {
      'society_id': societyId,
    });
    return Map<String, dynamic>.from(res.data['data'] ?? {});
  }

  Future<List<Map<String, dynamic>>> getAttendance(
    int societyId, {
    String? date,
    String? startDate,
    String? endDate,
  }) async {
    final res = await _dio.get('/app-api/hr/attendance', queryParameters: {
      'society_id': societyId,
      'date': ?date,
      'start_date': ?startDate,
      'end_date': ?endDate,
    });
    final list = res.data['data'] as List? ?? [];
    return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  Future<Map<String, dynamic>> getEmployeeAttendanceCalendar(
    int societyId, {
    required int userId,
    required String month,
  }) async {
    final res = await _dio.get('/app-api/hr/attendance/employee', queryParameters: {
      'society_id': societyId,
      'user_id': userId,
      'month': month,
    });
    return Map<String, dynamic>.from(res.data['data'] ?? {});
  }

  Future<List<Map<String, dynamic>>> getDirectoryEmployees(int societyId) async {
    final res = await _dio.get('/api/societies/$societyId/directories/residents');
    final raw = res.data;
    final list = raw is List ? raw : (raw['data'] as List? ?? []);
    return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  Future<Map<String, dynamic>> getEmployeeFormData(int societyId) async {
    final res = await _dio.get('/api/societies/$societyId/directories/employee-form-data');
    return Map<String, dynamic>.from(res.data as Map? ?? {});
  }

  Future<Map<String, dynamic>> addEmployee(int societyId, Map<String, dynamic> payload) async {
    final res = await _dio.post('/app-api/hr/employees', data: {
      ...payload,
      'society_id': societyId,
    });
    return Map<String, dynamic>.from(res.data as Map? ?? {});
  }

  Future<Map<String, dynamic>> resendSingleInvite({
    required int societyId,
    required String phone,
    required String name,
    String? email,
    String? floor,
    String? deskCode,
    String? cabinCode,
    String? department,
    String? role,
    String? invitedByName,
  }) async {
    final cleanPhone = phone.replaceAll(RegExp(r'\D'), '');
    final phone10 = cleanPhone.length >= 10 ? cleanPhone.substring(cleanPhone.length - 10) : cleanPhone;
    final loc = (deskCode != null && deskCode.isNotEmpty)
        ? deskCode
        : (cabinCode != null && cabinCode.isNotEmpty)
            ? cabinCode
            : 'Allocated';
    final locType = (cabinCode != null && cabinCode.isNotEmpty) ? 'Cabin' : 'Desk';

    final res = await _dio.post('/api/invites/generate', data: {
      'society_id': societyId,
      'token_type': 'ONBOARDING',
      'recipient_phone': phone10,
      'recipient_name': name,
      if (email != null && email.isNotEmpty) 'recipient_email': email,
      if (invitedByName != null && invitedByName.isNotEmpty) 'invited_by_name': invitedByName,
      'floor': (floor != null && floor.isNotEmpty) ? floor : 'G',
      'location_type': locType,
      'location': loc,
      'send_wati': true,
      'payload_json': {
        'desk_code': deskCode ?? '',
        'cabin_code': cabinCode ?? '',
        'floor': (floor != null && floor.isNotEmpty) ? floor : 'G',
        'location_type': locType,
        'department': department ?? '',
        'role': role ?? 'Staff',
      },
    });
    return Map<String, dynamic>.from(res.data as Map? ?? {});
  }

  Future<Map<String, dynamic>> bulkInvitePending(
    int societyId, {
    List<int>? userIds,
    String? invitedByName,
  }) async {
    final res = await _dio.post('/api/invites/bulk-generate-pending', data: {
      'society_id': societyId,
      if (userIds != null && userIds.isNotEmpty) 'user_ids': userIds,
      'send_wati': true,
      'send_sms': false,
      if (invitedByName != null && invitedByName.isNotEmpty) 'invited_by_name': invitedByName,
    });
    return Map<String, dynamic>.from(res.data as Map? ?? {});
  }

  Future<List<Map<String, dynamic>>> getLeaves(int societyId, {String status = 'ALL'}) async {
    final res = await _dio.get('/app-api/hr/leaves', queryParameters: {
      'society_id': societyId,
      'status': status,
    });
    final list = res.data['data'] as List? ?? [];
    return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  Future<Map<String, dynamic>> createLeave(Map<String, dynamic> payload) async {
    final res = await _dio.post('/app-api/hr/leaves', data: payload);
    return Map<String, dynamic>.from(res.data as Map? ?? {});
  }

  Future<Map<String, dynamic>> decideLeave(int id, String status, {String? remark}) async {
    final res = await _dio.patch('/app-api/hr/leaves/$id/decide', data: {
      'status': status,
      if (remark != null && remark.isNotEmpty) 'remark': remark,
    });
    return Map<String, dynamic>.from(res.data as Map? ?? {});
  }

  Future<List<Map<String, dynamic>>> getRegularizations(int societyId, {String status = 'ALL'}) async {
    final res = await _dio.get('/app-api/hr/regularizations', queryParameters: {
      'society_id': societyId,
      'status': status,
    });
    final list = res.data['data'] as List? ?? [];
    return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  Future<Map<String, dynamic>> createRegularization(Map<String, dynamic> payload) async {
    final res = await _dio.post('/app-api/hr/regularizations', data: payload);
    return Map<String, dynamic>.from(res.data as Map? ?? {});
  }

  Future<Map<String, dynamic>> decideRegularization(int id, String status, {String? remark}) async {
    final res = await _dio.patch('/app-api/hr/regularizations/$id/decide', data: {
      'status': status,
      if (remark != null && remark.isNotEmpty) 'remark': remark,
    });
    return Map<String, dynamic>.from(res.data as Map? ?? {});
  }

  Future<List<Map<String, dynamic>>> getNotices(int societyId) async {
    final res = await _dio.get('/app-api/hr/notices', queryParameters: {
      'society_id': societyId,
    });
    final list = res.data['data'] as List? ?? [];
    return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  Future<Map<String, dynamic>> createNotice(Map<String, dynamic> payload) async {
    final res = await _dio.post('/app-api/hr/notices', data: payload);
    return Map<String, dynamic>.from(res.data as Map? ?? {});
  }
}
