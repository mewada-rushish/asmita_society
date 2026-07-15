import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:asmita_society/core/constants/design_system.dart';
import 'package:asmita_society/core/widgets/asmita_primary_header.dart';
import 'package:asmita_society/core/widgets/asmita_bottom_sheet.dart';
import 'package:asmita_society/features/auth/bloc/auth_bloc.dart';
import 'package:asmita_society/features/auth/bloc/auth_state.dart';
import 'package:intl/intl.dart';
import '../../bloc/visitor_bloc.dart';
import '../../bloc/visitor_event.dart';
import '../../bloc/visitor_state.dart';

class VisitorHistoryScreen extends StatefulWidget {
  const VisitorHistoryScreen({super.key});

  @override
  State<VisitorHistoryScreen> createState() => _VisitorHistoryScreenState();
}

class _VisitorHistoryScreenState extends State<VisitorHistoryScreen> {
  @override
  void initState() {
    super.initState();
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated) {
      context.read<VisitorBloc>().add(LoadMyHistory(residentId: authState.user.userId));
    }
  }

  String _formatTime(String? dateStr) {
    if (dateStr == null) return '--:--';
    final date = DateTime.tryParse(dateStr);
    if (date == null) return dateStr;
    return DateFormat('hh:mm a').format(date);
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '--/--/----';
    final date = DateTime.tryParse(dateStr);
    if (date == null) return dateStr;
    final now = DateTime.now();
    if (date.year == now.year && date.month == now.month && date.day == now.day) {
      return 'Today';
    }
    if (date.year == now.year && date.month == now.month && date.day == now.day - 1) {
      return 'Yesterday';
    }
    return DateFormat('MMM dd, yyyy').format(date);
  }

  IconData _getIconForCategory(String category) {
    switch (category.toLowerCase()) {
      case 'delivery': return Icons.delivery_dining_rounded;
      case 'cab': return Icons.directions_car_rounded;
      case 'visiting help': return Icons.build_rounded;
      case 'guest': return Icons.person_outline_rounded;
      default: return Icons.person_outline_rounded;
    }
  }

  Color _getColorForBrand(String brand) {
    switch (brand.toLowerCase()) {
      case 'amazon': return const Color(0xFFFF9900);
      case 'flipkart': return const Color(0xFF2874F0);
      case 'zomato': return const Color(0xFFCB202D);
      case 'swiggy': return const Color(0xFFFC8019);
      case 'uber': return Colors.black;
      case 'ola': return const Color(0xFF37B44E);
      case 'rapido': return const Color(0xFFF9D100);
      case 'blinkit': return const Color(0xFFF8CB46);
      case 'zepto': return const Color(0xFF38153A);
      default: return AsmitaPalette.deepNavy;
    }
  }

  void _showVisitorDetailsModal(BuildContext context, Map<String, dynamic> visitor) {
    final textTheme = Theme.of(context).textTheme;

    final name = visitor['visitor_name'] ?? visitor['title'] ?? 'Unknown';
    final company = visitor['company_name'] ?? visitor['purpose'] ?? 'Visitor';
    final category = visitor['invite_sub_type'] ?? visitor['purpose'] ?? 'Guest';
    final isPreApproved = visitor['record_type'] == 'PRE_APPROVED';
    final entryTime = visitor['entry_time'] ?? visitor['created_at'];
    final exitTime = visitor['exit_time'] ?? visitor['valid_to'];
    final status = visitor['status'] ?? 'Active';
    final brandColor = _getColorForBrand(company);

    showAsmitaBottomSheet(
      context: context,
      title: name,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Visitor Avatar with High-Assurance Enclosed Border
          Center(
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: brandColor, width: 2),
              ),
              child: CircleAvatar(
                radius: 36,
                backgroundColor: AsmitaPalette.systemBG,
                child: Icon(
                  _getIconForCategory(category), 
                  color: brandColor, 
                  size: 32
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          // Header Labels
          Center(
            child: Text(
              name,
              style: const TextStyle(
                fontFamily: 'Montserrat',
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AsmitaPalette.deepNavy,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: brandColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '$category • $company',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: brandColor,
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Divider(color: AsmitaPalette.borderGrey, height: 1),
          const SizedBox(height: 20),

          // Data Parameters Section
          _buildDetailRow(textTheme, label: 'Record Type', value: isPreApproved ? 'Pre-Approved' : 'Walk-In', isHighlight: true),
          _buildDetailRow(textTheme, label: 'Gate Access Status', value: status, isStatus: status.toLowerCase() == 'exited'),
          _buildDetailRow(textTheme, label: 'Arrival Date', value: _formatDate(entryTime)),
          _buildDetailRow(textTheme, label: 'Entry Boundary Check', value: visitor['gate_number'] ?? 'Gate 1'),
          _buildDetailRow(textTheme, label: 'Inbound Timestamp', value: _formatTime(entryTime)),
          _buildDetailRow(textTheme, label: 'Outbound Timestamp', value: _formatTime(exitTime)),
          
          const SizedBox(height: 20),
          
          // Bottom Action Call Button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AsmitaPalette.actionRed,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text(
                'Dismiss Entry Records',
                style: TextStyle(
                  fontFamily: 'Montserrat',
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(
    TextTheme textTheme, {
    required String label,
    required String value,
    bool isStatus = false,
    bool isHighlight = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: textTheme.bodyMedium?.copyWith(
              fontFamily: 'Poppins',
              fontSize: 13,
              color: AsmitaPalette.textLight,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (isStatus)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle_outline_rounded, color: Color(0xFF388E3C), size: 14),
                  SizedBox(width: 4),
                  Text(
                    'Exited Gateway',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF388E3C),
                    ),
                  ),
                ],
              ),
            )
          else
            Text(
              value,
              style: textTheme.bodyLarge?.copyWith(
                fontFamily: 'Poppins',
                fontSize: 13,
                fontWeight: isHighlight ? FontWeight.w700 : FontWeight.w600,
                color: isHighlight ? AsmitaPalette.actionRed : AsmitaPalette.deepNavy,
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AsmitaPalette.systemBG,
      body: Column(
        children: [
          // Aligned Unified Header Structure matches Dashboard Layouts seamlessly
          const AsmitaPrimaryHeader(subtitle: 'Gate Records'),
          
          // Inline contextual back arrow support dynamically rendered only if pushed as an explicit page route
          if (Navigator.canPop(context))
            Container(
              color: AsmitaPalette.systemBG,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  InkWell(
                    onTap: () => Navigator.pop(context),
                    borderRadius: BorderRadius.circular(8),
                    child: const Padding(
                      padding: EdgeInsets.all(4.0),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.arrow_back_ios_new_rounded, size: 14, color: AsmitaPalette.deepNavy),
                          SizedBox(width: 6),
                          Text(
                            'Back to System',
                            style: TextStyle(
                              fontFamily: 'Montserrat',
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AsmitaPalette.deepNavy,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
          Expanded(
            child: BlocBuilder<VisitorBloc, VisitorState>(
              builder: (context, state) {
                if (state is VisitorLoading) {
                  return const Center(child: CircularProgressIndicator());
                } else if (state is VisitorError) {
                  return Center(
                    child: Text(
                      state.message,
                      style: const TextStyle(color: AsmitaPalette.actionRed, fontFamily: 'Poppins'),
                    ),
                  );
                } else if (state is VisitorHistoryLoaded) {
                  final history = state.history;
                  if (history.isEmpty) {
                    return const Center(
                      child: Text(
                        'No visitor records found.',
                        style: TextStyle(fontFamily: 'Poppins', color: AsmitaPalette.textLight),
                      ),
                    );
                  }
                  
                  return ListView.separated(
                    padding: const EdgeInsets.all(16),
                    physics: const BouncingScrollPhysics(),
                    itemCount: history.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final item = history[index];
                      final category = item['invite_sub_type'] ?? item['purpose'] ?? 'Guest';
                      final company = item['company_name'] ?? item['purpose'] ?? 'Visitor';
                      final gate = item['gate_number'] ?? 'Gate 1';
                      final entryTimeStr = item['entry_time'] ?? item['created_at'];
                      final isPreApproved = item['record_type'] == 'PRE_APPROVED';
                      final brandColor = _getColorForBrand(company);
                      final iconData = _getIconForCategory(category);
                      
                      return InkWell(
                        onTap: () => _showVisitorDetailsModal(context, item),
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AsmitaPalette.borderGrey, width: 1.5),
                          ),
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: const BoxDecoration(
                                  color: AsmitaPalette.systemBG, 
                                  shape: BoxShape.circle
                                ),
                                child: Icon(
                                  iconData, 
                                  color: brandColor, 
                                  size: 22
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '$category • $company',
                                      style: textTheme.titleLarge?.copyWith(
                                        fontFamily: 'Montserrat',
                                        fontSize: 14, 
                                        fontWeight: FontWeight.w700,
                                        color: AsmitaPalette.deepNavy,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Entered via $gate',
                                      style: textTheme.bodyMedium?.copyWith(
                                        fontFamily: 'Poppins',
                                        fontSize: 12, 
                                        fontWeight: FontWeight.w500,
                                        color: AsmitaPalette.textLight,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    _formatTime(entryTimeStr),
                                    style: textTheme.bodyLarge?.copyWith(
                                      fontFamily: 'Poppins',
                                      fontSize: 13, 
                                      fontWeight: FontWeight.w600,
                                      color: AsmitaPalette.deepNavy,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: isPreApproved ? const Color(0xFFE3F2FD) : const Color(0xFFFCE4EC),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      isPreApproved ? 'PRE' : 'WALK-IN',
                                      style: textTheme.bodyMedium?.copyWith(
                                        fontFamily: 'Poppins',
                                        fontSize: 9, 
                                        color: isPreApproved ? const Color(0xFF1976D2) : const Color(0xFFC2185B), 
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                }
                return const SizedBox();
              },
            ),
          ),
        ],
      ),
    );
  }
}