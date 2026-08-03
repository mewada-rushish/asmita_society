import 'package:equatable/equatable.dart';
import 'amenity_model.dart';

class AmenityBookingModel extends Equatable {
  final int bookingId;
  final int amenityId;
  final DateTime? bookingDate;
  final DateTime? startTime;
  final DateTime? endTime;
  final String bookingStatus;
  final String paymentStatus;
  final AmenityModel? amenity;

  const AmenityBookingModel({
    required this.bookingId,
    required this.amenityId,
    this.bookingDate,
    this.startTime,
    this.endTime,
    required this.bookingStatus,
    required this.paymentStatus,
    this.amenity,
  });

  factory AmenityBookingModel.fromJson(Map<String, dynamic> json) {
    return AmenityBookingModel(
      bookingId: json['booking_id'] ?? json['id'] ?? 0,
      amenityId: json['amenity_id'] ?? 0,
      bookingDate: json['booking_date'] != null ? DateTime.tryParse(json['booking_date']) : null,
      startTime: json['start_time'] != null ? DateTime.tryParse(json['start_time']) : null,
      endTime: json['end_time'] != null ? DateTime.tryParse(json['end_time']) : null,
      bookingStatus: json['booking_status'] ?? 'Pending',
      paymentStatus: json['payment_status'] ?? 'Pending',
      amenity: json['amenity'] != null ? AmenityModel.fromJson(json['amenity']) : null,
    );
  }

  @override
  List<Object?> get props => [bookingId, amenityId, bookingDate, startTime, endTime, bookingStatus, paymentStatus, amenity];
}
