import 'dart:ui';
import 'package:hive/hive.dart';

/// Hive TypeAdapter for [Color] to support safe storage and retrieval
/// of color properties in cached maps and objects without crashing.
class ColorAdapter extends TypeAdapter<Color> {
  @override
  final int typeId = 200;

  @override
  Color read(BinaryReader reader) {
    return Color(reader.readUint32());
  }

  @override
  void write(BinaryWriter writer, Color obj) {
    writer.writeUint32(obj.toARGB32());
  }
}
