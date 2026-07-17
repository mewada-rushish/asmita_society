import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/constants/design_system.dart';
import '../../../core/widgets/asmita_toast.dart';
import '../../../core/widgets/asmita_bottom_sheet.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';
import '../data/repositories/property_repository.dart';
import '../data/models/property_models.dart';
import '../../dashboard/presentation/main_dashboard_screen.dart';

class RegistrationScreen extends StatefulWidget {
  final String verifiedMobile;
  const RegistrationScreen({super.key, required this.verifiedMobile});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final PageController _pageController = PageController();
  int _currentStep = 0;
  final int _totalSteps = 2;

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  
  PropertyItem? _selectedSociety;
  PropertyItem? _selectedTower;
  PropertyItem? _selectedFloor;
  PropertyItem? _selectedFlat;
  String? _selectedRole;
  String? _selectedGender;
  
  File? _profileImage;
  final ImagePicker _picker = ImagePicker();

  final PropertyRepository _propertyRepo = PropertyRepository();
  bool _isLoadingProperties = false;

  List<PropertyItem> _societies = [];
  List<PropertyItem> _towers = [];
  List<PropertyItem> _floors = [];
  List<PropertyItem> _flats = [];

  @override
  void initState() {
    super.initState();
    _fetchSocieties();
  }

  Future<void> _fetchSocieties() async {
    setState(() => _isLoadingProperties = true);
    final data = await _propertyRepo.getSocieties();
    setState(() {
      _societies = data;
      _isLoadingProperties = false;
    });
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (image != null) {
      setState(() {
        _profileImage = File(image.path);
      });
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
    final data = await _propertyRepo.getTowers(society.id);
    setState(() {
      _towers = data;
      _isLoadingProperties = false;
    });
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
    final data = await _propertyRepo.getFloors(tower.id);
    setState(() {
      _floors = data;
      _isLoadingProperties = false;
    });
  }

  Future<void> _onFloorSelected(PropertyItem floor) async {
    setState(() {
      _selectedFloor = floor;
      _selectedFlat = null;
      _flats = [];
      _isLoadingProperties = true;
    });
    final data = await _propertyRepo.getFlats(floor.id);
    setState(() {
      _flats = data;
      _isLoadingProperties = false;
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep == 0) {
      if (_selectedSociety == null || _selectedTower == null || _selectedFloor == null || _selectedFlat == null || _selectedRole == null) {
        AsmitaToast.show(
          context,
          message: 'Please fill all society details to proceed.',
          type: AsmitaToastType.error,
        );
        return;
      }
    }
    
    if (_currentStep < _totalSteps - 1) {
      FocusScope.of(context).unfocus();
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _submitRegistration();
    }
  }

  void _submitRegistration() {
    if (_nameController.text.trim().isEmpty || _selectedGender == null) {
      AsmitaToast.show(
        context,
        message: 'Please fill in all required fields to continue.',
        type: AsmitaToastType.error,
      );
      return;
    }

    context.read<AuthBloc>().add(AuthRegisterRequested(
      mobile: widget.verifiedMobile,
      fullName: _nameController.text.trim(),
      email: _emailController.text.trim(),
      gender: _selectedGender!,
      society: _selectedSociety!.id.toString(),
      tower: _selectedTower!.id.toString(),
      floor: _selectedFloor!.id.toString(),
      flat: _selectedFlat!.id.toString(),
      role: _selectedRole!.toLowerCase(),
      profilePicture: _profileImage,
    ));
  }

  void _showSearchableBottomSheet<T>({
    required String title,
    required List<T> items,
    required T? currentValue,
    required ValueChanged<T> onSelected,
    bool enableSearch = true,
    bool useGrid = false,
    int gridCrossAxisCount = 4,
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
              padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (enableSearch)
                    TextField(
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
                  const SizedBox(height: 12),
                  Expanded(
                    child: filteredItems.isEmpty
                        ? const Center(
                            child: Text(
                              'No matching results found',
                              style: TextStyle(fontFamily: 'Poppins', color: Colors.black38),
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
                                  childAspectRatio: 1.0,
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
                            : ListView.builder(
                                shrinkWrap: true,
                                physics: const BouncingScrollPhysics(),
                                itemCount: filteredItems.length,
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
                                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
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

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.paddingOf(context).top;
    final bottomPadding = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      backgroundColor: AsmitaPalette.deepNavy,
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthAuthenticated) {
            AsmitaToast.show(
              context,
              message: 'Registration complete! Welcome to AsmitA.',
              type: AsmitaToastType.success,
            );
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(
                builder: (_) => MainDashboardScreen(userRole: state.user.userType),
              ),
              (route) => false,
            );
          } else if (state is AuthError) {
            AsmitaToast.show(
              context,
              message: state.message,
              type: AsmitaToastType.error,
            );
          }
        },
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.only(top: topPadding + 16.0, bottom: 16.0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
                  padding: const EdgeInsets.only(left: 24),
                  onPressed: () {
                    if (_currentStep > 0) {
                      FocusScope.of(context).unfocus();
                      _pageController.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
                    } else {
                      Navigator.pop(context);
                    }
                  },
                ),
              ),
            ),
            Expanded(
              child: Stack(
                children: [
                  Positioned(
                    top: 0, left: 24, right: 24, bottom: 0,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
                      ),
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.only(top: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8F8FB),
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 24,
                          offset: const Offset(0, -8),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildProgressHeader(),
                        Expanded(
                          child: PageView(
                            controller: _pageController,
                            physics: const NeverScrollableScrollPhysics(),
                            onPageChanged: (index) {
                              setState(() {
                                _currentStep = index;
                              });
                            },
                            children: [
                              _buildSocietyDetailsForm(bottomPadding),
                              _buildPersonalDetailsForm(bottomPadding),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Step ${_currentStep + 1} of $_totalSteps',
            key: const ValueKey('step_counter_text'),
            style: const TextStyle(
              fontFamily: 'Montserrat',
              color: AsmitaPalette.deepNavy,
              fontWeight: FontWeight.w700,
              fontSize: 13,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: List.generate(_totalSteps, (index) {
              final isActive = index <= _currentStep;
              return Expanded(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: EdgeInsets.only(right: index == 0 ? 8.0 : 0),
                  height: 4,
                  decoration: BoxDecoration(
                    color: isActive ? const Color(0xFFE21F26) : Colors.black12,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildSocietyDetailsForm(double bottomPadding) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      physics: const ClampingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Society Details', style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: AsmitaPalette.deepNavy, fontWeight: FontWeight.w800, fontFamily: 'Montserrat', fontSize: 26)),
          const SizedBox(height: 6),
          Text('Link your multi-step infrastructure setup profiles.', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade600, fontFamily: 'Poppins')),
          const SizedBox(height: 28),
          if (_isLoadingProperties)
            const Padding(
              padding: EdgeInsets.only(bottom: 20),
              child: LinearProgressIndicator(color: Color(0xFFE21F26)),
            ),
          _buildSearchableDropdownField<PropertyItem>(
            label: 'Society Name',
            icon: Icons.domain_rounded,
            hint: 'Select Society',
            items: _societies,
            value: _selectedSociety,
            onChanged: (val) {
              if (val != null) _onSocietySelected(val);
            },
          ),
          _buildSearchableDropdownField<PropertyItem>(
            label: 'Tower Number',
            icon: Icons.business_rounded,
            hint: 'Select Tower',
            items: _towers,
            value: _selectedTower,
            useGrid: true,
            onChanged: (val) {
              if (val != null) _onTowerSelected(val);
            },
          ),
          _buildSearchableDropdownField<PropertyItem>(
            label: 'Floor',
            icon: Icons.stairs_rounded,
            hint: 'Select Floor',
            items: _floors,
            value: _selectedFloor,
            useGrid: true,
            onChanged: (val) {
              if (val != null) _onFloorSelected(val);
            },
          ),
          _buildSearchableDropdownField<PropertyItem>(
            label: 'Apartment Number',
            icon: Icons.meeting_room_rounded,
            hint: 'Select Apartment',
            items: _flats,
            value: _selectedFlat,
            useGrid: true,
            onChanged: (val) {
              if (val != null) setState(() => _selectedFlat = val);
            },
          ),
          _buildSearchableDropdownField<String>(
            label: 'I am a...',
            modalTitle: 'Role',
            icon: Icons.person_outline_rounded,
            hint: 'Select Role',
            items: ['Owner', 'Tenant'],
            value: _selectedRole,
            onChanged: (val) => setState(() => _selectedRole = val),
            enableSearch: false,
          ),
          _buildBottomNavigation(bottomPadding),
        ],
      ),
    );
  }

  Widget _buildPersonalDetailsForm(double bottomPadding) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      physics: const ClampingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Personal Details', style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: AsmitaPalette.deepNavy, fontWeight: FontWeight.w800, fontFamily: 'Montserrat', fontSize: 26)),
          const SizedBox(height: 6),
          Text('Complete your onboarding identification record.', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade600, fontFamily: 'Poppins')),
          const SizedBox(height: 28),
          Center(
            child: GestureDetector(
              onTap: _pickImage,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    height: 96,
                    width: 96,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        )
                      ],
                    ),
                    clipBehavior: Clip.hardEdge,
                    child: _profileImage != null
                        ? Image.file(_profileImage!, fit: BoxFit.cover)
                        : const Icon(Icons.person_rounded, size: 40, color: Color(0xFF27347B)),
                  ),
                  Positioned(
                  bottom: -2,
                  right: -2,
                  child: Container(
                    height: 34,
                    width: 34,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE21F26),
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFFF8F8FB), width: 3),
                    ),
                    child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 14),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 32),
          _buildTextField('Full Name', Icons.person_outline_rounded, 'Enter full name', _nameController),
          _buildTextField('Email Address', Icons.email_outlined, 'name@example.com', _emailController, keyboardType: TextInputType.emailAddress),
          _buildSearchableDropdownField<String>(
            label: 'Gender',
            icon: Icons.person_outline_rounded,
            hint: 'Select Gender',
            items: ['Male', 'Female', 'Other'],
            value: _selectedGender,
            enableSearch: false,
            useGrid: true,
            gridCrossAxisCount: 3,
            onChanged: (val) => setState(() => _selectedGender = val),
          ),
          _buildBottomNavigation(bottomPadding),
        ],
      ),
    );
  }

  Widget _buildTextField(String label, IconData icon, String hint, TextEditingController controller, {TextInputType keyboardType = TextInputType.name}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontFamily: 'Montserrat', color: AsmitaPalette.deepNavy, fontWeight: FontWeight.w700, fontSize: 13)),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                )
              ],
            ),
            child: TextField(
              controller: controller,
              keyboardType: keyboardType,
              style: const TextStyle(fontFamily: 'Poppins', color: Colors.black87, fontSize: 15),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: const TextStyle(color: Colors.black38, fontSize: 14),
                prefixIcon: Icon(icon, color: const Color(0xFF27347B), size: 20),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF27347B), width: 1.5)),
                contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchableDropdownField<T>({
    required String label,
    required IconData icon,
    required String hint,
    required List<T> items,
    required T? value,
    required ValueChanged<T?> onChanged,
    String? modalTitle,
    bool enableSearch = true,
    bool useGrid = false,
    int gridCrossAxisCount = 4,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontFamily: 'Montserrat', color: AsmitaPalette.deepNavy, fontWeight: FontWeight.w700, fontSize: 13)),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () {
              _showSearchableBottomSheet(
                title: modalTitle ?? label,
                items: items,
                currentValue: value,
                onSelected: onChanged,
                enableSearch: enableSearch,
                useGrid: useGrid,
                gridCrossAxisCount: gridCrossAxisCount,
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  )
                ],
              ),
              child: Row(
                children: [
                  Icon(icon, color: const Color(0xFF27347B), size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      value?.toString() ?? hint,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 15,
                        color: value != null ? Colors.black87 : Colors.black38,
                      ),
                    ),
                  ),
                  const Icon(Icons.keyboard_arrow_down_rounded, color: AsmitaPalette.deepNavy, size: 22),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavigation(double bottomPadding) {
    return Padding(
      padding: EdgeInsets.only(top: 16.0, bottom: bottomPadding > 0 ? bottomPadding + 16.0 : 32.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (_currentStep > 0)
            InkWell(
              onTap: () {
                FocusScope.of(context).unfocus();
                _pageController.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
              },
              borderRadius: BorderRadius.circular(16),
              child: Container(
                height: 56,
                width: 56,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: const Icon(Icons.arrow_back_ios_new_rounded, color: AsmitaPalette.deepNavy, size: 18),
              ),
            )
          else
            const SizedBox(width: 56),
          const Spacer(),
          BlocBuilder<AuthBloc, AuthState>(
            builder: (context, state) {
              final isLoading = state is AuthLoading;
              return InkWell(
                onTap: isLoading ? null : _nextStep,
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  height: 56,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE21F26),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: Row(
                      key: ValueKey('$_currentStep-$isLoading'),
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isLoading)
                          const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        else ...[
                          Text(
                            _currentStep == 0 ? 'Next' : 'Complete',
                            style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600, fontFamily: 'Poppins'),
                          ),
                          const SizedBox(width: 8),
                          Icon(_currentStep == 0 ? Icons.arrow_forward_rounded : Icons.check_rounded, color: Colors.white, size: 20),
                        ]
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}