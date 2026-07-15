class PropertyItem {
  final int id;
  final String name;

  PropertyItem({required this.id, required this.name});

  factory PropertyItem.fromJson(Map<String, dynamic> json, String idKey, String nameKey) {
    return PropertyItem(
      id: json[idKey] as int,
      name: json[nameKey].toString(),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PropertyItem && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => name;
}
