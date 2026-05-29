import 'package:flutter/material.dart';
import '../../../core/constants/design_system.dart';

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

  // Form Controllers
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  
  // Dropdown States
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
    if (_currentStep < _totalSteps - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      setState(() => _currentStep++);
    } else {
      _submitRegistration();
    }
  }

  void _submitRegistration() {
    // TODO: Dispatch Bloc event with all collected data
    // context.read<AuthBloc>().add(AuthRegisterRequested(...));
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.paddingOf(context).top;
    final bottomPadding = MediaQuery.paddingOf(context).bottom;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: AsmitaPalette.deepNavy,
      body: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        child: SizedBox(
          height: screenHeight,
          child: Column(
            children: [
              // Top Spacing & App Bar
              Padding(
                padding: EdgeInsets.only(top: topPadding + 16.0, bottom: 24.0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
                    padding: const EdgeInsets.only(left: 24),
                    onPressed: () {
                      if (_currentStep > 0) {
                        _pageController.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
                        setState(() => _currentStep--);
                      } else {
                        Navigator.pop(context);
                      }
                    },
                  ),
                ),
              ),
              // Main White Container
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildProgressHeader(),
                      Expanded(
                        child: PageView(
                          controller: _pageController,
                          physics: const NeverScrollableScrollPhysics(), // Disable manual swipe, force button tap
                          children: [
                            _buildSocietyDetailsForm(),
                            _buildPersonalDetailsForm(),
                          ],
                        ),
                      ),
                      _buildBottomButton(bottomPadding),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${_currentStep + 1} of $_totalSteps',
            style: const TextStyle(
              fontFamily: 'Montserrat',
              color: AsmitaPalette.deepNavy,
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: List.generate(_totalSteps, (index) {
              return Expanded(
                child: Container(
                  margin: EdgeInsets.only(right: index == 0 ? 8.0 : 0),
                  height: 3,
                  decoration: BoxDecoration(
                    color: index <= _currentStep ? AsmitaPalette.deepNavy : Colors.grey.shade300,
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

  Widget _buildSocietyDetailsForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Society Details', style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: Colors.black, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text('Please enter your society details', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade500)),
          const SizedBox(height: 32),
          
          _buildDropdown('Society Name', Icons.domain_rounded, 'Select Society', ['Gaursons Green Mansion', 'AsmitA Club'], (val) => setState(() => _selectedSociety = val)),
          _buildDropdown('Tower Number', Icons.business_rounded, 'Select Tower', ['Tower A', 'Tower B'], (val) => setState(() => _selectedTower = val)),
          _buildDropdown('Floor', Icons.stairs_rounded, 'Select Floor', ['1st Floor', '7th Floor'], (val) => setState(() => _selectedFloor = val)),
          _buildDropdown('Apartment Number', Icons.meeting_room_rounded, 'Select Apartment', ['Apartment 101', 'Apartment 102'], (val) => setState(() => _selectedFlat = val)),
          _buildDropdown('I am a...', Icons.person_outline_rounded, 'Select Role', ['Owner', 'Tenant'], (val) => setState(() => _selectedRole = val)),
        ],
      ),
    );
  }

  Widget _buildPersonalDetailsForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Personal Details', style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: Colors.black, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text('Please enter your name and gender to continue.', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade500)),
          const SizedBox(height: 32),
          
          Center(
            child: Stack(
              children: [
                Container(
                  height: 100,
                  width: 100,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(24), // Squircle shape like screenshot
                  ),
                  child: const Icon(Icons.person_rounded, size: 48, color: Colors.grey),
                ),
                Positioned(
                  bottom: -8,
                  right: -8,
                  child: Container(
                    decoration: BoxDecoration(
                      color: AsmitaPalette.deepNavy,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 18),
                      onPressed: () {
                        // TODO: Trigger image picker
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
          
          _buildTextField('Full Name', Icons.person_outline_rounded, 'Ronal Smith', _nameController),
          // Added Email based on DB requirements
          _buildTextField('Email Address', Icons.email_outlined, 'name@example.com', _emailController, keyboardType: TextInputType.emailAddress),
          _buildDropdown('Gender', Icons.transgender_rounded, 'Select Gender', ['Male', 'Female', 'Other'], (val) => setState(() => _selectedGender = val)),
        ],
      ),
    );
  }

  Widget _buildTextField(String label, IconData icon, String hint, TextEditingController controller, {TextInputType keyboardType = TextInputType.name}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.titleSmall?.copyWith(color: AsmitaPalette.deepNavy, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: TextField(
              controller: controller,
              keyboardType: keyboardType,
              style: const TextStyle(fontFamily: 'Poppins', color: Colors.black87),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: TextStyle(color: Colors.grey.shade400),
                prefixIcon: Icon(icon, color: Colors.grey.shade500),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown(String label, IconData icon, String hint, List<String> items, ValueChanged<String?> onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.titleSmall?.copyWith(color: AsmitaPalette.deepNavy, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: DropdownButtonFormField<String>(
              decoration: InputDecoration(
                prefixIcon: Icon(icon, color: Colors.grey.shade500),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
              ),
              hint: Text(hint, style: TextStyle(color: Colors.grey.shade400, fontFamily: 'Poppins')),
              icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AsmitaPalette.deepNavy),
              items: items.map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value, style: const TextStyle(fontFamily: 'Poppins', color: Colors.black87)),
                );
              }).toList(),
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomButton(double bottomPadding) {
    return Padding(
      padding: EdgeInsets.fromLTRB(24, 16, 24, bottomPadding > 0 ? bottomPadding + 16.0 : 32.0),
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AsmitaPalette.actionRed,
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          onPressed: _nextStep,
          child: Text(
            _currentStep == 0 ? 'Next Step' : 'Complete Registration',
            style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }
}