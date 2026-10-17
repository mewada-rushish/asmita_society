import 'package:equatable/equatable.dart';

class PropertyConfig extends Equatable {
  final int societyId;
  final String societyName;
  final String propertyProfile;
  final bool mandatorySelfie;
  final bool mandatoryDeskCabin;
  final bool allowVehicleAtGate;
  final bool allowDeliveryAtGate;
  final List<String> deliveryActions;
  final List<String> visitorCategories;
  final List<String> hiddenDepartments;
  final Map<String, String> zoneLabels;
  final List<Map<String, dynamic>> departments;

  const PropertyConfig({
    required this.societyId,
    required this.societyName,
    required this.propertyProfile,
    this.mandatorySelfie = false,
    this.mandatoryDeskCabin = false,
    this.allowVehicleAtGate = true,
    this.allowDeliveryAtGate = true,
    this.deliveryActions = const ['DELIVER_TO_DESK', 'LEAVE_AT_GATE', 'COLLECT_AT_GATE', 'HOLD_FOR_APPROVAL'],
    this.visitorCategories = const ['Guest', 'Delivery', 'Cab', 'Service'],
    this.hiddenDepartments = const [],
    this.zoneLabels = const {'tower': 'Tower', 'wing': 'Wing', 'flat': 'Flat'},
    this.departments = const [],
  });

  bool get isIndustrial => propertyProfile.toUpperCase() == 'INDUSTRIAL';
  bool get isCommercial => propertyProfile.toUpperCase() == 'COMMERCIAL';
  bool get isHybrid => propertyProfile.toUpperCase() == 'HYBRID';
  bool get isResidential => propertyProfile.toUpperCase() == 'RESIDENTIAL';

  String get towerLabel => zoneLabels['tower'] ?? (isIndustrial ? 'Building' : 'Tower');
  String get wingLabel => zoneLabels['wing'] ?? (isIndustrial ? 'Department' : (isCommercial ? 'Floor' : 'Wing'));
  String get flatLabel => zoneLabels['flat'] ?? (isIndustrial ? 'Cabin / Desk' : (isCommercial ? 'Office' : 'Flat'));

  factory PropertyConfig.fromJson(Map<String, dynamic> json) {
    final propertyMap = (json['property'] as Map<String, dynamic>?) ?? {};
    final configMap = (json['config'] as Map<String, dynamic>?) ?? {};
    final zoneLabelsRaw = (configMap['zone_labels'] as Map<String, dynamic>?) ?? {};

    final rawSocietyId = propertyMap['society_id'] ?? json['society_id'] ?? configMap['society_id'];
    final societyId = rawSocietyId is int
        ? rawSocietyId
        : int.tryParse(rawSocietyId?.toString() ?? '0') ?? 0;

    final societyName = propertyMap['society_name']?.toString() ??
        json['society_name']?.toString() ??
        configMap['society_name']?.toString() ??
        'AsmitA Property';

    final propertyProfile = propertyMap['property_profile']?.toString() ??
        configMap['profile']?.toString() ??
        json['property_profile']?.toString() ??
        'RESIDENTIAL';

    final mandatorySelfie = configMap['requiresLiveSelfie'] == true || configMap['mandatory_selfie'] == true;
    final mandatoryDeskCabin = configMap['mandatoryCabinCode'] == true ||
        configMap['mandatoryDeskCode'] == true ||
        configMap['mandatory_desk_cabin'] == true;

    final allowVehicle = configMap['allow_vehicle_at_gate'] != false;
    final allowDelivery = configMap['allow_delivery_at_gate'] != false || configMap['supportsCabDeliveries'] == true;

    final deliveryActions = (configMap['allowedDeliveryActions'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        (configMap['delivery_actions'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        const ['DELIVER_TO_DESK', 'LEAVE_AT_GATE', 'ALLOW_ENTRY'];

    final visitorCategories = (configMap['visitor_categories'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        (propertyProfile.toUpperCase() == 'INDUSTRIAL'
            ? const ['Guest', 'Vendor', 'Contractor', 'Delivery', 'Cab']
            : const ['Guest', 'Delivery', 'Cab', 'Service']);

    final hiddenDepartments = (configMap['hiddenDepartments'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        (configMap['hidden_departments'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        const [];

    return PropertyConfig(
      societyId: societyId,
      societyName: societyName,
      propertyProfile: propertyProfile,
      mandatorySelfie: mandatorySelfie,
      mandatoryDeskCabin: mandatoryDeskCabin,
      allowVehicleAtGate: allowVehicle,
      allowDeliveryAtGate: allowDelivery,
      deliveryActions: deliveryActions,
      visitorCategories: visitorCategories,
      hiddenDepartments: hiddenDepartments,
      zoneLabels: zoneLabelsRaw.map((k, v) => MapEntry(k, v.toString())),
      departments: (json['departments'] as List<dynamic>?)
              ?.map((e) => Map<String, dynamic>.from(e as Map))
              .toList() ??
          const [],
    );
  }

  factory PropertyConfig.defaultResidential({int societyId = 1, String societyName = 'Residential Society'}) {
    return PropertyConfig(
      societyId: societyId,
      societyName: societyName,
      propertyProfile: 'RESIDENTIAL',
      mandatorySelfie: false,
      mandatoryDeskCabin: false,
      allowVehicleAtGate: true,
      allowDeliveryAtGate: true,
      deliveryActions: const ['LEAVE_AT_GATE', 'COLLECT_AT_GATE'],
      visitorCategories: const ['Guest', 'Delivery', 'Cab', 'Service'],
      hiddenDepartments: const [],
      zoneLabels: const {'tower': 'Tower', 'wing': 'Wing', 'flat': 'Flat'},
      departments: const [],
    );
  }

  @override
  List<Object?> get props => [
        societyId,
        societyName,
        propertyProfile,
        mandatorySelfie,
        mandatoryDeskCabin,
        allowVehicleAtGate,
        allowDeliveryAtGate,
        deliveryActions,
        visitorCategories,
        hiddenDepartments,
        zoneLabels,
        departments,
      ];
}
