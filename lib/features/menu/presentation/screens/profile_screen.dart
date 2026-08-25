import 'package:flutter/material.dart';
import 'package:asmita_society/core/constants/design_system.dart';
import 'package:asmita_society/core/widgets/asmita_sub_header.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    
    return Scaffold(
      backgroundColor: AsmitaPalette.systemBG,
      body: SafeArea(
        child: Column(
          children: [
            const AsmitaSubHeader(title: 'Profile'),
            Expanded(
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildProfileHeader(textTheme),
                    const SizedBox(height: 24),
                    _buildDetailsSection(textTheme),
                    const SizedBox(height: 24),
                    _buildEditButton(textTheme),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader(TextTheme textTheme) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AsmitaPalette.borderGrey, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: AsmitaPalette.deepNavy,
            child: Text(
              'RM', 
              style: textTheme.titleLarge?.copyWith(color: Colors.white, fontSize: 24)
            ),
          ),
          const SizedBox(height: 16),
          Text('Rushish Mewada', style: textTheme.titleLarge?.copyWith(fontSize: 20, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text('Flat A-402', style: textTheme.bodyLarge?.copyWith(color: AsmitaPalette.textLight)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AsmitaPalette.actionRed.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text('ADMIN', style: textTheme.bodySmall?.copyWith(color: AsmitaPalette.actionRed, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsSection(TextTheme textTheme) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AsmitaPalette.borderGrey, width: 1.5),
      ),
      child: Column(
        children: [
          _buildDetailRow(textTheme, Icons.email_rounded, 'Email', 'rushish@example.com', true),
          _buildDetailRow(textTheme, Icons.phone_rounded, 'Phone', '+91 9876543210', true),
          _buildDetailRow(textTheme, Icons.calendar_today_rounded, 'Move-in Date', '15 Aug 2021', false),
        ],
      ),
    );
  }

  Widget _buildDetailRow(TextTheme textTheme, IconData icon, String label, String value, bool showBorder) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: showBorder ? const Border(bottom: BorderSide(color: AsmitaPalette.borderGrey, width: 1)) : null,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AsmitaPalette.deepNavy.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AsmitaPalette.deepNavy, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: textTheme.bodyMedium?.copyWith(color: AsmitaPalette.textLight, fontSize: 12)),
                const SizedBox(height: 2),
                Text(value, style: textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600, fontSize: 14)),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildEditButton(TextTheme textTheme) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () {},
        style: ElevatedButton.styleFrom(
          backgroundColor: AsmitaPalette.deepNavy,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 0,
        ),
        child: Text('Edit Profile', style: textTheme.titleMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.w600)),
      ),
    );
  }
}
