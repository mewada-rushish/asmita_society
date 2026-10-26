import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:asmita_society/core/widgets/asmita_primary_header.dart';
import 'package:asmita_society/core/widgets/asmita_animated_refresh.dart';
import 'package:asmita_society/features/services/bloc/amenities_bloc.dart';
import 'package:asmita_society/features/services/bloc/amenities_event.dart';
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
            onSearchPressed: onNavigateToSearch,
            onChatPressed: onNavigateToCommunity,
          ),
          Expanded(
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              slivers: [
                AsmitaAnimatedRefresh(
                  onRefresh: () async {
                    context.read<AmenitiesBloc>().add(const FetchAmenities());
                    context.read<AmenitiesBloc>().add(const FetchMyBookings());
                    await Future.delayed(const Duration(milliseconds: 600));
                  },
                ),
                const SliverPadding(
                  padding: EdgeInsets.only(left: 16.0, right: 16.0, top: 16.0, bottom: 160.0),
                  sliver: SliverToBoxAdapter(
                    child: FacilityBookings(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
 