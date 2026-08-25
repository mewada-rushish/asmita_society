import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:asmita_society/core/constants/design_system.dart';
import 'package:asmita_society/core/widgets/asmita_sub_header.dart';
import 'package:asmita_society/features/menu/presentation/providers/vehicles_provider.dart';
import 'package:asmita_society/features/menu/data/models/vehicle_model.dart';

class VehiclesScreen extends ConsumerWidget {
  const VehiclesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final vehiclesState = ref.watch(vehiclesProvider);

    return Scaffold(
      backgroundColor: AsmitaPalette.systemBG,
      body: SafeArea(
        child: Column(
          children: [
            const AsmitaSubHeader(title: 'Vehicles'),
            Expanded(
              child: vehiclesState.when(
                data: (vehicles) {
                  return ListView(
                    physics: const ClampingScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    children: [
                      _buildAddButton(context, ref, textTheme),
                      const SizedBox(height: 24),
                      if (vehicles.isEmpty)
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.all(32.0),
                            child: Text(
                              'No vehicles added yet.',
                              style: textTheme.bodyLarge?.copyWith(color: AsmitaPalette.textLight),
                            ),
                          ),
                        )
                      else
                        ...vehicles.map((v) => Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: _buildVehicleCard(context, ref, textTheme, v),
                        )),
                    ],
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => Center(
                  child: Text('Error: $error', style: textTheme.bodyLarge?.copyWith(color: Colors.red)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddButton(BuildContext context, WidgetRef ref, TextTheme textTheme) {
    return InkWell(
      onTap: () => _showAddEditSheet(context, ref),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AsmitaPalette.deepNavy.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AsmitaPalette.deepNavy, width: 1.5, style: BorderStyle.solid),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.add_circle_outline_rounded, color: AsmitaPalette.deepNavy),
            const SizedBox(width: 8),
            Text('Add Vehicle', style: textTheme.titleMedium?.copyWith(color: AsmitaPalette.deepNavy, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _buildVehicleCard(BuildContext context, WidgetRef ref, TextTheme textTheme, VehicleModel vehicle) {
    bool isCar = vehicle.type.toLowerCase() == '4-wheeler' || vehicle.type.toLowerCase() == 'car';

    return Dismissible(
      key: ValueKey(vehicle.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (direction) async {
        return await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete Vehicle'),
            content: Text('Are you sure you want to remove ${vehicle.makeModel}?'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
              TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
            ],
          ),
        );
      },
      onDismissed: (direction) {
        ref.read(vehiclesProvider.notifier).deleteVehicle(vehicle.id);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${vehicle.makeModel} deleted')));
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AsmitaPalette.borderGrey, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AsmitaPalette.deepNavy.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(isCar ? Icons.directions_car_rounded : Icons.two_wheeler_rounded, color: AsmitaPalette.deepNavy, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(vehicle.makeModel, style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.amber.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.amber, width: 1),
                    ),
                    child: Text(vehicle.licensePlate, style: textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w700, letterSpacing: 1.2)),
                  ),
                  const SizedBox(height: 8),
                  if (vehicle.parkingSlot != null && vehicle.parkingSlot!.isNotEmpty)
                    Row(
                      children: [
                        const Icon(Icons.local_parking_rounded, size: 14, color: AsmitaPalette.textLight),
                        const SizedBox(width: 4),
                        Text('Slot: ${vehicle.parkingSlot}', style: textTheme.bodySmall?.copyWith(color: AsmitaPalette.textLight, fontWeight: FontWeight.w600)),
                      ],
                    ),
                ],
              ),
            ),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert_rounded, color: AsmitaPalette.textLight),
              onSelected: (val) {
                if (val == 'edit') {
                  _showAddEditSheet(context, ref, vehicle: vehicle);
                } else if (val == 'delete') {
                  ref.read(vehiclesProvider.notifier).deleteVehicle(vehicle.id);
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'edit', child: Text('Edit')),
                const PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: Colors.red))),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showAddEditSheet(BuildContext context, WidgetRef ref, {VehicleModel? vehicle}) {
    final makeModelCtrl = TextEditingController(text: vehicle?.makeModel ?? '');
    final licenseCtrl = TextEditingController(text: vehicle?.licensePlate ?? '');
    final slotCtrl = TextEditingController(text: vehicle?.parkingSlot ?? '');
    String type = vehicle?.type ?? '4-wheeler';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 20,
                right: 20,
                top: 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(vehicle == null ? 'Add Vehicle' : 'Edit Vehicle', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: type,
                    decoration: const InputDecoration(labelText: 'Vehicle Type', border: OutlineInputBorder()),
                    items: const [
                      DropdownMenuItem(value: '2-wheeler', child: Text('2-Wheeler')),
                      DropdownMenuItem(value: '4-wheeler', child: Text('4-Wheeler')),
                    ],
                    onChanged: (val) {
                      if (val != null) setState(() => type = val);
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: makeModelCtrl,
                    decoration: const InputDecoration(labelText: 'Make & Model (e.g. Honda City)', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: licenseCtrl,
                    textCapitalization: TextCapitalization.characters,
                    decoration: const InputDecoration(labelText: 'License Plate (e.g. MH 04 AB 1234)', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: slotCtrl,
                    decoration: const InputDecoration(labelText: 'Parking Slot (Optional)', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        if (makeModelCtrl.text.isEmpty || licenseCtrl.text.isEmpty) return;
                        final notifier = ref.read(vehiclesProvider.notifier);
                        bool success;
                        if (vehicle == null) {
                          success = await notifier.addVehicle(
                            type: type,
                            makeModel: makeModelCtrl.text,
                            licensePlate: licenseCtrl.text,
                            parkingSlot: slotCtrl.text.isEmpty ? null : slotCtrl.text,
                          );
                        } else {
                          success = await notifier.updateVehicle(
                            vehicle.id,
                            type: type,
                            makeModel: makeModelCtrl.text,
                            licensePlate: licenseCtrl.text,
                            parkingSlot: slotCtrl.text.isEmpty ? null : slotCtrl.text,
                          );
                        }
                        if (success && context.mounted) {
                          Navigator.pop(context);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AsmitaPalette.deepNavy,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(vehicle == null ? 'Save Vehicle' : 'Update Vehicle', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            );
          }
        );
      }
    );
  }
}
