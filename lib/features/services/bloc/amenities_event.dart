import 'package:equatable/equatable.dart';

abstract class AmenitiesEvent extends Equatable {
  const AmenitiesEvent();

  @override
  List<Object?> get props => [];
}

class FetchAmenities extends AmenitiesEvent {
  final int? societyId;
  const FetchAmenities({this.societyId});
  
  @override
  List<Object?> get props => [societyId];
}

class FetchMyBookings extends AmenitiesEvent {
  final int? societyId;
  const FetchMyBookings({this.societyId});
  
  @override
  List<Object?> get props => [societyId];
}

class SubmitBookingRequest extends AmenitiesEvent {
  final int amenityId;
  final int societyId;
  final int flatId;
  final DateTime bookingDate;
  final DateTime startTime;
  final DateTime endTime;

  const SubmitBookingRequest({
    required this.amenityId,
    required this.societyId,
    required this.flatId,
    required this.bookingDate,
    required this.startTime,
    required this.endTime,
  });

  @override
  List<Object?> get props => [amenityId, societyId, flatId, bookingDate, startTime, endTime];
}
