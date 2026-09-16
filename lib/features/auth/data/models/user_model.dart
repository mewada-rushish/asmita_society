class FlatMapping {
  final int mappingId;
  final int flatId;
  final String flatNumber;
  final int towerId;
  final String towerName;
  final String ownershipType;

  FlatMapping({
    required this.mappingId,
    required this.flatId,
    required this.flatNumber,
    required this.towerId,
    required this.towerName,
    required this.ownershipType,
  });

  factory FlatMapping.fromJson(Map<String, dynamic> json) {
    final flats = json['flats'] as Map<String, dynamic>? ?? {};
    final floors = flats['floors'] as Map<String, dynamic>? ?? {};
    final towers = floors['towers'] as Map<String, dynamic>? ?? {};

    return FlatMapping(
      mappingId: json['mapping_id'] is int ? json['mapping_id'] : int.tryParse(json['mapping_id']?.toString() ?? '0') ?? 0,
      flatId: json['flat_id'] is int ? json['flat_id'] : int.tryParse(json['flat_id']?.toString() ?? '0') ?? 0,
      flatNumber: flats['flat_number']?.toString() ?? '',
      towerId: floors['tower_id'] is int ? floors['tower_id'] : int.tryParse(floors['tower_id']?.toString() ?? '0') ?? 0,
      towerName: towers['tower_name']?.toString() ?? '',
      ownershipType: json['ownership_type']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'mapping_id': mappingId,
      'flat_id': flatId,
      'ownership_type': ownershipType,
      'flats': {
        'flat_number': flatNumber,
        'floors': {
          'tower_id': towerId,
          'towers': {
            'tower_name': towerName,
          }
        }
      }
    };
  }
}

class UserModel {
  final int userId;
  final String fullName;
  final String? systemRole;
  final String primaryRole;
  final String? secondaryRole;
  final String accountType;
  final int? societyId;
  final String? emailId;
  final String? mobileNumber;
  final String? gender;
  final String? profilePictureUrl;
  final String? societyName;
  final List<FlatMapping> flatMappings;

  UserModel({
    required this.userId,
    required this.fullName,
    this.systemRole,
    required this.primaryRole,
    this.secondaryRole,
    required this.accountType,
    this.societyId,
    this.emailId,
    this.mobileNumber,
    this.gender,
    this.profilePictureUrl,
    this.societyName,
    this.flatMappings = const [],
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    var mappings = <FlatMapping>[];
    if (json['user_flat_mapping'] != null && json['user_flat_mapping'] is List) {
      mappings = (json['user_flat_mapping'] as List).map((m) => FlatMapping.fromJson(m)).toList();
    } else if (json['flat_mappings'] != null && json['flat_mappings'] is List) {
      mappings = (json['flat_mappings'] as List).map((m) => FlatMapping.fromJson(m)).toList();
    }

    return UserModel(
      userId: json['user_id'] != null 
          ? (json['user_id'] is int ? json['user_id'] as int : int.tryParse(json['user_id'].toString()) ?? 0)
          : (json['id'] != null ? (json['id'] is int ? json['id'] as int : int.tryParse(json['id'].toString()) ?? 0) : 0),
      fullName: json['full_name']?.toString() ?? '',
      systemRole: json['system_role']?.toString(),
      primaryRole: json['primary_role']?.toString() ?? 'resident',
      secondaryRole: json['secondary_role']?.toString(),
      accountType: json['account_type']?.toString() ?? 'app',
      societyId: json['society_id'] is int
          ? json['society_id'] as int
          : int.tryParse(json['society_id']?.toString() ?? ''),
      emailId: json['email_id']?.toString(),
      mobileNumber: json['mobile_number']?.toString(),
      gender: json['gender']?.toString(),
      profilePictureUrl: json['profile_picture_url']?.toString(),
      societyName: json['society_name']?.toString(),
      flatMappings: mappings,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'full_name': fullName,
      'system_role': systemRole,
      'primary_role': primaryRole,
      'secondary_role': secondaryRole,
      'account_type': accountType,
      'society_id': societyId,
      'email_id': emailId,
      'mobile_number': mobileNumber,
      'gender': gender,
      'profile_picture_url': profilePictureUrl,
      'society_name': societyName,
      'user_flat_mapping': flatMappings.map((m) => m.toJson()).toList(),
    };
  }

  UserModel copyWith({
    int? userId,
    String? fullName,
    String? systemRole,
    String? primaryRole,
    String? secondaryRole,
    String? accountType,
    int? societyId,
    String? emailId,
    String? mobileNumber,
    String? gender,
    String? profilePictureUrl,
    String? societyName,
    List<FlatMapping>? flatMappings,
  }) {
    return UserModel(
      userId: userId ?? this.userId,
      fullName: fullName ?? this.fullName,
      systemRole: systemRole ?? this.systemRole,
      primaryRole: primaryRole ?? this.primaryRole,
      secondaryRole: secondaryRole ?? this.secondaryRole,
      accountType: accountType ?? this.accountType,
      societyId: societyId ?? this.societyId,
      emailId: emailId ?? this.emailId,
      mobileNumber: mobileNumber ?? this.mobileNumber,
      gender: gender ?? this.gender,
      profilePictureUrl: profilePictureUrl ?? this.profilePictureUrl,
      societyName: societyName ?? this.societyName,
      flatMappings: flatMappings ?? this.flatMappings,
    );
  }
}