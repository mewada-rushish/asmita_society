import 'package:flutter/material.dart';
import 'package:asmita_society/core/constants/design_system.dart';
import 'package:asmita_society/core/widgets/asmita_sub_header.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    
    return Scaffold(
      backgroundColor: AsmitaPalette.systemBG,
      body: SafeArea(
        child: Column(
          children: [
            const AsmitaSubHeader(title: 'Privacy Policy'),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AsmitaPalette.borderGrey),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Privacy Policy',
                        style: textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AsmitaPalette.deepNavy,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Last Updated: September 2026',
                        style: textTheme.bodySmall?.copyWith(
                          color: AsmitaPalette.textLight,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        '1. Introduction',
                        style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Welcome to the AsmitA Society platform. This privacy policy explains how we collect, use, and protect your personal information.',
                        style: textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 20),
                      Text(
                        '2. Information We Collect',
                        style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'We collect information you provide directly to us, such as your name, contact details, property information, and communication logs within the app.',
                        style: textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 20),
                      Text(
                        '3. Data Deletion',
                        style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'You can request to delete your account and associated personal data at any time from the Settings screen. Some data may be retained for legal compliance or security purposes.',
                        style: textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
