import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:asmita_society/core/constants/design_system.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../auth/bloc/auth_state.dart';
import '../../auth/data/models/user_model.dart';
import '../../visitor_management/bloc/visitor_bloc.dart';
import '../../visitor_management/bloc/visitor_event.dart';
import '../../visitor_management/bloc/visitor_state.dart';
import '../../visitor_management/presentation/screens/invite_pass_screen.dart';
import 'package:asmita_society/core/widgets/asmita_toast.dart';

class AsmitaPreApproveWizard extends StatefulWidget {
  const AsmitaPreApproveWizard({super.key});

  @override
  State<AsmitaPreApproveWizard> createState() => _AsmitaPreApproveWizardState();
}

class _AsmitaPreApproveWizardState extends State<AsmitaPreApproveWizard>
    with SingleTickerProviderStateMixin {
  int _currentStep = 0;
  String _selectedCategory = '';

  // Custom Flow States
  late TabController _tabController;
  final ScrollController _scrollController = ScrollController();

  FlatMapping? _selectedFlatMapping;

  bool _surpriseDelivery = false;
  bool _secureCabMode = false;
  final TextEditingController _cabNoController = TextEditingController();

  bool _leaveAtGate = false;
  bool _showAdvancedOptions = false;

  int _selectedDurationHours = 1;
  String _selectedCompany = 'Amazon';
  String _customCompanyName = '';
  String _selectedDaysOfWeek = 'All days of Week';
  List<bool> _customDaysSelected = [true, true, true, true, true, true, true];

  String _frequentValidity = '6 months';

  DateTime _selectedDate = DateTime.now();
  DateTime _selectedEndDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _selectedTime = TimeOfDay.now();
  TimeOfDay _selectedEndTime = const TimeOfDay(hour: 23, minute: 59);
  int _guestCount = 1;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_selectedFlatMapping == null) {
      final authState = context.read<AuthBloc>().state;
      if (authState is AuthAuthenticated &&
          authState.user.flatMappings.isNotEmpty) {
        _selectedFlatMapping = authState.user.flatMappings.first;
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    _cabNoController.dispose();
    super.dispose();
  }

  void _nextStep() => setState(() => _currentStep++);
  void _prevStep() {
    if (_currentStep > 0) setState(() => _currentStep--);
  }

  void _submitInvite() {
    final authState = context.read<AuthBloc>().state;
    if (authState is! AuthAuthenticated) return;

    final user = authState.user;
    FlatMapping? flat = _selectedFlatMapping;

    debugPrint('=== _submitInvite DEBUG ===');
    debugPrint('Full UserModel JSON: ${user.toJson()}');
    debugPrint('Initial flat selection: $flat');
    debugPrint('User flat mappings count: ${user.flatMappings.length}');
    if (user.flatMappings.isNotEmpty) {
      debugPrint('First flat mapping: ${user.flatMappings.first.flatNumber}');
    }

    if (flat == null && user.flatMappings.isNotEmpty) {
      if (user.flatMappings.length == 1) {
        flat = user.flatMappings.first;
      }
    }

    if (flat == null) {
      AsmitaToast.show(
        context,
        message: 'Please select a flat.',
        type: AsmitaToastType.error,
      );
      return;
    }

    final bool isOnce = _tabController.index == 0;

    final combinedStartTime = DateTime(
      isOnce ? DateTime.now().year : _selectedDate.year,
      isOnce ? DateTime.now().month : _selectedDate.month,
      isOnce ? DateTime.now().day : _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );

    final combinedEndTime = DateTime(
      _selectedEndDate.year,
      _selectedEndDate.month,
      _selectedEndDate.day,
      _selectedEndTime.hour,
      _selectedEndTime.minute,
    );

    String? allowedDays;
    if (!isOnce) {
      if (_selectedDaysOfWeek == 'All days of Week') {
        allowedDays = 'Mon,Tue,Wed,Thu,Fri,Sat,Sun';
      } else if (_selectedDaysOfWeek == 'Weekdays (Mon-Fri)') {
        allowedDays = 'Mon,Tue,Wed,Thu,Fri';
      } else if (_selectedDaysOfWeek == 'Weekends (Sat-Sun)') {
        allowedDays = 'Sat,Sun';
      } else {
        final daysList = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
        List<String> selected = [];
        for (int i = 0; i < 7; i++) {
          if (_customDaysSelected[i]) selected.add(daysList[i]);
        }
        allowedDays = selected.join(',');
      }
    }

    final startTimeStr =
        '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}:00';
    final endTimeStr =
        '${_selectedEndTime.hour.toString().padLeft(2, '0')}:${_selectedEndTime.minute.toString().padLeft(2, '0')}:00';

    final payload = {
      'society_id': user.societyId,
      'tower_id': flat.towerId,
      'unit_id': flat.flatId,
      'resident_id': user.userId,
      'invite_type': _selectedCategory == 'Visiting Help'
          ? 'Guest'
          : _selectedCategory,
      'invite_sub_type': isOnce ? 'ONCE' : 'FREQUENT',
      'title': '$_selectedCategory Invite',
      'visitor_name': '', // Form doesn't have this field currently
      'mobile_number': '',
      'company_name': _selectedCategory == 'Guest'
          ? 'Guest'
          : (_selectedCategory == 'Cab' ? 'Cab' : _selectedCompany),
      'vehicle_number': _cabNoController.text.trim(),
      'purpose': _selectedCategory,
      'max_guest_count': _selectedCategory == 'Guest' ? _guestCount : 1,
      'valid_from': _selectedCategory == 'Guest'
          ? combinedStartTime.toIso8601String()
          : (isOnce
                ? DateTime.now().toIso8601String()
                : _selectedDate.toIso8601String()),
      'valid_to': _selectedCategory == 'Guest'
          ? (isOnce
                ? combinedStartTime
                      .add(const Duration(hours: 24))
                      .toIso8601String()
                : combinedEndTime.toIso8601String())
          : (isOnce
                ? DateTime.now()
                      .add(Duration(hours: _selectedDurationHours))
                      .toIso8601String()
                : _selectedDate
                      .add(const Duration(days: 180))
                      .toIso8601String()),
      'is_private': _selectedCategory == 'Cab'
          ? _secureCabMode
          : _surpriseDelivery,
      if (!isOnce && allowedDays != null) 'allowed_days': allowedDays,
      if (!isOnce) 'start_time': startTimeStr,
      if (!isOnce) 'end_time': endTimeStr,
    };

    context.read<VisitorBloc>().add(
      CreatePreApprovedInviteEvent(payload: payload),
    );
  }

  int _getMaxAllowedHours() {
    switch (_selectedCategory) {
      case 'Guest':
        return 24;
      case 'Visiting Help':
        return 12;
      case 'Cab':
      case 'Delivery':
      default:
        return 4;
    }
  }

  // Native Date Formatter
  String _formatDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month - 1]} ${date.day.toString().padLeft(2, '0')}, ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<VisitorBloc, VisitorState>(
      listener: (context, state) {
        if (state is VisitorCreateSuccess) {
          if (_selectedCategory == 'Cab' || _selectedCategory == 'Delivery') {
            setState(() {
              _currentStep = 2;
            });
          } else {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => InvitePassScreen(invite: state.invite),
              ),
            );
          }
        } else if (state is VisitorError) {
          AsmitaToast.show(
            context,
            message: state.message,
            type: AsmitaToastType.error,
          );
        }
      },
      builder: (context, state) {
        return Stack(
          children: [
            AnimatedSize(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOutCubic,
              alignment: Alignment.topCenter,
              child: Theme(
                data: Theme.of(context).copyWith(
                  scrollbarTheme: ScrollbarThemeData(
                    thumbColor: WidgetStateProperty.all(
                      Colors.grey.withValues(alpha: 0.2),
                    ),
                    thickness: WidgetStateProperty.all(3.0),
                    radius: const Radius.circular(10),
                  ),
                ),
                child: Scrollbar(
                  controller: _scrollController,
                  thumbVisibility: true,
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    physics: const ClampingScrollPhysics(),
                    child: Padding(
                      padding: const EdgeInsets.only(right: 4.0),
                      child: _buildCurrentStep(),
                    ),
                  ),
                ),
              ),
            ),
            if (state is VisitorLoading)
              Positioned.fill(
                child: Container(
                  color: Colors.white.withValues(alpha: 0.7),
                  child: const Center(child: CircularProgressIndicator()),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case 0:
        return _buildCategorySelection();
      case 1:
        return _buildCategoryWorkflowRouter();
      case 2:
        return _buildSuccessPass();
      default:
        return _buildCategorySelection();
    }
  }

  // =========================================================================
  // STEP 0: Category Grid + Banner
  // =========================================================================
  Widget _buildCategorySelection() {
    final categories = [
      {'label': 'Guest', 'icon': Icons.person_outline_rounded},
      {'label': 'Cab', 'icon': Icons.directions_car_outlined},
      {'label': 'Delivery', 'icon': Icons.delivery_dining_outlined},
      {'label': 'Visiting Help', 'icon': Icons.build_outlined},
    ];

    final authState = context.watch<AuthBloc>().state;
    UserModel? user;
    if (authState is AuthAuthenticated) {
      user = authState.user;
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (user != null && user.flatMappings.length > 1) ...[
          const Text(
            'Select Flat',
            style: TextStyle(
              fontFamily: 'Montserrat',
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AsmitaPalette.textDark,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              border: Border.all(color: AsmitaPalette.borderGrey),
              borderRadius: BorderRadius.circular(12),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<FlatMapping>(
                value: _selectedFlatMapping,
                isExpanded: true,
                icon: const Icon(
                  Icons.arrow_drop_down_rounded,
                  color: AsmitaPalette.deepNavy,
                ),
                items: user.flatMappings.map((flat) {
                  return DropdownMenuItem(
                    value: flat,
                    child: Text(
                      '${flat.towerName} - ${flat.flatNumber}',
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 14,
                      ),
                    ),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedFlatMapping = val);
                },
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
        const Text(
          'Allow Future Entries',
          style: TextStyle(
            fontFamily: 'Montserrat',
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AsmitaPalette.deepNavy,
          ),
        ),
        const SizedBox(height: 20),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 0.7,
          ),
          itemCount: categories.length,
          itemBuilder: (context, index) {
            final cat = categories[index];
            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedCategory = cat['label'] as String;
                  _selectedDurationHours = 1;
                  _selectedCompany = _selectedCategory == 'Cab' ? 'Uber' : 'Amazon';
                });
                _nextStep();
              },
              behavior: HitTestBehavior.opaque,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AsmitaPalette.borderGrey,
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(
                      cat['icon'] as IconData,
                      color: AsmitaPalette.deepNavy,
                      size: 28,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    cat['label'] as String,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AsmitaPalette.deepNavy,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF3F0FF),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'Safe Pickup Mode',
                          style: TextStyle(
                            fontFamily: 'Montserrat',
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF4A3498),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E88E5),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'NEW',
                            style: TextStyle(
                              fontFamily: 'Montserrat',
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'No need to share flat details with the cab driver or guard. Know more »',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 11,
                        color: Color(0xFF6B5DA8),
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              const Icon(
                Icons.shield_rounded,
                color: Color(0xFFB39DDB),
                size: 36,
              ),
            ],
          ),
        ),
      ],
    );
  }

  // =========================================================================
  // STEP 1: Form Router
  // =========================================================================
  Widget _buildCategoryWorkflowRouter() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            GestureDetector(
              onTap: _prevStep,
              behavior: HitTestBehavior.opaque,
              child: const Padding(
                padding: EdgeInsets.only(right: 12.0, top: 4.0, bottom: 4.0),
                child: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: 18,
                  color: AsmitaPalette.deepNavy,
                ),
              ),
            ),
            Expanded(
              child: Text(
                '$_selectedCategory Invitation',
                style: const TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AsmitaPalette.deepNavy,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // 2. Segmented Pill TabBar
        Container(
          height: 48,
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: AsmitaPalette.systemBG,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AsmitaPalette.borderGrey, width: 1.0),
          ),
          child: TabBar(
            controller: _tabController,
            dividerColor: Colors.transparent,
            indicatorSize: TabBarIndicatorSize.tab,
            indicator: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            labelColor: AsmitaPalette.actionRed,
            unselectedLabelColor: AsmitaPalette.textLight,
            labelStyle: const TextStyle(
              fontFamily: 'Montserrat',
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
            unselectedLabelStyle: const TextStyle(
              fontFamily: 'Montserrat',
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
            tabs: const [
              Tab(text: 'Once'),
              Tab(text: 'Frequently'),
            ],
          ),
        ),
        const SizedBox(height: 24),
        _tabController.index == 0
            ? _buildOnceTabPane()
            : _buildFrequentlyTabPane(),
      ],
    );
  }

  Widget _buildOnceTabPane() {
    return _buildOnceLayout();
  }

  Widget _buildFrequentlyTabPane() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildBottomSheetTrigger(
          label: 'Select Days of Week',
          value: _selectedDaysOfWeek,
          onTap: _showDaysOfWeekPickerSheet,
        ),
        const SizedBox(height: 16),
        _buildBottomSheetTrigger(
          label: 'Select Validity',
          value: _frequentValidity,
          onTap: _showValidityPickerSheet,
        ),
        const SizedBox(height: 16),
        const Text(
          'Select time slot',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 12,
            color: AsmitaPalette.textDark,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildBottomSheetTrigger(
                value: _selectedTime.format(context),
                onTap: () => _showTimePickerSheet(isEndTime: false),
                isPill: true,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildBottomSheetTrigger(
                value: _selectedEndTime.format(context),
                onTap: () => _showTimePickerSheet(isEndTime: true),
                isPill: true,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (_selectedCategory != 'Guest') ...[
          _buildBottomSheetTrigger(
            label: 'Company Name',
            value: _selectedCompany == 'Other' && _customCompanyName.isNotEmpty
                ? _customCompanyName
                : _selectedCompany,
            onTap: _showCompanySelectionSheet,
          ),
          const SizedBox(height: 24),
        ],
        if (_selectedCategory == 'Guest') ...[
          Row(
            children: [
              Expanded(
                child: _buildBottomSheetTrigger(
                  label: 'Arrival Date',
                  value: _formatDate(_selectedDate),
                  onTap: _showDatePickerSheet,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildBottomSheetTrigger(
                  label: 'Departure Date',
                  value: _formatDate(_selectedEndDate),
                  onTap: _showEndDatePickerSheet,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Number of Guests:',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AsmitaPalette.textDark,
                ),
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.remove_circle_outline,
                      color: AsmitaPalette.actionRed,
                    ),
                    onPressed: () {
                      if (_guestCount > 1) setState(() => _guestCount--);
                    },
                  ),
                  Text(
                    '$_guestCount',
                    style: const TextStyle(
                      fontFamily: 'Montserrat',
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.add_circle_outline,
                      color: AsmitaPalette.actionRed,
                    ),
                    onPressed: () {
                      if (_guestCount < 20) setState(() => _guestCount++);
                    },
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
        ],
        _buildPrimaryButton(label: 'Authorize Entry', onPressed: _submitInvite),
      ],
    );
  }

  Widget _buildOnceLayout() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // DYNAMIC FEATURE BLOCK: Surprise Delivery
        if (_selectedCategory == 'Delivery') ...[
          GestureDetector(
            onTap: () => setState(() => _surpriseDelivery = !_surpriseDelivery),
            behavior: HitTestBehavior.opaque,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF6F5FD),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.transparent),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    _surpriseDelivery
                        ? Icons.check_box_rounded
                        : Icons.check_box_outline_blank_rounded,
                    color: const Color(0xFF4A3498),
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Surprise Delivery',
                          style: TextStyle(
                            fontFamily: 'Montserrat',
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF2C1F5C),
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Prevents active entry alerts to other flat members.',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 11,
                            color: Color(0xFF6B5DA8),
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.card_giftcard_rounded,
                    color: Color(0xFFB39DDB),
                    size: 36,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],

        // DYNAMIC FEATURE BLOCK: Secure Cab Identity
        if (_selectedCategory == 'Cab') ...[
          _buildBottomSheetTrigger(
            label: 'Company Name',
            value: _selectedCompany == 'Other' && _customCompanyName.isNotEmpty
                ? _customCompanyName
                : _selectedCompany,
            onTap: _showCompanySelectionSheet,
          ),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: () => setState(() => _secureCabMode = !_secureCabMode),
            behavior: HitTestBehavior.opaque,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF6F5FD),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.transparent),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    _secureCabMode
                        ? Icons.check_box_rounded
                        : Icons.check_box_outline_blank_rounded,
                    color: const Color(0xFF4A3498),
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Safe Pickup Mode',
                          style: TextStyle(
                            fontFamily: 'Montserrat',
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF2C1F5C),
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Guard directs cab to nearest parking. Driver won\'t know flat details.',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 11,
                            color: Color(0xFF6B5DA8),
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.shield_rounded,
                    color: Color(0xFFB39DDB),
                    size: 36,
                  ),
                ],
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            child: _secureCabMode
                ? Padding(
                    padding: const EdgeInsets.only(top: 12.0),
                    child: TextField(
                      controller: _cabNoController,
                      textCapitalization: TextCapitalization.characters,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 13,
                      ),
                      decoration: const InputDecoration(
                        hintText: 'Enter Cab No. (e.g., MH 02 AB 1234)',
                        filled: true,
                        fillColor: AsmitaPalette.systemBG,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(12)),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
          const SizedBox(height: 20),
        ],

        if (_selectedCategory == 'Guest') ...[
          _buildBottomSheetTrigger(
            label: 'Arrival Time',
            value: _selectedTime.format(context),
            onTap: () => _showTimePickerSheet(),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Number of Guests:',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AsmitaPalette.textDark,
                ),
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.remove_circle_outline,
                      color: AsmitaPalette.actionRed,
                    ),
                    onPressed: () {
                      if (_guestCount > 1) setState(() => _guestCount--);
                    },
                  ),
                  Text(
                    '$_guestCount',
                    style: const TextStyle(
                      fontFamily: 'Montserrat',
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.add_circle_outline,
                      color: AsmitaPalette.actionRed,
                    ),
                    onPressed: () {
                      if (_guestCount < 20) setState(() => _guestCount++);
                    },
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
        ] else ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Allow entry once in next:',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AsmitaPalette.textDark,
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: 16.0),
                  child: _buildBottomSheetTrigger(
                    value:
                        '$_selectedDurationHours Hour${_selectedDurationHours > 1 ? 's' : ''}',
                    onTap: _showDurationPickerSheet,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(
            height: 12,
          ), // Adjusted bottom margin slightly to give breathing room to the accordion

          if (_selectedCategory != 'Cab') ...[
            GestureDetector(
              onTap: () =>
                  setState(() => _showAdvancedOptions = !_showAdvancedOptions),
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Advanced Options',
                      style: TextStyle(
                        fontFamily: 'Montserrat',
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AsmitaPalette.actionRed,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      _showAdvancedOptions
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                      color: AsmitaPalette.actionRed,
                      size: 22,
                    ),
                  ],
                ),
              ),
            ),

            AnimatedSize(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              child: _showAdvancedOptions
                  ? Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: () =>
                              setState(() => _leaveAtGate = !_leaveAtGate),
                          behavior: HitTestBehavior.opaque,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: Row(
                              children: [
                                Icon(
                                  _leaveAtGate
                                      ? Icons.check_box_rounded
                                      : Icons.check_box_outline_blank_rounded,
                                  color: _leaveAtGate
                                      ? AsmitaPalette.actionRed
                                      : Colors.grey.shade600,
                                  size: 22,
                                ),
                                const SizedBox(width: 12),
                                const Text(
                                  'Leave at Gate option auto-auth',
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 13,
                                    color: AsmitaPalette.textLight,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: _buildBottomSheetTrigger(
                                label: 'Arrival Date',
                                value: _formatDate(_selectedDate),
                                onTap: _showDatePickerSheet,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildBottomSheetTrigger(
                                label: 'Arrival Time',
                                value: _selectedTime.format(context),
                                onTap: () => _showTimePickerSheet(),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildBottomSheetTrigger(
                          label: 'Company Name',
                          value:
                              _selectedCompany == 'Other' &&
                                  _customCompanyName.isNotEmpty
                              ? _customCompanyName
                              : _selectedCompany,
                          onTap: _showCompanySelectionSheet,
                        ),
                      ],
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ],

        const SizedBox(height: 24),
        _buildPrimaryButton(label: 'Authorize Entry', onPressed: _submitInvite),
      ],
    );
  }

  // =========================================================================
  // STEP 2: Success Pane
  // =========================================================================
  Widget _buildSuccessPass() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            color: Color(0xFFE8F5E9),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.check_circle_rounded,
            color: Color(0xFF388E3C),
            size: 40,
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Gate Pass Authorized',
          style: TextStyle(
            fontFamily: 'Montserrat',
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AsmitaPalette.deepNavy,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'The security team has been notified.',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 13,
            color: AsmitaPalette.textLight,
          ),
        ),
        const SizedBox(height: 32),
        _buildPrimaryButton(
          label: 'Done',
          onPressed: () => Navigator.pop(context),
        ),
      ],
    );
  }

  // =========================================================================
  // FUNCTIONAL INTERACTIVE BOTTOM SHEETS
  // =========================================================================

  void _showDaysOfWeekPickerSheet() {
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    List<bool> tempSelected = List.from(_customDaysSelected);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Select Days of Week',
                        style: TextStyle(
                          fontFamily: 'Montserrat',
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AsmitaPalette.deepNavy,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.close,
                          color: AsmitaPalette.deepNavy,
                          size: 20,
                        ),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Quick Presets Row
                  Row(
                    children: [
                      ActionChip(
                        label: const Text(
                          'All',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AsmitaPalette.deepNavy,
                          ),
                        ),
                        backgroundColor: AsmitaPalette.systemBG,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: BorderSide.none,
                        ),
                        onPressed: () {
                          setModalState(() {
                            tempSelected = [
                              true,
                              true,
                              true,
                              true,
                              true,
                              true,
                              true,
                            ];
                          });
                        },
                      ),
                      const SizedBox(width: 8),
                      ActionChip(
                        label: const Text(
                          'Weekdays',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AsmitaPalette.deepNavy,
                          ),
                        ),
                        backgroundColor: AsmitaPalette.systemBG,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: BorderSide.none,
                        ),
                        onPressed: () {
                          setModalState(() {
                            tempSelected = [
                              true,
                              true,
                              true,
                              true,
                              true,
                              false,
                              false,
                            ];
                          });
                        },
                      ),
                      const SizedBox(width: 8),
                      ActionChip(
                        label: const Text(
                          'Weekends',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AsmitaPalette.deepNavy,
                          ),
                        ),
                        backgroundColor: AsmitaPalette.systemBG,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: BorderSide.none,
                        ),
                        onPressed: () {
                          setModalState(() {
                            tempSelected = [
                              false,
                              false,
                              false,
                              false,
                              false,
                              true,
                              true,
                            ];
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Alarm-Style Circular Selectors Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(7, (index) {
                      final dayLetter = days[index][0];
                      final isSelected = tempSelected[index];
                      return GestureDetector(
                        onTap: () {
                          setModalState(() {
                            tempSelected[index] = !tempSelected[index];
                          });
                        },
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isSelected
                                ? AsmitaPalette.actionRed
                                : AsmitaPalette.systemBG,
                            border: Border.all(
                              color: isSelected
                                  ? Colors.transparent
                                  : AsmitaPalette.borderGrey,
                              width: 1,
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            dayLetter,
                            style: TextStyle(
                              fontFamily: 'Montserrat',
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              color: isSelected
                                  ? Colors.white
                                  : AsmitaPalette.deepNavy,
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 32),
                  _buildPrimaryButton(
                    label: 'Confirm Days',
                    onPressed: () {
                      setState(() {
                        _customDaysSelected = List.from(tempSelected);
                        final selectedCount = tempSelected
                            .where((val) => val)
                            .length;
                        if (selectedCount == 7) {
                          _selectedDaysOfWeek = 'All days of Week';
                        } else if (selectedCount == 5 &&
                            tempSelected[0] &&
                            tempSelected[1] &&
                            tempSelected[2] &&
                            tempSelected[3] &&
                            tempSelected[4] &&
                            !tempSelected[5] &&
                            !tempSelected[6]) {
                          _selectedDaysOfWeek = 'Weekdays';
                        } else if (selectedCount == 2 &&
                            !tempSelected[0] &&
                            !tempSelected[1] &&
                            !tempSelected[2] &&
                            !tempSelected[3] &&
                            !tempSelected[4] &&
                            tempSelected[5] &&
                            tempSelected[6]) {
                          _selectedDaysOfWeek = 'Weekends';
                        } else if (selectedCount == 0) {
                          _selectedDaysOfWeek = 'None selected';
                        } else {
                          final selectedNames = <String>[];
                          for (int i = 0; i < 7; i++) {
                            if (tempSelected[i]) {
                              selectedNames.add(days[i]);
                            }
                          }
                          _selectedDaysOfWeek = selectedNames.join(', ');
                        }
                      });
                      Navigator.pop(ctx);
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showValidityPickerSheet() {
    final options = ['1 week', '1 month', '6 months'];
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Select Validity',
                style: TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AsmitaPalette.deepNavy,
                ),
              ),
              const SizedBox(height: 20),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: options.map((opt) {
                  final isSelected = _frequentValidity == opt;
                  return ChoiceChip(
                    label: Text(opt),
                    selected: isSelected,
                    checkmarkColor: Colors.white,
                    onSelected: (_) {
                      setState(() => _frequentValidity = opt);
                      Navigator.pop(ctx);
                    },
                    selectedColor: AsmitaPalette.actionRed,
                    backgroundColor: AsmitaPalette.systemBG,
                    labelStyle: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? Colors.white : AsmitaPalette.deepNavy,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: BorderSide(
                        color: isSelected
                            ? Colors.transparent
                            : AsmitaPalette.borderGrey,
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  void _showDurationPickerSheet() {
    final allowedHours = [1, 2, 4, 6, 12, 18, 24];
    final maxLimit = _getMaxAllowedHours();
    final validOptions = allowedHours.where((h) => h <= maxLimit).toList();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Select Validity Duration',
                style: TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AsmitaPalette.deepNavy,
                ),
              ),
              const SizedBox(height: 20),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: validOptions.map((hours) {
                  final isSelected = _selectedDurationHours == hours;
                  return ChoiceChip(
                    label: Text('$hours Hour${hours > 1 ? 's' : ''}'),
                    selected: isSelected,
                    checkmarkColor: Colors.white,
                    onSelected: (_) {
                      setState(() => _selectedDurationHours = hours);
                      Navigator.pop(ctx);
                    },
                    selectedColor: AsmitaPalette.actionRed,
                    backgroundColor: AsmitaPalette.systemBG,
                    labelStyle: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? Colors.white : AsmitaPalette.deepNavy,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: BorderSide(
                        color: isSelected
                            ? Colors.transparent
                            : AsmitaPalette.borderGrey,
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  void _showDatePickerSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CalendarDatePicker(
                initialDate: _selectedDate,
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 365)),
                onDateChanged: (date) {
                  setState(() => _selectedDate = date);
                  Navigator.pop(ctx);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showEndDatePickerSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CalendarDatePicker(
                initialDate: _selectedEndDate.isBefore(_selectedDate)
                    ? _selectedDate
                    : _selectedEndDate,
                firstDate: _selectedDate,
                lastDate: _selectedDate.add(const Duration(days: 365)),
                onDateChanged: (date) {
                  setState(() => _selectedEndDate = date);
                  Navigator.pop(ctx);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showTimePickerSheet({bool isEndTime = false}) {
    TimeOfDay initialTime = isEndTime ? _selectedEndTime : _selectedTime;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                isEndTime ? 'Select End Time' : 'Select Arrival Time',
                style: const TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AsmitaPalette.deepNavy,
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 180,
                child: CupertinoDatePicker(
                  mode: CupertinoDatePickerMode.time,
                  initialDateTime: DateTime(
                    2026,
                    1,
                    1,
                    initialTime.hour,
                    initialTime.minute,
                  ),
                  onDateTimeChanged: (time) {
                    setState(() {
                      if (isEndTime) {
                        _selectedEndTime = TimeOfDay.fromDateTime(time);
                      } else {
                        _selectedTime = TimeOfDay.fromDateTime(time);
                      }
                    });
                  },
                ),
              ),
              const SizedBox(height: 16),
              _buildPrimaryButton(
                label: 'Done',
                onPressed: () => Navigator.pop(ctx),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCompanySelectionSheet() {
    String tempSelected = _selectedCompany;
    TextEditingController tempController = TextEditingController(
      text: _customCompanyName,
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          final companyLogos = {
            'Airtel': 'assets/images/logos/airtel.png',
            'Ajio': 'assets/images/logos/ajio.png',
            'Akshayakalpa Organic':
                'assets/images/logos/akshayakalpa organic.png',
            'Amazon': 'assets/images/logos/amazon.png',
            'Amazon Prime Now': 'assets/images/logos/Amazon Prime Now.png',
            'Apollo 24-7': 'assets/images/logos/Apollo 24-7.png',
            'Bharat Gas': 'assets/images/logos/Bharat Gas.png',
            'Big Basket': 'assets/images/logos/Big Basket.png',
            'Blinkit': 'assets/images/logos/Blinkit.png',
            'Blue Dart': 'assets/images/logos/Blue Dart.png',
            'Borzo': 'assets/images/logos/Borzo.png',
            'Box8': 'assets/images/logos/Box8.png',
            'Country Delight': 'assets/images/logos/Country Delight.png',
            'Delhivery': 'assets/images/logos/Delhivery.png',
            'DHL': 'assets/images/logos/DHL.png',
            'Dmart': 'assets/images/logos/Dmart.png',
            'Domino\'s': 'assets/images/logos/Domino\'s.png',
            'DTDC': 'assets/images/logos/DTDC.png',
            'Eat Club': 'assets/images/logos/eat club.png',
            'Eatfit': 'assets/images/logos/eatfit.png',
            'Ecom Express': 'assets/images/logos/ecom express.png',
            'Ekart': 'assets/images/logos/ekart.png',
            'Expressbees': 'assets/images/logos/expressbees.png',
            'Faasos': 'assets/images/logos/faasos.png',
            'Fedex': 'assets/images/logos/fedex.png',
            'Firstcry': 'assets/images/logos/firstcry.png',
            'Flipkart': 'assets/images/logos/flipkart.png',
            'Fresh Menu': 'assets/images/logos/fresh menu.png',
            'Fresh to Home': 'assets/images/logos/fresh to home.png',
            'Gati': 'assets/images/logos/gati.png',
            'HDFC Bank': 'assets/images/logos/hdfc bank.png',
            'HP Gas': 'assets/images/logos/hp gas.png',
            'Ikea': 'assets/images/logos/ikea.png',
            'Indane': 'assets/images/logos/indane.png',
            'India Post': 'assets/images/logos/India post.png',
            'Jio': 'assets/images/logos/jio.png',
            'JioMart': 'assets/images/logos/jiomart.png',
            'Lenskart': 'assets/images/logos/lenskart.png',
            'Licious': 'assets/images/logos/licious.png',
            'Meesho': 'assets/images/logos/meesho.png',
            'Milk Basket': 'assets/images/logos/milk basket.png',
            'Myntra': 'assets/images/logos/myntra.png',
            'Natures Basket': 'assets/images/logos/natures basket.png',
            'Netmeds': 'assets/images/logos/netmeds.png',
            'Nykaa': 'assets/images/logos/nykaa.png',
            'Ola': 'assets/images/logos/Ola.png',
            'Other': 'assets/images/logos/Other.png',
            'Paytm': 'assets/images/logos/paytm.png',
            'Pepperfry': 'assets/images/logos/pepperfry.png',
            'Pharmeasy': 'assets/images/logos/pharmeasy.png',
            'Pizza Hut': 'assets/images/logos/pizza hut.png',
            'Porter': 'assets/images/logos/porter.png',
            'Professional Courier':
                'assets/images/logos/professional courier.png',
            'Rapido': 'assets/images/logos/Rapido.png',
            'Shadowfax': 'assets/images/logos/shadowfax.png',
            'Shiprocket': 'assets/images/logos/shiprocket.png',
            'Snabbit': 'assets/images/logos/snabbit.png',
            'Snapdeal': 'assets/images/logos/snapdeal.png',
            'Swiggy': 'assets/images/logos/swiggy.png',
            'Swiggy Instamart': 'assets/images/logos/swiggy instamart.png',
            'Tata 1mg': 'assets/images/logos/tata 1mg.png',
            'Tata Play': 'assets/images/logos/tata play.png',
            'Uber': 'assets/images/logos/uber.png',
            'Urban Company': 'assets/images/logos/urban company.png',
            'Zepto': 'assets/images/logos/zepto.png',
            'Zomato': 'assets/images/logos/zomato.png',
          };

          final cabCompanies = ['Uber', 'Ola', 'Rapido', 'Other'];
          final List<String> companies;
          
          if (_selectedCategory == 'Cab') {
            companies = cabCompanies;
          } else {
            companies = [...companyLogos.keys.where((c) => !cabCompanies.contains(c)), 'Other'];
          }
          return Padding(
            padding: EdgeInsets.only(
              bottom:
                  MediaQuery.of(ctx).viewInsets.bottom +
                  MediaQuery.of(ctx).padding.bottom +
                  24,
              left: 20,
              right: 20,
              top: 24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Company Network',
                      style: TextStyle(
                        fontFamily: 'Montserrat',
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AsmitaPalette.deepNavy,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Flexible(
                  child: SingleChildScrollView(
                    physics: const ClampingScrollPhysics(),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 4,
                                mainAxisSpacing: 10,
                                crossAxisSpacing: 10,
                                childAspectRatio: 0.80,
                              ),
                          itemCount: companies.length,
                          itemBuilder: (context, i) {
                            final c = companies[i];
                            final isSel = tempSelected == c;

                            return GestureDetector(
                              onTap: () =>
                                  setModalState(() => tempSelected = c),
                              behavior: HitTestBehavior.opaque,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: isSel
                                      ? AsmitaPalette.deepNavy.withValues(
                                          alpha: 0.05,
                                        )
                                      : Colors.white,
                                  border: Border.all(
                                    color: isSel
                                        ? AsmitaPalette.deepNavy
                                        : AsmitaPalette.borderGrey,
                                    width: isSel ? 1.5 : 1.0,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      width: 60,
                                      height: 60,
                                      decoration: BoxDecoration(
                                        color: AsmitaPalette.systemBG,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      clipBehavior: Clip.hardEdge,
                                      child: companyLogos.containsKey(c)
                                          ? Image.asset(
                                              companyLogos[c]!,
                                              fit: BoxFit.cover,
                                              errorBuilder:
                                                  (
                                                    context,
                                                    error,
                                                    stackTrace,
                                                  ) => Center(
                                                    child: Text(
                                                      c[0],
                                                      style: const TextStyle(
                                                        fontFamily:
                                                            'Montserrat',
                                                        fontWeight:
                                                            FontWeight.w800,
                                                        fontSize: 18,
                                                        color: AsmitaPalette
                                                            .deepNavy,
                                                      ),
                                                    ),
                                                  ),
                                            )
                                          : Center(
                                              child: Text(
                                                c[0],
                                                style: const TextStyle(
                                                  fontFamily: 'Montserrat',
                                                  fontWeight: FontWeight.w800,
                                                  fontSize: 18,
                                                  color: AsmitaPalette.deepNavy,
                                                ),
                                              ),
                                            ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      c,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontFamily: 'Poppins',
                                        fontSize: 10,
                                        fontWeight: isSel
                                            ? FontWeight.w700
                                            : FontWeight.w500,
                                        color: isSel
                                            ? AsmitaPalette.deepNavy
                                            : AsmitaPalette.textDark,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                        if (tempSelected == 'Other')
                          Padding(
                            padding: const EdgeInsets.only(top: 16),
                            child: TextField(
                              controller: tempController,
                              style: const TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 13,
                              ),
                              decoration: const InputDecoration(
                                hintText: 'Enter company name',
                                filled: true,
                                fillColor: AsmitaPalette.systemBG,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.all(
                                    Radius.circular(12),
                                  ),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                _buildPrimaryButton(
                  label: 'Confirm Selection',
                  onPressed: () {
                    setState(() {
                      _selectedCompany = tempSelected;
                      _customCompanyName = tempController.text.trim();
                    });
                    Navigator.pop(ctx);
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildBottomSheetTrigger({
    String? label,
    required String value,
    required VoidCallback onTap,
    bool isPill = false,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (label != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 6.0),
            child: Text(
              label,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 12,
                color: AsmitaPalette.textDark,
              ),
            ),
          ),
        GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: AsmitaPalette.borderGrey, width: 1.2),
              borderRadius: BorderRadius.circular(isPill ? 24 : 12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AsmitaPalette.deepNavy,
                    ),
                  ),
                ),
                const Icon(
                  Icons.arrow_drop_down_rounded,
                  color: AsmitaPalette.deepNavy,
                  size: 24,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPrimaryButton({
    required String label,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AsmitaPalette.actionRed,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontFamily: 'Montserrat',
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 15,
          ),
        ),
      ),
    );
  }
}
