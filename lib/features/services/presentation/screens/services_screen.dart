import 'package:flutter/material.dart';
import 'package:asmita_society/core/constants/design_system.dart';
import 'package:asmita_society/core/widgets/asmita_primary_header.dart';
import '../widgets/facility_bookings.dart';
import '../widgets/verified_local_handymen.dart';

class ServicesScreen extends StatelessWidget {
  final VoidCallback? onNavigateToSearch;
  final VoidCallback? onNavigateToCommunity;

  const ServicesScreen({
    super.key,
    this.onNavigateToSearch,
    this.onNavigateToCommunity,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AsmitaPalette.systemBG,
      body: Column(
        children: [
          AsmitaPrimaryHeader(
            title: 'Society Services',
            subtitle: 'Amenities, payments & more',
            userInitials: 'RM',
            onSearchPressed: onNavigateToSearch,
            onChatPressed: onNavigateToCommunity,
          ),
          Expanded(
            child: SingleChildScrollView(
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
          ),
        ],
      ),
    );
  }
}
 