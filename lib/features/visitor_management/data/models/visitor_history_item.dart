class VisitorHistoryItem {
  final String recordType; // 'PRE_APPROVED' or 'WALK_IN'
  final String name;
  final String company;
  final String category;
  final String? entryTimeStr;
  final String? exitTimeStr;
  final String? dateStr;
  final String status;
  final String? validToRaw;
  final String? inviteSubType;
  final String? allowedDays;
  final String? startTime;
  final String? endTime;
  final String? vehicleNumber;
  final int? maxGuestCount;
  final bool isPrivate;
  
  final Map<String, dynamic> rawData;

  VisitorHistoryItem({
    required this.recordType,
    required this.name,
    required this.company,
    required this.category,
    this.entryTimeStr,
    this.exitTimeStr,
    this.dateStr,
    required this.status,
    this.validToRaw,
    this.inviteSubType,
    this.allowedDays,
    this.startTime,
    this.endTime,
    this.vehicleNumber,
    this.maxGuestCount,
    this.isPrivate = false,
    required this.rawData,
  });

  factory VisitorHistoryItem.fromJson(Map<String, dynamic> json) {
    final isPreApproved = json['record_type'] == 'PRE_APPROVED';

    final name = json['visitor_name'] ?? json['title'] ?? 'Unknown';
    final company = json['company_name'] ?? json['purpose'] ?? 'Visitor';
    final category = isPreApproved
        ? (json['invite_type'] ?? 'Invite')
        : (json['visitor_type_name'] ?? 'Walk-in');

    final entryTimeStr = json['checkin_at'] ?? json['start_time'];
    final exitTimeStr = json['checkout_at'] ?? json['end_time'];
    final dateStr = json['created_at'] ?? json['valid_from'];

    return VisitorHistoryItem(
      recordType: json['record_type'] ?? 'WALK_IN',
      name: name,
      company: company,
      category: category,
      entryTimeStr: entryTimeStr,
      exitTimeStr: exitTimeStr,
      dateStr: dateStr,
      status: json['status'] ?? 'Pending',
      validToRaw: json['valid_to'],
      inviteSubType: json['invite_sub_type']?.toString().toUpperCase(),
      allowedDays: json['allowed_days'],
      startTime: json['start_time'],
      endTime: json['end_time'],
      vehicleNumber: json['vehicle_number'],
      maxGuestCount: json['max_guest_count'],
      isPrivate: json['is_private'] == true,
      rawData: json,
    );
  }

  bool get isPreApproved => recordType == 'PRE_APPROVED';
}
