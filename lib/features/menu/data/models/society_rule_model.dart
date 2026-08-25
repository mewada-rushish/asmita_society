class SocietyRuleModel {
  final int id;
  final String title;
  final String description;

  SocietyRuleModel({
    required this.id,
    required this.title,
    required this.description,
  });

  factory SocietyRuleModel.fromJson(Map<String, dynamic> json) {
    return SocietyRuleModel(
      id: json['id'] as int? ?? 0,
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
    );
  }
}
