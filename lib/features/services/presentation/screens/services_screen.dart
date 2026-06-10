import 'package:flutter/material.dart';
import 'package:asmita_society/core/constants/design_system.dart';
import '../widgets/verified_local_handymen.dart';
import '../widgets/facility_bookings.dart';

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
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              Navigator.of(context, rootNavigator: true).maybePop();
            }
          },
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
            const FacilityBookings(),
            const SizedBox(height: 24),
            const VerifiedLocalHandymen(),
           
          ],
        ),
      ),
    );
  }

  }