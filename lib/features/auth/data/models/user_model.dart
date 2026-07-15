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
  final String userType;
  final String accountType;
  final int? societyId;
  final String? emailId;
  final String? mobileNumber;
  final String? gender;
  final String? profilePictureUrl;
  final List<FlatMapping> flatMappings;

  UserModel({
    required this.userId,
    required this.fullName,
    required this.userType,
    required this.accountType,
    this.societyId,
    this.emailId,
    this.mobileNumber,
    this.gender,
    this.profilePictureUrl,
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
      userType: json['user_type']?.toString() ?? 'resident',
      accountType: json['account_type']?.toString() ?? 'app',
      societyId: json['society_id'] is int
          ? json['society_id'] as int
          : int.tryParse(json['society_id']?.toString() ?? ''),
      emailId: json['email_id']?.toString(),
      mobileNumber: json['mobile_number']?.toString(),
      gender: json['gender']?.toString(),
      profilePictureUrl: json['profile_picture_url']?.toString(),
      flatMappings: mappings,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'full_name': fullName,
      'user_type': userType,
      'account_type': accountType,
      'society_id': societyId,
      'email_id': emailId,
      'mobile_number': mobileNumber,
      'gender': gender,
      'profile_picture_url': profilePictureUrl,
      'user_flat_mapping': flatMappings.map((m) => m.toJson()).toList(),
    };
  }
}