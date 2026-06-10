import 'package:flutter/material.dart';
import 'package:asmita_society/core/constants/design_system.dart';
import 'facility_booking/club_house.dart';
import 'facility_booking/gym_booking.dart';

class FacilityBookings extends StatelessWidget {
  const FacilityBookings({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

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
        const SizedBox(height: 12),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.4,
          children: [
            _ServiceCard(
              icon: Icons.sports_tennis_rounded,
              title: 'Clubhouse',
              availability: 'Available',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ClubhouseShowcase()),
                );
              },
            ),
            _ServiceCard(
              icon: Icons.fitness_center_rounded, 
              title: 'Community Gym', 
              availability: 'Slots Full',
                onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const GymBookingShowcase()),
                );
              },
              ),
            const _ServiceCard(icon: Icons.pool_rounded, title: 'Swimming Pool', availability: 'Maintenance'),
            const _ServiceCard(icon: Icons.celebration_rounded, title: 'Party Hall', availability: 'Available'),
          ],
        ),
      ],
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
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AsmitaPalette.borderGrey, width: 1.5),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(icon, color: AsmitaPalette.deepNavy, size: 24),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: textTheme.titleLarge?.copyWith(fontSize: 13, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(
                  availability,
                  style: textTheme.bodyMedium?.copyWith(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isAvailable ? AsmitaPalette.actionRed : AsmitaPalette.textLight,
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