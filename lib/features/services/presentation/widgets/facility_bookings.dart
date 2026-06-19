import 'package:flutter/material.dart';
import 'package:asmita_society/core/constants/design_system.dart';
import 'asmita_facility_booking_wizard.dart';
import 'package:asmita_society/core/widgets/asmita_dialog.dart';

class FacilityBookings extends StatelessWidget {
  const FacilityBookings({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    void onFacilityTap(String title, String availability) {
      if (availability == 'Available') {
        AsmitaDialog.show(
          context: context,
          content: AsmitaFacilityBookingWizard(initialFacility: title),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$title is currently $availability.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }

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
              icon: Icons.celebration_rounded,
              title: 'Banquet Hall',
              availability: 'Available',
              onTap: () => onFacilityTap('Banquet Hall', 'Available'),
            ),
            _ServiceCard(
              icon: Icons.fitness_center_rounded, 
              title: 'Community Gym', 
              availability: 'Slots Full',
              onTap: () => onFacilityTap('Community Gym', 'Slots Full'),
            ),
            _ServiceCard(
              icon: Icons.pool_rounded, 
              title: 'Swimming Pool', 
              availability: 'Maintenance',
              onTap: () => onFacilityTap('Swimming Pool', 'Maintenance'),
            ),
             _ServiceCard(
               icon: Icons.self_improvement_rounded,
               title: 'Yoga Studio', 
               availability: 'Available',
               onTap: () => onFacilityTap('Yoga Studio', 'Available'),
             ),
          ],
        ),
        const SizedBox(height: 16),
        Center(
          child: InkWell(
            onTap: () => _showAllFacilitiesSheet(context),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'View All Facilities',
                    style: textTheme.bodyLarge?.copyWith(color: AsmitaPalette.actionRed, fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  const Icon(Icons.keyboard_arrow_down_rounded, color: AsmitaPalette.actionRed, size: 18),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showAllFacilitiesSheet(BuildContext context) {
    final allFacilities = [
      // {'title': 'Clubhouse', 'icon': Icons.sports_tennis_rounded, 'availability': 'Available'},
      {'title': 'Banquet Hall', 'icon': Icons.celebration_rounded, 'availability': 'Available'},
      {'title': 'Community Gym', 'icon': Icons.fitness_center_rounded, 'availability': 'Slots Full'},
      {'title': 'Swimming Pool', 'icon': Icons.pool_rounded, 'availability': 'Maintenance'},
      {'title': 'Yoga Studio', 'icon': Icons.self_improvement_rounded, 'availability': 'Available'},
      // {'title': 'Tennis Court', 'icon': Icons.sports_tennis_rounded, 'availability': 'Slots Full'},
      // {'title': 'Badminton Court', 'icon': Icons.sports_tennis_rounded, 'availability': 'Available'},
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => SafeArea(
        child: DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          expand: false,
          builder: (_, scrollController) => Padding(
            padding: const EdgeInsets.only(top: 24, left: 24, right: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'All Facilities',
                      style: TextStyle(fontFamily: 'Montserrat', fontSize: 18, fontWeight: FontWeight.w800, color: AsmitaPalette.deepNavy),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(ctx),
                      icon: const Icon(Icons.close_rounded, color: AsmitaPalette.deepNavy),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: GridView.builder(
                    controller: scrollController,
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
                      return _ServiceCard(
                        icon: fac['icon'] as IconData,
                        title: fac['title'] as String,
                        availability: fac['availability'] as String,
                        onTap: () {
                          if (fac['availability'] == 'Available') {
                            Navigator.pop(ctx);
                            AsmitaDialog.show(context: context, content: AsmitaFacilityBookingWizard(initialFacility: fac['title'] as String));
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${fac['title']} is currently ${fac['availability']}.'), behavior: SnackBarBehavior.floating));
                          }
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
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