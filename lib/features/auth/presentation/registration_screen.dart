import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/di/injection_container.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/security/secure_storage_service.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_skeleton.dart';
import '../../../core/widgets/asmita_toast.dart';
import '../../../core/widgets/asmita_bottom_sheet.dart';
import '../../../core/navigation/app_transitions.dart';
import '../../../core/constants/design_system.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';
import '../data/repositories/auth_repository.dart';
import '../data/repositories/property_repository.dart';
import '../data/models/invite_token_info.dart';
import '../data/models/property_models.dart';
import '../../dashboard/presentation/main_dashboard_screen.dart';
import 'approval_pending_screen.dart';

class RegistrationScreen extends StatefulWidget {
  final String? verifiedMobile;
  final String? inviteToken;
  final AuthRepository? authRepository;
  final PropertyRepository? propertyRepository;

  const RegistrationScreen({
    super.key,
    this.verifiedMobile,
    this.inviteToken,
    this.authRepository,
    this.propertyRepository,
  });

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final PageController _pageController = PageController();
  int _currentStep = 0;
  final int _totalSteps = 2;

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _mobileController = TextEditingController();
  
  PropertyItem? _selectedSociety;
  PropertyItem? _selectedTower;
  PropertyItem? _selectedFloor;
  PropertyItem? _selectedFlat;
  String? _selectedRole;
  String? _selectedGender;
  
  File? _profileImage;
  final ImagePicker _picker = ImagePicker();

  late final PropertyRepository _propertyRepo = widget.propertyRepository ??
      (sl.isRegistered<PropertyRepository>()
          ? sl<PropertyRepository>()
          : PropertyRepository());
  late final AuthRepository _authRepo;
  bool _isLoadingProperties = false;
  bool _isLoadingInvite = false;
  String? _inviteError;
  bool _isInviteLocked = false;
  bool _recipientPhoneProvided = false;
  int? _departmentId;
  String? _departmentName;

  List<PropertyItem> _societies = [];
  List<PropertyItem> _towers = [];
  List<PropertyItem> _floors = [];
  List<PropertyItem> _flats = [];

  bool get _isCorporate =>
      _departmentId != null ||
      (_selectedRole != null &&
          _selectedRole != 'Owner' &&
          _selectedRole != 'Tenant');

  bool get _isMobileLocked =>
      (widget.verifiedMobile != null && widget.verifiedMobile!.isNotEmpty) ||
      (_isInviteLocked && _recipientPhoneProvided);

  @override
  void initState() {
    super.initState();
    if (widget.authRepository != null) {
      _authRepo = widget.authRepository!;
    } else if (sl.isRegistered<AuthRepository>()) {
      _authRepo = sl<AuthRepository>();
    } else {
      _authRepo = AuthRepository(dio: AsmitaDioClient(SecureStorageService()).dio);
    }

    if (widget.verifiedMobile != null && widget.verifiedMobile!.isNotEmpty) {
      _mobileController.text = widget.verifiedMobile!;
    }

    if (widget.inviteToken != null && widget.inviteToken!.isNotEmpty) {
      _resolveInviteToken(widget.inviteToken!);
    } else {
      _fetchSocieties();
    }
  }

  Future<void> _resolveInviteToken(String token) async {
    setState(() {
      _isLoadingInvite = true;
      _inviteError = null;
    });
    try {
      final InviteTokenInfo info = await _authRepo.getInviteTokenInfo(token);
      if (!mounted) return;
      setState(() {
        _isLoadingInvite = false;
        _isInviteLocked = true;
        _selectedSociety = PropertyItem(id: info.societyId, name: info.societyName);
        _departmentId = info.departmentId;
        _departmentName = info.departmentName;
        _selectedRole = info.targetRole;

        if (info.recipientPhone != null && info.recipientPhone!.isNotEmpty) {
          _mobileController.text = info.recipientPhone!;
          _recipientPhoneProvided = true;
        }
        if (info.recipientName != null && info.recipientName!.isNotEmpty) {
          _nameController.text = info.recipientName!;
        }
        if (info.recipientEmail != null && info.recipientEmail!.isNotEmpty) {
          _emailController.text = info.recipientEmail!;
        }
        if (info.recipientGender != null && info.recipientGender!.isNotEmpty) {
          _selectedGender = info.recipientGender!;
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoadingInvite = false;
        _inviteError = e.toString().replaceFirst('Exception: ', '');
      });
      _fetchSocieties();
      AsmitaToast.show(
        context,
        message: _inviteError ?? 'Failed to resolve invite token',
        type: AsmitaToastType.error,
      );
    }
  }

  Future<void> _fetchSocieties() async {
    setState(() => _isLoadingProperties = true);
    final data = await _propertyRepo.getSocieties();
    if (!mounted) return;
    setState(() {
      _societies = data;
      _isLoadingProperties = false;
    });
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (!mounted) return;
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
    if (!mounted) return;
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
    if (!mounted) return;
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
    if (!mounted) return;
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
    _mobileController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep == 0) {
      if (_isCorporate) {
        if (_selectedSociety == null || _selectedRole == null) {
          AsmitaToast.show(
            context,
            message: 'Please fill all society details to proceed.',
            type: AsmitaToastType.error,
          );
          return;
        }
      } else {
        if (_selectedSociety == null ||
            _selectedTower == null ||
            _selectedFloor == null ||
            _selectedFlat == null ||
            _selectedRole == null) {
          AsmitaToast.show(
            context,
            message: 'Please fill all society details to proceed.',
            type: AsmitaToastType.error,
          );
          return;
        }
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
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final mobile = _mobileController.text.trim();

    if (name.isEmpty || email.isEmpty || mobile.isEmpty || _selectedGender == null) {
      AsmitaToast.show(
        context,
        message: 'Please fill in all required fields to continue.',
        type: AsmitaToastType.error,
      );
      return;
    }

    if (mobile.length != 10 || !RegExp(r'^[0-9]{10}$').hasMatch(mobile)) {
      AsmitaToast.show(
        context,
        message: 'Please enter a valid 10-digit mobile number.',
        type: AsmitaToastType.error,
      );
      return;
    }

    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
      AsmitaToast.show(
        context,
        message: 'Please enter a valid email address.',
        type: AsmitaToastType.error,
      );
      return;
    }

    if (_isInviteLocked && _profileImage == null) {
      AsmitaToast.show(
        context,
        message: 'Please upload your profile photo to complete registration.',
        type: AsmitaToastType.info,
      );
      return;
    }

    final bool isFromInvite = (widget.inviteToken != null && widget.inviteToken!.isNotEmpty) || _isInviteLocked;

    if (isFromInvite) {
      _promptInviteOtpVerification(
        mobile: mobile,
        name: name,
        email: email,
      );
      return;
    }

    context.read<AuthBloc>().add(AuthRegisterRequested(
      mobile: mobile,
      fullName: name,
      email: email,
      gender: _selectedGender!,
      society: _selectedSociety?.id.toString() ?? '',
      tower: _selectedTower?.id.toString() ?? '',
      floor: _selectedFloor?.id.toString() ?? '',
      flat: _selectedFlat?.id.toString() ?? '',
      role: _selectedRole?.toLowerCase() ?? 'resident',
      profilePicture: _profileImage,
    ));
  }

  Future<void> _promptInviteOtpVerification({
    required String mobile,
    required String name,
    required String email,
  }) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(color: Color(0xFFE21F26)),
      ),
    );

    try {
      await _authRepo.initiateLogin(mobile);
      if (!mounted) return;
      Navigator.pop(context); // Close loading dialog
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      AsmitaToast.show(
        context,
        message: 'Unable to send verification OTP: ${e.toString().replaceAll("Exception: ", "")}',
        type: AsmitaToastType.error,
      );
      return;
    }

    if (!mounted) return;

    AsmitaToast.show(
      context,
      message: 'OTP sent to +91 $mobile. Please enter code to verify.',
      type: AsmitaToastType.success,
    );

    _showInviteOtpSheet(
      mobile: mobile,
      name: name,
      email: email,
    );
  }

  void _showInviteOtpSheet({
    required String mobile,
    required String name,
    required String email,
  }) {
    final otpController = TextEditingController();
    int countdown = 30;
    bool isResending = false;
    Timer? timer;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            timer ??= Timer.periodic(const Duration(seconds: 1), (t) {
              if (countdown > 0) {
                setSheetState(() => countdown--);
              } else {
                t.cancel();
              }
            });

            final isDark = Theme.of(context).brightness == Brightness.dark;
            final bg = isDark ? AsmitaPalette.surfaceDark : Colors.white;
            final textMain = isDark ? AsmitaPalette.textDarkModeMain : Colors.black87;
            final textMuted = isDark ? AsmitaPalette.textDarkModeMuted : Colors.black54;

            return Container(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 24,
                bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 24,
              ),
              decoration: BoxDecoration(
                color: bg,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE21F26).withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.shield_outlined, color: Color(0xFFE21F26), size: 24),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Verify Identity',
                              style: TextStyle(
                                fontFamily: 'Montserrat',
                                fontWeight: FontWeight.w700,
                                fontSize: 18,
                                color: textMain,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Enter code sent to +91 $mobile',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 13,
                                color: textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Container(
                    decoration: BoxDecoration(
                      color: isDark ? AsmitaPalette.surfaceElevatedDark : const Color(0xFFF5F6FA),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: isDark ? AsmitaPalette.borderGreyDark : Colors.grey.shade200),
                    ),
                    child: TextField(
                      controller: otpController,
                      autofocus: true,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      maxLength: 6,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      buildCounter: (_, {required currentLength, required isFocused, maxLength}) => null,
                      style: const TextStyle(
                        fontFamily: 'Montserrat',
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 12,
                      ),
                      decoration: const InputDecoration(
                        hintText: '------',
                        hintStyle: TextStyle(
                          letterSpacing: 12,
                          color: Colors.black26,
                        ),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 16),
                      ),
                      onChanged: (val) {
                        if (val.length == 6) {
                          timer?.cancel();
                          Navigator.pop(sheetContext);
                          this.context.read<AuthBloc>().add(AuthRegisterRequested(
                            mobile: mobile,
                            fullName: name,
                            email: email,
                            gender: _selectedGender!,
                            society: _selectedSociety?.id.toString() ?? '',
                            tower: _selectedTower?.id.toString() ?? '',
                            floor: _selectedFloor?.id.toString() ?? '',
                            flat: _selectedFlat?.id.toString() ?? '',
                            role: _selectedRole?.toLowerCase() ?? 'resident',
                            profilePicture: _profileImage,
                            inviteToken: widget.inviteToken,
                            otp: val.trim(),
                          ));
                        }
                      },
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        countdown > 0 ? 'Resend OTP in ${countdown}s' : 'Didn\'t receive code?',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 12,
                          color: textMuted,
                        ),
                      ),
                      TextButton(
                        onPressed: isResending || countdown > 0
                            ? null
                            : () async {
                                setSheetState(() => isResending = true);
                                try {
                                  await _authRepo.initiateLogin(mobile);
                                  if (!sheetContext.mounted) return;
                                  timer?.cancel();
                                  setSheetState(() {
                                    countdown = 30;
                                    isResending = false;
                                  });
                                  timer = Timer.periodic(const Duration(seconds: 1), (t) {
                                    if (countdown > 0) {
                                      setSheetState(() => countdown--);
                                    } else {
                                      t.cancel();
                                    }
                                  });
                                  AsmitaToast.show(
                                    sheetContext,
                                    message: 'New OTP dispatched to +91 $mobile',
                                    type: AsmitaToastType.success,
                                  );
                                } catch (e) {
                                  if (!sheetContext.mounted) return;
                                  setSheetState(() => isResending = false);
                                  AsmitaToast.show(
                                    sheetContext,
                                    message: 'Failed to resend: ${e.toString().replaceAll("Exception: ", "")}',
                                    type: AsmitaToastType.error,
                                  );
                                }
                              },
                        child: Text(
                          'Resend',
                          style: TextStyle(
                            fontFamily: 'Montserrat',
                            fontWeight: FontWeight.w700,
                            color: countdown == 0 ? const Color(0xFFE21F26) : Colors.grey,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () {
                      final enteredOtp = otpController.text.trim();
                      if (enteredOtp.length != 6) {
                        AsmitaToast.show(
                          context,
                          message: 'Please enter a valid 6-digit OTP.',
                          type: AsmitaToastType.error,
                        );
                        return;
                      }
                      timer?.cancel();
                      Navigator.pop(sheetContext);
                      this.context.read<AuthBloc>().add(AuthRegisterRequested(
                        mobile: mobile,
                        fullName: name,
                        email: email,
                        gender: _selectedGender!,
                        society: _selectedSociety?.id.toString() ?? '',
                        tower: _selectedTower?.id.toString() ?? '',
                        floor: _selectedFloor?.id.toString() ?? '',
                        flat: _selectedFlat?.id.toString() ?? '',
                        role: _selectedRole?.toLowerCase() ?? 'resident',
                        profilePicture: _profileImage,
                        inviteToken: widget.inviteToken,
                        otp: enteredOtp,
                      ));
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE21F26),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      'Verify & Activate',
                      style: TextStyle(
                        fontFamily: 'Montserrat',
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    ).whenComplete(() {
      timer?.cancel();
    });
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
          final isDark = Theme.of(context).brightness == Brightness.dark;
          final cardBg = isDark ? AsmitaPalette.surfaceDark : Colors.white;
          final textPrimaryColor = isDark ? AsmitaPalette.textDarkModeMain : Colors.black87;
          final textMutedColor = isDark ? AsmitaPalette.textDarkModeMuted : Colors.black38;
          final borderColor = isDark ? AsmitaPalette.borderGreyDark : Colors.grey.shade300;
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
                      prefixIcon: Icon(Icons.search_rounded, color: Theme.of(context).iconTheme.color),
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
                        borderSide: BorderSide(color: Theme.of(context).colorScheme.primary),
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
                  Flexible(
                    child: filteredItems.isEmpty
                        ? Center(
                            child: Text(
                              'No matching results found',
                              style: TextStyle(fontFamily: 'Poppins', color: textMutedColor),
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
                                        color: isSelected ? const Color(0xFFE21F26).withValues(alpha: 0.1) : cardBg,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: isSelected ? const Color(0xFFE21F26) : borderColor,
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
                                          color: isSelected ? const Color(0xFFE21F26) : textPrimaryColor,
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
                                separatorBuilder: (context, index) => Divider(height: 1, color: isDark ? AsmitaPalette.borderGreyDark : Colors.black12),
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
                                        color: isSelected ? const Color(0xFFE21F26) : textPrimaryColor,
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

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.paddingOf(context).top;
    final bottomPadding = MediaQuery.paddingOf(context).bottom;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.primary,
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthAuthenticated) {
            AsmitaToast.show(
              context,
              message: 'Registration complete! Welcome to AsmitA.',
              type: AsmitaToastType.success,
            );
            if (Navigator.canPop(context)) {
              Navigator.popUntil(context, (route) => route.isFirst);
            } else {
              Navigator.pushReplacement(
                context,
                AsmitaPageTransitions.adaptiveRoute(
                  builder: (_) => MainDashboardScreen(userRole: state.sessionRole),
                ),
              );
            }
          } else if (state is AuthError) {
            AsmitaToast.show(
              context,
              message: state.message,
              type: AsmitaToastType.error,
            );
          } else if (state is AuthPendingApproval) {
            final effectiveMobile = _mobileController.text.trim().isNotEmpty
                ? _mobileController.text.trim()
                : (widget.verifiedMobile ?? '');
            Navigator.pushAndRemoveUntil(
              context,
              AsmitaPageTransitions.adaptiveRoute(builder: (_) => ApprovalPendingScreen(mobile: effectiveMobile)),
              (route) => false,
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
                      color: isDark ? Theme.of(context).scaffoldBackgroundColor : const Color(0xFFF8F8FB),
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
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
            style: TextStyle(
              fontFamily: 'Montserrat',
              color: Theme.of(context).textTheme.titleLarge?.color,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      physics: const ClampingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Society Details', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800, fontFamily: 'Montserrat', fontSize: 26)),
          const SizedBox(height: 6),
          Text('Link your multi-step infrastructure setup profiles.', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade600, fontFamily: 'Poppins')),
          const SizedBox(height: 28),
          if (_isLoadingProperties || _isLoadingInvite)
            const Padding(
              padding: EdgeInsets.only(bottom: 20),
              child: LinearProgressIndicator(color: Color(0xFFE21F26)),
            ),
          if (_isInviteLocked)
            Container(
              margin: const EdgeInsets.only(bottom: 20),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF2E7D32).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF2E7D32).withValues(alpha: 0.25)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Color(0xFF2E7D32),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.check, color: Colors.white, size: 14),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Verified Invitation',
                          style: TextStyle(
                            fontFamily: 'Montserrat',
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF2E7D32),
                          ),
                        ),
                        Text(
                          'Organization & role details locked by invite',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 11,
                            color: Color(0xFF2E7D32),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.lock_rounded, color: Color(0xFF2E7D32), size: 18),
                ],
              ),
            ),
          if (_inviteError != null)
            Container(
              margin: const EdgeInsets.only(bottom: 20),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFE21F26).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE21F26).withValues(alpha: 0.25)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline_rounded, color: Color(0xFFE21F26), size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _inviteError!,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12,
                        color: Color(0xFFE21F26),
                      ),
                    ),
                  ),
                  if (widget.inviteToken != null)
                    TextButton(
                      onPressed: () => _resolveInviteToken(widget.inviteToken!),
                      child: const Text('Retry', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFFE21F26))),
                    ),
                ],
              ),
            ),
          Container(
            decoration: BoxDecoration(
              color: isDark ? AsmitaPalette.surfaceDark : Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
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
                    icon: Icons.domain_rounded,
                    iconBackgroundColor: Colors.blue.shade500,
                    isLocked: _isInviteLocked,
                    onTap: () {
                      _showSearchableBottomSheet(
                        title: 'Society Name',
                        items: _societies,
                        currentValue: _selectedSociety,
                        onSelected: (val) {
                          _onSocietySelected(val);
                        },
                      );
                    },
                  ),
                  if (_departmentName != null || _departmentId != null)
                    _buildIOSListTile(
                      label: 'Department',
                      value: _departmentName ?? 'Department #$_departmentId',
                      hint: 'Assigned Department',
                      icon: Icons.corporate_fare_rounded,
                      iconBackgroundColor: Colors.teal.shade600,
                      isLocked: true,
                      onTap: () {},
                    ),
                  if (_isCorporate)
                    _buildIOSListTile(
                      label: 'Workplace',
                      value: 'Corporate Campus',
                      hint: 'Corporate Campus',
                      icon: Icons.business_center_rounded,
                      iconBackgroundColor: Colors.indigo.shade500,
                      isLocked: true,
                      onTap: () {},
                    )
                  else ...[
                    _buildIOSListTile(
                      label: 'Tower',
                      value: _selectedTower?.name,
                      hint: 'Select Tower',
                      icon: Icons.business_rounded,
                      iconBackgroundColor: Colors.indigo.shade400,
                      isDisabled: _selectedSociety == null,
                      isLoading: _towers.isEmpty && _isLoadingProperties,
                      onTap: () {
                        _showSearchableBottomSheet(
                          title: 'Tower',
                          items: _towers,
                          currentValue: _selectedTower,
                          useGrid: true,
                          onSelected: (val) {
                            _onTowerSelected(val);
                          },
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
                          onSelected: (val) {
                            _onFloorSelected(val);
                          },
                        );
                      },
                    ),
                    _buildIOSListTile(
                      label: 'Flat No.',
                      value: _selectedFlat?.name,
                      hint: 'Select Flat',
                      icon: Icons.door_front_door_rounded,
                      iconBackgroundColor: Colors.teal.shade500,
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
                  ],
                  _buildIOSListTile(
                    label: 'I am a',
                    value: _selectedRole,
                    hint: 'Owner / Tenant',
                    icon: Icons.person_rounded,
                    iconBackgroundColor: Colors.orange.shade500,
                    showDivider: false,
                    isLocked: _isInviteLocked,
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
          const SizedBox(height: 24),
          _buildBottomNavigation(bottomPadding),
        ],
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
    bool isLocked = false,
    bool showDivider = true,
  }) {
    final effectivelyDisabled = isDisabled || isLocked;
    return InkWell(
      onTap: effectivelyDisabled || isLoading ? null : onTap,
      child: Opacity(
        opacity: isDisabled && !isLocked ? 0.4 : 1.0,
        child: Container(
          color: Colors.transparent,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: iconBackgroundColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(icon, color: Colors.white, size: 18),
                    ),
                    const SizedBox(width: 14),
                    Text(
                      label,
                      style: TextStyle(
                        fontFamily: 'Montserrat',
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).textTheme.titleMedium?.color,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: isLoading
                          ? Align(
                              alignment: Alignment.centerRight,
                              child: AsmitaSkeleton.bone(
                                width: 70,
                                height: 16,
                                borderRadius: 4,
                              ),
                            )
                          : Text(
                              value ?? hint,
                              textAlign: TextAlign.right,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 15,
                                color: value != null
                                    ? (Theme.of(context).brightness == Brightness.dark ? AsmitaPalette.textDarkModeMain : Colors.black87)
                                    : (Theme.of(context).brightness == Brightness.dark ? AsmitaPalette.textDarkModeMuted : Colors.black38),
                                fontWeight: isLocked ? FontWeight.w600 : FontWeight.normal,
                              ),
                            ),
                    ),
                    const SizedBox(width: 8),
                    if (isLocked)
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Theme.of(context).brightness == Brightness.dark ? AsmitaPalette.borderGreyDark : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Icon(Icons.lock_rounded, color: Theme.of(context).brightness == Brightness.dark ? AsmitaPalette.textDarkModeMuted : Colors.grey.shade600, size: 16),
                      )
                    else
                      Icon(Icons.chevron_right_rounded, color: Theme.of(context).brightness == Brightness.dark ? AsmitaPalette.textDarkModeMuted : Colors.black26, size: 20),
                  ],
                ),
              ),
              if (showDivider)
                Divider(height: 1, thickness: 1, indent: 52, color: Theme.of(context).brightness == Brightness.dark ? AsmitaPalette.borderGreyDark : const Color(0xFFF0F0F0)),
            ],
          ),
        ),
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
          Text('Personal Details', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800, fontFamily: 'Montserrat', fontSize: 26)),
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
          _buildTextField(
            'Full Name',
            Icons.person_outline_rounded,
            'Enter full name',
            _nameController,
            readOnly: _isInviteLocked && _nameController.text.isNotEmpty,
          ),
          _buildTextField(
            'Mobile Number',
            Icons.phone_outlined,
            'Enter 10-digit mobile number',
            _mobileController,
            keyboardType: TextInputType.phone,
            readOnly: _isMobileLocked,
            maxLength: 10,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          ),
          _buildTextField(
            'Email Address',
            Icons.email_outlined,
            'name@example.com',
            _emailController,
            keyboardType: TextInputType.emailAddress,
            readOnly: _isInviteLocked && _emailController.text.isNotEmpty,
          ),
          _buildSearchableDropdownField<String>(
            label: 'Gender',
            icon: Icons.person_outline_rounded,
            hint: 'Select Gender',
            items: const ['Male', 'Female', 'Other'],
            value: _selectedGender,
            enableSearch: false,
            useGrid: true,
            gridCrossAxisCount: 3,
            gridChildAspectRatio: 2.5,
            readOnly: _isInviteLocked && _selectedGender != null,
            onChanged: (val) => setState(() => _selectedGender = val),
          ),
          _buildBottomNavigation(bottomPadding),
        ],
      ),
    );
  }

  Widget _buildTextField(
    String label,
    IconData icon,
    String hint,
    TextEditingController controller, {
    TextInputType keyboardType = TextInputType.name,
    bool readOnly = false,
    Widget? suffix,
    List<TextInputFormatter>? inputFormatters,
    int? maxLength,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'Montserrat',
                  color: Theme.of(context).textTheme.titleMedium?.color,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
              if (readOnly)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.lock_rounded, size: 11, color: Colors.grey.shade600),
                      const SizedBox(width: 4),
                      Text(
                        'Verified',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Builder(
            builder: (context) {
              final isDark = Theme.of(context).brightness == Brightness.dark;
              final inputBg = readOnly
                  ? (isDark ? AsmitaPalette.surfaceDark : const Color(0xFFF5F6FA))
                  : (isDark ? AsmitaPalette.surfaceElevatedDark : Colors.white);
              final textColor = readOnly
                  ? (isDark ? AsmitaPalette.textDarkModeMuted : Colors.black54)
                  : (isDark ? AsmitaPalette.textDarkModeMain : Colors.black87);
              final hintColor = isDark ? AsmitaPalette.textDarkModeMuted : Colors.black38;
              final borderStrokeColor = isDark ? AsmitaPalette.borderGreyDark : Colors.grey.shade200;

              return Container(
                decoration: BoxDecoration(
                  color: inputBg,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.02),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    )
                  ],
                ),
                child: TextField(
                  controller: controller,
                  readOnly: readOnly,
                  keyboardType: keyboardType,
                  inputFormatters: inputFormatters,
                  maxLength: maxLength,
                  buildCounter: maxLength != null
                      ? (_, {required currentLength, required isFocused, maxLength}) => null
                      : null,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    color: textColor,
                    fontSize: 15,
                    fontWeight: readOnly ? FontWeight.w500 : FontWeight.normal,
                  ),
                  decoration: InputDecoration(
                    hintText: hint,
                    hintStyle: TextStyle(color: hintColor, fontSize: 14),
                    prefixIcon: Icon(icon, color: isDark ? AsmitaPalette.deepNavyDark : const Color(0xFF27347B), size: 20),
                    suffixIcon: suffix,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: borderStrokeColor)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: borderStrokeColor)),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: readOnly
                          ? BorderSide(color: borderStrokeColor)
                          : BorderSide(color: isDark ? AsmitaPalette.deepNavyDark : const Color(0xFF27347B), width: 1.5),
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                  ),
                ),
              );
            },
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
    double gridChildAspectRatio = 2.0,
    bool readOnly = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: TextStyle(fontFamily: 'Montserrat', color: Theme.of(context).textTheme.titleMedium?.color, fontWeight: FontWeight.w700, fontSize: 13)),
              if (readOnly)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.lock_rounded, size: 11, color: Colors.grey.shade600),
                      const SizedBox(width: 4),
                      Text(
                        'Verified',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: readOnly
                ? null
                : () {
                    _showSearchableBottomSheet(
                      title: modalTitle ?? label,
                      items: items,
                      currentValue: value,
                      onSelected: onChanged,
                      enableSearch: enableSearch,
                      useGrid: useGrid,
                      gridCrossAxisCount: gridCrossAxisCount,
                      gridChildAspectRatio: gridChildAspectRatio,
                    );
                  },
            child: Builder(
              builder: (context) {
                final isDark = Theme.of(context).brightness == Brightness.dark;
                final inputBg = readOnly
                    ? (isDark ? AsmitaPalette.surfaceDark : const Color(0xFFF5F6FA))
                    : (isDark ? AsmitaPalette.surfaceElevatedDark : Colors.white);
                final borderStrokeColor = isDark ? AsmitaPalette.borderGreyDark : Colors.grey.shade200;

                return Container(
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                  decoration: BoxDecoration(
                    color: inputBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: borderStrokeColor),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.02),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      )
                    ],
                  ),
                  child: Row(
                    children: [
                      Icon(icon, color: isDark ? AsmitaPalette.deepNavyDark : const Color(0xFF27347B), size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          value?.toString() ?? hint,
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 15,
                            color: value != null
                                ? (readOnly ? (isDark ? AsmitaPalette.textDarkModeMuted : Colors.black54) : (isDark ? AsmitaPalette.textDarkModeMain : Colors.black87))
                                : (isDark ? AsmitaPalette.textDarkModeMuted : Colors.black38),
                            fontWeight: readOnly ? FontWeight.w500 : FontWeight.normal,
                          ),
                        ),
                      ),
                      if (readOnly)
                        Icon(Icons.lock_rounded, color: isDark ? AsmitaPalette.textDarkModeMuted : Colors.grey.shade600, size: 16)
                      else
                        Icon(Icons.keyboard_arrow_down_rounded, color: Theme.of(context).iconTheme.color, size: 22),
                    ],
                  ),
                );
              },
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
                child: Icon(Icons.arrow_back_ios_new_rounded, color: Theme.of(context).iconTheme.color, size: 18),
              ),
            )
          else
            const SizedBox(width: 56),
          const Spacer(),
          BlocBuilder<AuthBloc, AuthState>(
            builder: (context, state) {
              final isLoading = state is AuthLoading;
              return AppButton(
                style: AppButtonStyle.custom,
                backgroundColor: const Color(0xFFE21F26),
                foregroundColor: Colors.white,
                height: 56,
                borderRadius: 16,
                padding: const EdgeInsets.symmetric(horizontal: 24),
                isLoading: isLoading,
                onPressed: _nextStep,
                label: _currentStep == 0 ? 'Next' : 'Complete',
                icon: Icon(
                  _currentStep == 0 ? Icons.arrow_forward_rounded : Icons.check_rounded,
                  color: Colors.white,
                  size: 20,
                ),
                textStyle: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Poppins',
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}