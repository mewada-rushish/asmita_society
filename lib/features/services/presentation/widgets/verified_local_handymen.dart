import 'package:flutter/material.dart';
import 'package:asmita_society/core/constants/design_system.dart';
import 'package:asmita_society/core/widgets/asmita_dialog.dart';

class VerifiedLocalHandymen extends StatelessWidget {
  const VerifiedLocalHandymen({super.key});

  static const List<_Handyman> _handymen = [
    _Handyman(
      specialized: 'Electrician',
      name: 'Ramesh Kumar',
      rate: '₹250/hr',
      rating: 4.8,
      jobsCompleted: 124,
    ),
    _Handyman(
      specialized: 'Plumber',
      name: 'Dilip Solanki',
      rate: '₹300/hr',
      rating: 4.6,
      jobsCompleted: 89,
    ),
    _Handyman(
      specialized: 'Carpenter',
      name: 'Anand Viswakarma',
      rate: '₹200/hr',
      rating: 4.9,
      jobsCompleted: 210,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Verified Local Handymen',
          style: textTheme.titleLarge?.copyWith(
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _handymen.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final handyman = _handymen[index];
            return _HandymanRow(handyman: handyman);
          },
        ),
      ],
    );
  }
}

class _HandymanRow extends StatelessWidget {
  final _Handyman handyman;

  const _HandymanRow({required this.handyman});

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
            child: const Icon(
              Icons.build_circle_outlined,
              color: AsmitaPalette.deepNavy,
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  handyman.name,
                  style: textTheme.titleLarge?.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${handyman.specialized} - ${handyman.rate}',
                  style: textTheme.bodyMedium?.copyWith(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (context) => _HandymanBookingSheet(handyman: handyman),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AsmitaPalette.systemBG,
              foregroundColor: AsmitaPalette.deepNavy,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              'Book',
              style: textTheme.bodyLarge?.copyWith(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AsmitaPalette.deepNavy,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Handyman {
  final String specialized;
  final String name;
  final String rate;
  final double rating;
  final int jobsCompleted;

  const _Handyman({
    required this.specialized,
    required this.name,
    required this.rate,
    required this.rating,
    required this.jobsCompleted,
  });
}

class _HandymanBookingSheet extends StatefulWidget {
  final _Handyman handyman;

  const _HandymanBookingSheet({required this.handyman});

  @override
  State<_HandymanBookingSheet> createState() => _HandymanBookingSheetState();
}

class _HandymanBookingSheetState extends State<_HandymanBookingSheet> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _descController = TextEditingController();
  DateTime? _selectedDate;
  String? _selectedTimeSlot;
  bool _isUrgent = false;
  final List<String> _images = [];

  final List<String> _timeSlots = [
    '09:00 AM – 11:00 AM',
    '11:00 AM – 01:00 PM',
    '01:00 PM – 03:00 PM',
    '03:00 PM – 05:00 PM',
    '05:00 PM – 07:00 PM',
  ];

  @override
  void dispose() {
    _descController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a preferred date.'), behavior: SnackBarBehavior.floating));
      return;
    }
    if (_selectedTimeSlot == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a preferred time slot.'), behavior: SnackBarBehavior.floating));
      return;
    }
    if (_images.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please upload at least one image.'), behavior: SnackBarBehavior.floating));
      return;
    }

    Navigator.pop(context); // Close booking sheet
    _showSuccessSheet();
  }

  void _showSuccessSheet() {
    AsmitaDialog.show(
      context: context,
      content: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(color: Color(0xFFE8F5E9), shape: BoxShape.circle),
                child: const Icon(Icons.check_circle_rounded, color: Color(0xFF4CAF50), size: 48),
              ),
              const SizedBox(height: 16),
              const Text('Booking Confirmed!', style: TextStyle(fontFamily: 'Montserrat', fontSize: 20, fontWeight: FontWeight.w800, color: AsmitaPalette.deepNavy)),
              const SizedBox(height: 8),
              Text('Your request has been sent to ${widget.handyman.name}.', textAlign: TextAlign.center, style: const TextStyle(fontFamily: 'Poppins', fontSize: 13, color: AsmitaPalette.textLight)),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AsmitaPalette.systemBG,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AsmitaPalette.borderGrey),
                ),
                child: Column(
                  children: [
                    _buildSummaryRow('Booking ID', '#BKG-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}'),
                    const SizedBox(height: 12),
                    _buildSummaryRow('Handyman', widget.handyman.name),
                    const SizedBox(height: 12),
                    _buildSummaryRow('Date', '${_selectedDate?.day.toString().padLeft(2, '0')}/${_selectedDate?.month.toString().padLeft(2, '0')}/${_selectedDate?.year}'),
                    const SizedBox(height: 12),
                    _buildSummaryRow('Time Slot', _selectedTimeSlot ?? ''),
                    const SizedBox(height: 12),
                    _buildSummaryRow('Status', 'Pending', statusColor: Colors.orange),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(backgroundColor: AsmitaPalette.actionRed, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0),
                  child: const Text('Done', style: TextStyle(fontFamily: 'Montserrat', color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {Color? statusColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontFamily: 'Poppins', fontSize: 13, color: AsmitaPalette.textLight)),
        Text(
          value, 
          style: TextStyle(fontFamily: 'Poppins', fontSize: 13, fontWeight: FontWeight.w700, color: statusColor ?? AsmitaPalette.deepNavy),
        ),
      ],
    );
  }

  void _showDatePickerSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: CalendarDatePicker(
            initialDate: _selectedDate ?? DateTime.now().add(const Duration(days: 1)),
            firstDate: DateTime.now(),
            lastDate: DateTime.now().add(const Duration(days: 60)),
            onDateChanged: (date) {
              setState(() => _selectedDate = date);
              Navigator.pop(ctx);
            },
          ),
        ),
      ),
    );
  }

  void _showTimeSlotPickerSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.7),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  child: Text('Available Slots', style: TextStyle(fontFamily: 'Montserrat', fontSize: 16, fontWeight: FontWeight.w800, color: AsmitaPalette.deepNavy)),
                ),
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: _timeSlots.length,
                    itemBuilder: (context, index) {
                      final slot = _timeSlots[index];
                      return ListTile(
                        title: Text(slot, style: TextStyle(fontFamily: 'Poppins', fontSize: 14, color: _selectedTimeSlot == slot ? AsmitaPalette.actionRed : AsmitaPalette.deepNavy, fontWeight: _selectedTimeSlot == slot ? FontWeight.w600 : FontWeight.normal)),
                        trailing: _selectedTimeSlot == slot ? const Icon(Icons.check, color: AsmitaPalette.actionRed) : null,
                        onTap: () {
                          setState(() => _selectedTimeSlot = slot);
                          Navigator.pop(ctx);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomSheetTrigger({required String label, required String value, required VoidCallback onTap}) {
    final isSelected = !(value.toLowerCase().contains('select'));
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(padding: const EdgeInsets.only(bottom: 6.0), child: Text(label, style: const TextStyle(fontFamily: 'Poppins', fontSize: 12, color: AsmitaPalette.textDark))),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(color: Colors.white, border: Border.all(color: AsmitaPalette.borderGrey, width: 1.2), borderRadius: BorderRadius.circular(12)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(child: Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontFamily: 'Poppins', fontSize: 13, fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal, color: isSelected ? AsmitaPalette.deepNavy : AsmitaPalette.textLight))),
                const Icon(Icons.arrow_drop_down_rounded, color: AsmitaPalette.deepNavy, size: 24),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final bottomSafeArea = MediaQuery.viewPaddingOf(context).bottom;

    return Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.90,
        ),
        child: Padding(
          padding: EdgeInsets.only(bottom: bottomInset),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: const BoxDecoration(
                      color: AsmitaPalette.systemBG,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.person_rounded, color: AsmitaPalette.deepNavy, size: 36),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.handyman.name, style: const TextStyle(fontFamily: 'Montserrat', fontSize: 16, fontWeight: FontWeight.w800, color: AsmitaPalette.deepNavy)),
                        const SizedBox(height: 2),
                        Text('${widget.handyman.specialized} • ${widget.handyman.rate}', style: const TextStyle(fontFamily: 'Poppins', fontSize: 13, fontWeight: FontWeight.w500, color: AsmitaPalette.actionRed)),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.star_rounded, color: Colors.amber, size: 16),
                            const SizedBox(width: 4),
                            Text('${widget.handyman.rating} (${widget.handyman.jobsCompleted} jobs completed)', style: const TextStyle(fontFamily: 'Poppins', fontSize: 11, color: AsmitaPalette.textLight)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: AsmitaPalette.textLight),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: AsmitaPalette.borderGrey),
            Flexible(
              child: Form(
                key: _formKey,
                child: ListView(
                  shrinkWrap: true,
                  padding: const EdgeInsets.all(20),
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(bottom: 6.0),
                      child: Text('Service Description *', style: TextStyle(fontFamily: 'Poppins', fontSize: 12, color: AsmitaPalette.textDark)),
                    ),
                    TextFormField(
                      controller: _descController,
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText: 'Describe the issue or work required...',
                        hintStyle: const TextStyle(fontFamily: 'Poppins', fontSize: 13, color: AsmitaPalette.textLight),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AsmitaPalette.borderGrey, width: 1.2)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AsmitaPalette.borderGrey, width: 1.2)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AsmitaPalette.deepNavy, width: 1.2)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      style: const TextStyle(fontFamily: 'Poppins', fontSize: 13, color: AsmitaPalette.deepNavy, fontWeight: FontWeight.w500),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) return 'Please describe the issue';
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _buildBottomSheetTrigger(
                            label: 'Preferred Date *',
                            value: _selectedDate != null
                                ? '${_selectedDate!.day.toString().padLeft(2, '0')}/${_selectedDate!.month.toString().padLeft(2, '0')}/${_selectedDate!.year}'
                                : 'Select Date',
                            onTap: _showDatePickerSheet,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildBottomSheetTrigger(
                            label: 'Preferred Time Slot *',
                            value: _selectedTimeSlot ?? 'Select Time Slot',
                            onTap: _showTimeSlotPickerSheet,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    const Padding(
                      padding: EdgeInsets.only(bottom: 6.0),
                      child: Text('Upload Images *', style: TextStyle(fontFamily: 'Poppins', fontSize: 12, color: AsmitaPalette.textDark)),
                    ),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          InkWell(
                            onTap: () {
                              setState(() => _images.add('image_${_images.length}.png'));
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                color: AsmitaPalette.systemBG,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AsmitaPalette.borderGrey, style: BorderStyle.solid),
                              ),
                              child: const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.add_a_photo_rounded, color: AsmitaPalette.textLight, size: 24),
                                  SizedBox(height: 4),
                                  Text('Add', style: TextStyle(fontFamily: 'Poppins', fontSize: 10, color: AsmitaPalette.textLight)),
                                ],
                              ),
                            ),
                          ),
                          ..._images.map((img) => Padding(
                            padding: const EdgeInsets.only(left: 8.0),
                            child: Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                color: AsmitaPalette.deepNavy.withValues(alpha: 0.05),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AsmitaPalette.borderGrey),
                              ),
                              child: Stack(
                                children: [
                                  const Center(child: Icon(Icons.image_rounded, color: AsmitaPalette.textLight, size: 32)),
                                  Positioned(
                                    top: 4,
                                    right: 4,
                                    child: InkWell(
                                      onTap: () => setState(() => _images.remove(img)),
                                      child: Container(
                                        padding: const EdgeInsets.all(2),
                                        decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                                        child: const Icon(Icons.close_rounded, size: 14, color: AsmitaPalette.actionRed),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Urgent Service', style: TextStyle(fontFamily: 'Poppins', fontSize: 13, color: AsmitaPalette.textDark, fontWeight: FontWeight.w600)),
                        Switch(
                          value: _isUrgent,
                          onChanged: (val) => setState(() => _isUrgent = val),
                          activeColor: Colors.white,
                          activeTrackColor: AsmitaPalette.actionRed,
                          inactiveThumbColor: Colors.white,
                          inactiveTrackColor: AsmitaPalette.borderGrey,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Container(
              padding: EdgeInsets.only(
                left: 20, right: 20, top: 16, 
                bottom: bottomSafeArea > 0 ? bottomSafeArea : 20,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: AsmitaPalette.borderGrey)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: const BorderSide(color: AsmitaPalette.borderGrey, width: 1.5),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Cancel', style: TextStyle(fontFamily: 'Montserrat', fontSize: 14, fontWeight: FontWeight.w700, color: AsmitaPalette.deepNavy)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _submit,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        backgroundColor: AsmitaPalette.actionRed,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Confirm Booking', style: TextStyle(fontFamily: 'Montserrat', fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white)),
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
}
