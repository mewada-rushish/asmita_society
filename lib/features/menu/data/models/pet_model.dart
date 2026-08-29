class PetModel {
  final int id;
  final String name;
  final String breed;
  final bool isVaccinated;
  final String? avatarUrl;

  PetModel({
    required this.id,
    required this.name,
    required this.breed,
    this.isVaccinated = false,
    this.avatarUrl,
  });

  factory PetModel.fromJson(Map<String, dynamic> json) {
    return PetModel(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      breed: json['breed'] as String? ?? '',
      isVaccinated: json['is_vaccinated'] == 1 || json['is_vaccinated'] == true || json['is_vaccinated'] == 'true',
      avatarUrl: json['avatar_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'breed': breed,
      'is_vaccinated': isVaccinated ? 1 : 0,
      'avatar_url': avatarUrl,
    };
  }
}
