import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/design_system.dart';

/// Screen for Department Head (HOD) to configure delegation:
/// - Select delegate staff member from department
/// - Date range picker (start and end dates)
/// - Submits delegation to backend
class DepartmentDelegationScreen extends StatefulWidget {
  final int departmentId;
  final String departmentName;

  const DepartmentDelegationScreen({
    super.key,
    this.departmentId = 1,
    this.departmentName = 'Accounts',
  });

  @override
  State<DepartmentDelegationScreen> createState() => _DepartmentDelegationScreenState();
}

class _DepartmentDelegationScreenState extends State<DepartmentDelegationScreen> {
  int? _selectedDelegateId;
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now().add(const Duration(days: 7));
  bool _isSubmitting = false;

  final List<Map<String, dynamic>> _departmentStaff = [
    {'id': 102, 'name': 'Aditi Sharma', 'designation': 'Senior Accountant'},
    {'id': 103, 'name': 'Rahul Verma', 'designation': 'Accounts Officer'},
    {'id': 104, 'name': 'Pooja Iyer', 'designation': 'Junior Executive'},
  ];

  Future<void> _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AsmitaPalette.deepNavy,
              onPrimary: Colors.white,
              onSurface: AsmitaPalette.textDark,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
    }
  }

  void _submitDelegation() {
    if (_selectedDelegateId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a staff member to delegate approval authority.'),
          backgroundColor: AsmitaPalette.actionRed,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    // Simulate network submission
    Future.delayed(const Duration(milliseconds: 600), () {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Delegation active for ${widget.departmentName} from ${DateFormat('dd MMM').format(_startDate)} to ${DateFormat('dd MMM').format(_endDate)}.',
          ),
          backgroundColor: AsmitaPalette.successGreen,
        ),
      );
      Navigator.pop(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd MMM yyyy');

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${widget.departmentName} Delegation',
          style: const TextStyle(fontFamily: 'Montserrat', fontSize: 16, fontWeight: FontWeight.bold),
        ),
        backgroundColor: AsmitaPalette.deepNavy,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Banner
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AsmitaPalette.deepNavy.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AsmitaPalette.deepNavy.withValues(alpha: 0.2)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.assignment_ind_outlined, color: AsmitaPalette.deepNavy, size: 24),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'When you are out of office or in meetings, your designated delegate can approve department visitor requests on your behalf.',
                      style: TextStyle(fontSize: 13, height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Select Staff Member
            const Text(
              'Select Delegate Staff Member:',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<int>(
              initialValue: _selectedDelegateId,
              decoration: InputDecoration(
                hintText: 'Choose staff member',
                prefixIcon: const Icon(Icons.person, color: AsmitaPalette.deepNavy),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
              items: _departmentStaff.map((s) {
                return DropdownMenuItem<int>(
                  value: s['id'] as int,
                  child: Text('${s['name']} (${s['designation']})', style: const TextStyle(fontSize: 13)),
                );
              }).toList(),
              onChanged: (val) => setState(() => _selectedDelegateId = val),
            ),
            const SizedBox(height: 20),

            // Date Range Selector
            const Text(
              'Active Delegation Window:',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            InkWell(
              onTap: _selectDateRange,
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                decoration: BoxDecoration(
                  border: Border.all(color: Theme.of(context).dividerColor),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.date_range, color: AsmitaPalette.deepNavy),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '${dateFormat.format(_startDate)}  →  ${dateFormat.format(_endDate)}',
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios, size: 14, color: AsmitaPalette.textLight),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),

            ElevatedButton.icon(
              onPressed: _isSubmitting ? null : _submitDelegation,
              icon: _isSubmitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.check, color: Colors.white),
              label: const Text('Save & Activate Delegation'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AsmitaPalette.deepNavy,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
