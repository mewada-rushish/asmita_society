import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:asmita_society/core/widgets/asmita_loading_indicator.dart';
import 'asmita_facility_booking_wizard.dart';
import 'package:asmita_society/core/widgets/asmita_dialog.dart';
import 'package:asmita_society/core/widgets/asmita_bottom_sheet.dart';
import '../../bloc/amenities_bloc.dart';
import '../../bloc/amenities_state.dart';
import '../../data/models/amenity_model.dart';

class FacilityBookings extends StatelessWidget {
  const FacilityBookings({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    void onFacilityTap(AmenityModel facility, bool isAvailable) {
      if (isAvailable) {
        AsmitaDialog.show(
          context: context,
          title: '${facility.name} Booking',
          content: AsmitaFacilityBookingWizard(initialAmenity: facility),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${facility.name} is currently unavailable.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
    
    IconData getIconForFacility(String name) {
      final lower = name.toLowerCase();
      if (lower.contains('pool')) return Icons.pool_rounded;
      if (lower.contains('gym')) return Icons.fitness_center_rounded;
      if (lower.contains('yoga')) return Icons.self_improvement_rounded;
      if (lower.contains('banquet') || lower.contains('hall')) return Icons.celebration_rounded;
      return Icons.business_center_rounded;
    }

    return BlocBuilder<AmenitiesBloc, AmenitiesState>(
      builder: (context, state) {
        if (state.status == AmenitiesStatus.loading && state.amenities.isEmpty) {
          return Center(child: AsmitaLoadingIndicator(color: Theme.of(context).colorScheme.primary, size: 28));
        }
        
        final amenities = state.amenities;
        final myBookings = state.myBookings;

        // Show max 4 on the main grid
        final displayAmenities = amenities.take(4).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Facility Bookings',
              style: textTheme.titleLarge?.copyWith(
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: 12),
            if (displayAmenities.isEmpty && state.status != AmenitiesStatus.loading)
              Text('No facilities available at the moment.'),
            if (displayAmenities.isNotEmpty)
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.4,
                ),
                itemCount: displayAmenities.length,
                itemBuilder: (context, index) {
                  final fac = displayAmenities[index];
                  final isAvailable = fac.capacity != 0;
                  return _ServiceCard(
                    icon: getIconForFacility(fac.name),
                    title: fac.name,
                    availability: isAvailable ? 'Available' : 'Unavailable',
                    onTap: () => onFacilityTap(fac, isAvailable),
                  );
                },
              ),
            if (amenities.length > 4) ...[
              SizedBox(height: 16),
              Center(
                child: InkWell(
                  onTap: () => _showAllFacilitiesSheet(context, amenities),
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'View All Facilities',
                          style: textTheme.bodyLarge?.copyWith(color: Theme.of(context).colorScheme.primary, fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                        Icon(Icons.keyboard_arrow_down_rounded, color: Theme.of(context).colorScheme.primary, size: 18),
                      ],
                    ),
                  ),
                ),
              ),
            ],
            if (myBookings.isNotEmpty) ...[
              SizedBox(height: 24),
              Text(
                'My Bookings',
                style: textTheme.titleLarge?.copyWith(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: 12),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: myBookings.length,
                itemBuilder: (context, index) {
                  final booking = myBookings[index];
                  return Card(
                    margin: EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      title: Text(booking.amenity?.name ?? 'Facility'),
                      subtitle: Text('${booking.bookingDate != null ? booking.bookingDate!.toLocal().toString().split(' ')[0] : ''} - Status: ${booking.bookingStatus}'),
                      trailing: Icon(Icons.chevron_right),
                    ),
                  );
                },
              ),
            ],
          ],
        );
      },
    );
  }

  void _showAllFacilitiesSheet(BuildContext context, List<AmenityModel> allFacilities) {
    IconData getIconForFacility(String name) {
      final lower = name.toLowerCase();
      if (lower.contains('pool')) return Icons.pool_rounded;
      if (lower.contains('gym')) return Icons.fitness_center_rounded;
      if (lower.contains('yoga')) return Icons.self_improvement_rounded;
      if (lower.contains('banquet') || lower.contains('hall')) return Icons.celebration_rounded;
      return Icons.business_center_rounded;
    }

    showAsmitaBottomSheet(
      context: context,
      title: 'All Facilities',
      isScrollControlled: true,
      child: GridView.builder(
        shrinkWrap: true,
        physics: const BouncingScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.4,
        ),
        itemCount: allFacilities.length,
        itemBuilder: (context, index) {
          final fac = allFacilities[index];
          final isAvailable = fac.capacity != 0;
          return _ServiceCard(
            icon: getIconForFacility(fac.name),
            title: fac.name,
            availability: isAvailable ? 'Available' : 'Unavailable',
            onTap: () {
              if (isAvailable) {
                Navigator.pop(context); // Close the bottom sheet first
                AsmitaDialog.show(context: context, title: '${fac.name} Booking', content: AsmitaFacilityBookingWizard(initialAmenity: fac));
              } else {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${fac.name} is currently unavailable.'), behavior: SnackBarBehavior.floating));
              }
            },
          );
        },
      ),
    );
  }
}

class _ServiceCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String availability;
  final VoidCallback? onTap;

  const _ServiceCard({
    required this.icon,
    required this.title,
    required this.availability,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final isAvailable = availability == 'Available';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Theme.of(context).dividerColor, width: 1.5),
        ),
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.primary, size: 24),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: textTheme.titleLarge?.copyWith(fontSize: 13, fontWeight: FontWeight.w700),
                ),
                SizedBox(height: 2),
                Text(
                  availability,
                  style: textTheme.bodyMedium?.copyWith(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isAvailable ? Theme.of(context).colorScheme.primary : Theme.of(context).textTheme.bodyMedium?.color,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}