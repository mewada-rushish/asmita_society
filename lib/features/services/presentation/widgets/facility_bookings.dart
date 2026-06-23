import 'package:flutter/material.dart';
import 'package:asmita_society/core/constants/design_system.dart';

class FacilityBookings extends StatelessWidget {
  const FacilityBookings({super.key});

  static const List<Map<String, dynamic>> _facilities = [
    {'name': 'Banquet Hall', 'capacity': '100 Guests', 'icon': Icons.celebration_rounded},
    {'name': 'Swimming Pool', 'capacity': 'Hourly Slots', 'icon': Icons.pool_rounded},
    {'name': 'Clubhouse Gym', 'capacity': 'Hourly Slots', 'icon': Icons.fitness_center_rounded},
  ];

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Book an Amenity',
          style: textTheme.titleLarge?.copyWith(
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _facilities.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final facility = _facilities[index];
            return _FacilityRow(
              name: facility['name'],
              capacity: facility['capacity'],
              icon: facility['icon'],
            );
          },
        ),
      ],
    );
  }
}

class _FacilityRow extends StatelessWidget {
  final String name;
  final String capacity;
  final IconData icon;

  const _FacilityRow({required this.name, required this.capacity, required this.icon});

  void _showBookingSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _SimpleBookingSheet(facilityName: name),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AsmitaPalette.borderGrey, width: 1.5),
      ),
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: const BoxDecoration(
              color: AsmitaPalette.systemBG,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AsmitaPalette.deepNavy, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: textTheme.titleLarge?.copyWith(fontSize: 14, fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(capacity, style: textTheme.bodyMedium?.copyWith(fontSize: 12, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () => _showBookingSheet(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: AsmitaPalette.actionRed.withOpacity(0.08),
              foregroundColor: AsmitaPalette.actionRed,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text('Book', style: textTheme.bodyLarge?.copyWith(fontSize: 12, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

class _SimpleBookingSheet extends StatefulWidget {
  final String facilityName;
  const _SimpleBookingSheet({required this.facilityName});

  @override
  State<_SimpleBookingSheet> createState() => _SimpleBookingSheetState();
}

class _SimpleBookingSheetState extends State<_SimpleBookingSheet> {
  DateTime? _selectedDate;
  String? _selectedTimeSlot;

  final List<String> _timeSlots = ['09:00 AM - 11:00 AM', '01:00 PM - 03:00 PM', '05:00 PM - 07:00 PM'];

  void _submitBooking() {
    if (_selectedDate == null || _selectedTimeSlot == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a date and time slot.'), backgroundColor: AsmitaPalette.actionRed),
      );
      return;
    }
    Navigator.pop(context); // Close sheet
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Booking successful!'), backgroundColor: Colors.green),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom + MediaQuery.of(context).padding.bottom;

    return Padding(
      padding: EdgeInsets.only(left: 24, right: 24, top: 24, bottom: bottomPadding > 0 ? bottomPadding : 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Book ${widget.facilityName}', style: textTheme.titleLarge?.copyWith(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 24),
          // Date Picker
          _buildPicker(
            context,
            icon: Icons.calendar_today_rounded,
            label: _selectedDate == null ? 'Select Date' : '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}',
            onTap: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: DateTime.now(),
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 30)),
              );
              if (date != null) setState(() => _selectedDate = date);
            },
          ),
          const SizedBox(height: 16),
          // Time Slot Picker
          _buildPicker(
            context,
            icon: Icons.access_time_rounded,
            label: _selectedTimeSlot ?? 'Select Time Slot',
            onTap: () => _showTimeSlotPicker(context),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: _submitBooking,
            style: ElevatedButton.styleFrom(
              backgroundColor: AsmitaPalette.deepNavy,
              minimumSize: const Size(double.infinity, 54),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: Text('Confirm Booking', style: textTheme.bodyLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget _buildPicker(BuildContext context, {required IconData icon, required String label, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(color: AsmitaPalette.systemBG, borderRadius: BorderRadius.circular(12)),
        child: Row(
          children: [
            Icon(icon, color: AsmitaPalette.textLight, size: 20),
            const SizedBox(width: 12),
            Expanded(child: Text(label, style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontSize: 14))),
            const Icon(Icons.keyboard_arrow_down_rounded, color: AsmitaPalette.textLight),
          ],
        ),
      ),
    );
  }

  void _showTimeSlotPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: _timeSlots.map((slot) => ListTile(
            title: Text(slot),
            onTap: () {
              setState(() => _selectedTimeSlot = slot);
              Navigator.pop(ctx);
            },
          )).toList(),
        ),
      ),
    );
  }
}