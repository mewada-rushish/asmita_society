import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';

class AmenityModel extends Equatable {
  final int amenityId;
  final int? societyId;
  final String name;
  final String? description;
  final int? capacity;
  final String? rules;
  final String type;
  final List<Map<String, dynamic>> customFields;
  final List<AmenityTimeSlot> bookedSlots;
  final List<Map<String, dynamic>> bookingOptions;

  const AmenityModel({
    required this.amenityId,
    this.societyId,
    required this.name,
    this.description,
    this.capacity,
    this.rules,
    this.type = 'activity',
    this.customFields = const [],
    this.bookedSlots = const [],
    this.bookingOptions = const [],
  });

  factory AmenityModel.fromJson(Map<String, dynamic> json) {
    List<Map<String, dynamic>> parsedOptions = [];
    if (json['booking_options'] != null) {
      try {
        if (json['booking_options'] is String) {
          final decoded = jsonDecode(json['booking_options']);
          if (decoded is List) {
            parsedOptions = decoded.map((e) => Map<String, dynamic>.from(e as Map)).toList();
          }
        } else if (json['booking_options'] is List) {
          parsedOptions = (json['booking_options'] as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
        }
      } catch (e) {
        debugPrint('Error parsing booking_options: $e');
      }
    }

    List<Map<String, dynamic>> parsedCustomFields = [];
    if (json['custom_fields'] != null) {
      try {
        if (json['custom_fields'] is String) {
          final decoded = jsonDecode(json['custom_fields']);
          if (decoded is List) {
            parsedCustomFields = decoded.map((e) => Map<String, dynamic>.from(e as Map)).toList();
          }
        } else if (json['custom_fields'] is List) {
          parsedCustomFields = (json['custom_fields'] as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
        }
      } catch (e) {
        debugPrint('Error parsing custom_fields: $e');
      }
    }

    return AmenityModel(
      amenityId: json['amenity_id'] ?? json['id'] ?? 0,
      societyId: json['society_id'],
      name: json['name'] ?? '',
      description: json['description'],
      capacity: json['capacity'],
      rules: json['rules'],
      type: json['type'] ?? 'activity',
      customFields: parsedCustomFields,
      bookingOptions: parsedOptions,
      bookedSlots: (json['bookings'] as List<dynamic>?)
              ?.map((e) => AmenityTimeSlot.fromJson(Map<String, dynamic>.from(e as Map)))
              .toList() ??
          [],
    );
  }

  @override
  List<Object?> get props => [amenityId, societyId, name, description, capacity, rules, type, customFields, bookedSlots, bookingOptions];
}

class AmenityTimeSlot extends Equatable {
  final DateTime? bookingDate;
  final DateTime? startTime;
  final DateTime? endTime;

  const AmenityTimeSlot({this.bookingDate, this.startTime, this.endTime});

  factory AmenityTimeSlot.fromJson(Map<String, dynamic> json) {
    return AmenityTimeSlot(
      bookingDate: json['booking_date'] != null ? DateTime.tryParse(json['booking_date']) : null,
      startTime: json['start_time'] != null ? DateTime.tryParse(json['start_time']) : null,
      endTime: json['end_time'] != null ? DateTime.tryParse(json['end_time']) : null,
    );
  }

  @override
  List<Object?> get props => [bookingDate, startTime, endTime];
}
