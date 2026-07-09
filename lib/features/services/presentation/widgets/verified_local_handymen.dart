import 'package:flutter/material.dart';
import 'package:asmita_society/core/constants/design_system.dart';
import 'package:url_launcher/url_launcher.dart';

class VerifiedLocalHandymen extends StatelessWidget {
  const VerifiedLocalHandymen({super.key});

  static const List<_Handyman> _handymen = [
    _Handyman(
      specialized: 'Electrician',
      name: 'Ramesh Kumar',
      phoneNumber: '+919876543210',
      rating: 4.8,
      jobsCompleted: 124,
    ),
    _Handyman(
      specialized: 'Plumber',
      name: 'Dilip Solanki',
      phoneNumber: '+919876543211',
      rating: 4.6,
      jobsCompleted: 89,
    ),
    _Handyman(
      specialized: 'Carpenter',
      name: 'Anand Viswakarma',
      phoneNumber: '+919876543212',
      rating: 4.9,
      jobsCompleted: 210,
    ),
  ];

  // Helper to map handyman specialty to a specific icon
  IconData _getHandymanIcon(String specialty) {
    switch (specialty.toLowerCase()) {
      case 'electrician':
        return Icons.electrical_services_rounded;
      case 'plumber':
        return Icons.plumbing_rounded;
      case 'carpenter':
        return Icons.carpenter_rounded;
      default:
        return Icons.build_circle_outlined; // Default fallback icon
    }
  }

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
            return _HandymanRow(handyman: handyman, icon: _getHandymanIcon(handyman.specialized));
          },
        ),
      ],
    );
  }
}

class _HandymanRow extends StatelessWidget {
  final _Handyman handyman;
  final IconData icon;

  const _HandymanRow({required this.handyman, required this.icon});

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
            child: Icon(
              icon,
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
                  handyman.specialized,
                  style: textTheme.bodyMedium?.copyWith(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () async {
              final Uri url = Uri.parse('tel:${handyman.phoneNumber}');
              if (await canLaunchUrl(url)) {
                await launchUrl(url);
              }
            },
            icon: const Icon(Icons.call_rounded, color: AsmitaPalette.actionRed, size: 18),
            style: IconButton.styleFrom(
              backgroundColor: AsmitaPalette.actionRed.withValues(alpha: 0.08),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.all(10),
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
  final String phoneNumber;
  final double rating;
  final int jobsCompleted;

  const _Handyman({
    required this.specialized,
    required this.name,
    required this.phoneNumber,
    required this.rating,
    required this.jobsCompleted,
  });
}
