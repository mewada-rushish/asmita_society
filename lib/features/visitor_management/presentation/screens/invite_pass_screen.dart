import 'package:flutter/material.dart';
import 'package:asmita_society/core/constants/design_system.dart';

class InvitePassScreen extends StatelessWidget {
  const InvitePassScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AsmitaPalette.systemBG,
      appBar: AppBar(
        backgroundColor: AsmitaPalette.systemBG,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AsmitaPalette.deepNavy),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Visitor Pass',
          style: textTheme.titleLarge?.copyWith(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AsmitaPalette.borderGrey, width: 1.5),
              ),
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Text(
                    'GUEST PASS',
                    style: textTheme.labelLarge?.copyWith(
                      color: AsmitaPalette.actionRed,
                      letterSpacing: 2,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Rahul Sharma',
                    style: textTheme.titleLarge?.copyWith(fontSize: 20, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      color: AsmitaPalette.systemBG,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AsmitaPalette.borderGrey),
                    ),
                    child: const Center(
                      child: Icon(Icons.qr_code_2_rounded, size: 140, color: AsmitaPalette.deepNavy),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Divider(color: AsmitaPalette.borderGrey, thickness: 1.5),
                  const SizedBox(height: 16),
                  _buildPassDetailRow(context, 'Valid On', '02 Jun 2026'),
                  const SizedBox(height: 12),
                  _buildPassDetailRow(context, 'Unit', 'Flat A-402'),
                  const SizedBox(height: 12),
                  _buildPassDetailRow(context, 'Code', 'ASM-9821'),
                ],
              ),
            ),
            const SizedBox(height: 40),
            ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.share_rounded, color: Colors.white, size: 18),
              label: Text(
                'Share Invite Pass',
                style: textTheme.bodyLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AsmitaPalette.deepNavy,
                minimumSize: const Size(double.infinity, 54),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPassDetailRow(BuildContext context, String label, String value) {
    final textTheme = Theme.of(context).textTheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: textTheme.bodyMedium?.copyWith(fontSize: 13, fontWeight: FontWeight.w500)),
        Text(value, style: textTheme.bodyLarge?.copyWith(fontSize: 14, fontWeight: FontWeight.w600)),
      ],
    );
  }
}