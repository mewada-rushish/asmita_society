import 'package:flutter/material.dart';
import 'package:asmita_society/core/constants/design_system.dart';
import 'package:asmita_society/core/widgets/asmita_primary_header.dart';

class VisitorHistoryScreen extends StatelessWidget {
  const VisitorHistoryScreen({super.key});

  // Comprehensive Mock Dataset for realistic and unique details on selection
  static const List<Map<String, dynamic>> _mockHistory = [
    {
      'name': 'Ramesh Kumar',
      'company': 'Amazon',
      'category': 'Delivery',
      'entryTime': '04:25 PM',
      'exitTime': '04:45 PM',
      'duration': '20 mins',
      'gate': 'Gate 2',
      'date': 'Today',
      'status': 'Exited',
      'icon': Icons.delivery_dining_rounded,
      'brandColor': Color(0xFFFF9900),
    },
    {
      'name': 'Amit Sharma',
      'company': 'Zomato',
      'category': 'Delivery',
      'entryTime': '01:15 PM',
      'exitTime': '01:32 PM',
      'duration': '17 mins',
      'gate': 'Gate 1',
      'date': 'Today',
      'status': 'Exited',
      'icon': Icons.fastfood_rounded,
      'brandColor': Color(0xFFCB202D),
    },
    {
      'name': 'Suresh Raina',
      'company': 'Uber',
      'category': 'Cab',
      'entryTime': '11:04 AM',
      'exitTime': '11:12 AM',
      'duration': '8 mins',
      'gate': 'Gate 1',
      'date': 'Today',
      'status': 'Exited',
      'icon': Icons.directions_car_rounded,
      'brandColor': Colors.black,
    },
    {
      'name': 'Mahesh Babu',
      'company': 'Urban Company',
      'category': 'Visiting Help',
      'entryTime': '09:30 AM',
      'exitTime': '11:45 AM',
      'duration': '2 hrs 15 mins',
      'gate': 'Gate 2',
      'date': 'Today',
      'status': 'Exited',
      'icon': Icons.build_rounded,
      'brandColor': AsmitaPalette.deepNavy,
    },
    {
      'name': 'Vikram Singh',
      'company': 'Swiggy',
      'category': 'Delivery',
      'entryTime': '09:15 PM',
      'exitTime': '09:28 PM',
      'duration': '13 mins',
      'gate': 'Gate 2',
      'date': 'Yesterday',
      'status': 'Exited',
      'icon': Icons.delivery_dining_rounded,
      'brandColor': Color(0xFFFC8019),
    },
    {
      'name': 'Sunil Gavaskar',
      'company': 'Dunzo',
      'category': 'Delivery',
      'entryTime': '04:10 PM',
      'exitTime': '04:28 PM',
      'duration': '18 mins',
      'gate': 'Gate 1',
      'date': 'Yesterday',
      'status': 'Exited',
      'icon': Icons.local_shipping_rounded,
      'brandColor': Color(0xFF00E676),
    },
    {
      'name': 'Rahul Dravid',
      'company': 'Ola Cabs',
      'category': 'Cab',
      'entryTime': '02:05 PM',
      'exitTime': '02:12 PM',
      'duration': '7 mins',
      'gate': 'Gate 2',
      'date': 'Yesterday',
      'status': 'Exited',
      'icon': Icons.directions_car_rounded,
      'brandColor': Color(0xFF37B44E),
    },
    {
      'name': 'Karan Johar',
      'company': 'Blinkit',
      'category': 'Delivery',
      'entryTime': '10:40 AM',
      'exitTime': '10:52 AM',
      'duration': '12 mins',
      'gate': 'Gate 1',
      'date': 'Yesterday',
      'status': 'Exited',
      'icon': Icons.shopping_basket_rounded,
      'brandColor': Color(0xFFF8CB46),
    },
  ];

  void _showVisitorDetailsModal(BuildContext context, Map<String, dynamic> visitor) {
    final textTheme = Theme.of(context).textTheme;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        top: false, // Ensures protection against bottom system/software navigation overlays
        child: Padding(
          padding: EdgeInsets.only(
            left: 24, 
            right: 24, 
            top: 12, 
            bottom: MediaQuery.of(ctx).padding.bottom + 24
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Bottom Sheet Drag Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              
              // Visitor Avatar with High-Assurance Enclosed Border
              Center(
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: visitor['brandColor'] as Color, width: 2),
                  ),
                  child: CircleAvatar(
                    radius: 36,
                    backgroundColor: AsmitaPalette.systemBG,
                    child: Icon(
                      visitor['icon'] as IconData, 
                      color: visitor['brandColor'] as Color, 
                      size: 32
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // Header Labels (Montserrat for structural emphasis)
              Center(
                child: Text(
                  visitor['name'] as String,
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
                    color: (visitor['brandColor'] as Color).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${visitor['category']} • ${visitor['company']}',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: visitor['brandColor'] as Color,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Divider(color: AsmitaPalette.borderGrey, height: 1),
              const SizedBox(height: 20),

              // Data Parameters Section (Poppins for legible data layouts)
              _buildDetailRow(textTheme, label: 'Gate Access Status', value: visitor['status'] as String, isStatus: true),
              _buildDetailRow(textTheme, label: 'Arrival Date', value: visitor['date'] as String),
              _buildDetailRow(textTheme, label: 'Entry Boundary Check', value: visitor['gate'] as String),
              _buildDetailRow(textTheme, label: 'Inbound Timestamp', value: visitor['entryTime'] as String),
              _buildDetailRow(textTheme, label: 'Outbound Timestamp', value: visitor['exitTime'] as String),
              _buildDetailRow(textTheme, label: 'Total Security Cycle Duration', value: visitor['duration'] as String, isHighlight: true),
              
              const SizedBox(height: 20),
              
              // Bottom Action Call Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
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
        ),
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
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              physics: const BouncingScrollPhysics(),
              itemCount: _mockHistory.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final item = _mockHistory[index];
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
                            item['icon'] as IconData, 
                            color: item['brandColor'] as Color, 
                            size: 22
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${item['category']} • ${item['company']}',
                                style: textTheme.titleLarge?.copyWith(
                                  fontFamily: 'Montserrat',
                                  fontSize: 14, 
                                  fontWeight: FontWeight.w700,
                                  color: AsmitaPalette.deepNavy,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Entered via ${item['gate']}',
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
                              item['entryTime'] as String,
                              style: textTheme.bodyLarge?.copyWith(
                                fontFamily: 'Poppins',
                                fontSize: 13, 
                                fontWeight: FontWeight.w600,
                                color: AsmitaPalette.deepNavy,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              item['date'] as String,
                              style: textTheme.bodyMedium?.copyWith(
                                fontFamily: 'Poppins',
                                fontSize: 11, 
                                color: AsmitaPalette.actionRed, 
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}