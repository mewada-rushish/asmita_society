import 'package:flutter/material.dart';
import 'package:asmita_society/core/constants/design_system.dart';

class VerifiedLocalHandymen extends StatelessWidget {
  const VerifiedLocalHandymen({super.key});

  static const List<_Handyman> _handymen = [
    _Handyman(
      specialized: 'Electrician',
      name: 'Ramesh Kumar',
      rate: 'Rs. 250/hr',
    ),
    _Handyman(
      specialized: 'Plumber',
      name: 'Dilip Solanki',
      rate: 'Rs. 300/hr',
    ),
    _Handyman(
      specialized: 'Carpenter',
      name: 'Anand Viswakarma',
      rate: 'Rs. 200/hr',
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
            onPressed: () {},
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

  const _Handyman({
    required this.specialized,
    required this.name,
    required this.rate,
  });
}
