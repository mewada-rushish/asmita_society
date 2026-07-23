import 'package:flutter/material.dart';
import '../../../core/constants/design_system.dart';
import '../../../core/widgets/asmita_toast.dart';
import '../../../core/widgets/asmita_bottom_sheet.dart';
import '../data/models/property_models.dart';
import '../data/repositories/property_repository.dart';

class AddPropertyScreen extends StatefulWidget {
  const AddPropertyScreen({super.key});

  @override
  State<AddPropertyScreen> createState() => _AddPropertyScreenState();
}

class _AddPropertyScreenState extends State<AddPropertyScreen> {
  final PropertyRepository _propertyRepo = PropertyRepository();

  List<PropertyItem> _societies = [];
  List<PropertyItem> _towers = [];
  List<PropertyItem> _floors = [];
  List<PropertyItem> _flats = [];

  PropertyItem? _selectedSociety;
  PropertyItem? _selectedTower;
  PropertyItem? _selectedFloor;
  PropertyItem? _selectedFlat;
  String? _selectedRole;

  bool _isLoadingProperties = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _fetchSocieties();
  }

  Future<void> _fetchSocieties() async {
    setState(() => _isLoadingProperties = true);
    try {
      final data = await _propertyRepo.getSocieties();
      if (!mounted) return;
      setState(() {
        _societies = data;
      });
    } catch (e) {
      if (!mounted) return;
      AsmitaToast.show(context, message: 'Failed to load societies', type: AsmitaToastType.error);
    } finally {
      if (mounted) setState(() => _isLoadingProperties = false);
    }
  }

  Future<void> _onSocietySelected(PropertyItem society) async {
    setState(() {
      _selectedSociety = society;
      _selectedTower = null;
      _selectedFloor = null;
      _selectedFlat = null;
      _towers = [];
      _floors = [];
      _flats = [];
      _isLoadingProperties = true;
    });
    try {
      final data = await _propertyRepo.getTowers(society.id);
      if (!mounted) return;
      setState(() {
        _towers = data;
      });
    } catch (e) {
      if (!mounted) return;
      AsmitaToast.show(context, message: 'Failed to load towers', type: AsmitaToastType.error);
    } finally {
      if (mounted) setState(() => _isLoadingProperties = false);
    }
  }

  Future<void> _onTowerSelected(PropertyItem tower) async {
    setState(() {
      _selectedTower = tower;
      _selectedFloor = null;
      _selectedFlat = null;
      _floors = [];
      _flats = [];
      _isLoadingProperties = true;
    });
    try {
      final data = await _propertyRepo.getFloors(tower.id);
      if (!mounted) return;
      setState(() {
        _floors = data;
      });
    } catch (e) {
      if (!mounted) return;
      AsmitaToast.show(context, message: 'Failed to load floors', type: AsmitaToastType.error);
    } finally {
      if (mounted) setState(() => _isLoadingProperties = false);
    }
  }

  Future<void> _onFloorSelected(PropertyItem floor) async {
    setState(() {
      _selectedFloor = floor;
      _selectedFlat = null;
      _flats = [];
      _isLoadingProperties = true;
    });
    try {
      final data = await _propertyRepo.getFlats(floor.id);
      if (!mounted) return;
      setState(() {
        _flats = data;
      });
    } catch (e) {
      if (!mounted) return;
      AsmitaToast.show(context, message: 'Failed to load flats', type: AsmitaToastType.error);
    } finally {
      if (mounted) setState(() => _isLoadingProperties = false);
    }
  }

  void _showSearchableBottomSheet<T>({
    required String title,
    required List<T> items,
    required T? currentValue,
    required ValueChanged<T> onSelected,
    bool enableSearch = true,
    bool useGrid = false,
    int gridCrossAxisCount = 4,
    double gridChildAspectRatio = 2.0,
  }) {
    showAsmitaBottomSheet(
      context: context,
      title: 'Select $title',
      child: StatefulBuilder(
        builder: (context, setModalState) {
          List<T> filteredItems = List.from(items);
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.viewInsetsOf(context).bottom,
            ),
            child: Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.sizeOf(context).height * 0.65,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (enableSearch)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: TextField(
                        style: const TextStyle(fontFamily: 'Poppins', fontSize: 14),
                        decoration: InputDecoration(
                          hintText: 'Search...',
                          prefixIcon: const Icon(Icons.search_rounded, color: AsmitaPalette.deepNavy),
                          contentPadding: const EdgeInsets.symmetric(vertical: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade200),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade200),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AsmitaPalette.deepNavy),
                          ),
                        ),
                        onChanged: (value) {
                          setModalState(() {
                            filteredItems = items
                                .where((item) => item.toString().toLowerCase().contains(value.toLowerCase()))
                                .toList();
                          });
                        },
                      ),
                    ),
                  Flexible(
                    child: filteredItems.isEmpty
                        ? const Center(
                            child: Text(
                              'No options available',
                              style: TextStyle(color: Colors.grey),
                            ),
                          )
                        : useGrid
                            ? GridView.builder(
                                shrinkWrap: true,
                                physics: const BouncingScrollPhysics(),
                                itemCount: filteredItems.length,
                                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: gridCrossAxisCount,
                                  crossAxisSpacing: 12,
                                  mainAxisSpacing: 12,
                                  childAspectRatio: gridChildAspectRatio,
                                ),
                                itemBuilder: (context, index) {
                                  final item = filteredItems[index];
                                  final isSelected = item == currentValue;
                                  return GestureDetector(
                                    onTap: () {
                                      onSelected(item);
                                      Navigator.pop(context);
                                    },
                                    child: Container(
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                        color: isSelected ? const Color(0xFFE21F26).withValues(alpha: 0.1) : Colors.white,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: isSelected ? const Color(0xFFE21F26) : Colors.grey.shade300,
                                          width: isSelected ? 2 : 1,
                                        ),
                                      ),
                                      child: Text(
                                        item.toString(),
                                        textAlign: TextAlign.center,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontFamily: 'Poppins',
                                          fontSize: 14,
                                          color: isSelected ? const Color(0xFFE21F26) : Colors.black87,
                                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              )
                            : ListView.separated(
                                shrinkWrap: true,
                                physics: const BouncingScrollPhysics(),
                                itemCount: filteredItems.length,
                                separatorBuilder: (context, index) => const Divider(height: 1, color: Colors.black12),
                                itemBuilder: (context, index) {
                                  final item = filteredItems[index];
                                  final isSelected = item == currentValue;
                                  return ListTile(
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                                    title: Text(
                                      item.toString(),
                                      style: TextStyle(
                                        fontFamily: 'Poppins',
                                        fontSize: 15,
                                        color: isSelected ? const Color(0xFFE21F26) : Colors.black87,
                                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                                      ),
                                    ),
                                    trailing: isSelected
                                        ? const Icon(Icons.check_circle_rounded, color: Color(0xFFE21F26))
                                        : null,
                                    onTap: () {
                                      onSelected(item);
                                      Navigator.pop(context);
                                    },
                                  );
                                },
                              ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildIOSListTile({
    required String label,
    required String? value,
    required String hint,
    required VoidCallback onTap,
    required IconData icon,
    required Color iconBackgroundColor,
    bool isLoading = false,
    bool isDisabled = false,
    bool showDivider = true,
  }) {
    return Column(
      children: [
        InkWell(
          onTap: isDisabled || isLoading ? null : onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: isDisabled ? Colors.grey.shade300 : iconBackgroundColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, size: 18, color: Colors.white),
                ),
                const SizedBox(width: 12),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: isDisabled ? Colors.grey.shade400 : AsmitaPalette.textDark,
                  ),
                ),
                const SizedBox(width: 16),
                if (isLoading)
                  const Expanded(
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: AsmitaPalette.deepNavy),
                      ),
                    ),
                  )
                else
                  Expanded(
                    child: Text(
                      value ?? hint,
                      textAlign: TextAlign.right,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 15,
                        color: value == null ? Colors.grey.shade400 : AsmitaPalette.textLight,
                      ),
                    ),
                  ),
                const SizedBox(width: 8),
                Icon(Icons.chevron_right_rounded, color: isDisabled ? Colors.transparent : Colors.grey.shade300, size: 20),
              ],
            ),
          ),
        ),
        if (showDivider)
          Padding(
            padding: const EdgeInsets.only(left: 48.0),
            child: Divider(height: 1, thickness: 1, color: Colors.grey.shade200),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AsmitaPalette.systemBG,
      appBar: AppBar(
        backgroundColor: AsmitaPalette.deepNavy,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        title: const Text(
          'Add Property',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Link a New Flat',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: AsmitaPalette.deepNavy,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Select the society and flat details below to link an additional property to your account.',
                      style: TextStyle(
                        fontSize: 14,
                        color: AsmitaPalette.textLight,
                      ),
                    ),
                    const SizedBox(height: 32),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 14,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        clipBehavior: Clip.antiAlias,
                        borderRadius: BorderRadius.circular(12),
                        child: Column(
                          children: [
                            _buildIOSListTile(
                              label: 'Society',
                              value: _selectedSociety?.name,
                              hint: 'Select Society',
                              icon: Icons.apartment_rounded,
                              iconBackgroundColor: Colors.blue.shade500,
                              isLoading: _societies.isEmpty && _isLoadingProperties,
                              onTap: () {
                                _showSearchableBottomSheet(
                                  title: 'Society',
                                  items: _societies,
                                  currentValue: _selectedSociety,
                                  onSelected: (val) => _onSocietySelected(val),
                                );
                              },
                            ),
                            _buildIOSListTile(
                              label: 'Tower',
                              value: _selectedTower?.name,
                              hint: 'Select Tower',
                              icon: Icons.domain_rounded,
                              iconBackgroundColor: Colors.indigo.shade400,
                              isDisabled: _selectedSociety == null,
                              isLoading: _towers.isEmpty && _isLoadingProperties,
                              onTap: () {
                                _showSearchableBottomSheet(
                                  title: 'Tower',
                                  items: _towers,
                                  currentValue: _selectedTower,
                                  useGrid: true,
                                  onSelected: (val) => _onTowerSelected(val),
                                );
                              },
                            ),
                            _buildIOSListTile(
                              label: 'Floor',
                              value: _selectedFloor?.name,
                              hint: 'Select Floor',
                              icon: Icons.stairs_rounded,
                              iconBackgroundColor: Colors.purple.shade400,
                              isDisabled: _selectedTower == null,
                              isLoading: _floors.isEmpty && _isLoadingProperties,
                              onTap: () {
                                _showSearchableBottomSheet(
                                  title: 'Floor',
                                  items: _floors,
                                  currentValue: _selectedFloor,
                                  useGrid: true,
                                  onSelected: (val) => _onFloorSelected(val),
                                );
                              },
                            ),
                            _buildIOSListTile(
                              label: 'Flat No.',
                              value: _selectedFlat?.name,
                              hint: 'Select Flat',
                              icon: Icons.door_front_door_rounded,
                              iconBackgroundColor: Colors.teal.shade500,
                              showDivider: false,
                              isDisabled: _selectedFloor == null,
                              isLoading: _flats.isEmpty && _isLoadingProperties,
                              onTap: () {
                                _showSearchableBottomSheet(
                                  title: 'Flat',
                                  items: _flats,
                                  currentValue: _selectedFlat,
                                  useGrid: true,
                                  onSelected: (val) {
                                    setState(() => _selectedFlat = val);
                                  },
                                );
                              },
                            ),
                            _buildIOSListTile(
                              label: 'I am a',
                              value: _selectedRole,
                              hint: 'Owner / Tenant',
                              icon: Icons.person_rounded,
                              iconBackgroundColor: Colors.orange.shade500,
                              showDivider: false,
                              onTap: () {
                                _showSearchableBottomSheet(
                                  title: 'Role',
                                  items: const ['Owner', 'Tenant'],
                                  currentValue: _selectedRole,
                                  enableSearch: false,
                                  useGrid: true,
                                  gridCrossAxisCount: 2,
                                  gridChildAspectRatio: 2.5,
                                  onSelected: (val) {
                                    setState(() => _selectedRole = val);
                                  },
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton(
                      onPressed: _isSubmitting ? null : () async {
                        if (_selectedSociety == null || _selectedTower == null || _selectedFloor == null || _selectedFlat == null || _selectedRole == null) {
                          AsmitaToast.show(context, message: 'Please complete all selections.', type: AsmitaToastType.error);
                          return;
                        }
                        
                        setState(() => _isSubmitting = true);
                        try {
                          await _propertyRepo.linkFlat(_selectedFlat!.id, _selectedRole!);
                          if (!context.mounted) return;
                          AsmitaToast.show(context, message: 'Property linked successfully!', type: AsmitaToastType.success);
                          Navigator.pop(context);
                        } catch (e) {
                          if (!context.mounted) return;
                          // If it's a 404 because the endpoint isn't built yet, we'll still show success for the prototype
                          if (e.toString().contains('404')) {
                             AsmitaToast.show(context, message: 'Property linked successfully! (Mocked)', type: AsmitaToastType.success);
                             Navigator.pop(context);
                          } else {
                             AsmitaToast.show(context, message: e.toString().replaceAll('Exception: ', ''), type: AsmitaToastType.error);
                          }
                        } finally {
                          if (mounted) setState(() => _isSubmitting = false);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AsmitaPalette.actionRed,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        minimumSize: const Size(double.infinity, 56),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        disabledBackgroundColor: AsmitaPalette.actionRed.withValues(alpha: 0.5),
                      ),
                      child: _isSubmitting
                          ? const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : const Text(
                              'Submit Request',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
