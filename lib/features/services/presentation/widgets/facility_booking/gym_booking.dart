import 'package:flutter/material.dart';
import 'package:asmita_society/core/constants/design_system.dart';

class GymBookingShowcase extends StatelessWidget {
  const GymBookingShowcase({super.key});

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
          'Community Gym',
          style: textTheme.titleLarge?.copyWith(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
      ),
      body: Center(
        child: Text(
          'Gym booking details will be displayed here.',
          style: textTheme.bodyMedium?.copyWith(color: AsmitaPalette.deepNavy),
        ),
      ),
    );
  }
}