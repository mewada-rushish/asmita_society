import 'dart:math' as math;
import 'package:flutter/services.dart';
import 'package:asmita_society/core/utils/date_formatter.dart';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../../core/constants/design_system.dart';
import '../../../../core/config/env_config.dart';
import '../../../../core/widgets/asmita_toast.dart';
import 'package:asmita_society/core/network/dio_client.dart';
import 'package:asmita_society/core/security/secure_storage_service.dart';
import '../../data/models/invite_model.dart';
import '../../data/models/industrial_visit_model.dart';
import '../widgets/receptionist_reassign_sheet.dart';
import 'package:share_plus/share_plus.dart';

class InvitePassScreen extends StatefulWidget {
  final PreApprovedInvite invite;

  const InvitePassScreen({super.key, required this.invite});

  @override
  State<InvitePassScreen> createState() => _InvitePassScreenState();
}

class _InvitePassScreenState extends State<InvitePassScreen> {
  String? _hostName;
  String? _departmentName;

  @override
  void initState() {
    super.initState();
    _hostName = widget.invite.title ?? 'Assigned Host';
  }

  void _openUpdatePtmSheet() {
    final inv = widget.invite;
    final visitModel = IndustrialVisitModel(
      id: inv.id,
      requestNumber: (inv.passCode ?? inv.id.toString()),
      propertyId: inv.societyId,
      visitorName: inv.visitorName ?? inv.companyName ?? 'Visitor',
      hostName: _hostName,
      departmentName: _departmentName,
      passCode: inv.passCode,
      status: IndustrialVisitStatus.awaitingHost,
    );

    ReceptionistReassignSheet.show(
      context,
      visit: visitModel,
      societyId: inv.societyId,
      onConfirmReassign: (newHostId, cabin, desk) async {
        if (newHostId == null) return;
        try {
          final secureStorage = SecureStorageService();
          final dio = AsmitaDioClient(secureStorage).dio;
          final code = inv.passCode;
          if (code != null && code.isNotEmpty) {
            await dio.post(
              '${EnvConfig.baseUrl}/api/public/visitor/status/$code/update-ptm',
              data: {
                'host_user_id': newHostId,
                'cabin_id': cabin,
                'desk_id': desk,
              },
            );
          } else if (inv.id > 0) {
            await dio.post(
              '${EnvConfig.baseUrl}/api/public/visitor/entries/${inv.id}/update-ptm',
              data: {
                'host_user_id': newHostId,
                'cabin_id': cabin,
                'desk_id': desk,
              },
            );
          }
          if (mounted) {
            setState(() {
              _hostName = 'Executive Host #$newHostId';
            });
            AsmitaToast.show(
              context,
              message: 'Person to Meet (PTM) updated successfully!',
              type: AsmitaToastType.success,
            );
          }
        } catch (e) {
          if (mounted) {
            AsmitaToast.show(
              context,
              message: 'Failed to update PTM: $e',
              type: AsmitaToastType.error,
            );
          }
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final invite = widget.invite;
    final textTheme = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomInset = math.max(
      MediaQuery.viewPaddingOf(context).bottom,
      MediaQuery.paddingOf(context).bottom,
    );

    final overlayStyle = SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      systemNavigationBarColor: Theme.of(context).scaffoldBackgroundColor,
      systemNavigationBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      systemNavigationBarDividerColor: Colors.transparent,
    );

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: overlayStyle,
      child: Scaffold(
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
        body: SafeArea(
          top: false,
          bottom: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
            child: Container(
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
                    invite.visitorName?.isNotEmpty == true
                        ? invite.visitorName!
                        : (invite.companyName ?? invite.title ?? 'VIP Visitor'),
                    style: textTheme.titleLarge?.copyWith(fontSize: 20, fontWeight: FontWeight.w700),
                  ),
                  if (invite.passCode != null && invite.passCode!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'PASS CODE: #${invite.passCode}',
                        style: TextStyle(
                          fontFamily: 'Montserrat',
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
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
                  if (invite.passCode != null && invite.passCode!.isNotEmpty) ...[
                    _buildPassDetailRow(context, 'Pass Code', '#${invite.passCode}'),
                    const SizedBox(height: 12),
                  ],
                  _buildPassDetailRow(context, 'Person to Meet', _hostName ?? 'Not Assigned'),
                  const SizedBox(height: 12),
                  _buildPassDetailRow(context, 'Valid Until', _formatDate(invite.validTo?.toIso8601String())),
                  const SizedBox(height: 12),
                  _buildPassDetailRow(context, 'Unit / Suite', 'Unit ${invite.unitId}'),
                  const SizedBox(height: 12),
                  _buildPassDetailRow(context, 'Pass Type', invite.inviteType),
                  const SizedBox(height: 16),

                  // Update PTM Action Button
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _openUpdatePtmSheet,
                      icon: const Icon(Icons.swap_horiz_rounded, size: 16),
                      label: const Text(
                        'Update Person to Meet (PTM)',
                        style: TextStyle(
                          fontFamily: 'Montserrat',
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AsmitaPalette.deepNavy,
                        side: BorderSide(color: AsmitaPalette.deepNavy.withValues(alpha: 0.5)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Start Next Walk-in / New Pass
                  TextButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.add_circle_outline_rounded, size: 16),
                    label: const Text(
                      'Done / Check in Next Visitor',
                      style: TextStyle(
                        fontFamily: 'Montserrat',
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AsmitaPalette.textLight,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        bottomNavigationBar: Container(
          color: Theme.of(context).scaffoldBackgroundColor,
          padding: EdgeInsets.fromLTRB(
            24,
            8,
            24,
            16 + bottomInset,
          ),
          child: ElevatedButton.icon(
            onPressed: () {
              final String passDetails = '''
Visitor Pass for ${invite.companyName ?? 'Visitor'}
Unit: Flat ${invite.unitId}
Pass Type: ${invite.inviteType}
Valid Until: ${_formatDate(invite.validTo?.toIso8601String())}
Pass Code: ${invite.passCode ?? 'N/A'}

Please present this code at the gate.
''';
              // ignore: deprecated_member_use
              Share.share(passDetails);
            },
            icon: Icon(Icons.share_rounded, color: Theme.of(context).colorScheme.surface, size: 18),
            label: Text(
              'Share Invite Pass',
              style: textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.surface,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              minimumSize: const Size(double.infinity, 54),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
          ),
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