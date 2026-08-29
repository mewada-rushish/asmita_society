import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:asmita_society/features/auth/bloc/auth_bloc.dart';
import 'package:asmita_society/features/auth/bloc/auth_state.dart';
import 'package:asmita_society/features/auth/data/models/user_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:asmita_society/core/constants/design_system.dart';
import 'package:asmita_society/core/widgets/asmita_toast.dart';
import 'package:asmita_society/features/menu/data/models/vehicle_model.dart';
import 'package:asmita_society/features/menu/presentation/providers/vehicles_provider.dart';

class AddEditVehicleSheet extends ConsumerStatefulWidget {
  final VehicleModel? vehicle;

  const AddEditVehicleSheet({super.key, this.vehicle});

  @override
  ConsumerState<AddEditVehicleSheet> createState() => _AddEditVehicleSheetState();
}

class _AddEditVehicleSheetState extends ConsumerState<AddEditVehicleSheet> {
  late TextEditingController makeModelCtrl;
  String selectedYear = DateTime.now().year.toString();
  late String type;
  
  final lc1 = TextEditingController();
  final lc2 = TextEditingController();
  final lc3 = TextEditingController();
  final lc4 = TextEditingController();

  final fn1 = FocusNode();
  final fn2 = FocusNode();
  final fn3 = FocusNode();
  final fn4 = FocusNode();

  String? selectedSlot;
  List<String> parkingSlots = [];
  List<String> filteredSlots = [];
  bool isLoadingSlots = true;
  bool isSaving = false;
  bool isSlotPickerOpen = false;
  final TextEditingController slotSearchCtrl = TextEditingController();
  FlatMapping? selectedFlat;
  List<FlatMapping> userFlats = [];



  @override
  void initState() {
    super.initState();
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated) {
      userFlats = authState.user.flatMappings;
    } else {
      userFlats = [];
    }
    if (userFlats.isNotEmpty) {

      if (widget.vehicle != null && widget.vehicle!.flatId != null) {
        try {
          selectedFlat = userFlats.firstWhere((f) => f.flatId == widget.vehicle!.flatId);
        } catch (e) {
          selectedFlat = userFlats.first;
        }
      } else {
        selectedFlat = userFlats.first;
      }
    }

    type = widget.vehicle?.type ?? '4-wheeler';
    
    if (widget.vehicle != null) {
      final parts = widget.vehicle!.makeModel.split(' - ');
      makeModelCtrl = TextEditingController(text: parts[0]);
      if (parts.length > 1) {
        selectedYear = parts[1];
      }
      
      final lpParts = widget.vehicle!.licensePlate.split(' ');
      if (lpParts.length == 4) {
        lc1.text = lpParts[0];
        lc2.text = lpParts[1];
        lc3.text = lpParts[2];
        lc4.text = lpParts[3];
      } else {
        // Fallback if it wasn't formatted with spaces
        lc1.text = widget.vehicle!.licensePlate;
      }
      selectedSlot = widget.vehicle!.parkingSlot;
    } else {
      makeModelCtrl = TextEditingController();
    }

    slotSearchCtrl.addListener(() {
      setState(() {
        filteredSlots = parkingSlots.where((s) => s.toLowerCase().contains(slotSearchCtrl.text.toLowerCase())).toList();
      });
    });
    
    _loadParkingSlots();
  }

  Future<void> _loadParkingSlots() async {
    try {
      final slots = await ref.read(vehiclesRepositoryProvider).getParkingSlots();
      if (mounted) {
        setState(() {
          parkingSlots = slots;
          filteredSlots = slots;
          isLoadingSlots = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => isLoadingSlots = false);
      }
    }
  }

  @override
  void dispose() {
    makeModelCtrl.dispose();
    lc1.dispose();
    lc2.dispose();
    lc3.dispose();
    lc4.dispose();
    fn1.dispose();
    fn2.dispose();
    fn3.dispose();
    fn4.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        left: 16,
        right: 16,
        top: 24,
      ),
      decoration: const BoxDecoration(
        color: AsmitaPalette.systemBG,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(widget.vehicle == null ? 'Add Vehicle' : 'Edit Vehicle', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(CupertinoIcons.xmark_circle_fill, color: AsmitaPalette.textLight, size: 28),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
          
          Text('VEHICLE TYPE', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AsmitaPalette.textLight, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _buildTypeCard('2-wheeler', Icons.two_wheeler_rounded, '2-Wheeler')),
              const SizedBox(width: 12),
              Expanded(child: _buildTypeCard('4-wheeler', Icons.directions_car_rounded, '4-Wheeler')),
            ],
          ),
          
          const SizedBox(height: 20),
          Text('MAKE & MODEL', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AsmitaPalette.textLight, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: CupertinoTextField(
                  controller: makeModelCtrl,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AsmitaPalette.borderGrey),
                  ),
                  placeholder: 'e.g. Honda City',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 1,
                child: GestureDetector(
                  onTap: _showYearPicker,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AsmitaPalette.borderGrey),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(selectedYear, style: Theme.of(context).textTheme.bodyLarge),
                        const Icon(CupertinoIcons.chevron_down, size: 16, color: AsmitaPalette.textLight),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),
          Text('LICENSE PLATE', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AsmitaPalette.textLight, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildLicenseInput(lc1, fn1, fn2, 2, 'MH', FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z]'))),
              const SizedBox(width: 8),
              _buildLicenseInput(lc2, fn2, fn3, 2, '04', FilteringTextInputFormatter.digitsOnly),
              const SizedBox(width: 8),
              _buildLicenseInput(lc3, fn3, fn4, 3, 'AB', FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z]'))),
              const SizedBox(width: 8),
              _buildLicenseInput(lc4, fn4, null, 4, '1234', FilteringTextInputFormatter.digitsOnly, isLast: true),
            ],
          ),

          const SizedBox(height: 20),
          Text('PARKING SLOT (OPTIONAL)', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AsmitaPalette.textLight, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
          const SizedBox(height: 8),
          if (isLoadingSlots)
            const Center(child: CupertinoActivityIndicator())
          else if (parkingSlots.isEmpty)
            const Text("No parking slots available")
          else
            GestureDetector(
              onTap: () => _showSlotPickerBottomSheet(context),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AsmitaPalette.borderGrey),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      selectedSlot ?? 'Select Parking Slot',
                      style: TextStyle(
                        color: selectedSlot == null ? CupertinoColors.placeholderText : AsmitaPalette.textDark,
                        fontWeight: selectedSlot == null ? FontWeight.normal : FontWeight.bold,
                      ),
                    ),
                    const Icon(CupertinoIcons.chevron_down, color: AsmitaPalette.textLight, size: 18),
                  ],
                ),
              ),
            ),

              ],
            ),
          ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: CupertinoButton(
              color: AsmitaPalette.deepNavy,
              borderRadius: BorderRadius.circular(12),
              padding: const EdgeInsets.symmetric(vertical: 16),
              onPressed: _saveVehicle,
              child: isSaving 
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                  : Text(widget.vehicle == null ? 'Save Vehicle' : 'Update Vehicle', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }


  void _showSlotPickerBottomSheet(BuildContext context) {
    slotSearchCtrl.clear();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            void updateSearch() {
              setModalState(() {
                filteredSlots = parkingSlots
                    .where((s) => s.toLowerCase().contains(slotSearchCtrl.text.toLowerCase()))
                    .toList();
              });
            }
            
            // Need to remove previous listener if we are adding a new one that captures setModalState, 
            // but it's easier to just use onChanged on the TextField directly instead of a listener.
            
            return Container(
              height: MediaQuery.of(context).size.height * 0.7,
              padding: const EdgeInsets.only(top: 24, left: 16, right: 16),
              decoration: const BoxDecoration(
                color: AsmitaPalette.systemBG,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Select Parking Slot', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(CupertinoIcons.xmark_circle_fill, color: AsmitaPalette.textLight, size: 28),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  CupertinoTextField(
                    controller: slotSearchCtrl,
                    placeholder: 'Search Slot (e.g. B-001)',
                    prefix: const Padding(padding: EdgeInsets.only(left: 12), child: Icon(CupertinoIcons.search, size: 18, color: AsmitaPalette.textLight)),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AsmitaPalette.borderGrey),
                    ),
                    onChanged: (val) => updateSearch(),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: filteredSlots.isEmpty
                        ? const Center(child: Text('No slots found'))
                        : GridView.builder(
                            physics: const BouncingScrollPhysics(),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 4,
                              childAspectRatio: 2.5,
                              crossAxisSpacing: 8,
                              mainAxisSpacing: 8,
                            ),
                            itemCount: filteredSlots.length,
                            itemBuilder: (context, index) {
                              final slot = filteredSlots[index];
                              final isSelected = selectedSlot == slot;
                              return GestureDetector(
                                onTap: () {
                                  setState(() => selectedSlot = isSelected ? null : slot);
                                  Navigator.pop(context);
                                },
                                child: Container(
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: isSelected ? AsmitaPalette.deepNavy : Colors.white,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: isSelected ? AsmitaPalette.deepNavy : AsmitaPalette.borderGrey),
                                  ),
                                  child: Text(
                                    slot,
                                    style: TextStyle(
                                      color: isSelected ? Colors.white : AsmitaPalette.textDark,
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildTypeCard(String value, IconData icon, String label) {
    final isSelected = type == value;
    return GestureDetector(
      onTap: () => setState(() => type = value),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AsmitaPalette.deepNavy.withValues(alpha: 0.1) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? AsmitaPalette.deepNavy : AsmitaPalette.borderGrey, width: isSelected ? 2 : 1),
        ),
        child: Column(
          children: [
            Icon(icon, color: isSelected ? AsmitaPalette.deepNavy : AsmitaPalette.textLight, size: 28),
            const SizedBox(height: 8),
            Text(label, style: TextStyle(
              color: isSelected ? AsmitaPalette.deepNavy : AsmitaPalette.textDark,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildLicenseInput(
    TextEditingController controller,
    FocusNode currentFocus,
    FocusNode? nextFocus,
    int maxLength,
    String placeholder,
    TextInputFormatter formatter,
    {bool isLast = false}
  ) {
    return Expanded(
      flex: isLast ? 2 : 1,
      child: CupertinoTextField(
        controller: controller,
        focusNode: currentFocus,
        textCapitalization: TextCapitalization.characters,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
        textAlign: TextAlign.center,
        maxLength: maxLength,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AsmitaPalette.borderGrey),
        ),
        placeholder: placeholder,
        style: const TextStyle(fontWeight: FontWeight.bold),
        inputFormatters: [formatter, UpperCaseTextFormatter()],
        onChanged: (val) {
          if (val.length == maxLength && nextFocus != null) {
            nextFocus.requestFocus();
          }
        },
      ),
    );
  }

  void _showYearPicker() {
    final currentYear = DateTime.now().year;
    final years = List.generate(30, (index) => (currentYear - index).toString());
    
    int initialIndex = years.indexOf(selectedYear);
    if (initialIndex == -1) initialIndex = 0;

    showCupertinoModalPopup(
      context: context,
      builder: (BuildContext context) => Container(
        height: 250,
        margin: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        color: CupertinoColors.systemBackground.resolveFrom(context),
        child: SafeArea(
          top: false,
          child: Column(
            children: [
              Container(
                decoration: const BoxDecoration(
                  color: CupertinoColors.systemGroupedBackground,
                  border: Border(bottom: BorderSide(color: AsmitaPalette.borderGrey, width: 0.5)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    CupertinoButton(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Done', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: CupertinoPicker(
                  itemExtent: 40,
                  scrollController: FixedExtentScrollController(initialItem: initialIndex),
                  onSelectedItemChanged: (index) {
                    setState(() => selectedYear = years[index]);
                  },
                  children: years.map((y) => Center(child: Text(y))).toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _saveVehicle() async {
    if (isSaving) return;
    
    final modelName = makeModelCtrl.text.trim();
    final combinedMakeModel = "$modelName - $selectedYear";
    
    final l1 = lc1.text.trim();
    final l2 = lc2.text.trim();
    final l3 = lc3.text.trim();
    final l4 = lc4.text.trim();
    final combinedLicense = "$l1 $l2 $l3 $l4".trim();
    
    if (modelName.isEmpty || l1.isEmpty || l2.isEmpty || l4.isEmpty) {
       AsmitaToast.show(context, message: 'Please fill in all required fields', type: AsmitaToastType.error);
       return;
    }

    setState(() => isSaving = true);
    
    final notifier = ref.read(vehiclesProvider.notifier);
    bool success;
    
    if (widget.vehicle == null) {
      success = await notifier.addVehicle(
        type: type,
        makeModel: combinedMakeModel,
        licensePlate: combinedLicense,
        parkingSlot: selectedSlot,
        flatId: selectedFlat!.flatId,
      );
    } else {
      success = await notifier.updateVehicle(
        widget.vehicle!.id,
        type: type,
        makeModel: combinedMakeModel,
        licensePlate: combinedLicense,
        parkingSlot: selectedSlot,
        flatId: selectedFlat!.flatId,
      );
    }
    
    if (mounted) {
      setState(() => isSaving = false);
      if (success) {
        AsmitaToast.show(
          context,
          message: widget.vehicle == null ? 'Vehicle saved successfully!' : 'Vehicle updated successfully!',
          type: AsmitaToastType.success,
        );
        Navigator.pop(context);
      }
    }
  }
}

class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    return TextEditingValue(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
    );
  }
}
