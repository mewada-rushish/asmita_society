import 'package:equatable/equatable.dart';
import '../data/models/amenity_model.dart';
import '../data/models/amenity_booking_model.dart';

enum AmenitiesStatus { initial, loading, loaded, error }

class AmenitiesState extends Equatable {
  final AmenitiesStatus status;
  final List<AmenityModel> amenities;
  final List<AmenityBookingModel> myBookings;
  final String? errorMessage;
  final bool isSubmittingBooking;
  final String? bookingSuccessMessage;

  const AmenitiesState({
    this.status = AmenitiesStatus.initial,
    this.amenities = const [],
    this.myBookings = const [],
    this.errorMessage,
    this.isSubmittingBooking = false,
    this.bookingSuccessMessage,
  });

  AmenitiesState copyWith({
    AmenitiesStatus? status,
    List<AmenityModel>? amenities,
    List<AmenityBookingModel>? myBookings,
    String? errorMessage,
    bool? isSubmittingBooking,
    String? bookingSuccessMessage,
  }) {
    return AmenitiesState(
      status: status ?? this.status,
      amenities: amenities ?? this.amenities,
      myBookings: myBookings ?? this.myBookings,
      errorMessage: errorMessage ?? this.errorMessage,
      isSubmittingBooking: isSubmittingBooking ?? this.isSubmittingBooking,
      bookingSuccessMessage: bookingSuccessMessage, // Don't persist success message
    );
  }

  @override
  List<Object?> get props => [status, amenities, myBookings, errorMessage, isSubmittingBooking, bookingSuccessMessage];
}
