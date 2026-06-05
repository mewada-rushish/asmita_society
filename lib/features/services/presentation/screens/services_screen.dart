import 'package:flutter/material.dart';
import 'package:asmita_society/core/constants/design_system.dart';
import 'package:asmita_society/core/widgets/asmita_primary_header.dart'; // Import the new widget

class ServicesScreen extends StatelessWidget {
  const ServicesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AsmitaPalette.systemBG,
      body: Column(
        children: [
          // Injecting the reusable header here
          const AsmitaPrimaryHeader(),
          
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Facility Bookings',
                    style: textTheme.titleLarge?.copyWith(fontSize: 15, fontWeight: FontWeight.w700),
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
                      _buildServiceCard(context, Icons.sports_tennis_rounded, 'Clubhouse', 'Available'),
                      _buildServiceCard(context, Icons.fitness_center_rounded, 'Community Gym', 'Slots Full'),
                      _buildServiceCard(context, Icons.pool_rounded, 'Swimming Pool', 'Maintenance'),
                      _buildServiceCard(context, Icons.celebration_rounded, 'Party Hall', 'Available'),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Verified Local Handymen',
                    style: textTheme.titleLarge?.copyWith(fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 12),
                  ListView.separated(
                    shrinkWrap: true,
                    padding: EdgeInsets.zero,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: 3,
                    separatorBuilder: (context, index) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final utilities = [
                        {'type': 'Electrician', 'name': 'Ramesh Kumar', 'rate': '₹250/hr'},
                        {'type': 'Plumber', 'name': 'Dilip Solanki', 'rate': '₹300/hr'},
                        {'type': 'Carpenter', 'name': 'Anand Viswakarma', 'rate': '₹200/hr'},
                      ];
                      return _buildHandymanRow(context, utilities[index]['type']!, utilities[index]['name']!, utilities[index]['rate']!);
                    },
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceCard(BuildContext context, IconData icon, String title, String availability) {
    final textTheme = Theme.of(context).textTheme;
    final isAvailable = availability == 'Available';

    return Container(
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
              Text(title, style: textTheme.titleLarge?.copyWith(fontSize: 13, fontWeight: FontWeight.w700)),
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
    );
  }

  Widget _buildHandymanRow(BuildContext context, String specialized, String pilotName, String costMetrics) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AsmitaPalette.borderGrey, width: 1.5),
      ),
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: const BoxDecoration(color: AsmitaPalette.systemBG, shape: BoxShape.circle),
            child: const Icon(Icons.build_circle_outlined, color: AsmitaPalette.deepNavy, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(pilotName, style: textTheme.titleLarge?.copyWith(fontSize: 14, fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text('$specialized • $costMetrics', style: textTheme.bodyMedium?.copyWith(fontSize: 12, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: AsmitaPalette.systemBG,
              foregroundColor: AsmitaPalette.deepNavy,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text('Book', style: textTheme.bodyLarge?.copyWith(fontSize: 12, fontWeight: FontWeight.w700, color: AsmitaPalette.deepNavy)),
          ),
        ],
      ),
    );
  }
}