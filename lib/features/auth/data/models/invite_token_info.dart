import 'package:equatable/equatable.dart';

/// Data class representing resolved invite token details for registration prefill.
class InviteTokenInfo extends Equatable {
  final bool success;
  final int societyId;
  final String societyName;
  final String targetRole;
  final int? departmentId;
  final String? departmentName;
  final String? recipientPhone;
  final String? recipientName;

  const InviteTokenInfo({
    required this.success,
    required this.societyId,
    required this.societyName,
    required this.targetRole,
    this.departmentId,
    this.departmentName,
    this.recipientPhone,
    this.recipientName,
  });

  factory InviteTokenInfo.fromJson(Map<String, dynamic> json) {
    int parsedSocietyId = 0;
    if (json['society_id'] is int) {
      parsedSocietyId = json['society_id'] as int;
    } else if (json['society_id'] != null) {
      parsedSocietyId = int.tryParse(json['society_id'].toString()) ?? 0;
    }

    int? parsedDepartmentId;
    if (json['department_id'] is int) {
      parsedDepartmentId = json['department_id'] as int;
    } else if (json['department_id'] != null) {
      parsedDepartmentId = int.tryParse(json['department_id'].toString());
    }

    final phoneStr = json['recipient_phone']?.toString().trim();
    final nameStr = json['recipient_name']?.toString().trim();
    final deptNameStr = json['department_name']?.toString().trim();

    return InviteTokenInfo(
      success: json['success'] == true,
      societyId: parsedSocietyId,
      societyName: json['society_name']?.toString().trim() ?? '',
      targetRole: json['target_role']?.toString().trim() ?? 'Corporate Employee',
      departmentId: parsedDepartmentId,
      departmentName: (deptNameStr != null && deptNameStr.isNotEmpty) ? deptNameStr : null,
      recipientPhone: (phoneStr != null && phoneStr.isNotEmpty) ? phoneStr : null,
      recipientName: (nameStr != null && nameStr.isNotEmpty) ? nameStr : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'society_id': societyId,
      'society_name': societyName,
      'target_role': targetRole,
      if (departmentId != null) 'department_id': departmentId,
      if (departmentName != null) 'department_name': departmentName,
      if (recipientPhone != null) 'recipient_phone': recipientPhone,
      if (recipientName != null) 'recipient_name': recipientName,
    };
  }

  InviteTokenInfo copyWith({
    bool? success,
    int? societyId,
    String? societyName,
    String? targetRole,
    int? departmentId,
    String? departmentName,
    String? recipientPhone,
    String? recipientName,
  }) {
    return InviteTokenInfo(
      success: success ?? this.success,
      societyId: societyId ?? this.societyId,
      societyName: societyName ?? this.societyName,
      targetRole: targetRole ?? this.targetRole,
      departmentId: departmentId ?? this.departmentId,
      departmentName: departmentName ?? this.departmentName,
      recipientPhone: recipientPhone ?? this.recipientPhone,
      recipientName: recipientName ?? this.recipientName,
    );
  }

  @override
  List<Object?> get props => [
        success,
        societyId,
        societyName,
        targetRole,
        departmentId,
        departmentName,
        recipientPhone,
        recipientName,
      ];
}
