import 'package:flutter_bloc/flutter_bloc.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../auth/bloc/auth_state.dart';
import '../data/repositories/amenities_repository.dart';
import 'amenities_event.dart';
import 'amenities_state.dart';

class AmenitiesBloc extends Bloc<AmenitiesEvent, AmenitiesState> {
  final AmenitiesRepository repository;
  final AuthBloc authBloc;

  AmenitiesBloc({required this.repository, required this.authBloc}) : super(const AmenitiesState()) {
    on<FetchAmenities>(_onFetchAmenities);
    on<FetchMyBookings>(_onFetchMyBookings);
    on<SubmitBookingRequest>(_onSubmitBookingRequest);
  }

  int? get _societyId {
    final state = authBloc.state;
    if (state is AuthAuthenticated) {
      return state.user.societyId;
    }
    return null;
  }

  int? get _userId {
    final state = authBloc.state;
    if (state is AuthAuthenticated) {
      return state.user.userId;
    }
    return null;
  }

  Future<void> _onFetchAmenities(FetchAmenities event, Emitter<AmenitiesState> emit) async {
    emit(state.copyWith(status: AmenitiesStatus.loading));
    try {
      final societyId = event.societyId ?? _societyId;
      final amenities = await repository.getAmenities(societyId: societyId);
      emit(state.copyWith(status: AmenitiesStatus.loaded, amenities: amenities, errorMessage: null));
    } catch (e) {
      emit(state.copyWith(status: AmenitiesStatus.error, errorMessage: e.toString()));
    }
  }

  Future<void> _onFetchMyBookings(FetchMyBookings event, Emitter<AmenitiesState> emit) async {
    emit(state.copyWith(status: AmenitiesStatus.loading));
    try {
      final societyId = event.societyId ?? _societyId;
      final bookings = await repository.getMyBookings(societyId: societyId);
      emit(state.copyWith(status: AmenitiesStatus.loaded, myBookings: bookings, errorMessage: null));
    } catch (e) {
      emit(state.copyWith(status: AmenitiesStatus.error, errorMessage: e.toString()));
    }
  }

  Future<void> _onSubmitBookingRequest(SubmitBookingRequest event, Emitter<AmenitiesState> emit) async {
    emit(state.copyWith(isSubmittingBooking: true));
    try {
      final userId = _userId;
      if (userId == null) {
        throw Exception('User not logged in');
      }

      await repository.bookAmenity(
        amenityId: event.amenityId,
        societyId: event.societyId,
        userId: userId,
        flatId: event.flatId,
        bookingDate: event.bookingDate,
        startTime: event.startTime,
        endTime: event.endTime,
      );
      
      emit(state.copyWith(
        isSubmittingBooking: false, 
        bookingSuccessMessage: 'Amenity booked successfully. Waiting for approval.',
      ));
      
      // Refresh bookings
      add(const FetchMyBookings());
    } catch (e) {
      emit(state.copyWith(
        isSubmittingBooking: false,
        errorMessage: e.toString(),
      ));
    }
  }
}
