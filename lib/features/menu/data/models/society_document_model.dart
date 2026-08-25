class SocietyDocumentModel {
  final int id;
  final String title;
  final String fileUrl;
  final DateTime? uploadedAt;

  SocietyDocumentModel({
    required this.id,
    required this.title,
    required this.fileUrl,
    this.uploadedAt,
  });

  factory SocietyDocumentModel.fromJson(Map<String, dynamic> json) {
    return SocietyDocumentModel(
      id: json['id'] as int? ?? 0,
      title: json['title'] as String? ?? '',
      fileUrl: json['file_url'] as String? ?? '',
      uploadedAt: json['uploaded_at'] != null ? DateTime.tryParse(json['uploaded_at'].toString()) : null,
    );
  }
}
