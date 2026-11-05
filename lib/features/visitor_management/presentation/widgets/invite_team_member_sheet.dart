import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/constants/design_system.dart';
import '../../../../core/widgets/asmita_bottom_sheet.dart';
import '../../../../core/widgets/asmita_text_field.dart';
import '../../../../core/widgets/asmita_toast.dart';
import '../../../auth/bloc/auth_bloc.dart';
import '../../../auth/bloc/auth_state.dart';
import '../../../auth/data/models/user_model.dart';
import '../../data/repositories/team_invite_repository.dart';

/// Top-level helper function to present the "Invite Team Member" modal sheet.
/// Constrained to max 80% screen height via [showAsmitaBottomSheet].
Future<void> showInviteTeamMemberSheet(
  BuildContext context, {
  UserModel? user,
  TeamInviteRepository? repository,
}) {
  UserModel? resolvedUser = user;
  if (resolvedUser == null) {
    try {
      final authState = context.read<AuthBloc>().state;
      if (authState is AuthAuthenticated) {
        resolvedUser = authState.user;
      }
    } catch (_) {}
  }

  final repo = repository ?? TeamInviteRepository();

  return showAsmitaBottomSheet<void>(
    context: context,
    title: 'Invite Team Member',
    subtitle: 'Generate secure onboarding pass for new staff',
    maxHeightFactor: 0.80,
    isScrollControlled: true,
    child: InviteTeamMemberSheet(
      user: resolvedUser,
      repository: repo,
    ),
  );
}

/// Evaluation of role privilege levels for inviting team members.
enum TeamInviteRoleLevel {
  director,
  hod,
  teamLeader,
  unauthorized,
}

/// Encapsulates the permission evaluation result for a user session.
class TeamInvitePermission {
  final bool isAuthorized;
  final TeamInviteRoleLevel roleLevel;
  final bool isDelegatee;
  final String? delegatorName;
  final String? delegatorDepartment;
  final int? lockedDepartmentId;
  final String? lockedDepartmentName;
  final List<String> allowedRoles;
  final String? rejectionReason;

  const TeamInvitePermission({
    required this.isAuthorized,
    required this.roleLevel,
    this.isDelegatee = false,
    this.delegatorName,
    this.delegatorDepartment,
    this.lockedDepartmentId,
    this.lockedDepartmentName,
    this.allowedRoles = const [],
    this.rejectionReason,
  });

  /// Evaluates permissions based on UserModel and optional delegation status.
  factory TeamInvitePermission.evaluate({
    required UserModel? user,
    Map<String, dynamic>? delegationData,
  }) {
    if (user == null) {
      return const TeamInvitePermission(
        isAuthorized: false,
        roleLevel: TeamInviteRoleLevel.unauthorized,
        rejectionReason: 'User session not found.',
      );
    }

    final primaryRole = user.primaryRole.toLowerCase();
    final designation = user.designation.toLowerCase();
    final rolePower = user.rolePower ?? 0;
    final isHodFlag = user.roleDetails?['is_hod'] == true;

    // 1. Direct Role Check
    final isDirector = rolePower >= 500 || primaryRole.contains('director');
    final isHod = isHodFlag || primaryRole.contains('hod') || designation.contains('head');
    final isTL = primaryRole.contains('team leader') ||
        primaryRole.contains('lead') ||
        designation.contains('lead') ||
        designation.contains('tl');

    if (isDirector) {
      return const TeamInvitePermission(
        isAuthorized: true,
        roleLevel: TeamInviteRoleLevel.director,
        isDelegatee: false,
        lockedDepartmentId: null,
        lockedDepartmentName: null,
        allowedRoles: [
          'Head of Department (HOD)',
          'Team Leader',
          'Corporate Employee',
          'Security Guard',
        ],
      );
    }

    if (isHod) {
      return TeamInvitePermission(
        isAuthorized: true,
        roleLevel: TeamInviteRoleLevel.hod,
        isDelegatee: false,
        lockedDepartmentId: user.departmentId,
        lockedDepartmentName: user.departmentName,
        allowedRoles: const [
          'Team Leader',
          'Corporate Employee',
        ],
      );
    }

    if (isTL) {
      return TeamInvitePermission(
        isAuthorized: true,
        roleLevel: TeamInviteRoleLevel.teamLeader,
        isDelegatee: false,
        lockedDepartmentId: user.departmentId,
        lockedDepartmentName: user.departmentName,
        allowedRoles: const [
          'Corporate Employee',
        ],
      );
    }

    // 2. Incoming Delegation Check (Fallback for non-management employees)
    if (delegationData != null) {
      final incoming = delegationData['incomingDelegations'] as List? ?? [];
      for (final raw in incoming) {
        if (raw is! Map) continue;
        final d = Map<String, dynamic>.from(raw);
        if (d['is_active'] != true) continue;

        final delegator = d['delegator'] as Map<String, dynamic>?;
        final dRole = (delegator?['primary_role'] ?? delegator?['role'] ?? '').toString().toLowerCase();
        final dDetails = delegator?['role_details'] as Map<String, dynamic>?;
        final dDesignation = (dDetails?['designation'] ?? dDetails?['leadership_role'] ?? dRole).toString().toLowerCase();
        final dPower = delegator?['role_power'] is int
            ? delegator!['role_power'] as int
            : int.tryParse(delegator?['role_power']?.toString() ?? '') ?? 0;
        final dIsHod = dDetails?['is_hod'] == true || dRole.contains('hod') || dDesignation.contains('head');

        final dName = delegator?['full_name']?.toString() ?? 'Management';
        final dDeptName = dDetails?['department_name']?.toString() ??
            dDetails?['department']?.toString() ??
            'Department';
        final dDeptId = dDetails?['department_id'] != null
            ? int.tryParse(dDetails!['department_id'].toString())
            : null;

        if (dPower >= 500 || dRole.contains('director')) {
          return TeamInvitePermission(
            isAuthorized: true,
            roleLevel: TeamInviteRoleLevel.director,
            isDelegatee: true,
            delegatorName: dName,
            delegatorDepartment: dDeptName,
            lockedDepartmentId: null,
            lockedDepartmentName: null,
            allowedRoles: const [
              'Head of Department (HOD)',
              'Team Leader',
              'Corporate Employee',
              'Security Guard',
            ],
          );
        }

        if (dIsHod) {
          return TeamInvitePermission(
            isAuthorized: true,
            roleLevel: TeamInviteRoleLevel.hod,
            isDelegatee: true,
            delegatorName: dName,
            delegatorDepartment: dDeptName,
            lockedDepartmentId: dDeptId,
            lockedDepartmentName: dDeptName,
            allowedRoles: const [
              'Team Leader',
              'Corporate Employee',
            ],
          );
        }

        if (dRole.contains('team leader') ||
            dRole.contains('lead') ||
            dDesignation.contains('lead') ||
            dDesignation.contains('tl')) {
          return TeamInvitePermission(
            isAuthorized: true,
            roleLevel: TeamInviteRoleLevel.teamLeader,
            isDelegatee: true,
            delegatorName: dName,
            delegatorDepartment: dDeptName,
            lockedDepartmentId: dDeptId,
            lockedDepartmentName: dDeptName,
            allowedRoles: const [
              'Corporate Employee',
            ],
          );
        }
      }
    }

    return const TeamInvitePermission(
      isAuthorized: false,
      roleLevel: TeamInviteRoleLevel.unauthorized,
      rejectionReason:
          'Access Restricted: Only Directors, Department Heads, Team Leaders, or their active delegatees can invite team members.',
    );
  }
}

/// Modal Bottom Sheet Widget for inviting team members.
class InviteTeamMemberSheet extends StatefulWidget {
  final UserModel? user;
  final TeamInviteRepository repository;

  const InviteTeamMemberSheet({
    super.key,
    required this.user,
    required this.repository,
  });

  @override
  State<InviteTeamMemberSheet> createState() => _InviteTeamMemberSheetState();
}

class _InviteTeamMemberSheetState extends State<InviteTeamMemberSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();

  late TeamInvitePermission _permission;
  bool _isLoadingPermission = false;

  // Department state for Directors
  List<Map<String, dynamic>> _societyDepartments = [];
  bool _isLoadingDepartments = false;
  int? _selectedDepartmentId;
  String? _selectedDepartmentName;

  // Target role selection
  String _selectedTargetRole = '';

  // Form submission state
  bool _isSubmitting = false;

  // Post-generation State B
  Map<String, dynamic>? _generatedInvite;

  @override
  void initState() {
    super.initState();
    _evaluateInitialPermissions();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _evaluateInitialPermissions() {
    final direct = TeamInvitePermission.evaluate(user: widget.user);
    _permission = direct;

    if (direct.isAuthorized) {
      _initFormValues();
    } else {
      // Query delegation endpoint for possible active incoming delegation
      _checkDelegationFallback();
    }
  }

  Future<void> _checkDelegationFallback() async {
    final societyId = widget.user?.societyId ?? 0;
    if (societyId == 0) return;

    setState(() => _isLoadingPermission = true);
    final delegationData = await widget.repository.getDelegationStatus(societyId: societyId);
    if (!mounted) return;

    final evaluated = TeamInvitePermission.evaluate(
      user: widget.user,
      delegationData: delegationData,
    );

    setState(() {
      _permission = evaluated;
      _isLoadingPermission = false;
    });

    if (evaluated.isAuthorized) {
      _initFormValues();
    }
  }

  void _initFormValues() {
    if (_permission.allowedRoles.isNotEmpty) {
      _selectedTargetRole = _permission.allowedRoles.first;
    }

    if (_permission.roleLevel == TeamInviteRoleLevel.director) {
      _loadSocietyDepartments();
    } else {
      _selectedDepartmentId = _permission.lockedDepartmentId;
      _selectedDepartmentName = _permission.lockedDepartmentName;
    }
  }

  Future<void> _loadSocietyDepartments() async {
    final societyId = widget.user?.societyId ?? 0;
    if (societyId == 0) return;

    setState(() => _isLoadingDepartments = true);
    final depts = await widget.repository.getSocietyDepartments(societyId);
    if (!mounted) return;

    setState(() {
      _societyDepartments = depts;
      _isLoadingDepartments = false;
      if (depts.isNotEmpty) {
        _selectedDepartmentId = depts.first['id'] is int
            ? depts.first['id'] as int
            : int.tryParse(depts.first['id']?.toString() ?? '');
        _selectedDepartmentName = depts.first['name']?.toString() ??
            depts.first['department_name']?.toString();
      }
    });
  }

  Future<void> _onSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    final societyId = widget.user?.societyId ?? 0;
    if (societyId == 0) {
      AsmitaToast.show(
        context,
        message: 'Society information not available.',
        type: AsmitaToastType.error,
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final response = await widget.repository.generateInvite(
        societyId: societyId,
        targetRole: _selectedTargetRole,
        departmentId: _selectedDepartmentId,
        departmentName: _selectedDepartmentName,
        recipientName: _nameController.text.trim().isNotEmpty ? _nameController.text.trim() : null,
        recipientPhone: _phoneController.text.trim().isNotEmpty ? _phoneController.text.trim() : null,
        targetUnitId: _selectedDepartmentId,
      );

      if (!mounted) return;
      setState(() {
        _generatedInvite = response;
        _isSubmitting = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      final raw = e.toString().replaceFirst('Exception: ', '');
      AsmitaToast.show(
        context,
        message: raw.isNotEmpty ? raw : 'Failed to generate invite.',
        type: AsmitaToastType.error,
      );
    }
  }

  Future<void> _copyToClipboard(String inviteUrl) async {
    await Clipboard.setData(ClipboardData(text: inviteUrl));
    HapticFeedback.lightImpact();
    if (mounted) {
      AsmitaToast.show(
        context,
        message: 'Invite link copied to clipboard',
        type: AsmitaToastType.success,
      );
    }
  }

  Future<void> _shareViaWhatsApp({
    required String inviteUrl,
    required String recipientName,
    required String recipientPhone,
  }) async {
    final societyName = widget.user?.societyName ?? 'My AsmitA';
    final name = recipientName.isNotEmpty ? recipientName : 'Colleague';
    final role = _selectedTargetRole;
    final dept = _selectedDepartmentName ?? 'AsmitA Society';

    final message =
        'Dear $name, you are invited to join My AsmitA for $societyName as $role ($dept). Download the app: $inviteUrl';

    final cleanPhone = recipientPhone.replaceAll(RegExp(r'\D'), '');
    final Uri whatsappUri;
    final Uri webFallbackUri;

    if (cleanPhone.isNotEmpty) {
      final phoneWithCountry = cleanPhone.length == 10 ? '91$cleanPhone' : cleanPhone;
      whatsappUri = Uri.parse(
        'whatsapp://send?phone=$phoneWithCountry&text=${Uri.encodeComponent(message)}',
      );
      webFallbackUri = Uri.parse(
        'https://wa.me/$phoneWithCountry?text=${Uri.encodeComponent(message)}',
      );
    } else {
      whatsappUri = Uri.parse(
        'whatsapp://send?text=${Uri.encodeComponent(message)}',
      );
      webFallbackUri = Uri.parse(
        'https://wa.me/?text=${Uri.encodeComponent(message)}',
      );
    }

    try {
      if (await canLaunchUrl(whatsappUri)) {
        await launchUrl(whatsappUri);
      } else {
        await launchUrl(webFallbackUri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {
      // Fallback to native share sheet if WhatsApp cannot be launched directly
      await _shareViaNative(inviteUrl);
    }
  }

  Future<void> _shareViaNative(String inviteUrl) async {
    final societyName = widget.user?.societyName ?? 'My AsmitA';
    final name = _nameController.text.trim().isNotEmpty
        ? _nameController.text.trim()
        : 'Colleague';
    final role = _selectedTargetRole;
    final dept = _selectedDepartmentName ?? 'AsmitA Society';

    final message =
        'Dear $name, you are invited to join My AsmitA for $societyName as $role ($dept). Download the app: $inviteUrl';

    await Clipboard.setData(ClipboardData(text: inviteUrl));
    await SharePlus.instance.share(
      ShareParams(
        text: message,
        subject: 'My AsmitA Team Invitation',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingPermission) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (!_permission.isAuthorized) {
      return _buildUnauthorizedView();
    }

    if (_generatedInvite != null) {
      return _buildSuccessState();
    }

    return _buildFormState();
  }

  Widget _buildUnauthorizedView() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SingleChildScrollView(
      physics: const ClampingScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 8.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AsmitaPalette.actionRed.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.lock_person_rounded,
                size: 40,
                color: AsmitaPalette.actionRed,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Access Restricted',
              style: GoogleFonts.montserrat(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: isDark ? AsmitaPalette.textDarkModeMain : AsmitaPalette.textDark,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              _permission.rejectionReason ??
                  'You do not have permission to invite team members. This action requires Director, HOD, or Team Leader authorization, or an active delegation.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: isDark ? AsmitaPalette.textDarkModeMuted : AsmitaPalette.textLight,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: OutlinedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Close',
                  style: GoogleFonts.montserrat(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormState() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      physics: const ClampingScrollPhysics(),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // 1. Active Delegation Banner
            if (_permission.isDelegatee) ...[
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: AsmitaPalette.amberWarning.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AsmitaPalette.amberWarning.withValues(alpha: 0.4),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.swap_horiz_rounded,
                      color: AsmitaPalette.amberWarning,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Acting on behalf of ${_permission.delegatorName} (${_permission.delegatorDepartment})',
                        style: GoogleFonts.montserrat(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? AsmitaPalette.textDarkModeMain
                              : const Color(0xFF92400E),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // 2. Department Field
            Text(
              'Department',
              style: GoogleFonts.montserrat(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isDark ? AsmitaPalette.textDarkModeMain : AsmitaPalette.textDark,
              ),
            ),
            const SizedBox(height: 8),
            _buildDepartmentSelector(isDark),
            const SizedBox(height: 16),

            // 3. Target Role Selection
            Text(
              'Target Role',
              style: GoogleFonts.montserrat(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isDark ? AsmitaPalette.textDarkModeMain : AsmitaPalette.textDark,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _permission.allowedRoles.map((role) {
                final isSelected = _selectedTargetRole == role;
                return ChoiceChip(
                  label: Text(
                    role,
                    style: GoogleFonts.montserrat(
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected
                          ? Colors.white
                          : (isDark
                              ? AsmitaPalette.textDarkModeMain
                              : AsmitaPalette.textDark),
                    ),
                  ),
                  selected: isSelected,
                  selectedColor: AsmitaPalette.deepNavy,
                  backgroundColor: isDark
                      ? AsmitaPalette.surfaceDark
                      : AsmitaPalette.systemBG,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: BorderSide(
                      color: isSelected
                          ? AsmitaPalette.deepNavy
                          : Theme.of(context).dividerColor,
                    ),
                  ),
                  onSelected: (selected) {
                    if (selected) {
                      setState(() => _selectedTargetRole = role);
                    }
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // 4. Recipient Name (Optional)
            AsmitaTextField(
              controller: _nameController,
              label: 'Recipient Name (Optional)',
              hint: 'e.g. John Doe',
              icon: Icons.person_outline_rounded,
            ),
            const SizedBox(height: 16),

            // 5. Recipient Mobile Number (Optional)
            AsmitaTextField(
              controller: _phoneController,
              label: 'Recipient Mobile Number (Optional)',
              hint: '10-digit mobile number',
              icon: Icons.phone_android_rounded,
              keyboardType: TextInputType.phone,
              maxLength: 10,
              validator: (val) {
                if (val != null && val.trim().isNotEmpty) {
                  final trimmed = val.trim();
                  if (!RegExp(r'^\d{10}$').hasMatch(trimmed)) {
                    return 'Please enter a valid 10-digit mobile number';
                  }
                }
                return null;
              },
            ),
            const SizedBox(height: 24),

            // 6. Submit Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _onSubmit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AsmitaPalette.deepNavy,
                  disabledBackgroundColor: AsmitaPalette.deepNavy.withValues(alpha: 0.6),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        'Generate Invite Link',
                        style: GoogleFonts.montserrat(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _buildDepartmentSelector(bool isDark) {
    if (_permission.roleLevel != TeamInviteRoleLevel.director) {
      // Locked to department
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          color: isDark ? AsmitaPalette.surfaceDark : AsmitaPalette.systemBG,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Theme.of(context).dividerColor),
        ),
        child: Row(
          children: [
            Icon(
              Icons.lock_rounded,
              size: 18,
              color: isDark ? AsmitaPalette.textDarkModeMuted : AsmitaPalette.textLight,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                _permission.lockedDepartmentName ?? 'Assigned Department',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: isDark ? AsmitaPalette.textDarkModeMain : AsmitaPalette.textDark,
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Unlocked department selection for Directors
    if (_isLoadingDepartments) {
      return Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: isDark ? AsmitaPalette.surfaceDark : AsmitaPalette.systemBG,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Theme.of(context).dividerColor),
        ),
        child: const Center(
          child: SizedBox(
            height: 18,
            width: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    if (_societyDepartments.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          color: isDark ? AsmitaPalette.surfaceDark : AsmitaPalette.systemBG,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Theme.of(context).dividerColor),
        ),
        child: Text(
          'All Departments (Executive)',
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: isDark ? AsmitaPalette.textDarkModeMain : AsmitaPalette.textDark,
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: isDark ? AsmitaPalette.surfaceDark : AsmitaPalette.systemBG,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: _selectedDepartmentId,
          isExpanded: true,
          icon: const Icon(Icons.arrow_drop_down_rounded),
          dropdownColor: isDark ? AsmitaPalette.surfaceElevatedDark : Colors.white,
          items: _societyDepartments.map((d) {
            final id = d['id'] is int ? d['id'] as int : int.tryParse(d['id']?.toString() ?? '') ?? 0;
            final name = d['name']?.toString() ?? d['department_name']?.toString() ?? 'Department';
            return DropdownMenuItem<int>(
              value: id,
              child: Text(
                name,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: isDark ? AsmitaPalette.textDarkModeMain : AsmitaPalette.textDark,
                ),
              ),
            );
          }).toList(),
          onChanged: (newId) {
            if (newId != null) {
              final match = _societyDepartments.firstWhere(
                (d) => (d['id'] is int ? d['id'] as int : int.tryParse(d['id']?.toString() ?? '') ?? 0) == newId,
                orElse: () => {},
              );
              setState(() {
                _selectedDepartmentId = newId;
                _selectedDepartmentName = match['name']?.toString() ?? match['department_name']?.toString();
              });
            }
          },
        ),
      ),
    );
  }

  Widget _buildSuccessState() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final inviteUrl = _generatedInvite?['inviteUrl']?.toString() ?? '';
    final phone = _phoneController.text.trim();
    final name = _nameController.text.trim();

    return SingleChildScrollView(
      physics: const ClampingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Success Header
          Center(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AsmitaPalette.successGreen.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle_rounded,
                color: AsmitaPalette.successGreen,
                size: 36,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: Text(
              'Invite Created Successfully!',
              style: GoogleFonts.montserrat(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: isDark ? AsmitaPalette.textDarkModeMain : AsmitaPalette.textDark,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // DLT SMS Alert Status
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: phone.isNotEmpty
                  ? AsmitaPalette.successGreen.withValues(alpha: 0.1)
                  : AsmitaPalette.deepNavy.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: phone.isNotEmpty
                    ? AsmitaPalette.successGreen.withValues(alpha: 0.3)
                    : AsmitaPalette.deepNavy.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  phone.isNotEmpty
                      ? Icons.mark_email_read_rounded
                      : Icons.info_outline_rounded,
                  size: 20,
                  color: phone.isNotEmpty
                      ? AsmitaPalette.successGreen
                      : AsmitaPalette.deepNavy,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    phone.isNotEmpty
                        ? 'SMS invite dispatched to +91 $phone via DLT Template 1677100000000395667'
                        : 'Direct link ready for sharing (DLT Template 1677100000000395667)',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: isDark
                          ? AsmitaPalette.textDarkModeMain
                          : (phone.isNotEmpty ? const Color(0xFF166534) : AsmitaPalette.deepNavy),
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Invite Link Display with one-tap copy
          Text(
            'Invite Link',
            style: GoogleFonts.montserrat(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isDark ? AsmitaPalette.textDarkModeMain : AsmitaPalette.textDark,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: isDark ? AsmitaPalette.surfaceDark : AsmitaPalette.systemBG,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Theme.of(context).dividerColor),
            ),
            child: Row(
              children: [
                Expanded(
                  child: SelectableText(
                    inviteUrl,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: isDark ? AsmitaPalette.textDarkModeMain : AsmitaPalette.textDark,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.copy_rounded, size: 20),
                  tooltip: 'Copy Link',
                  onPressed: () => _copyToClipboard(inviteUrl),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Share via WhatsApp Button
          SizedBox(
            height: 48,
            child: ElevatedButton.icon(
              onPressed: () => _shareViaWhatsApp(
                inviteUrl: inviteUrl,
                recipientName: name,
                recipientPhone: phone,
              ),
              icon: const Icon(Icons.chat_rounded, color: Colors.white, size: 20),
              label: Text(
                'Share via WhatsApp',
                style: GoogleFonts.montserrat(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF25D366),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Copy Link / Native Share Button
          SizedBox(
            height: 48,
            child: OutlinedButton.icon(
              onPressed: () => _shareViaNative(inviteUrl),
              icon: const Icon(Icons.share_rounded, size: 20),
              label: Text(
                'Copy Link / Share',
                style: GoogleFonts.montserrat(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Done Button
          SizedBox(
            height: 44,
            child: TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Done',
                style: GoogleFonts.montserrat(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AsmitaPalette.textDarkModeMuted : AsmitaPalette.textLight,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
