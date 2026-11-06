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
    DateTime? parseDate(dynamic val) {
      if (val == null) return null;
      if (val is DateTime) return val;
      return DateTime.tryParse(val.toString());
    }

    return SocietyDocumentModel(
      id: json['id'] as int? ?? 0,
      title: json['title'] as String? ?? '',
      fileUrl: json['file_url'] as String? ?? json['fileUrl'] as String? ?? '',
      uploadedAt: parseDate(json['upload_date'] ?? json['uploaded_at'] ?? json['created_at']),
    );
  }
}
