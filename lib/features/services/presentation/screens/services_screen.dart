import 'package:flutter/material.dart';
import 'package:asmita_society/core/constants/design_system.dart';

class ServicesScreen extends StatelessWidget {
  const ServicesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AsmitaPalette.systemBG,
      appBar: AppBar(
        backgroundColor: AsmitaPalette.systemBG,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AsmitaPalette.deepNavy),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Society Services',
          style: textTheme.titleLarge?.copyWith(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
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
          ],
        ),
      ),
    );
  }

  }