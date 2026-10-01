import 'package:asmita_society/core/utils/date_formatter.dart';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../data/models/invite_model.dart';
import 'package:share_plus/share_plus.dart';

class InvitePassScreen extends StatelessWidget {
  final PreApprovedInvite invite;

  const InvitePassScreen({super.key, required this.invite});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: Theme.of(context).colorScheme.primary),
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
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Theme.of(context).dividerColor, width: 1.5),
              ),
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Text(
                    '${invite.inviteSubType.toUpperCase()} PASS',
                    style: textTheme.labelLarge?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      letterSpacing: 2,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    invite.companyName ?? 'Visitor',
                    style: textTheme.titleLarge?.copyWith(fontSize: 20, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      color: Theme.of(context).scaffoldBackgroundColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Theme.of(context).dividerColor),
                    ),
                    child: Center(
                          child: (invite.qrCode ?? '').isNotEmpty 
                            ? QrImageView(
                                data: invite.qrCode ?? '',
                                version: QrVersions.auto,
                                size: 180.0,
                                eyeStyle: QrEyeStyle(eyeShape: QrEyeShape.square, color: Theme.of(context).colorScheme.primary),
                                dataModuleStyle: QrDataModuleStyle(dataModuleShape: QrDataModuleShape.square, color: Theme.of(context).colorScheme.primary),
                              )
                            : Icon(Icons.qr_code_2_rounded, size: 140, color: Theme.of(context).colorScheme.primary),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Divider(color: Theme.of(context).dividerColor, thickness: 1.5),
                  const SizedBox(height: 16),
                  _buildPassDetailRow(context, 'Valid Until', _formatDate(invite.validTo?.toIso8601String())),
                  const SizedBox(height: 12),
                  _buildPassDetailRow(context, 'Unit', 'Flat ${invite.unitId}'),
                  const SizedBox(height: 12),
                  _buildPassDetailRow(context, 'Pass Type', invite.inviteType),
                ],
              ),
            ),
            const SizedBox(height: 40),
            ElevatedButton.icon(
              onPressed: () {
                final String passDetails = '''
Visitor Pass for ${invite.companyName ?? 'Visitor'}
Unit: Flat ${invite.unitId}
Pass Type: ${invite.inviteType}
Valid Until: ${_formatDate(invite.validTo?.toIso8601String())}
Pass Code: ${invite.passCode ?? 'N/A'}

Please present this code at the gate.
''';
                // Ignore deprecation warning for now since Share is stable or use standard Share
                // ignore: deprecated_member_use
                Share.share(passDetails);
              },
              icon: Icon(Icons.share_rounded, color: Theme.of(context).colorScheme.surface, size: 18),
              label: Text(
                'Share Invite Pass',
                style: textTheme.bodyLarge?.copyWith(color: Theme.of(context).colorScheme.surface, fontWeight: FontWeight.w600, fontSize: 14),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
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

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '--/--/----';
    final date = DateTime.tryParse(dateStr);
    if (date == null) return dateStr;
    return AppDateFormatter.formatDate(date);
  }
}