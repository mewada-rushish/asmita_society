class PetModel {
  final int id;
  final String name;
  final String breed;
  final bool isVaccinated;

  PetModel({
    required this.id,
    required this.name,
    required this.breed,
    this.isVaccinated = false,
  });

  factory PetModel.fromJson(Map<String, dynamic> json) {
    return PetModel(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      breed: json['breed'] as String? ?? '',
      isVaccinated: json['is_vaccinated'] == 1 || json['is_vaccinated'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'breed': breed,
      'is_vaccinated': isVaccinated ? 1 : 0,
    };
  }
}
