import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/design_system.dart';
import '../../../../core/widgets/app_refresh.dart';
import '../../../../core/widgets/asmita_primary_header.dart';
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
  bool _isBulkInviting = false;
  int? _resendingUserId;

  Map<String, dynamic> _summary = {};
  List<Map<String, dynamic>> _attendance = [];
  List<Map<String, dynamic>> _employees = [];
  List<Map<String, dynamic>> _desks = [];
  List<Map<String, dynamic>> _leaves = [];
  List<Map<String, dynamic>> _regularizations = [];
  List<Map<String, dynamic>> _notices = [];

  String _searchQuery = '';
  String _attendanceFilter = 'ALL'; // ALL, IN, OUT, NOT_MARKED
  String _peopleMode = 'PENDING'; // PENDING, ALL, SEATS
  String _leaveStatusFilter = 'PENDING'; // PENDING, APPROVED, REJECTED, ALL
  bool _showRegularizations = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
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

  Future<void> _loadAll() async {
    final sId = _resolveSocietyId();
    if (mounted) setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        _repo.getSummary(sId).catchError((_) => <String, dynamic>{}),
        _repo.getAttendance(sId).catchError((_) => <Map<String, dynamic>>[]),
        _repo.getDirectoryEmployees(sId).catchError((_) => <Map<String, dynamic>>[]),
        _repo.getEmployeeFormData(sId).catchError((_) => <String, dynamic>{}),
        _repo.getLeaves(sId, status: 'ALL').catchError((_) => <Map<String, dynamic>>[]),
        _repo.getRegularizations(sId, status: 'ALL').catchError((_) => <Map<String, dynamic>>[]),
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
        _leaves = results[4] as List<Map<String, dynamic>>;
        _regularizations = results[5] as List<Map<String, dynamic>>;
        _notices = results[6] as List<Map<String, dynamic>>;
        _isLoading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
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
    } catch (e) {
      if (mounted) {
        AsmitaToast.show(context, message: 'Failed to send invite', type: AsmitaToastType.error);
      }
    } finally {
      if (mounted) setState(() => _resendingUserId = null);
    }
  }

  Future<void> _handleDecideLeave(int id, String status) async {
    try {
      await _repo.decideLeave(id, status);
      if (!mounted) return;
      AsmitaToast.show(
        context,
        message: 'Leave ${status.toLowerCase()}',
        type: status == 'APPROVED' ? AsmitaToastType.success : AsmitaToastType.info,
      );
      _loadAll();
    } catch (e) {
      if (mounted) {
        AsmitaToast.show(context, message: 'Failed to update leave', type: AsmitaToastType.error);
      }
    }
  }

  Future<void> _handleDecideRegularization(int id, String status) async {
    try {
      await _repo.decideRegularization(id, status);
      if (!mounted) return;
      AsmitaToast.show(
        context,
        message: 'Regularization ${status.toLowerCase()}',
        type: status == 'APPROVED' ? AsmitaToastType.success : AsmitaToastType.info,
      );
      _loadAll();
    } catch (e) {
      if (mounted) {
        AsmitaToast.show(context, message: 'Failed to update request', type: AsmitaToastType.error);
      }
    }
  }

  void _openAddEmployeeSheet() {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final deptCtrl = TextEditingController();
    final desigCtrl = TextEditingController(text: 'Executive');
    bool saving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AsmitaPalette.surface(context),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Add New Employee', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AsmitaPalette.textPrimary(context))),
                const SizedBox(height: 14),
                TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Full Name *', border: OutlineInputBorder())),
                const SizedBox(height: 10),
                TextField(controller: phoneCtrl, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Mobile Number *', border: OutlineInputBorder())),
                const SizedBox(height: 10),
                TextField(controller: emailCtrl, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'Email', border: OutlineInputBorder())),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(child: TextField(controller: deptCtrl, decoration: const InputDecoration(labelText: 'Department', border: OutlineInputBorder()))),
                    const SizedBox(width: 10),
                    Expanded(child: TextField(controller: desigCtrl, decoration: const InputDecoration(labelText: 'Designation', border: OutlineInputBorder()))),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: AsmitaPalette.deepNavy, foregroundColor: Colors.white),
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
                            } catch (e) {
                              setModalState(() => saving = false);
                              if (mounted) AsmitaToast.show(context, message: 'Failed to add employee', type: AsmitaToastType.error);
                            }
                          },
                    child: Text(saving ? 'Saving...' : 'Create Employee'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _openApplyLeaveSheet() {
    String leaveType = 'CASUAL';
    DateTime startDate = DateTime.now();
    DateTime endDate = DateTime.now();
    final reasonCtrl = TextEditingController();
    bool saving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AsmitaPalette.surface(context),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: MediaQuery.of(ctx).viewInsets.bottom + 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Apply Leave / WFH', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AsmitaPalette.textPrimary(context))),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: leaveType,
                decoration: const InputDecoration(labelText: 'Request Type', border: OutlineInputBorder()),
                items: const [
                  DropdownMenuItem(value: 'CASUAL', child: Text('Casual Leave')),
                  DropdownMenuItem(value: 'SICK', child: Text('Sick Leave')),
                  DropdownMenuItem(value: 'EARNED', child: Text('Earned Leave')),
                  DropdownMenuItem(value: 'WFH', child: Text('Work From Home (WFH)')),
                ],
                onChanged: (v) => setModalState(() => leaveType = v ?? 'CASUAL'),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.calendar_today, size: 16),
                      label: Text('From: ${DateFormat('dd MMM').format(startDate)}'),
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: ctx,
                          initialDate: startDate,
                          firstDate: DateTime.now().subtract(const Duration(days: 7)),
                          lastDate: DateTime.now().add(const Duration(days: 180)),
                        );
                        if (picked != null) {
                          setModalState(() {
                            startDate = picked;
                            if (endDate.isBefore(startDate)) endDate = startDate;
                          });
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.calendar_today, size: 16),
                      label: Text('To: ${DateFormat('dd MMM').format(endDate)}'),
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: ctx,
                          initialDate: endDate,
                          firstDate: startDate,
                          lastDate: DateTime.now().add(const Duration(days: 180)),
                        );
                        if (picked != null) setModalState(() => endDate = picked);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              TextField(controller: reasonCtrl, maxLines: 2, decoration: const InputDecoration(labelText: 'Reason *', border: OutlineInputBorder())),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: AsmitaPalette.deepNavy, foregroundColor: Colors.white),
                  onPressed: saving
                      ? null
                      : () async {
                          if (reasonCtrl.text.trim().isEmpty) {
                            AsmitaToast.show(context, message: 'Please enter a reason', type: AsmitaToastType.error);
                            return;
                          }
                          setModalState(() => saving = true);
                          try {
                            await _repo.createLeave({
                              'society_id': _resolveSocietyId(),
                              'leave_type': leaveType,
                              'start_date': DateFormat('yyyy-MM-dd').format(startDate),
                              'end_date': DateFormat('yyyy-MM-dd').format(endDate),
                              'reason': reasonCtrl.text.trim(),
                            });
                            if (ctx.mounted) Navigator.pop(ctx);
                            if (mounted) {
                              AsmitaToast.show(context, message: 'Leave request submitted', type: AsmitaToastType.success);
                              _loadAll();
                            }
                          } catch (_) {
                            setModalState(() => saving = false);
                            if (mounted) AsmitaToast.show(context, message: 'Failed to submit leave', type: AsmitaToastType.error);
                          }
                        },
                  child: Text(saving ? 'Submitting...' : 'Submit Request'),
                ),
              ),
            ],
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

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AsmitaPalette.surface(context),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: MediaQuery.of(ctx).viewInsets.bottom + 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Post HR Notice / Broadcast', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AsmitaPalette.textPrimary(context))),
              const SizedBox(height: 12),
              TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Title *', border: OutlineInputBorder())),
              const SizedBox(height: 10),
              TextField(controller: descCtrl, maxLines: 3, decoration: const InputDecoration(labelText: 'Message *', border: OutlineInputBorder())),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                initialValue: priority,
                decoration: const InputDecoration(labelText: 'Priority', border: OutlineInputBorder()),
                items: const [
                  DropdownMenuItem(value: 'Normal', child: Text('Normal')),
                  DropdownMenuItem(value: 'High', child: Text('High')),
                  DropdownMenuItem(value: 'Urgent', child: Text('Urgent')),
                ],
                onChanged: (v) => setModalState(() => priority = v ?? 'Normal'),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: AsmitaPalette.deepNavy, foregroundColor: Colors.white),
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
                  child: Text(saving ? 'Publishing...' : 'Publish Notice'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bg = Theme.of(context).brightness == Brightness.dark ? AsmitaPalette.systemBGDark : AsmitaPalette.systemBG;

    return Scaffold(
      backgroundColor: bg,
      body: Column(
        children: [
          AsmitaPrimaryHeader(
            showBackButton: true,
            subtitleOverride: 'HR Hub',
            userInitials: _currentUserName().isNotEmpty ? _currentUserName()[0].toUpperCase() : 'H',
          ),
          _buildKpiStrip(),
          Container(
            color: AsmitaPalette.surface(context),
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              labelColor: AsmitaPalette.primary(context),
              unselectedLabelColor: AsmitaPalette.textSecondary(context),
              indicatorColor: AsmitaPalette.primary(context),
              tabs: const [
                Tab(text: 'Attendance'),
                Tab(text: 'People & Invites'),
                Tab(text: 'Leaves & WFH'),
                Tab(text: 'Visits & Notices'),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildAttendanceTab(),
                      _buildPeopleTab(),
                      _buildLeavesTab(),
                      _buildVisitsAndNoticesTab(),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildKpiStrip() {
    return Container(
      color: AsmitaPalette.surface(context),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _kpiChip('On-Site', _summary['on_site_count'] ?? 0, Colors.green),
            _kpiChip('Checked Out', _summary['checked_out_count'] ?? 0, Colors.blueGrey),
            _kpiChip('Not Marked', _summary['not_marked_count'] ?? 0, Colors.orange),
            _kpiChip('Pending Invites', _summary['pending_invites_count'] ?? 0, Colors.amber.shade800),
            _kpiChip('Leave Req', _summary['pending_leaves_count'] ?? 0, Colors.indigo),
            _kpiChip('Reg Req', _summary['pending_regularizations_count'] ?? 0, Colors.deepPurple),
          ],
        ),
      ),
    );
  }

  Widget _kpiChip(String label, dynamic count, Color color) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Text('$count', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: color)),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AsmitaPalette.textPrimary(context))),
        ],
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

    final pendingRegs = _regularizations.where((r) => r['status'] == 'PENDING').toList();

    return AppRefresh(
      onRefresh: _loadAll,
      child: ListView(
        padding: const EdgeInsets.all(14),
        children: [
          TextField(
            controller: _searchController,
            onChanged: (v) => setState(() => _searchQuery = v.trim()),
            decoration: InputDecoration(
              hintText: 'Search employee or department...',
              prefixIcon: const Icon(Icons.search, size: 20),
              filled: true,
              fillColor: AsmitaPalette.surface(context),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AsmitaPalette.border(context))),
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
            ),
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _filterChip('All', _attendanceFilter == 'ALL', () => setState(() => _attendanceFilter = 'ALL')),
                _filterChip('In (On-Site)', _attendanceFilter == 'IN', () => setState(() => _attendanceFilter = 'IN')),
                _filterChip('Out', _attendanceFilter == 'OUT', () => setState(() => _attendanceFilter = 'OUT')),
                _filterChip('Not Marked', _attendanceFilter == 'NOT_MARKED', () => setState(() => _attendanceFilter = 'NOT_MARKED')),
                _filterChip(
                  'Regularizations (${pendingRegs.length})',
                  _showRegularizations,
                  () => setState(() => _showRegularizations = !_showRegularizations),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          if (_showRegularizations) ...[
            Text('Attendance Regularizations', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AsmitaPalette.textPrimary(context))),
            const SizedBox(height: 8),
            if (_regularizations.isEmpty)
              _emptyCard('No regularization requests yet')
            else
              ..._regularizations.map((r) => _buildRegularizationCard(r)),
            const Divider(height: 24),
          ],
          if (filtered.isEmpty)
            _emptyCard('No attendance records match this filter')
          else
            ...filtered.map((item) => _buildAttendanceCard(item)),
        ],
      ),
    );
  }

  Widget _buildAttendanceCard(Map<String, dynamic> item) {
    final st = (item['current_status'] ?? 'NOT_MARKED').toString();
    final Color badgeColor = st == 'IN' ? Colors.green : (st == 'OUT' ? Colors.blueGrey : Colors.orange);
    final String badgeText = st == 'IN' ? 'ON-SITE' : (st == 'OUT' ? 'CHECKED OUT' : 'NOT MARKED');

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AsmitaPalette.surface(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AsmitaPalette.border(context)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: AsmitaPalette.subtleAccent(context),
            child: Text(
              (item['full_name'] ?? 'E').toString().isNotEmpty ? item['full_name'].toString()[0].toUpperCase() : 'E',
              style: TextStyle(fontWeight: FontWeight.w700, color: AsmitaPalette.primary(context)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text((item['full_name'] ?? 'Employee').toString(), style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AsmitaPalette.textPrimary(context))),
                Text(
                  '${item['department'] ?? 'General'} • ${item['designation'] ?? 'Staff'}${(item['desk_code'] ?? '').toString().isNotEmpty ? ' • ${item['desk_code']}' : ''}',
                  style: TextStyle(fontSize: 12, color: AsmitaPalette.textSecondary(context)),
                ),
                const SizedBox(height: 4),
                Text(
                  'In: ${_formatTime(item['first_in_time'])}   Out: ${_formatTime(item['last_out_time'])}',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AsmitaPalette.textPrimary(context)),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: badgeColor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
            child: Text(badgeText, style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: badgeColor)),
          ),
        ],
      ),
    );
  }

  Widget _buildRegularizationCard(Map<String, dynamic> r) {
    final st = (r['status'] ?? 'PENDING').toString();
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AsmitaPalette.surface(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AsmitaPalette.border(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text((r['employee_name'] ?? 'Employee').toString(), style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AsmitaPalette.textPrimary(context))),
              _statusPill(st),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Date: ${_formatDate(r['attendance_date'])} | In: ${r['requested_in_time'] ?? '--'} Out: ${r['requested_out_time'] ?? '--'}',
            style: TextStyle(fontSize: 12, color: AsmitaPalette.textSecondary(context)),
          ),
          const SizedBox(height: 4),
          Text((r['reason'] ?? '').toString(), style: TextStyle(fontSize: 13, color: AsmitaPalette.textPrimary(context))),
          if (st == 'PENDING') ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _handleDecideRegularization(r['id'] as int, 'REJECTED'),
                    style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                    child: const Text('Reject'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _handleDecideRegularization(r['id'] as int, 'APPROVED'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                    child: const Text('Approve'),
                  ),
                ),
              ],
            ),
          ],
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

    return AppRefresh(
      onRefresh: _loadAll,
      child: ListView(
        padding: const EdgeInsets.all(14),
        children: [
          TextField(
            controller: _searchController,
            onChanged: (v) => setState(() => _searchQuery = v.trim()),
            decoration: InputDecoration(
              hintText: _peopleMode == 'SEATS' ? 'Search desk, cabin or occupant...' : 'Search name, phone or department...',
              prefixIcon: const Icon(Icons.search, size: 20),
              filled: true,
              fillColor: AsmitaPalette.surface(context),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AsmitaPalette.border(context))),
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _filterChip('Pending (${pendingList.length})', _peopleMode == 'PENDING', () => setState(() => _peopleMode = 'PENDING')),
              _filterChip('Directory (${_employees.length})', _peopleMode == 'ALL', () => setState(() => _peopleMode = 'ALL')),
              _filterChip('Seats (${_desks.length})', _peopleMode == 'SEATS', () => setState(() => _peopleMode = 'SEATS')),
              const Spacer(),
              IconButton(
                onPressed: _openAddEmployeeSheet,
                icon: Icon(Icons.person_add_alt_1, color: AsmitaPalette.primary(context)),
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
                color: Colors.blue.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.withValues(alpha: 0.25)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '${pendingList.length} colleague(s) have not activated their app yet.',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AsmitaPalette.textPrimary(context)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: _isBulkInviting ? null : _handleBulkInvite,
                    style: ElevatedButton.styleFrom(backgroundColor: AsmitaPalette.deepNavy, foregroundColor: Colors.white),
                    icon: _isBulkInviting
                        ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.send, size: 15),
                    label: Text(_isBulkInviting ? 'Sending...' : 'Bulk Invite'),
                  ),
                ],
              ),
            ),
          ],
          if (_peopleMode == 'SEATS') ...[
            if (filteredDesks.isEmpty)
              _emptyCard('No desks or cabins found')
            else
              ...filteredDesks.map((d) {
              final occ = d['is_occupied'] == true;
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: AsmitaPalette.surface(context),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AsmitaPalette.border(context)),
                ),
                child: Row(
                  children: [
                    Icon(occ ? Icons.person : Icons.event_seat, color: occ ? Colors.blueGrey : Colors.green, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${d['flat_number']} (Floor ${d['floor']})', style: TextStyle(fontWeight: FontWeight.w700, color: AsmitaPalette.textPrimary(context))),
                          Text(
                            occ ? 'Occupied by ${d['occupant_name'] ?? 'Colleague'}' : 'Available • ${d['department'] ?? 'Open'}',
                            style: TextStyle(fontSize: 12, color: occ ? AsmitaPalette.textSecondary(context) : Colors.green.shade700),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
          ] else if (filteredEmployees.isEmpty)
            _emptyCard('No employees found')
          else
            ...filteredEmployees.map((emp) {
              final uid = emp['user_id'] ?? emp['id'];
              final isPending = emp['approval_status'] == 'PENDING' || emp['status'] == 'Invite Pending';
              final isSendingThis = _resendingUserId != null && _resendingUserId.toString() == uid.toString();
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AsmitaPalette.surface(context),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AsmitaPalette.border(context)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text((emp['full_name'] ?? emp['name'] ?? 'Employee').toString(), style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AsmitaPalette.textPrimary(context))),
                          Text(
                            '${emp['department'] ?? 'General'} • ${emp['designation'] ?? emp['role'] ?? 'Staff'}',
                            style: TextStyle(fontSize: 12, color: AsmitaPalette.textSecondary(context)),
                          ),
                          Text(
                            '${emp['mobile_number'] ?? emp['phone'] ?? ''}${(emp['desk_code'] ?? '').toString().isNotEmpty ? ' • ${emp['desk_code']}' : ''}',
                            style: TextStyle(fontSize: 12, color: AsmitaPalette.textSecondary(context)),
                          ),
                        ],
                      ),
                    ),
                    if (isPending)
                      ElevatedButton.icon(
                        onPressed: isSendingThis ? null : () => _handleSingleInvite(emp),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8)),
                        icon: isSendingThis
                            ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Icon(Icons.send, size: 14),
                        label: const Text('Invite', style: TextStyle(fontSize: 12)),
                      )
                    else
                      _statusPill('ACTIVE'),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildLeavesTab() {
    final filtered = _leaves.where((l) => _leaveStatusFilter == 'ALL' || l['status'] == _leaveStatusFilter).toList();

    return AppRefresh(
      onRefresh: _loadAll,
      child: ListView(
        padding: const EdgeInsets.all(14),
        children: [
          Row(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _filterChip('Pending', _leaveStatusFilter == 'PENDING', () => setState(() => _leaveStatusFilter = 'PENDING')),
                      _filterChip('Approved', _leaveStatusFilter == 'APPROVED', () => setState(() => _leaveStatusFilter = 'APPROVED')),
                      _filterChip('Rejected', _leaveStatusFilter == 'REJECTED', () => setState(() => _leaveStatusFilter = 'REJECTED')),
                      _filterChip('All', _leaveStatusFilter == 'ALL', () => setState(() => _leaveStatusFilter = 'ALL')),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: _openApplyLeaveSheet,
                style: ElevatedButton.styleFrom(backgroundColor: AsmitaPalette.deepNavy, foregroundColor: Colors.white),
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Apply'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (filtered.isEmpty)
            _emptyCard('No leave or WFH requests')
          else
            ...filtered.map((l) {
              final st = (l['status'] ?? 'PENDING').toString();
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AsmitaPalette.surface(context),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AsmitaPalette.border(context)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text((l['employee_name'] ?? 'Employee').toString(), style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AsmitaPalette.textPrimary(context))),
                        _statusPill(st),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${l['leave_type']} • ${_formatDate(l['start_date'])} → ${_formatDate(l['end_date'])}',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AsmitaPalette.primary(context)),
                    ),
                    const SizedBox(height: 4),
                    Text((l['reason'] ?? '').toString(), style: TextStyle(fontSize: 13, color: AsmitaPalette.textPrimary(context))),
                    if (st == 'PENDING') ...[
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => _handleDecideLeave(l['id'] as int, 'REJECTED'),
                              style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                              child: const Text('Reject'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () => _handleDecideLeave(l['id'] as int, 'APPROVED'),
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                              child: const Text('Approve'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildVisitsAndNoticesTab() {
    return AppRefresh(
      onRefresh: _loadAll,
      child: ListView(
        padding: const EdgeInsets.all(14),
        children: [
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => AsmitaPreApproveWizard.showAsModalSheet(context, title: 'Pre-Approve Candidate'),
                  style: ElevatedButton.styleFrom(backgroundColor: AsmitaPalette.deepNavy, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 12)),
                  icon: const Icon(Icons.qr_code_2, size: 18),
                  label: const Text('Pre-Approve Candidate'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _openPostNoticeSheet,
                  style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12)),
                  icon: const Icon(Icons.campaign, size: 18),
                  label: const Text('Post HR Notice'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text('Upcoming / Recent Visitor Passes', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AsmitaPalette.textPrimary(context))),
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
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AsmitaPalette.border(context)),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(v.visitorName, style: TextStyle(fontWeight: FontWeight.w700, color: AsmitaPalette.textPrimary(context))),
                                    Text('${v.purpose ?? 'Visit'} • ${v.visitorMobile ?? ''}', style: TextStyle(fontSize: 12, color: AsmitaPalette.textSecondary(context))),
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
          Text('HR Notices & Broadcasts', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AsmitaPalette.textPrimary(context))),
          const SizedBox(height: 8),
          if (_notices.isEmpty)
            _emptyCard('No notices published yet')
          else
            ..._notices.map((n) => Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AsmitaPalette.surface(context),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AsmitaPalette.border(context)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(child: Text((n['title'] ?? '').toString(), style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AsmitaPalette.textPrimary(context)))),
                          _statusPill((n['priority'] ?? 'Normal').toString().toUpperCase()),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text((n['description'] ?? '').toString(), style: TextStyle(fontSize: 13, color: AsmitaPalette.textSecondary(context))),
                      const SizedBox(height: 6),
                      Text(_formatDate(n['created_at']), style: TextStyle(fontSize: 11, color: AsmitaPalette.textTertiary(context))),
                    ],
                  ),
                )),
        ],
      ),
    );
  }

  Widget _filterChip(String label, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? AsmitaPalette.deepNavy : AsmitaPalette.surface(context),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? AsmitaPalette.deepNavy : AsmitaPalette.border(context)),
        ),
        child: Text(
          label,
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: selected ? Colors.white : AsmitaPalette.textPrimary(context)),
        ),
      ),
    );
  }

  Widget _statusPill(String status) {
    final s = status.toUpperCase();
    final Color c = (s == 'APPROVED' || s == 'ACTIVE' || s == 'CHECKED_IN')
        ? Colors.green
        : (s == 'REJECTED' || s == 'URGENT')
            ? Colors.red
            : Colors.amber.shade800;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: c.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
      child: Text(s, style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: c)),
    );
  }

  Widget _emptyCard(String msg) {
    return Container(
      padding: const EdgeInsets.all(20),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AsmitaPalette.surface(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AsmitaPalette.border(context)),
      ),
      child: Text(msg, style: TextStyle(fontSize: 13, color: AsmitaPalette.textSecondary(context))),
    );
  }
}
