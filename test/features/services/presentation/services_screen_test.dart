import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mocktail/mocktail.dart';
import 'package:asmita_society/features/services/presentation/screens/services_screen.dart';
import 'package:asmita_society/features/services/bloc/amenities_bloc.dart';
import 'package:asmita_society/features/services/bloc/amenities_event.dart';
import 'package:asmita_society/features/services/bloc/amenities_state.dart';
import 'package:asmita_society/features/services/data/models/amenity_model.dart';
import 'package:asmita_society/features/services/data/models/amenity_booking_model.dart';
import 'package:asmita_society/features/auth/bloc/auth_bloc.dart';
import 'package:asmita_society/features/auth/bloc/auth_state.dart';
import 'package:asmita_society/features/auth/data/models/user_model.dart';
import 'package:asmita_society/core/widgets/asmita_loading_indicator.dart';

class MockAmenitiesBloc extends Mock implements AmenitiesBloc {}
class MockAuthBloc extends Mock implements AuthBloc {}

void main() {
  late MockAmenitiesBloc mockAmenitiesBloc;
  late MockAuthBloc mockAuthBloc;
  late StreamController<AmenitiesState> amenitiesStateController;
  late StreamController<AuthState> authStateController;

  final testUser = UserModel(
    userId: 202,
    fullName: 'Pooja Mehta',
    primaryRole: 'owner',
    accountType: 'app',
    societyName: 'AsmitA Grandeur',
  );

  final sampleAmenities = [
    const AmenityModel(
      amenityId: 1,
      name: 'Swimming Pool',
      capacity: 25,
      type: 'activity',
    ),
    const AmenityModel(
      amenityId: 2,
      name: 'Community Gym',
      capacity: 15,
      type: 'activity',
    ),
    const AmenityModel(
      amenityId: 3,
      name: 'Banquet Hall',
      capacity: 150,
      type: 'booking',
    ),
    const AmenityModel(
      amenityId: 4,
      name: 'Yoga Studio',
      capacity: 0, // Unavailable
      type: 'activity',
    ),
    const AmenityModel(
      amenityId: 5,
      name: 'Tennis Court',
      capacity: 4,
      type: 'activity',
    ),
  ];

  final sampleBookings = [
    AmenityBookingModel(
      bookingId: 10,
      amenityId: 3,
      bookingDate: DateTime(2026, 11, 15),
      bookingStatus: 'Confirmed',
      paymentStatus: 'Paid',
      amenity: const AmenityModel(
        amenityId: 3,
        name: 'Banquet Hall',
      ),
    ),
  ];

  setUpAll(() {
    registerFallbackValue(const FetchAmenities());
    registerFallbackValue(const FetchMyBookings());
  });

  setUp(() {
    mockAmenitiesBloc = MockAmenitiesBloc();
    mockAuthBloc = MockAuthBloc();
    amenitiesStateController = StreamController<AmenitiesState>.broadcast();
    authStateController = StreamController<AuthState>.broadcast();

    when(() => mockAuthBloc.stream).thenAnswer((_) => authStateController.stream);
    when(() => mockAuthBloc.state).thenReturn(
      AuthAuthenticated(user: testUser, sessionRole: 'owner'),
    );
    when(() => mockAuthBloc.close()).thenAnswer((_) async {});

    when(() => mockAmenitiesBloc.stream).thenAnswer((_) => amenitiesStateController.stream);
    when(() => mockAmenitiesBloc.state).thenReturn(
      AmenitiesState(
        status: AmenitiesStatus.loaded,
        amenities: sampleAmenities,
        myBookings: sampleBookings,
      ),
    );
    when(() => mockAmenitiesBloc.close()).thenAnswer((_) async {});
    when(() => mockAmenitiesBloc.add(any())).thenReturn(null);
  });

  tearDown(() async {
    await amenitiesStateController.close();
    await authStateController.close();
  });

  Widget buildTestableWidget({
    VoidCallback? onNavigateToSearch,
    VoidCallback? onNavigateToCommunity,
  }) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>.value(value: mockAuthBloc),
        BlocProvider<AmenitiesBloc>.value(value: mockAmenitiesBloc),
      ],
      child: MaterialApp(
        home: ServicesScreen(
          onNavigateToSearch: onNavigateToSearch,
          onNavigateToCommunity: onNavigateToCommunity,
        ),
      ),
    );
  }

  void setMobileScreen(WidgetTester tester) {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  group('ServicesScreen & FacilityBookings Production Widget Tests', () {
    testWidgets('renders AsmitaLoadingIndicator when amenities state is loading and list is empty', (tester) async {
      setMobileScreen(tester);
      when(() => mockAmenitiesBloc.state).thenReturn(
        const AmenitiesState(status: AmenitiesStatus.loading, amenities: []),
      );

      await tester.pumpWidget(buildTestableWidget());
      await tester.pump();

      expect(find.byType(AsmitaLoadingIndicator), findsOneWidget);
    });

    testWidgets('renders facility cards with correct names and availability status', (tester) async {
      setMobileScreen(tester);
      await tester.pumpWidget(buildTestableWidget());
      await tester.pump();

      expect(find.text('Facility Bookings'), findsOneWidget);
      // First 4 amenities rendered on the main grid
      expect(find.text('Swimming Pool'), findsOneWidget);
      expect(find.text('Community Gym'), findsOneWidget);
      expect(find.text('Banquet Hall'), findsNWidgets(2)); // Once in grid, once in My Bookings
      expect(find.text('Yoga Studio'), findsOneWidget);

      // Yoga Studio has capacity = 0, so should be marked Unavailable
      expect(find.text('Unavailable'), findsOneWidget);
      expect(find.text('Available'), findsNWidgets(3));
    });

    testWidgets('renders View All Facilities button when amenities list exceeds 4 items and opens bottom sheet', (tester) async {
      setMobileScreen(tester);
      await tester.pumpWidget(buildTestableWidget());
      await tester.pump();

      final viewAllBtn = find.text('View All Facilities');
      expect(viewAllBtn, findsOneWidget);

      await tester.tap(viewAllBtn);
      await tester.pumpAndSettle();

      expect(find.text('All Facilities'), findsOneWidget);
      // All 5 amenities now visible in the sheet
      expect(find.text('Tennis Court'), findsOneWidget);
    });

    testWidgets('renders My Bookings section with booking details', (tester) async {
      setMobileScreen(tester);
      await tester.pumpWidget(buildTestableWidget());
      await tester.pump();

      expect(find.text('My Bookings'), findsOneWidget);
      expect(find.textContaining('Status: Confirmed'), findsOneWidget);
    });

    testWidgets('shows snackbar when unavailable facility is tapped', (tester) async {
      setMobileScreen(tester);
      await tester.pumpWidget(buildTestableWidget());
      await tester.pump();

      // Tap unavailable Yoga Studio
      await tester.tap(find.text('Yoga Studio'));
      await tester.pump();

      expect(find.text('Yoga Studio is currently unavailable.'), findsOneWidget);
    });

    testWidgets('header callbacks onSearchPressed and onChatPressed trigger correctly', (tester) async {
      setMobileScreen(tester);
      bool searchTriggered = false;
      bool chatTriggered = false;

      await tester.pumpWidget(buildTestableWidget(
        onNavigateToSearch: () => searchTriggered = true,
        onNavigateToCommunity: () => chatTriggered = true,
      ));
      await tester.pump();

      final searchIcon = find.byIcon(Icons.search_rounded);
      expect(searchIcon, findsOneWidget);
      await tester.tap(searchIcon);
      await tester.pump();
      expect(searchTriggered, isTrue);

      final chatIcon = find.byIcon(Icons.chat_bubble_outline_rounded);
      expect(chatIcon, findsOneWidget);
      await tester.tap(chatIcon);
      await tester.pump();
      expect(chatTriggered, isTrue);
    });
  });
}
