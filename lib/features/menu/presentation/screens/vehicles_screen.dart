import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:asmita_society/core/constants/design_system.dart';
import 'package:asmita_society/core/widgets/asmita_sub_header.dart';
import 'package:asmita_society/core/widgets/asmita_primary_header.dart';
import 'package:asmita_society/core/widgets/asmita_animated_refresh.dart';
import 'package:asmita_society/core/widgets/asmita_toast.dart';
import 'package:asmita_society/core/widgets/asmita_bottom_nav_bar.dart';
import 'package:asmita_society/features/menu/presentation/providers/vehicles_provider.dart';
import 'package:asmita_society/features/menu/data/models/vehicle_model.dart';
import 'package:asmita_society/features/menu/presentation/screens/widgets/add_edit_vehicle_sheet.dart';

class VehiclesScreen extends ConsumerWidget {
  final ValueChanged<int>? onNavigateToTab;

  const VehiclesScreen({super.key, this.onNavigateToTab});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final vehiclesState = ref.watch(vehiclesProvider);

    return Scaffold(
      backgroundColor: AsmitaPalette.systemBG,
      bottomNavigationBar: AsmitaBottomNavBar(
        currentIndex: -1,
        onTap: (index) {
          Navigator.pop(context);
          if (onNavigateToTab != null) {
            onNavigateToTab!(index);
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEditSheet(context, ref),
        backgroundColor: AsmitaPalette.deepNavy,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const Icon(CupertinoIcons.add, color: Colors.white),
      ),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            AsmitaPrimaryHeader(
              showBackButton: false,
              backgroundColor: Colors.white,
              onSearchPressed: () {},
              onChatPressed: () {},
            ),
            const AsmitaSubHeader(title: 'Vehicles'),
            Expanded(
              child: vehiclesState.when(
                data: (vehicles) {
                  return CustomScrollView(
                    physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                    slivers: [
                      AsmitaAnimatedRefresh(
                        onRefresh: () async {
                          ref.invalidate(vehiclesProvider);
                          await Future.delayed(const Duration(milliseconds: 1000));
                        },
                      ),
                      if (vehicles.isEmpty)
                        SliverFillRemaining(
                          child: Center(
                            child: Text(
                              'No vehicles added yet.',
                              style: textTheme.bodyLarge?.copyWith(color: AsmitaPalette.textLight),
                            ),
                          ),
                        )
                      else
                        SliverPadding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                          sliver: SliverGrid(
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              childAspectRatio: 0.85,
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                            ),
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                return _buildVehicleGridCard(context, ref, textTheme, vehicles[index]);
                              },
                              childCount: vehicles.length,
                            ),
                          ),
                        ),
                    ],
                  );
                },
                loading: () => const Center(child: CupertinoActivityIndicator()),
                error: (error, _) => Center(
                  child: Text('Error: ', style: textTheme.bodyLarge?.copyWith(color: Colors.red)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVehicleGridCard(BuildContext context, WidgetRef ref, TextTheme textTheme, VehicleModel vehicle) {
    bool isCar = vehicle.type.toLowerCase() == '4-wheeler' || vehicle.type.toLowerCase() == 'car';

    return GestureDetector(
      onTap: () => _showVehicleOptions(context, ref, vehicle),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AsmitaPalette.borderGrey, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(),
            CircleAvatar(
              radius: 38,
              backgroundColor: AsmitaPalette.deepNavy.withValues(alpha: 0.08),
              child: Icon(isCar ? Icons.directions_car_rounded : Icons.two_wheeler_rounded, color: AsmitaPalette.deepNavy, size: 36),
            ),
            const SizedBox(height: 12),
            Text(
              vehicle.makeModel, 
              style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.amber, width: 1),
              ),
              child: Text(vehicle.licensePlate, style: textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w700, letterSpacing: 1.2)),
            ),
            const Spacer(),
            if (vehicle.parkingSlot != null && vehicle.parkingSlot!.isNotEmpty)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.local_parking_rounded, size: 14, color: AsmitaPalette.textLight),
                  const SizedBox(width: 4),
                  Text('Slot: ${vehicle.parkingSlot}', style: textTheme.bodySmall?.copyWith(color: AsmitaPalette.textLight, fontWeight: FontWeight.w600)),
                ],
              ),
          ],
        ),
      ),
    );
  }

  void _showVehicleOptions(BuildContext context, WidgetRef ref, VehicleModel vehicle) {
    showCupertinoModalPopup(
      context: context,
      builder: (BuildContext context) => SafeArea(
        child: CupertinoActionSheet(
          title: Text(vehicle.makeModel),
        message: const Text('Select an action'),
        actions: <CupertinoActionSheetAction>[
          CupertinoActionSheetAction(
            child: const Text('Edit Vehicle'),
            onPressed: () {
              Navigator.pop(context);
              _showAddEditSheet(context, ref, vehicle: vehicle);
            },
          ),
          CupertinoActionSheetAction(
            isDestructiveAction: true,
            onPressed: () {
              Navigator.pop(context);
              _confirmDelete(context, ref, vehicle);
            },
            child: const Text('Delete Vehicle'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          child: const Text('Cancel'),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref, VehicleModel vehicle) async {
    final confirm = await showCupertinoDialog<bool>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('Delete Vehicle'),
        content: Text('Are you sure you want to remove ?'),
        actions: [
          CupertinoDialogAction(
            child: const Text('Cancel'),
            onPressed: () => Navigator.pop(ctx, false),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            child: const Text('Delete'),
            onPressed: () => Navigator.pop(ctx, true),
          ),
        ],
      ),
    );
    
    if (confirm == true) {
      final success = await ref.read(vehiclesProvider.notifier).deleteVehicle(vehicle.id);
      if (success && context.mounted) {
        AsmitaToast.show(context, message: ' deleted', type: AsmitaToastType.success);
      }
    }
  }

  void _showAddEditSheet(BuildContext context, WidgetRef ref, {VehicleModel? vehicle}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return AddEditVehicleSheet(vehicle: vehicle);
      },
    );
  }
}
