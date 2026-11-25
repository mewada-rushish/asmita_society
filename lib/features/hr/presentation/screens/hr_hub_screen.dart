import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/design_system.dart';
import '../../../../core/widgets/app_skeleton.dart';
import '../../../../core/widgets/asmita_bottom_sheet.dart';
import '../../../../core/widgets/asmita_calendar_sheet.dart';
import '../../../../core/widgets/asmita_primary_header.dart';
import '../../../../core/widgets/asmita_select_field.dart';
import '../../../../core/widgets/asmita_toast.dart';
import '../../../auth/bloc/auth_bloc.dart';
import '../../../auth/bloc/auth_state.dart';
import '../../../dashboard/widgets/asmita_pre_approve_wizard.dart';
import '../../../visitor_management/bloc/industrial_visit_bloc.dart';
import '../../../visitor_management/bloc/industrial_visit_event.dart';
import '../../../visitor_management/bloc/industrial_visit_state.dart';
import '../../data/repositories/hr_repository.dart';

class HrHubScreen extends StatefulWidget {
  final int? societyId;

  const HrHubScreen({super.key, this.societyId});

  static Future<void> open(BuildContext context, {int? societyId}) {
    return Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => HrHubScreen(societyId: societyId)),
    );
  }

  @override
  State<HrHubScreen> createState() => _HrHubScreenState();
}

class _HrHubScreenState extends State<HrHubScreen> with SingleTickerProviderStateMixin {
  final HrRepository _repo = HrRepository();
  late final TabController _tabController;
  final TextEditingController _searchController = TextEditingController();

  bool _isLoading = true;
  bool _isAttendanceLoading = false;
  bool _isBulkInviting = false;
  int? _resendingUserId;

  DateTimeRange _selectedRange = DateTimeRange(
    start: DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day),
    end: DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day),
  );
  Map<String, dynamic> _summary = {};
  List<Map<String, dynamic>> _attendance = [];
  List<Map<String, dynamic>> _employees = [];
  List<Map<String, dynamic>> _desks = [];
  List<Map<String, dynamic>> _notices = [];

  static const int _pageSize = 20;
  int _attendanceVisibleCount = _pageSize;
  int _peopleVisibleCount = _pageSize;

  String _searchQuery = '';
  String _attendanceFilter = 'ALL'; // ALL, IN, OUT, NOT_MARKED
  String _peopleMode = 'PENDING'; // PENDING, ALL, SEATS

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadAll();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  int _resolveSocietyId() {
    if (widget.societyId != null && widget.societyId! > 0) return widget.societyId!;
    try {
      final st = context.read<AuthBloc>().state;
      if (st is AuthAuthenticated && st.user.societyId != null) return st.user.societyId!;
    } catch (_) {}
    return 1;
  }

  String _currentUserName() {
    try {
      final st = context.read<AuthBloc>().state;
      if (st is AuthAuthenticated && st.user.fullName.isNotEmpty) return st.user.fullName;
    } catch (_) {}
    return 'HR Team';
  }

  String get _startDateParam => DateFormat('yyyy-MM-dd').format(_selectedRange.start);
  String get _endDateParam => DateFormat('yyyy-MM-dd').format(_selectedRange.end);

  bool get _isSingleDay =>
      _selectedRange.start.year == _selectedRange.end.year &&
      _selectedRange.start.month == _selectedRange.end.month &&
      _selectedRange.start.day == _selectedRange.end.day;

  bool get _isSelectedToday {
    if (!_isSingleDay) return false;
    final now = DateTime.now();
    return _selectedRange.end.year == now.year &&
        _selectedRange.end.month == now.month &&
        _selectedRange.end.day == now.day;
  }

  bool get _canGoNextRange {
    final now = DateTime.now();
    final todayOnly = DateTime(now.year, now.month, now.day);
    return _selectedRange.end.isBefore(todayOnly);
  }

  String get _rangeDisplayLabel {
    if (_isSelectedToday) {
      return 'Today, ${DateFormat('dd MMM yyyy').format(_selectedRange.start)}';
    }
    if (_isSingleDay) {
      return DateFormat('EEE, dd MMM yyyy').format(_selectedRange.start);
    }
    return '${DateFormat('dd MMM').format(_selectedRange.start)} – ${DateFormat('dd MMM yyyy').format(_selectedRange.end)}';
  }

  Future<void> _loadAll() async {
    final sId = _resolveSocietyId();
    if (mounted) setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        _repo.getSummary(sId).catchError((_) => <String, dynamic>{}),
        _repo.getAttendance(sId, startDate: _startDateParam, endDate: _endDateParam).catchError((_) => <Map<String, dynamic>>[]),
        _repo.getDirectoryEmployees(sId).catchError((_) => <Map<String, dynamic>>[]),
        _repo.getEmployeeFormData(sId).catchError((_) => <String, dynamic>{}),
        _repo.getNotices(sId).catchError((_) => <Map<String, dynamic>>[]),
      ]);

      try {
        if (mounted) context.read<IndustrialVisitBloc>().add(const LoadIndustrialVisits());
      } catch (_) {}

      if (!mounted) return;
      final formData = results[3] as Map<String, dynamic>;
      final rawDesks = formData['desks'] as List? ?? [];
      setState(() {
        _summary = results[0] as Map<String, dynamic>;
        _attendance = results[1] as List<Map<String, dynamic>>;
        _employees = results[2] as List<Map<String, dynamic>>;
        _desks = rawDesks.map((e) => Map<String, dynamic>.from(e as Map)).toList();
        _notices = results[4] as List<Map<String, dynamic>>;
        _attendanceVisibleCount = _pageSize;
        _peopleVisibleCount = _pageSize;
        _isLoading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _changeRange(DateTimeRange newRange) async {
    final today = DateTime.now();
    final todayOnly = DateTime(today.year, today.month, today.day);
    final startOnly = DateTime(newRange.start.year, newRange.start.month, newRange.start.day);
    final endOnly = DateTime(newRange.end.year, newRange.end.month, newRange.end.day);
    if (endOnly.isAfter(todayOnly)) return;

    setState(() {
      _selectedRange = DateTimeRange(start: startOnly, end: endOnly);
      _isAttendanceLoading = true;
    });
    try {
      final rows = await _repo.getAttendance(_resolveSocietyId(), startDate: _startDateParam, endDate: _endDateParam);
      if (!mounted) return;
      setState(() {
        _attendance = rows;
        _attendanceVisibleCount = _pageSize;
        _isAttendanceLoading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _isAttendanceLoading = false);
    }
  }

  Future<void> _pickDate() async {
    final picked = await showAsmitaCalendarRangeSheet(
      context: context,
      initialRange: _selectedRange,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
      title: 'Select Attendance Range',
      subtitle: 'Check who checked in, checked out, or was absent',
    );
    if (picked != null) {
      await _changeRange(picked);
    }
  }

  String _formatTime(dynamic raw) {
    if (raw == null) return '--';
    try {
      final dt = DateTime.parse(raw.toString()).toLocal();
      return DateFormat('hh:mm a').format(dt);
    } catch (_) {
      return '--';
    }
  }

  String _formatDate(dynamic raw) {
    if (raw == null) return '--';
    try {
      final dt = DateTime.parse(raw.toString()).toLocal();
      return DateFormat('dd MMM yyyy').format(dt);
    } catch (_) {
      return raw.toString();
    }
  }

  Future<void> _handleBulkInvite() async {
    final sId = _resolveSocietyId();
    setState(() => _isBulkInviting = true);
    try {
      final res = await _repo.bulkInvitePending(sId, invitedByName: _currentUserName());
      if (!mounted) return;
      final sent = res['sentCount'] ?? 0;
      final failed = res['failedCount'] ?? 0;
      AsmitaToast.show(
        context,
        message: 'Sent $sent WhatsApp invite(s)${failed > 0 ? ' ($failed failed)' : ''}',
        type: AsmitaToastType.success,
      );
      _loadAll();
    } catch (e) {
      if (mounted) {
        AsmitaToast.show(context, message: 'Bulk invite failed: $e', type: AsmitaToastType.error);
      }
    } finally {
      if (mounted) setState(() => _isBulkInviting = false);
    }
  }

  Future<void> _handleSingleInvite(Map<String, dynamic> emp) async {
    final uid = emp['user_id'] ?? emp['id'];
    final phone = (emp['mobile_number'] ?? emp['phone'] ?? '').toString();
    if (phone.replaceAll(RegExp(r'\D'), '').length < 10) {
      AsmitaToast.show(context, message: 'No valid 10-digit phone number', type: AsmitaToastType.error);
      return;
    }
    setState(() => _resendingUserId = uid is int ? uid : int.tryParse(uid.toString()));
    try {
      await _repo.resendSingleInvite(
        societyId: _resolveSocietyId(),
        phone: phone,
        name: (emp['full_name'] ?? emp['name'] ?? 'Colleague').toString(),
        email: (emp['email_id'] ?? emp['email'])?.toString(),
        floor: emp['floor']?.toString(),
        deskCode: emp['desk_code']?.toString(),
        cabinCode: emp['cabin_code']?.toString(),
        department: emp['department']?.toString(),
        role: (emp['designation'] ?? emp['role'])?.toString(),
        invitedByName: _currentUserName(),
      );
      if (mounted) {
        AsmitaToast.show(
          context,
          message: 'WhatsApp invite sent to ${emp['full_name'] ?? emp['name']}',
          type: AsmitaToastType.success,
        );
      }
    } catch (_) {
      if (mounted) {
        AsmitaToast.show(context, message: 'Failed to send invite', type: AsmitaToastType.error);
      }
    } finally {
      if (mounted) setState(() => _resendingUserId = null);
    }
  }

  void _openAddEmployeeSheet() {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final deptCtrl = TextEditingController();
    final desigCtrl = TextEditingController(text: 'Executive');
    bool saving = false;

    showAsmitaBottomSheet(
      context: context,
      title: 'Add New Employee',
      subtitle: 'Create a staff record and assign department & role',
      child: StatefulBuilder(
        builder: (ctx, setModalState) => SafeArea(
          top: false,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _fieldLabel('Full Name *'),
                TextField(
                  controller: nameCtrl,
                  decoration: _inputDecoration('e.g. Rahul Sharma', icon: Icons.person_outline_rounded),
                ),
                const SizedBox(height: 12),
                _fieldLabel('Mobile Number *'),
                TextField(
                  controller: phoneCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: _inputDecoration('10-digit mobile number', icon: Icons.phone_outlined),
                ),
                const SizedBox(height: 12),
                _fieldLabel('Email Address'),
                TextField(
                  controller: emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: _inputDecoration('name@company.com', icon: Icons.email_outlined),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _fieldLabel('Department'),
                          TextField(
                            controller: deptCtrl,
                            decoration: _inputDecoration('e.g. Sales', icon: Icons.business_outlined),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _fieldLabel('Designation'),
                          TextField(
                            controller: desigCtrl,
                            decoration: _inputDecoration('e.g. Executive', icon: Icons.badge_outlined),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AsmitaPalette.deepNavy,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: saving
                        ? null
                        : () async {
                            if (nameCtrl.text.trim().isEmpty || phoneCtrl.text.trim().length < 10) {
                              AsmitaToast.show(context, message: 'Name and 10-digit phone required', type: AsmitaToastType.error);
                              return;
                            }
                            setModalState(() => saving = true);
                            try {
                              await _repo.addEmployee(_resolveSocietyId(), {
                                'name': nameCtrl.text.trim(),
                                'phone': phoneCtrl.text.trim(),
                                'email': emailCtrl.text.trim(),
                                'department': deptCtrl.text.trim(),
                                'designation': desigCtrl.text.trim(),
                              });
                              if (ctx.mounted) Navigator.pop(ctx);
                              if (mounted) {
                                AsmitaToast.show(context, message: 'Employee added successfully', type: AsmitaToastType.success);
                                _loadAll();
                              }
                            } catch (_) {
                              setModalState(() => saving = false);
                              if (mounted) AsmitaToast.show(context, message: 'Failed to add employee', type: AsmitaToastType.error);
                            }
                          },
                    icon: saving
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.person_add_alt_1_rounded, size: 18),
                    label: Text(saving ? 'Saving...' : 'Create Employee', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _openPostNoticeSheet() {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    String priority = 'Normal';
    bool saving = false;

    showAsmitaBottomSheet(
      context: context,
      title: 'Post HR Notice',
      subtitle: 'Broadcast an announcement to all employees',
      child: StatefulBuilder(
        builder: (ctx, setModalState) => SafeArea(
          top: false,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _fieldLabel('Notice Title *'),
                TextField(
                  controller: titleCtrl,
                  decoration: _inputDecoration('e.g. Holiday Schedule Update', icon: Icons.title_rounded),
                ),
                const SizedBox(height: 12),
                _fieldLabel('Message *'),
                TextField(
                  controller: descCtrl,
                  maxLines: 3,
                  decoration: _inputDecoration('Write details for your team...', icon: Icons.notes_rounded),
                ),
                const SizedBox(height: 12),
                AsmitaSelectField<String>(
                  label: 'Priority',
                  hint: 'Select Priority',
                  value: priority,
                  prefixIcon: Icons.flag_outlined,
                  sheetTitle: 'Select Notice Priority',
                  items: const [
                    AsmitaSelectItem(value: 'Normal', label: 'Normal', icon: Icons.info_outline_rounded),
                    AsmitaSelectItem(value: 'High', label: 'High', icon: Icons.priority_high_rounded, iconColor: Colors.orange),
                    AsmitaSelectItem(value: 'Urgent', label: 'Urgent', icon: Icons.warning_amber_rounded, iconColor: Colors.red),
                  ],
                  onChanged: (v) => setModalState(() => priority = v ?? 'Normal'),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AsmitaPalette.deepNavy,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: saving
                        ? null
                        : () async {
                            if (titleCtrl.text.trim().isEmpty || descCtrl.text.trim().isEmpty) {
                              AsmitaToast.show(context, message: 'Title and message are required', type: AsmitaToastType.error);
                              return;
                            }
                            setModalState(() => saving = true);
                            try {
                              await _repo.createNotice({
                                'society_id': _resolveSocietyId(),
                                'title': titleCtrl.text.trim(),
                                'description': descCtrl.text.trim(),
                                'priority': priority,
                              });
                              if (ctx.mounted) Navigator.pop(ctx);
                              if (mounted) {
                                AsmitaToast.show(context, message: 'HR Notice published', type: AsmitaToastType.success);
                                _loadAll();
                              }
                            } catch (_) {
                              setModalState(() => saving = false);
                              if (mounted) AsmitaToast.show(context, message: 'Failed to post notice', type: AsmitaToastType.error);
                            }
                          },
                    icon: saving
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.campaign_rounded, size: 18),
                    label: Text(saving ? 'Publishing...' : 'Publish Notice', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _fieldLabel(String text) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: isDark ? AsmitaPalette.textDarkModeMuted : AsmitaPalette.textDark,
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint, {IconData? icon}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.poppins(fontSize: 13, color: AsmitaPalette.textTertiary(context)),
      prefixIcon: icon != null ? Icon(icon, size: 19, color: AsmitaPalette.primary(context)) : null,
      filled: true,
      fillColor: isDark ? AsmitaPalette.surfaceDark : AsmitaPalette.systemBG,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AsmitaPalette.border(context), width: 1.2)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AsmitaPalette.border(context), width: 1.2)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AsmitaPalette.primary(context), width: 1.5)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AsmitaPalette.systemBGDark : AsmitaPalette.systemBG;

    return Scaffold(
      backgroundColor: bg,
      body: Column(
        children: [
          AsmitaPrimaryHeader(
            showBackButton: true,
            subtitleOverride: 'HR Hub',
            userInitials: _currentUserName().isNotEmpty ? _currentUserName()[0].toUpperCase() : 'H',
          ),
          Expanded(
            child: RefreshIndicator(
              color: isDark ? const Color(0xFF60A5FA) : AsmitaPalette.deepNavy,
              backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
              notificationPredicate: (notification) =>
                  notification.metrics.axis == Axis.vertical && notification.depth <= 1,
              onRefresh: _loadAll,
              child: NestedScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                headerSliverBuilder: (context, innerBoxIsScrolled) => [
                  SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 12, bottom: 8),
                    child: _buildMetricsGrid(context),
                  ),
                ),
                SliverOverlapAbsorber(
                  handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context),
                  sliver: SliverPersistentHeader(
                    pinned: true,
                    delegate: _StickyTabBarDelegate(
                      height: 56,
                      backgroundColor: bg,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                        child: Container(
                          height: 44,
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                              width: 1,
                            ),
                          ),
                          child: TabBar(
                            controller: _tabController,
                            dividerColor: Colors.transparent,
                            indicatorSize: TabBarIndicatorSize.tab,
                            indicator: BoxDecoration(
                              color: isDark ? const Color(0xFF3B82F6) : AsmitaPalette.deepNavy,
                              borderRadius: BorderRadius.circular(9),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.08),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            labelColor: Colors.white,
                            unselectedLabelColor: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                            labelPadding: const EdgeInsets.symmetric(horizontal: 4),
                            labelStyle: GoogleFonts.poppins(fontSize: 11 * _uiScale(context), fontWeight: FontWeight.w600),
                            unselectedLabelStyle: GoogleFonts.poppins(fontSize: 11 * _uiScale(context), fontWeight: FontWeight.w500),
                            tabs: const [
                              Tab(child: FittedBox(fit: BoxFit.scaleDown, child: Text('Attendance', maxLines: 1))),
                              Tab(child: FittedBox(fit: BoxFit.scaleDown, child: Text('People', maxLines: 1))),
                              Tab(child: FittedBox(fit: BoxFit.scaleDown, child: Text('Visits & Notices', maxLines: 1))),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
              body: TabBarView(
                controller: _tabController,
                children: [
                  _buildAttendanceTab(),
                  _buildPeopleTab(),
                  _buildVisitsAndNoticesTab(),
                ],
              ),
            ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsGrid(BuildContext context) {
    final s = _uiScale(context);
    final onSite = _attendance.where((e) => e['current_status'] == 'IN').length;
    final checkedOut = _attendance.where((e) => e['current_status'] == 'OUT').length;
    final notMarked = _attendance.where((e) => e['current_status'] == 'NOT_MARKED').length;
    final pendingInvites = (_summary['pending_invites_count'] ??
            _employees.where((e) => e['approval_status'] == 'PENDING' || e['status'] == 'Invite Pending').length)
        as int;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16 * s),
      child: Row(
        children: [
          Expanded(
            child: _buildMetricTile(
              context,
              title: 'Checked In',
              count: onSite,
              icon: Icons.login_rounded,
              accentColor: const Color(0xFF10B981),
              isSelected: _tabController.index == 0 && _attendanceFilter == 'IN',
              onTap: () {
                HapticFeedback.selectionClick();
                _tabController.animateTo(0);
                setState(() => _attendanceFilter = _attendanceFilter == 'IN' ? 'ALL' : 'IN');
              },
            ),
          ),
          SizedBox(width: 8 * s),
          Expanded(
            child: _buildMetricTile(
              context,
              title: 'Out',
              count: checkedOut,
              icon: Icons.logout_rounded,
              accentColor: const Color(0xFF64748B),
              isSelected: _tabController.index == 0 && _attendanceFilter == 'OUT',
              onTap: () {
                HapticFeedback.selectionClick();
                _tabController.animateTo(0);
                setState(() => _attendanceFilter = _attendanceFilter == 'OUT' ? 'ALL' : 'OUT');
              },
            ),
          ),
          SizedBox(width: 8 * s),
          Expanded(
            child: _buildMetricTile(
              context,
              title: 'Not Marked',
              count: notMarked,
              icon: Icons.person_off_outlined,
              accentColor: const Color(0xFFF59E0B),
              isSelected: _tabController.index == 0 && _attendanceFilter == 'NOT_MARKED',
              onTap: () {
                HapticFeedback.selectionClick();
                _tabController.animateTo(0);
                setState(() => _attendanceFilter = _attendanceFilter == 'NOT_MARKED' ? 'ALL' : 'NOT_MARKED');
              },
            ),
          ),
          SizedBox(width: 8 * s),
          Expanded(
            child: _buildMetricTile(
              context,
              title: 'Pending',
              count: pendingInvites,
              icon: Icons.mark_email_unread_outlined,
              accentColor: const Color(0xFF3B82F6),
              isSelected: false,
              onTap: () {
                HapticFeedback.selectionClick();
                _tabController.animateTo(1);
                setState(() => _peopleMode = 'PENDING');
              },
            ),
          ),
        ],
      ),
    );
  }

  double _uiScale(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    return (w / 390.0).clamp(0.80, 1.0);
  }

  Widget _buildMetricTile(
    BuildContext context, {
    required String title,
    required int count,
    required IconData icon,
    required Color accentColor,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final s = _uiScale(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(horizontal: 6 * s, vertical: 10 * s),
        decoration: BoxDecoration(
          color: isSelected
              ? accentColor.withValues(alpha: isDark ? 0.16 : 0.08)
              : (isDark ? const Color(0xFF1E293B) : Colors.white),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? accentColor
                : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
            width: isSelected ? 1.6 : 1.1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(7 * s),
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 17 * s, color: accentColor),
            ),
            SizedBox(height: 6 * s),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                '$count',
                style: GoogleFonts.poppins(
                  fontSize: 16 * s,
                  fontWeight: FontWeight.w700,
                  height: 1.1,
                  color: AsmitaPalette.textPrimary(context),
                ),
              ),
            ),
            SizedBox(height: 2 * s),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                title,
                maxLines: 1,
                style: GoogleFonts.poppins(
                  fontSize: 10 * s,
                  fontWeight: FontWeight.w600,
                  color: AsmitaPalette.textSecondary(context),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttendanceTab() {
    final filtered = _attendance.where((item) {
      if (_attendanceFilter != 'ALL' && item['current_status'] != _attendanceFilter) return false;
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final name = (item['full_name'] ?? '').toString().toLowerCase();
        final dept = (item['department'] ?? '').toString().toLowerCase();
        if (!name.contains(q) && !dept.contains(q)) return false;
      }
      return true;
    }).toList();

    final visibleCount = _attendanceVisibleCount.clamp(0, filtered.length);
    final hasMore = visibleCount < filtered.length;

    return Builder(
      builder: (context) => NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          if (hasMore &&
              notification.metrics.axis == Axis.vertical &&
              notification.metrics.pixels >= notification.metrics.maxScrollExtent - 240) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted && _attendanceVisibleCount < filtered.length) {
                setState(() => _attendanceVisibleCount += _pageSize);
              }
            });
          }
          return false;
        },
        child: CustomScrollView(
          key: const PageStorageKey<String>('hr_attendance_tab'),
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverOverlapInjector(
              handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
          TextField(
            controller: _searchController,
            onChanged: (v) => setState(() {
              _searchQuery = v.trim();
              _attendanceVisibleCount = _pageSize;
            }),
            style: GoogleFonts.poppins(
              fontSize: 13 * _uiScale(context),
              color: AsmitaPalette.textPrimary(context),
            ),
            decoration: InputDecoration(
              hintText: 'Search employee or department...',
              hintStyle: GoogleFonts.poppins(
                fontSize: 13 * _uiScale(context),
                color: AsmitaPalette.textTertiary(context),
              ),
              prefixIcon: Icon(
                Icons.search_rounded,
                size: 20,
                color: AsmitaPalette.textTertiary(context),
              ),
              filled: true,
              fillColor: AsmitaPalette.surface(context),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: AsmitaPalette.border(context))),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: AsmitaPalette.border(context))),
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AsmitaPalette.surface(context),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AsmitaPalette.border(context)),
            ),
            child: Row(
              children: [
                IconButton(
                  onPressed: () {
                    final span = _selectedRange.duration.inDays + 1;
                    _changeRange(DateTimeRange(
                      start: _selectedRange.start.subtract(Duration(days: span)),
                      end: _selectedRange.end.subtract(Duration(days: span)),
                    ));
                  },
                  icon: const Icon(Icons.chevron_left_rounded),
                  tooltip: 'Previous',
                ),
                Expanded(
                  child: InkWell(
                    onTap: _pickDate,
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.calendar_today_rounded, size: 15, color: AsmitaPalette.primary(context)),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              _rangeDisplayLabel,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: AsmitaPalette.textPrimary(context)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                IconButton(
                  onPressed: !_canGoNextRange
                      ? null
                      : () {
                          final span = _selectedRange.duration.inDays + 1;
                          final now = DateTime.now();
                          final todayOnly = DateTime(now.year, now.month, now.day);
                          var nextEnd = _selectedRange.end.add(Duration(days: span));
                          var nextStart = _selectedRange.start.add(Duration(days: span));
                          if (nextEnd.isAfter(todayOnly)) {
                            nextEnd = todayOnly;
                            nextStart = todayOnly.subtract(Duration(days: span - 1));
                          }
                          _changeRange(DateTimeRange(start: nextStart, end: nextEnd));
                        },
                  icon: const Icon(Icons.chevron_right_rounded),
                  tooltip: 'Next',
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          if (_isLoading || _isAttendanceLoading)
            _buildAttendanceSkeletonList()
          else if (filtered.isEmpty)
            _emptyCard('No attendance records match this filter'),
                  ],
                ),
              ),
            ),
            if (!_isLoading && !_isAttendanceLoading && filtered.isNotEmpty)
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                sliver: SliverList.builder(
                  itemCount: visibleCount + (hasMore ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index < visibleCount) {
                      return _buildAttendanceCard(filtered[index]);
                    }
                    return _buildLoadMoreFooter(
                      shown: visibleCount,
                      total: filtered.length,
                      onTap: () => setState(() => _attendanceVisibleCount += _pageSize),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttendanceSkeletonList() {
    final dummy = {
      'full_name': 'Employee Name Placeholder',
      'department': 'Department',
      'designation': 'Designation Role',
      'desk_code': 'D-101-S1',
      'current_status': 'NOT_MARKED',
    };
    return AsmitaSkeleton(
      isLoading: true,
      child: Column(
        children: List.generate(5, (_) => _buildAttendanceCard(dummy)),
      ),
    );
  }

  Widget _buildAttendanceCard(Map<String, dynamic> item) {
    final s = _uiScale(context);
    final st = (item['current_status'] ?? 'NOT_MARKED').toString();
    final Color badgeColor = st == 'IN' ? const Color(0xFF10B981) : (st == 'OUT' ? const Color(0xFF64748B) : const Color(0xFFF59E0B));
    final String badgeText = st == 'IN' ? 'IN' : (st == 'OUT' ? 'OUT' : 'NOT MARKED');
    final dept = (item['department'] ?? 'General').toString().trim();
    final role = (item['designation'] ?? 'Staff').toString().trim();
    final desk = (item['desk_code'] ?? '').toString().trim();

    return GestureDetector(
      onTap: () => _openEmployeeAttendanceSheet(item),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: EdgeInsets.all(12 * s),
        decoration: BoxDecoration(
          color: AsmitaPalette.surface(context),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AsmitaPalette.border(context)),
        ),
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 18 * s,
                backgroundColor: AsmitaPalette.subtleAccent(context),
                child: Text(
                  (item['full_name'] ?? 'E').toString().isNotEmpty ? item['full_name'].toString()[0].toUpperCase() : 'E',
                  style: GoogleFonts.poppins(fontSize: 13 * s, fontWeight: FontWeight.w700, color: AsmitaPalette.primary(context)),
                ),
              ),
              SizedBox(width: 10 * s),
              Expanded(
                child: Text(
                  (item['full_name'] ?? 'Employee').toString(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13 * s, color: AsmitaPalette.textPrimary(context)),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8 * s, vertical: 3.5 * s),
                decoration: BoxDecoration(color: badgeColor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
                child: Text(badgeText, style: GoogleFonts.poppins(fontSize: 9.5 * s, fontWeight: FontWeight.w700, color: badgeColor)),
              ),
            ],
          ),
          SizedBox(height: 8 * s),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _infoPill(Icons.badge_outlined, role, scale: s),
                SizedBox(width: 6 * s),
                _infoPill(Icons.business_outlined, dept, scale: s),
                if (desk.isNotEmpty) ...[
                  SizedBox(width: 6 * s),
                  _infoPill(Icons.desk_rounded, desk, highlight: true, scale: s),
                ],
              ],
            ),
          ),
          SizedBox(height: 8 * s),
          Padding(
            padding: EdgeInsets.only(top: 2 * s),
            child: Row(
              children: [
                Icon(
                  st == 'NOT_MARKED' ? Icons.info_outline_rounded : Icons.access_time_rounded,
                  size: 13 * s,
                  color: st == 'NOT_MARKED' ? const Color(0xFFD97706) : AsmitaPalette.primary(context),
                ),
                SizedBox(width: 6 * s),
                Expanded(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      st == 'NOT_MARKED'
                          ? (_isSingleDay
                              ? 'Did not check in on ${DateFormat('dd MMM').format(_selectedRange.start)}'
                              : 'Did not check in (${DateFormat('dd MMM').format(_selectedRange.start)} – ${DateFormat('dd MMM').format(_selectedRange.end)})')
                          : (_isSingleDay
                              ? 'In: ${_formatTime(item['first_in_time'])}  •  Out: ${_formatTime(item['last_out_time'])}${item['last_gate_name'] != null ? '  •  ${item['last_gate_name']}' : ''}'
                              : 'Present ${item['days_present'] ?? 1}/${item['total_days'] ?? 1} days  •  First In: ${_formatTime(item['first_in_time'])}  •  Last Out: ${_formatTime(item['last_out_time'])}'),
                      maxLines: 1,
                      style: GoogleFonts.poppins(
                        fontSize: 10.5 * s,
                        fontWeight: FontWeight.w600,
                        color: st == 'NOT_MARKED' ? const Color(0xFFD97706) : AsmitaPalette.textPrimary(context),
                      ),
                    ),
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

  void _openEmployeeAttendanceSheet(Map<String, dynamic> item) {
    final userId = int.tryParse((item['user_id'] ?? item['id'] ?? '').toString());
    if (userId == null) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _EmployeeAttendanceCalendarSheet(
        repo: _repo,
        societyId: _resolveSocietyId(),
        userId: userId,
        employeeName: (item['full_name'] ?? 'Employee').toString(),
        subtitle: [
          if ((item['designation'] ?? item['role'] ?? '').toString().trim().isNotEmpty)
            (item['designation'] ?? item['role']).toString().trim(),
          if ((item['department'] ?? '').toString().trim().isNotEmpty)
            item['department'].toString().trim(),
        ].join(' • '),
        initialMonth: DateTime(_selectedRange.end.year, _selectedRange.end.month),
      ),
    );
  }

  Widget _infoPill(IconData icon, String text, {bool highlight = false, double scale = 1.0}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = highlight
        ? AsmitaPalette.subtleAccent(context)
        : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9));
    final fg = highlight ? AsmitaPalette.primary(context) : AsmitaPalette.textSecondary(context);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 7.5 * scale, vertical: 3.5 * scale),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11.5 * scale, color: fg),
          SizedBox(width: 4 * scale),
          Text(
            text,
            style: GoogleFonts.poppins(fontSize: 10.5 * scale, fontWeight: FontWeight.w600, color: fg),
          ),
        ],
      ),
    );
  }

  Widget _buildPeopleTab() {
    final pendingList = _employees.where((e) => e['approval_status'] == 'PENDING' || e['status'] == 'Invite Pending').toList();
    final filteredEmployees = (_peopleMode == 'PENDING' ? pendingList : _employees).where((e) {
      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      return (e['full_name'] ?? e['name'] ?? '').toString().toLowerCase().contains(q) ||
          (e['department'] ?? '').toString().toLowerCase().contains(q) ||
          (e['mobile_number'] ?? e['phone'] ?? '').toString().toLowerCase().contains(q);
    }).toList();

    final filteredDesks = _desks.where((d) {
      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      return (d['flat_number'] ?? '').toString().toLowerCase().contains(q) ||
          (d['occupant_name'] ?? '').toString().toLowerCase().contains(q) ||
          (d['department'] ?? '').toString().toLowerCase().contains(q);
    }).toList();

    final activeTotal = _peopleMode == 'SEATS' ? filteredDesks.length : filteredEmployees.length;
    final visibleCount = _peopleVisibleCount.clamp(0, activeTotal);
    final hasMore = visibleCount < activeTotal;

    return Builder(
      builder: (context) => NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          if (hasMore &&
              notification.metrics.axis == Axis.vertical &&
              notification.metrics.pixels >= notification.metrics.maxScrollExtent - 240) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted && _peopleVisibleCount < activeTotal) {
                setState(() => _peopleVisibleCount += _pageSize);
              }
            });
          }
          return false;
        },
        child: CustomScrollView(
          key: const PageStorageKey<String>('hr_people_tab'),
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverOverlapInjector(
              handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      controller: _searchController,
                      onChanged: (v) => setState(() {
                        _searchQuery = v.trim();
                        _peopleVisibleCount = _pageSize;
                      }),
            style: GoogleFonts.poppins(
              fontSize: 13 * _uiScale(context),
              color: AsmitaPalette.textPrimary(context),
            ),
            decoration: InputDecoration(
              hintText: _peopleMode == 'SEATS' ? 'Search desk, cabin or occupant...' : 'Search name, phone or department...',
              hintStyle: GoogleFonts.poppins(
                fontSize: 13 * _uiScale(context),
                color: AsmitaPalette.textTertiary(context),
              ),
              prefixIcon: Icon(
                Icons.search_rounded,
                size: 20,
                color: AsmitaPalette.textTertiary(context),
              ),
              filled: true,
              fillColor: AsmitaPalette.surface(context),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: AsmitaPalette.border(context))),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: AsmitaPalette.border(context))),
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _filterChip('Pending (${pendingList.length})', _peopleMode == 'PENDING', () => setState(() {
                        _peopleMode = 'PENDING';
                        _peopleVisibleCount = _pageSize;
                      })),
                      _filterChip('Directory (${_employees.length})', _peopleMode == 'ALL', () => setState(() {
                        _peopleMode = 'ALL';
                        _peopleVisibleCount = _pageSize;
                      })),
                      _filterChip('Seats (${_desks.length})', _peopleMode == 'SEATS', () => setState(() {
                        _peopleMode = 'SEATS';
                        _peopleVisibleCount = _pageSize;
                      })),
                    ],
                  ),
                ),
              ),
              IconButton(
                onPressed: _openAddEmployeeSheet,
                icon: Icon(Icons.person_add_alt_1_rounded, color: AsmitaPalette.primary(context)),
                tooltip: 'Add Employee',
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (_peopleMode == 'PENDING' && pendingList.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(14),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: AsmitaPalette.subtleAccent(context),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AsmitaPalette.primary(context).withValues(alpha: 0.25)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '${pendingList.length} colleague(s) awaiting activation.',
                      style: GoogleFonts.poppins(fontSize: 12.5, fontWeight: FontWeight.w600, color: AsmitaPalette.textPrimary(context)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: _isBulkInviting ? null : _handleBulkInvite,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AsmitaPalette.deepNavy,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    icon: _isBulkInviting
                        ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.send_rounded, size: 15),
                    label: Text(_isBulkInviting ? 'Sending...' : 'Bulk Invite', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ),
          ],
          if (_isLoading)
            _buildAttendanceSkeletonList()
          else if (_peopleMode == 'SEATS' && filteredDesks.isEmpty)
            _emptyCard('No desks or cabins found')
          else if (_peopleMode != 'SEATS' && filteredEmployees.isEmpty)
            _emptyCard('No employees found'),
                  ],
                ),
              ),
            ),
            if (!_isLoading && activeTotal > 0)
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                sliver: SliverList.builder(
                  itemCount: visibleCount + (hasMore ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index < visibleCount) {
                      return _peopleMode == 'SEATS'
                          ? _buildDeskCard(filteredDesks[index])
                          : _buildEmployeeCard(filteredEmployees[index]);
                    }
                    return _buildLoadMoreFooter(
                      shown: visibleCount,
                      total: activeTotal,
                      onTap: () => setState(() => _peopleVisibleCount += _pageSize),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeskCard(Map<String, dynamic> d) {
    final occ = d['is_occupied'] == true;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AsmitaPalette.surface(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AsmitaPalette.border(context)),
      ),
      child: Row(
        children: [
          Icon(occ ? Icons.person_rounded : Icons.event_seat_rounded, color: occ ? const Color(0xFF64748B) : const Color(0xFF10B981), size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${d['flat_number']} (Floor ${d['floor']})', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13.5, color: AsmitaPalette.textPrimary(context))),
                Text(
                  occ ? 'Occupied by ${d['occupant_name'] ?? 'Colleague'}' : 'Available • ${d['department'] ?? 'Open'}',
                  style: GoogleFonts.poppins(fontSize: 12, color: occ ? AsmitaPalette.textSecondary(context) : const Color(0xFF059669)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmployeeCard(Map<String, dynamic> emp) {
    final s = _uiScale(context);
    final uid = emp['user_id'] ?? emp['id'];
    final isPending = emp['approval_status'] == 'PENDING' || emp['status'] == 'Invite Pending';
    final isSendingThis = _resendingUserId != null && _resendingUserId.toString() == uid.toString();
    final dept = (emp['department'] ?? 'General').toString().trim();
    final role = (emp['designation'] ?? emp['role'] ?? 'Staff').toString().trim();
    final desk = (emp['desk_code'] ?? emp['cabin_code'] ?? '').toString().trim();
    final phone = (emp['mobile_number'] ?? emp['phone'] ?? '').toString().trim();

    return GestureDetector(
      onTap: () => _openEmployeeAttendanceSheet(emp),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: EdgeInsets.all(12 * s),
        decoration: BoxDecoration(
          color: AsmitaPalette.surface(context),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AsmitaPalette.border(context)),
        ),
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  (emp['full_name'] ?? emp['name'] ?? 'Employee').toString(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13 * s, color: AsmitaPalette.textPrimary(context)),
                ),
              ),
              const SizedBox(width: 8),
              if (isPending)
                ElevatedButton.icon(
                  onPressed: isSendingThis ? null : () => _handleSingleInvite(emp),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(horizontal: 9 * s, vertical: 6 * s),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: isSendingThis
                      ? const SizedBox(width: 13, height: 13, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : Icon(Icons.send_rounded, size: 13 * s),
                  label: Text('Invite', style: GoogleFonts.poppins(fontSize: 11 * s, fontWeight: FontWeight.w600)),
                )
              else
                _statusPill('ACTIVE'),
            ],
          ),
          SizedBox(height: 8 * s),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _infoPill(Icons.badge_outlined, role, scale: s),
                SizedBox(width: 6 * s),
                _infoPill(Icons.business_outlined, dept, scale: s),
                if (desk.isNotEmpty) ...[
                  SizedBox(width: 6 * s),
                  _infoPill(Icons.desk_rounded, desk, highlight: true, scale: s),
                ],
                if (phone.isNotEmpty) ...[
                  SizedBox(width: 6 * s),
                  _infoPill(Icons.phone_outlined, phone, scale: s),
                ],
              ],
            ),
          ),
        ],
      ),
      ),
    );
  }

  Widget _buildLoadMoreFooter({
    required int shown,
    required int total,
    required VoidCallback onTap,
  }) {
    final s = _uiScale(context);
    final remaining = total - shown;
    final nextBatch = remaining < _pageSize ? remaining : _pageSize;
    return Padding(
      padding: const EdgeInsets.only(top: 6, bottom: 8),
      child: Column(
        children: [
          Text(
            'Showing $shown of $total',
            style: GoogleFonts.poppins(
              fontSize: 11.5 * s,
              color: AsmitaPalette.textTertiary(context),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: onTap,
            style: OutlinedButton.styleFrom(
              foregroundColor: AsmitaPalette.primary(context),
              side: BorderSide(color: AsmitaPalette.border(context)),
              padding: EdgeInsets.symmetric(horizontal: 16 * s, vertical: 8 * s),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
            icon: Icon(Icons.expand_more_rounded, size: 18 * s),
            label: Text(
              'Load $nextBatch more',
              style: GoogleFonts.poppins(fontSize: 12 * s, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVisitsAndNoticesTab() {
    return Builder(
      builder: (context) => CustomScrollView(
        key: const PageStorageKey<String>('hr_visits_notices_tab'),
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverOverlapInjector(
            handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
            sliver: SliverToBoxAdapter(
              child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => AsmitaPreApproveWizard.showAsModalSheet(context, title: 'Pre-Approve Candidate'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AsmitaPalette.deepNavy,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.qr_code_2_rounded, size: 18),
                  label: Text('Pre-Approve', style: GoogleFonts.poppins(fontSize: 12.5, fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _openPostNoticeSheet,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.campaign_rounded, size: 18),
                  label: Text('Post Notice', style: GoogleFonts.poppins(fontSize: 12.5, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text('Upcoming / Recent Visitor Passes', style: GoogleFonts.poppins(fontSize: 14.5, fontWeight: FontWeight.w700, color: AsmitaPalette.textPrimary(context))),
          const SizedBox(height: 8),
          BlocBuilder<IndustrialVisitBloc, IndustrialVisitState>(
            builder: (context, state) {
              if (state.status == IndustrialVisitBlocStatus.loading && state.visits.isEmpty) {
                return const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator()));
              }
              final visits = state.visits.take(5).toList();
              if (visits.isEmpty) return _emptyCard('No candidate/visitor requests right now');
              return Column(
                children: visits
                    .map((v) => Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AsmitaPalette.surface(context),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AsmitaPalette.border(context)),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(v.visitorName, style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: AsmitaPalette.textPrimary(context))),
                                    Text('${v.purpose ?? 'Visit'} • ${v.visitorMobile ?? ''}', style: GoogleFonts.poppins(fontSize: 12, color: AsmitaPalette.textSecondary(context))),
                                  ],
                                ),
                              ),
                              _statusPill(v.status.name.toUpperCase()),
                            ],
                          ),
                        ))
                    .toList(),
              );
            },
          ),
          const SizedBox(height: 16),
          Text('HR Notices & Broadcasts', style: GoogleFonts.poppins(fontSize: 14.5, fontWeight: FontWeight.w700, color: AsmitaPalette.textPrimary(context))),
          const SizedBox(height: 8),
          if (_notices.isEmpty)
            _emptyCard('No notices published yet')
          else
            ..._notices.map((n) => Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AsmitaPalette.surface(context),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AsmitaPalette.border(context)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(child: Text((n['title'] ?? '').toString(), style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14, color: AsmitaPalette.textPrimary(context)))),
                          _statusPill((n['priority'] ?? 'Normal').toString().toUpperCase()),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text((n['description'] ?? '').toString(), style: GoogleFonts.poppins(fontSize: 12.5, color: AsmitaPalette.textSecondary(context))),
                      const SizedBox(height: 6),
                      Text(_formatDate(n['created_at']), style: GoogleFonts.poppins(fontSize: 11, color: AsmitaPalette.textTertiary(context))),
                    ],
                  ),
                )),
              ],
            ),
          ),
        ),
      ],
    ),
  );
  }

  Widget _filterChip(String label, bool selected, VoidCallback onTap) {
    final s = _uiScale(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.only(right: 8 * s),
        padding: EdgeInsets.symmetric(horizontal: 11 * s, vertical: 6 * s),
        decoration: BoxDecoration(
          color: selected ? AsmitaPalette.deepNavy : AsmitaPalette.surface(context),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? AsmitaPalette.deepNavy : AsmitaPalette.border(context)),
        ),
        child: Text(
          label,
          style: GoogleFonts.poppins(fontSize: 11 * s, fontWeight: FontWeight.w600, color: selected ? Colors.white : AsmitaPalette.textPrimary(context)),
        ),
      ),
    );
  }

  Widget _statusPill(String status) {
    final s = status.toUpperCase();
    final Color c = (s == 'APPROVED' || s == 'ACTIVE' || s == 'CHECKED_IN')
        ? const Color(0xFF10B981)
        : (s == 'REJECTED' || s == 'URGENT')
            ? AsmitaPalette.actionRed
            : const Color(0xFFD97706);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(color: c.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
      child: Text(s, style: GoogleFonts.poppins(fontSize: 10.5, fontWeight: FontWeight.w700, color: c)),
    );
  }

  Widget _emptyCard(String msg) {
    return Container(
      padding: const EdgeInsets.all(22),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AsmitaPalette.surface(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AsmitaPalette.border(context)),
      ),
      child: Text(msg, style: GoogleFonts.poppins(fontSize: 13, color: AsmitaPalette.textSecondary(context))),
    );
  }
}

class _StickyTabBarDelegate extends SliverPersistentHeaderDelegate {
  final double height;
  final Color backgroundColor;
  final Widget child;

  const _StickyTabBarDelegate({
    required this.height,
    required this.backgroundColor,
    required this.child,
  });

  @override
  double get minExtent => height;

  @override
  double get maxExtent => height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: backgroundColor,
      alignment: Alignment.center,
      child: child,
    );
  }

  @override
  bool shouldRebuild(covariant _StickyTabBarDelegate oldDelegate) {
    return oldDelegate.height != height ||
        oldDelegate.backgroundColor != backgroundColor ||
        oldDelegate.child != child;
  }
}

class _EmployeeAttendanceCalendarSheet extends StatefulWidget {
  final HrRepository repo;
  final int societyId;
  final int userId;
  final String employeeName;
  final String subtitle;
  final DateTime initialMonth;

  const _EmployeeAttendanceCalendarSheet({
    required this.repo,
    required this.societyId,
    required this.userId,
    required this.employeeName,
    required this.subtitle,
    required this.initialMonth,
  });

  @override
  State<_EmployeeAttendanceCalendarSheet> createState() =>
      _EmployeeAttendanceCalendarSheetState();
}

class _EmployeeAttendanceCalendarSheetState
    extends State<_EmployeeAttendanceCalendarSheet> {
  late DateTime _displayedMonth;
  DateTime? _selectedDay;
  bool _isLoading = true;
  int _presentCount = 0;
  int _absentCount = 0;
  Map<String, dynamic> _days = {};

  @override
  void initState() {
    super.initState();
    _displayedMonth = DateTime(widget.initialMonth.year, widget.initialMonth.month);
    _loadMonth();
  }

  Future<void> _loadMonth() async {
    if (mounted) setState(() => _isLoading = true);
    final monthKey =
        '${_displayedMonth.year}-${_displayedMonth.month.toString().padLeft(2, '0')}';
    try {
      final data = await widget.repo.getEmployeeAttendanceCalendar(
        widget.societyId,
        userId: widget.userId,
        month: monthKey,
      );
      if (!mounted) return;
      setState(() {
        _presentCount = (data['present_count'] ?? 0) as int;
        _absentCount = (data['absent_count'] ?? 0) as int;
        _days = Map<String, dynamic>.from(data['days'] as Map? ?? {});
        _selectedDay = null;
        _isLoading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  bool get _canGoNextMonth {
    final now = DateTime.now();
    return _displayedMonth.year < now.year ||
        (_displayedMonth.year == now.year && _displayedMonth.month < now.month);
  }

  String _formatTime(dynamic raw) {
    if (raw == null) return '--';
    try {
      final dt = DateTime.parse(raw.toString()).toLocal();
      return DateFormat('hh:mm a').format(dt);
    } catch (_) {
      return '--';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF0F172A) : Colors.white;
    final now = DateTime.now();
    final todayOnly = DateTime(now.year, now.month, now.day);
    final firstDayOfMonth = DateTime(_displayedMonth.year, _displayedMonth.month, 1);
    final daysInMonth = DateTime(_displayedMonth.year, _displayedMonth.month + 1, 0).day;
    final leadingBlanks = firstDayOfMonth.weekday - 1; // Mon = 1 -> 0 blanks

    String? selectedKey;
    Map<String, dynamic>? selectedRecord;
    if (_selectedDay != null) {
      selectedKey =
          '${_selectedDay!.year}-${_selectedDay!.month.toString().padLeft(2, '0')}-${_selectedDay!.day.toString().padLeft(2, '0')}';
      final raw = _days[selectedKey];
      if (raw is Map) selectedRecord = Map<String, dynamic>.from(raw);
    }

    return SafeArea(
      top: false,
      child: Container(
        decoration: BoxDecoration(
          color: bg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: AsmitaPalette.border(context),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.employeeName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AsmitaPalette.textPrimary(context),
                        ),
                      ),
                      if (widget.subtitle.isNotEmpty)
                        Text(
                          widget.subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: AsmitaPalette.textSecondary(context),
                          ),
                        ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _countBox(
                    context,
                    label: 'Present',
                    count: _presentCount,
                    color: const Color(0xFF10B981),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _countBox(
                    context,
                    label: 'Absent',
                    count: _absentCount,
                    color: const Color(0xFFD97706),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AsmitaPalette.subtleAccent(context),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () {
                      setState(() {
                        _displayedMonth = DateTime(
                          _displayedMonth.year,
                          _displayedMonth.month - 1,
                        );
                      });
                      _loadMonth();
                    },
                    icon: const Icon(Icons.chevron_left_rounded),
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        DateFormat('MMMM yyyy').format(_displayedMonth),
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AsmitaPalette.textPrimary(context),
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: _canGoNextMonth
                        ? () {
                            setState(() {
                              _displayedMonth = DateTime(
                                _displayedMonth.year,
                                _displayedMonth.month + 1,
                              );
                            });
                            _loadMonth();
                          }
                        : null,
                    icon: const Icon(Icons.chevron_right_rounded),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: const ['Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa', 'Su']
                  .map(
                    (d) => Expanded(
                      child: Center(
                        child: Text(
                          d,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF94A3B8),
                          ),
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 6),
            if (_isLoading)
              SizedBox(
                height: 252,
                child: GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 7,
                    mainAxisExtent: 42,
                  ),
                  itemCount: 42,
                  itemBuilder: (context, index) => AsmitaSkeleton(
                    child: Container(
                      margin: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              )
            else
              SizedBox(
                height: 252,
                child: GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 7,
                    mainAxisExtent: 42,
                  ),
                  itemCount: 42,
                  itemBuilder: (context, index) {
                    final dayNum = index - leadingBlanks + 1;
                    if (dayNum < 1 || dayNum > daysInMonth) {
                      return const SizedBox.shrink();
                    }
                    final date = DateTime(
                      _displayedMonth.year,
                      _displayedMonth.month,
                      dayNum,
                    );
                    final key =
                        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
                    final isFuture = date.isAfter(todayOnly);
                    final isPresent = _days.containsKey(key);
                    final isSelected = _selectedDay != null &&
                        _selectedDay!.year == date.year &&
                        _selectedDay!.month == date.month &&
                        _selectedDay!.day == date.day;

                    Color? cellBg;
                    Color textColor = AsmitaPalette.textPrimary(context);
                    if (isFuture) {
                      textColor = AsmitaPalette.textTertiary(context);
                    } else if (isPresent) {
                      cellBg = const Color(0xFF10B981).withValues(alpha: 0.16);
                      textColor = const Color(0xFF059669);
                    } else {
                      cellBg = const Color(0xFFF59E0B).withValues(alpha: 0.14);
                      textColor = const Color(0xFFD97706);
                    }

                    return GestureDetector(
                      onTap: isFuture
                          ? null
                          : () => setState(() => _selectedDay = date),
                      child: Container(
                        margin: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          color: cellBg,
                          borderRadius: BorderRadius.circular(10),
                          border: isSelected
                              ? Border.all(
                                  color: AsmitaPalette.primary(context),
                                  width: 1.5,
                                )
                              : null,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '$dayNum',
                          style: GoogleFonts.poppins(
                            fontSize: 12.5,
                            fontWeight:
                                isPresent ? FontWeight.w700 : FontWeight.w500,
                            color: textColor,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            if (_selectedDay != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: AsmitaPalette.subtleAccent(context),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  selectedRecord != null
                      ? '${DateFormat('dd MMM yyyy').format(_selectedDay!)}  •  In: ${_formatTime(selectedRecord['first_in_time'])}  •  Out: ${_formatTime(selectedRecord['last_out_time'])}'
                      : '${DateFormat('dd MMM yyyy').format(_selectedDay!)}  •  Absent / Not Marked',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AsmitaPalette.textPrimary(context),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _countBox(
    BuildContext context, {
    required String label,
    required int count,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
          _isLoading
              ? AsmitaSkeleton(
                  child: Container(
                    width: 28,
                    height: 18,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                )
              : Text(
                  '$count',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
        ],
      ),
    );
  }
}
