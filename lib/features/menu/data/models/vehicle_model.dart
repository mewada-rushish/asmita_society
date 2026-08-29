class VehicleModel {
  final int id;
  final String type;
  final String makeModel;
  final String licensePlate;
  final String? parkingSlot;
  final int? flatId;

  VehicleModel({
    required this.id,
    required this.type,
    required this.makeModel,
    required this.licensePlate,
    this.parkingSlot,
    this.flatId,
  });

  factory VehicleModel.fromJson(Map<String, dynamic> json) {
    return VehicleModel(
      id: json['id'] as int? ?? 0,
      type: json['type'] as String? ?? '',
      makeModel: json['make_model'] as String? ?? '',
      licensePlate: json['license_plate'] as String? ?? '',
      parkingSlot: json['parking_slot'] as String?,
      flatId: json['flat_id'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'make_model': makeModel,
      'license_plate': licensePlate,
      'parking_slot': parkingSlot,
      'flat_id': flatId,
    };
  }
}
