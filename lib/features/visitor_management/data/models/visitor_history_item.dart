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
  final String? photoUrl;
  
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
    this.photoUrl,
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
    final photo = json['photo_url'] ?? json['visitor_photo_url'] ?? json['photo'] ?? json['image_url'];

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
      photoUrl: photo?.toString(),
      rawData: json,
    );
  }

  bool get isPreApproved => recordType == 'PRE_APPROVED';

  bool get isVip =>
      rawData['is_vip'] == true ||
      rawData['isVip'] == true ||
      name.contains(RegExp(r'[\(\[]VIP[\)\]]', caseSensitive: false)) ||
      company.contains(RegExp(r'[\(\[]VIP[\)\]]', caseSensitive: false));

  /// Returns visitor name without legacy embedded "(VIP)" or "[VIP]" tags
  String get cleanName => name
      .replaceAll(RegExp(r'\s*[\(\[]VIP[\)\]]', caseSensitive: false), '')
      .trim();

  /// Returns company or purpose without legacy embedded "[VIP]" or "(VIP)" tags
  String get cleanCompany => company
      .replaceAll(RegExp(r'\s*[\(\[]VIP[\)\]]', caseSensitive: false), '')
      .trim();

  dynamic operator [](String key) => rawData[key];
}
