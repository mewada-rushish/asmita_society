import 'package:flutter/material.dart';
import 'package:asmita_society/core/widgets/asmita_primary_header.dart';
import '../widgets/facility_bookings.dart';

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
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        children: [
          AsmitaPrimaryHeader(
            userInitials: 'RM',
            onSearchPressed: onNavigateToSearch,
            onChatPressed: onNavigateToCommunity,
          ),
          const Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.only(left: 16.0, right: 16.0, top: 16.0, bottom: 160.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FacilityBookings(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
 