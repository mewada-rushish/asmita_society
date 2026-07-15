class PreApprovedInvite {
  final int id;
  final int societyId;
  final int towerId;
  final int unitId;
  final int residentId;
  final String inviteType;
  final String inviteSubType;
  final String? title;
  final String? visitorName;
  final String? mobileNumber;
  final String? companyName;
  final String? vehicleNumber;
  final String? purpose;
  final DateTime? validFrom;
  final DateTime? validTo;
  final String? startTime;
  final String? endTime;
  final String? allowedDays;
  final int? entriesPerDay;
  final int? maxGuestCount;
  final String? qrCode;
  final String? passCode;
  final bool isPrivate;
  final bool approvalRequired;
  final String status;

  PreApprovedInvite({
    required this.id,
    required this.societyId,
    required this.towerId,
    required this.unitId,
    required this.residentId,
    required this.inviteType,
    required this.inviteSubType,
    this.title,
    this.visitorName,
    this.mobileNumber,
    this.companyName,
    this.vehicleNumber,
    this.purpose,
    this.validFrom,
    this.validTo,
    this.startTime,
    this.endTime,
    this.allowedDays,
    this.entriesPerDay,
    this.maxGuestCount,
    this.qrCode,
    this.passCode,
    this.isPrivate = false,
    this.approvalRequired = false,
    this.status = 'active',
  });

  factory PreApprovedInvite.fromJson(Map<String, dynamic> json) {
    return PreApprovedInvite(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      societyId: json['society_id'] is int ? json['society_id'] : int.tryParse(json['society_id']?.toString() ?? '0') ?? 0,
      towerId: json['tower_id'] is int ? json['tower_id'] : int.tryParse(json['tower_id']?.toString() ?? '0') ?? 0,
      unitId: json['unit_id'] is int ? json['unit_id'] : int.tryParse(json['unit_id']?.toString() ?? '0') ?? 0,
      residentId: json['resident_id'] is int ? json['resident_id'] : int.tryParse(json['resident_id']?.toString() ?? '0') ?? 0,
      inviteType: json['invite_type']?.toString() ?? '',
      inviteSubType: json['invite_sub_type']?.toString() ?? '',
      title: json['title']?.toString(),
      visitorName: json['visitor_name']?.toString(),
      mobileNumber: json['mobile_number']?.toString(),
      companyName: json['company_name']?.toString(),
      vehicleNumber: json['vehicle_number']?.toString(),
      purpose: json['purpose']?.toString(),
      validFrom: json['valid_from'] != null ? DateTime.tryParse(json['valid_from'].toString()) : null,
      validTo: json['valid_to'] != null ? DateTime.tryParse(json['valid_to'].toString()) : null,
      startTime: json['start_time']?.toString(),
      endTime: json['end_time']?.toString(),
      allowedDays: json['allowed_days']?.toString(),
      entriesPerDay: json['entries_per_day'] is int ? json['entries_per_day'] : int.tryParse(json['entries_per_day']?.toString() ?? ''),
      maxGuestCount: json['max_guest_count'] is int ? json['max_guest_count'] : int.tryParse(json['max_guest_count']?.toString() ?? ''),
      qrCode: json['qr_code']?.toString(),
      passCode: json['pass_code']?.toString(),
      isPrivate: json['is_private'] == true || json['is_private'] == 1 || json['is_private'] == 'true',
      approvalRequired: json['approval_required'] == true || json['approval_required'] == 1 || json['approval_required'] == 'true',
      status: json['status']?.toString() ?? 'active',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'society_id': societyId,
      'tower_id': towerId,
      'unit_id': unitId,
      'resident_id': residentId,
      'invite_type': inviteType,
      'invite_sub_type': inviteSubType,
      'title': title,
      'visitor_name': visitorName,
      'mobile_number': mobileNumber,
      'company_name': companyName,
      'vehicle_number': vehicleNumber,
      'purpose': purpose,
      'valid_from': validFrom?.toIso8601String(),
      'valid_to': validTo?.toIso8601String(),
      'start_time': startTime,
      'end_time': endTime,
      'allowed_days': allowedDays,
      'entries_per_day': entriesPerDay,
      'max_guest_count': maxGuestCount,
      'qr_code': qrCode,
      'pass_code': passCode,
      'is_private': isPrivate,
      'approval_required': approvalRequired,
      'status': status,
    };
  }
}
