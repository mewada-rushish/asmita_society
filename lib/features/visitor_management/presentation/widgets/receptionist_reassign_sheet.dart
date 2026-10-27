import 'package:flutter/material.dart';
import '../../../../core/constants/design_system.dart';
import '../../data/models/industrial_visit_model.dart';
import '../../../dashboard/widgets/asmita_pre_approve_wizard.dart';

/// Modal sheet for receptionist / security to:
/// 1. Update Person to Meet (PTM) / Host employee
/// 2. Reassign cabin & desk allocation
class ReceptionistReassignSheet extends StatefulWidget {
  final IndustrialVisitModel visit;
  final int? societyId;
  final Function(int? assignedUserId, int? cabinId, int? deskId) onConfirmReassign;

  const ReceptionistReassignSheet({
    super.key,
    required this.visit,
    this.societyId,
    required this.onConfirmReassign,
  });

  static Future<void> show(
    BuildContext context, {
    required IndustrialVisitModel visit,
    int? societyId,
    required Function(int? assignedUserId, int? cabinId, int? deskId) onConfirmReassign,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: ReceptionistReassignSheet(
          visit: visit,
          societyId: societyId,
          onConfirmReassign: onConfirmReassign,
        ),
      ),
    );
  }

  @override
  State<ReceptionistReassignSheet> createState() => _ReceptionistReassignSheetState();
}

class _ReceptionistReassignSheetState extends State<ReceptionistReassignSheet> {
  int? _selectedExecutiveId;
  String? _selectedExecutiveName;
  String? _selectedExecutiveDept;
  final TextEditingController _cabinController = TextEditingController();
  final TextEditingController _deskController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();

  List<Map<String, dynamic>> _allEmployees = [];
  bool _isLoading = false;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _selectedExecutiveId = widget.visit.hostUserId;
    _selectedExecutiveName = widget.visit.hostName;
    _selectedExecutiveDept = widget.visit.departmentName;

    if (widget.visit.cabinNumber != null) {
      _cabinController.text = widget.visit.cabinNumber.toString();
    }
    if (widget.visit.deskNumber != null) {
      _deskController.text = widget.visit.deskNumber.toString();
    }

    _loadEmployees();
  }

  Future<void> _loadEmployees() async {
    final sId = widget.societyId ?? widget.visit.propertyId;
    setState(() => _isLoading = true);
    try {
      final list = await AsmitaPreApproveWizard.loadSocietyEmployees(sId);
      if (!mounted) return;
      setState(() {
        _allEmployees = List.from(list);
        _isLoading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _cabinController.dispose();
    _deskController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get _filteredEmployees {
    if (_searchQuery.trim().isEmpty) return _allEmployees;
    final q = _searchQuery.trim().toLowerCase();
    return _allEmployees.where((e) {
      final name = (e['full_name'] ?? e['name'] ?? '').toString().toLowerCase();
      final dept = (e['department_name'] ?? e['department'] ?? '').toString().toLowerCase();
      final role = (e['primary_role'] ?? e['role'] ?? e['designation'] ?? '').toString().toLowerCase();
      return name.contains(q) || dept.contains(q) || role.contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Handle Drag bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AsmitaPalette.deepNavy.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.swap_horiz_rounded,
                      color: AsmitaPalette.deepNavy,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Change Person to Meet',
                          style: TextStyle(
                            fontFamily: 'Montserrat',
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Visitor: ${widget.visit.visitorName} • #${widget.visit.requestNumber}',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 12,
                            color: isDark ? Colors.white60 : AsmitaPalette.textLight,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Currently Selected PTM Banner
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF1E293B)
                      : AsmitaPalette.deepNavy.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AsmitaPalette.deepNavy.withValues(alpha: 0.15),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.person_pin_rounded,
                      color: AsmitaPalette.deepNavy,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Current / Selected PTM:',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: AsmitaPalette.textLight,
                            ),
                          ),
                          Text(
                            _selectedExecutiveName ?? widget.visit.hostName ?? 'Not Assigned',
                            style: const TextStyle(
                              fontFamily: 'Montserrat',
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AsmitaPalette.deepNavy,
                            ),
                          ),
                          if (_selectedExecutiveDept != null || widget.visit.departmentName != null)
                            Text(
                              _selectedExecutiveDept ?? widget.visit.departmentName ?? '',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 11,
                                color: isDark ? Colors.white60 : const Color(0xFF64748B),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // Search Input
              TextField(
                controller: _searchController,
                onChanged: (val) => setState(() => _searchQuery = val),
                decoration: InputDecoration(
                  hintText: 'Search person or department...',
                  hintStyle: const TextStyle(fontSize: 13, fontFamily: 'Poppins'),
                  prefixIcon: const Icon(Icons.search_rounded, size: 20),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: isDark ? const Color(0xFF1E293B) : AsmitaPalette.systemBG,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),

              const SizedBox(height: 10),

              // Employee List Section
              Expanded(
                child: _isLoading
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(20.0),
                          child: CircularProgressIndicator(strokeWidth: 2.5),
                        ),
                      )
                    : _filteredEmployees.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Text(
                                _searchQuery.isNotEmpty
                                    ? 'No employees match "$_searchQuery"'
                                    : 'No employees found in directory',
                                style: const TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 13,
                                  color: AsmitaPalette.textLight,
                                ),
                              ),
                            ),
                          )
                        : ListView.separated(
                            shrinkWrap: true,
                            itemCount: _filteredEmployees.length,
                            separatorBuilder: (_, _) => const SizedBox(height: 6),
                            itemBuilder: (context, idx) {
                              final emp = _filteredEmployees[idx];
                              final empId = emp['user_id'] is int
                                  ? emp['user_id']
                                  : int.tryParse(emp['user_id']?.toString() ?? emp['id']?.toString() ?? '') ?? 0;
                              final name = (emp['full_name'] ?? emp['name'] ?? 'Staff').toString();
                              final dept = (emp['department_name'] ?? emp['department'] ?? 'General').toString();
                              final role = (emp['primary_role'] ?? emp['designation'] ?? emp['role'] ?? '').toString();
                              final isSelected = _selectedExecutiveId == empId;

                              return InkWell(
                                onTap: () {
                                  setState(() {
                                    _selectedExecutiveId = empId;
                                    _selectedExecutiveName = name;
                                    _selectedExecutiveDept = dept;
                                  });
                                },
                                borderRadius: BorderRadius.circular(10),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? AsmitaPalette.deepNavy.withValues(alpha: 0.08)
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: isSelected
                                          ? AsmitaPalette.deepNavy
                                          : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                                      width: isSelected ? 1.5 : 1.0,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 16,
                                        backgroundColor: isSelected
                                            ? AsmitaPalette.deepNavy
                                            : AsmitaPalette.deepNavy.withValues(alpha: 0.1),
                                        child: Text(
                                          name.isNotEmpty ? name[0].toUpperCase() : 'E',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: isSelected ? Colors.white : AsmitaPalette.deepNavy,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              name,
                                              style: TextStyle(
                                                fontFamily: 'Montserrat',
                                                fontSize: 13,
                                                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            Text(
                                              '$dept${role.isNotEmpty ? " • $role" : ""}',
                                              style: TextStyle(
                                                fontFamily: 'Poppins',
                                                fontSize: 11,
                                                color: isDark ? Colors.white60 : const Color(0xFF64748B),
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ),
                                      ),
                                      if (isSelected)
                                        const Icon(
                                          Icons.check_circle_rounded,
                                          color: AsmitaPalette.deepNavy,
                                          size: 18,
                                        ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
              ),

              const SizedBox(height: 12),

              // Optional Cabin & Desk
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Cabin (Optional):',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 4),
                        TextField(
                          controller: _cabinController,
                          keyboardType: TextInputType.text,
                          decoration: InputDecoration(
                            hintText: 'e.g. 104',
                            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Desk (Optional):',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 4),
                        TextField(
                          controller: _deskController,
                          keyboardType: TextInputType.text,
                          decoration: InputDecoration(
                            hintText: 'e.g. Desk-02',
                            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Confirm Button
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  final cabin = int.tryParse(_cabinController.text.trim());
                  final desk = int.tryParse(_deskController.text.trim());
                  widget.onConfirmReassign(_selectedExecutiveId, cabin, desk);
                },
                icon: const Icon(Icons.check_rounded, size: 18),
                label: const Text(
                  'Confirm Person to Meet',
                  style: TextStyle(
                    fontFamily: 'Montserrat',
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AsmitaPalette.deepNavy,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

