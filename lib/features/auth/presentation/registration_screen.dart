import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/design_system.dart';
import '../../../core/widgets/asmita_toast.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';

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
  
  String? _selectedSociety;
  String? _selectedTower;
  String? _selectedFloor;
  String? _selectedFlat;
  String? _selectedRole;
  String? _selectedGender;

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
      society: _selectedSociety!,
      tower: _selectedTower!,
      floor: _selectedFloor!,
      flat: _selectedFlat!,
      role: _selectedRole!.toLowerCase(),
    ));
  }

  void _showSearchableBottomSheet({
    required String title,
    required List<String> items,
    required String? currentValue,
    required ValueChanged<String> onSelected,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        List<String> filteredItems = List.from(items);
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.viewInsetsOf(context).bottom,
              ),
              child: Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.sizeOf(context).height * 0.65,
                ),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Select $title',
                      style: const TextStyle(
                        fontFamily: 'Montserrat',
                        color: AsmitaPalette.deepNavy,
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 16),
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
                              .where((item) => item.toLowerCase().contains(value.toLowerCase()))
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
                                    item,
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
        );
      },
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
                builder: (_) => Scaffold(body: Center(child: Text('Dashboard for ${state.user.userType}'))),
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
          _buildSearchableDropdownField(
            label: 'Society Name',
            icon: Icons.domain_rounded,
            hint: 'Select Society',
            items: ['Gaursons Green Mansion', 'AsmitA Club'],
            value: _selectedSociety,
            onChanged: (val) => setState(() => _selectedSociety = val),
          ),
          _buildSearchableDropdownField(
            label: 'Tower Number',
            icon: Icons.business_rounded,
            hint: 'Select Tower',
            items: ['Tower A', 'Tower B'],
            value: _selectedTower,
            onChanged: (val) => setState(() => _selectedTower = val),
          ),
          _buildSearchableDropdownField(
            label: 'Floor',
            icon: Icons.stairs_rounded,
            hint: 'Select Floor',
            items: ['1st Floor', '7th Floor'],
            value: _selectedFloor,
            onChanged: (val) => setState(() => _selectedFloor = val),
          ),
          _buildSearchableDropdownField(
            label: 'Apartment Number',
            icon: Icons.meeting_room_rounded,
            hint: 'Select Apartment',
            items: ['Apartment 101', 'Apartment 102'],
            value: _selectedFlat,
            onChanged: (val) => setState(() => _selectedFlat = val),
          ),
          _buildSearchableDropdownField(
            label: 'I am a...',
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
            child: Stack(
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
                  child: const Icon(Icons.person_rounded, size: 40, color: Color(0xFF27347B)),
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
          const SizedBox(height: 32),
          _buildTextField('Full Name', Icons.person_outline_rounded, 'Enter full name', _nameController),
          _buildTextField('Email Address', Icons.email_outlined, 'name@example.com', _emailController, keyboardType: TextInputType.emailAddress),
          _buildSearchableDropdownField(
            label: 'Gender',
            icon: Icons.transgender_rounded,
            hint: 'Select Gender',
            items: ['Male', 'Female', 'Other'],
            value: _selectedGender,
            onChanged: (val) => setState(() => _selectedGender = val),
            enableSearch: false,
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

  Widget _buildSearchableDropdownField({
    required String label,
    required IconData icon,
    required String hint,
    required List<String> items,
    required String? value,
    required ValueChanged<String?> onChanged,
    bool enableSearch = true,
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
              if (enableSearch) {
                _showSearchableBottomSheet(
                  title: label,
                  items: items,
                  currentValue: value,
                  onSelected: onChanged,
                );
              } else {
                _showSearchableBottomSheet(
                  title: label,
                  items: items,
                  currentValue: value,
                  onSelected: onChanged,
                );
              }
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
                      value ?? hint,
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