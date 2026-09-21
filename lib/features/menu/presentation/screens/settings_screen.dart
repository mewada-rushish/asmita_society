import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:asmita_society/core/constants/design_system.dart';
import 'package:asmita_society/core/widgets/asmita_loading_indicator.dart';
import 'package:asmita_society/core/widgets/asmita_sub_header.dart';
import 'package:asmita_society/core/widgets/asmita_dialog.dart';
import 'package:asmita_society/features/menu/presentation/providers/preferences_provider.dart';
import 'package:asmita_society/features/menu/presentation/screens/privacy_policy_screen.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final prefsState = ref.watch(preferencesProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            const AsmitaSubHeader(title: 'Settings'),
            Expanded(
              child: prefsState.when(
                data: (prefs) {
                  if (prefs == null) return const Center(child: Text('Failed to load preferences'));
                  return ListView(
                    physics: const ClampingScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    children: [
                      _buildSectionTitle(textTheme, 'Notifications'),
                      const SizedBox(height: 12),
                      _buildSettingsCard(
                        context,
                        children: [
                          _buildToggleRow(
                            textTheme, 
                            Icons.notifications_active_rounded, 
                            'Push Notifications', 
                            prefs.pushNotifications, 
                            true,
                            (val) => ref.read(preferencesProvider.notifier).updatePreference(pushNotifications: val)
                          ),
                          _buildToggleRow(
                            textTheme, 
                            Icons.email_rounded, 
                            'Email Alerts', 
                            prefs.emailAlerts, 
                            false,
                            (val) => ref.read(preferencesProvider.notifier).updatePreference(emailAlerts: val)
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      
                      _buildSectionTitle(textTheme, 'Preferences'),
                      const SizedBox(height: 12),
                      _buildSettingsCard(
                        context,
                        children: [
                          _buildActionRow(textTheme, Icons.language_rounded, 'Language', prefs.language, true, () {}),
                          _buildActionRow(textTheme, Icons.dark_mode_rounded, 'App Theme', prefs.appTheme, false, () {}),
                        ],
                      ),
                      const SizedBox(height: 24),
                      
                      _buildSectionTitle(textTheme, 'Security'),
                      const SizedBox(height: 12),
                      _buildSettingsCard(
                        context,
                        children: [
                          _buildActionRow(textTheme, Icons.lock_rounded, 'Change Password', '', true, () {}),
                          _buildToggleRow(
                            textTheme, 
                            Icons.fingerprint_rounded, 
                            'Biometric Login', 
                            prefs.biometricLogin, 
                            false,
                            (val) => ref.read(preferencesProvider.notifier).updatePreference(biometricLogin: val)
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      
                      _buildSectionTitle(textTheme, 'Legal & Compliance'),
                      const SizedBox(height: 12),
                      _buildSettingsCard(
                        context,
                        children: [
                          _buildActionRow(textTheme, Icons.privacy_tip_rounded, 'Privacy Policy', '', true, () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const PrivacyPolicyScreen()),
                            );
                          }),
                          _buildActionRow(textTheme, Icons.delete_forever_rounded, 'Delete Account', '', false, () {
                            _showDeleteAccountDialog(context);
                          }, textColor: AsmitaPalette.actionRed, iconColor: AsmitaPalette.actionRed),
                        ],
                      ),
                      const SizedBox(height: 24),
                    ],
                  );
                },
                loading: () => const Center(child: AsmitaLoadingIndicator(color: AsmitaPalette.actionRed, size: 28)),
                error: (err, _) => Center(child: Text('Error: $err', style: const TextStyle(color: Colors.red))),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(TextTheme textTheme, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title.toUpperCase(),
        style: textTheme.bodySmall?.copyWith(
          color: AsmitaPalette.textLight,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildSettingsCard(BuildContext context, {required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
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
      child: Column(children: children),
    );
  }

  Widget _buildToggleRow(TextTheme textTheme, IconData icon, String title, bool value, bool showBorder, ValueChanged<bool> onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: showBorder ? const Border(bottom: BorderSide(color: AsmitaPalette.borderGrey, width: 1)) : null,
      ),
      child: Row(
        children: [
          Icon(icon, color: AsmitaPalette.textLight, size: 22),
          const SizedBox(width: 16),
          Expanded(
            child: Text(title, style: textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600)),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: AsmitaPalette.deepNavy,
          ),
        ],
      ),
    );
  }

  Widget _buildActionRow(TextTheme textTheme, IconData icon, String title, String trailingText, bool showBorder, VoidCallback onTap, {Color? textColor, Color? iconColor}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          border: showBorder ? const Border(bottom: BorderSide(color: AsmitaPalette.borderGrey, width: 1)) : null,
        ),
        child: Row(
          children: [
            Icon(icon, color: iconColor ?? AsmitaPalette.textLight, size: 22),
            const SizedBox(width: 16),
            Expanded(
              child: Text(title, style: textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600, color: textColor)),
            ),
            if (trailingText.isNotEmpty) ...[
              Text(trailingText, style: textTheme.bodyMedium?.copyWith(color: AsmitaPalette.textLight)),
              const SizedBox(width: 8),
            ],
            Icon(Icons.arrow_forward_ios_rounded, size: 14, color: iconColor ?? AsmitaPalette.textLight),
          ],
        ),
      ),
    );
  }

  void _showDeleteAccountDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AsmitaDialog(
        title: 'Delete Account',
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Are you sure you want to delete your account? This action cannot be undone and will permanently remove your data.',
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel', style: TextStyle(color: AsmitaPalette.deepNavy)),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    // Add actual delete account logic here
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Account deletion requested. Support will contact you shortly.')),
                    );
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: AsmitaPalette.actionRed),
                  child: const Text('Delete', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
