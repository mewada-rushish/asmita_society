import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/design_system.dart';
import '../../../../core/widgets/asmita_loading_indicator.dart';
import '../../../../core/widgets/asmita_primary_header.dart';
import '../../../../core/widgets/asmita_toast.dart';
import '../../../../core/widgets/asmita_animated_refresh.dart';
import '../../../../core/widgets/asmita_dialog.dart';
import '../../../../core/widgets/asmita_bottom_sheet.dart';
import '../../../../core/widgets/asmita_visitor_card.dart';
import '../../widgets/asmita_pre_approve_wizard.dart';
import '../../../auth/bloc/auth_bloc.dart';
import '../../../auth/bloc/auth_state.dart';
import '../../../visitor_management/bloc/visitor_bloc.dart';
import '../../../visitor_management/bloc/visitor_event.dart';
import '../../../visitor_management/bloc/industrial_visit_bloc.dart';
import '../../../visitor_management/bloc/industrial_visit_event.dart';
import '../../../visitor_management/bloc/industrial_visit_state.dart';
import '../../../visitor_management/data/models/industrial_visit_model.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/config/env_config.dart';

class IndustrialVisitsScreen extends StatefulWidget {
  final VoidCallback? onBack;
  final String initialFilter;

  const IndustrialVisitsScreen({super.key, this.onBack, this.initialFilter = 'ALL'});

  @override
  State<IndustrialVisitsScreen> createState() => _IndustrialVisitsScreenState();
}

class _IndustrialVisitsScreenState extends State<IndustrialVisitsScreen> {
  late String _selectedFilter = widget.initialFilter;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  final Set<int> _acknowledgedIds = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      try {
        context.read<IndustrialVisitBloc>().add(const LoadIndustrialVisits());
      } catch (_) {}
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _showPreApproveModal(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (context) => const AsmitaDialog(
        title: 'Schedule Visitor',
        content: AsmitaPreApproveWizard(),
      ),
    );

    if (!context.mounted) return;
    context.read<IndustrialVisitBloc>().add(const LoadIndustrialVisits());
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated) {
      context.read<VisitorBloc>().add(
        LoadMyHistory(residentId: authState.user.userId, isRefresh: true),
      );
    }
  }

  void _showVisitDetailsModal(BuildContext context, IndustrialVisitModel visit) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isPending = visit.isPending;
    final isExpired = visit.status == IndustrialVisitStatus.expired ||
        visit.status == IndustrialVisitStatus.cancelled ||
        visit.status == IndustrialVisitStatus.rejected;

    showAsmitaBottomSheet(
      context: context,
      title: 'Visitor Pass Details',
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Executive Boarding Pass / Digital Pass Header Card
            Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0F172A), AsmitaPalette.deepNavy],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.15),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AsmitaPalette.deepNavy.withValues(alpha: 0.35),
                    blurRadius: 14,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Upper Row: Avatar, Visitor Name, Category & Status Pill
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        _buildVisitorPhotoAvatar(visit, size: 48),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                visit.visitorName,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontFamily: 'Montserrat',
                                  fontWeight: FontWeight.bold,
                                  fontSize: 17,
                                  color: Colors.white,
                                  letterSpacing: 0.2,
                                  height: 1.2,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    visit.isDelivery
                                        ? Icons.local_shipping_outlined
                                        : Icons.badge_outlined,
                                    size: 13,
                                    color: Colors.white70,
                                  ),
                                  const SizedBox(width: 4),
                                  Flexible(
                                    child: Text(
                                      visit.deliveryCompany ??
                                          visit.purpose ??
                                          (visit.isDelivery ? 'Delivery Entry' : 'Guest Visitor'),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontFamily: 'Poppins',
                                        fontSize: 12,
                                        color: Colors.white70,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Status Badge in header (Solid white background capsule pill)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5.5),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.18),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                visit.status.iconData,
                                size: 12,
                                color: visit.status.lightTextColor,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                visit.status.label,
                                style: TextStyle(
                                  fontFamily: 'Montserrat',
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: visit.status.lightTextColor,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Perforated ticket dash divider
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: Row(
                      children: List.generate(
                        24,
                        (index) => Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 2),
                            child: Container(
                              height: 1.5,
                              color: index.isEven
                                  ? Colors.white.withValues(alpha: 0.22)
                                  : Colors.transparent,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Lower Section: Full-Width Digital Pass Code Strip
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.12),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.vpn_key_rounded,
                                      size: 11,
                                      color: Colors.white60,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'PASS CODE',
                                      style: TextStyle(
                                        fontFamily: 'Montserrat',
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white.withValues(alpha: 0.7),
                                        letterSpacing: 0.8,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  visit.passCode ?? visit.requestNumber,
                                  style: const TextStyle(
                                    fontFamily: 'Montserrat',
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    letterSpacing: 1.1,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (visit.passCode != null)
                            Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () {
                                  Clipboard.setData(ClipboardData(text: visit.passCode!));
                                  HapticFeedback.lightImpact();
                                  AsmitaToast.show(
                                    context,
                                    message: 'Pass code ${visit.passCode} copied!',
                                    type: AsmitaToastType.success,
                                  );
                                },
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: Colors.white.withValues(alpha: 0.25),
                                    ),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.copy_rounded, size: 12, color: Colors.white),
                                      SizedBox(width: 5),
                                      Text(
                                        'Copy',
                                        style: TextStyle(
                                          fontFamily: 'Montserrat',
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 2. Structured Information Card
            Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B).withValues(alpha: 0.35) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Theme.of(context).dividerColor.withValues(alpha: isDark ? 0.3 : 0.8),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildDetailRow(
                    context,
                    icon: Icons.flag_rounded,
                    label: 'Current Status',
                    customValue: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                      decoration: BoxDecoration(
                        color: visit.status.fillColor(isDark),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        visit.status.label,
                        style: TextStyle(
                          fontFamily: 'Montserrat',
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: visit.status.textColor(isDark),
                        ),
                      ),
                    ),
                  ),
                  _buildRowDivider(context),
                  _buildDetailRow(
                    context,
                    icon: Icons.business_rounded,
                    label: 'Department',
                    value: visit.departmentName ?? 'General Campus',
                  ),
                  if (visit.hostName != null && visit.hostName!.isNotEmpty) ...[
                    _buildRowDivider(context),
                    _buildDetailRow(
                      context,
                      icon: Icons.person_outline_rounded,
                      label: 'Host Person',
                      value: visit.hostName!,
                    ),
                  ],
                  if (visit.visitorMobile != null && visit.visitorMobile!.isNotEmpty) ...[
                    _buildRowDivider(context),
                    _buildDetailRow(
                      context,
                      icon: Icons.phone_outlined,
                      label: 'Visitor Contact',
                      value: visit.visitorMobile!,
                      trailing: IconButton(
                        constraints: const BoxConstraints(),
                        padding: const EdgeInsets.all(4),
                        icon: const Icon(Icons.phone_in_talk_rounded, size: 16, color: AsmitaPalette.successGreen),
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: visit.visitorMobile!));
                          HapticFeedback.lightImpact();
                          AsmitaToast.show(
                            context,
                            message: 'Phone number ${visit.visitorMobile} copied!',
                            type: AsmitaToastType.info,
                          );
                        },
                      ),
                    ),
                  ],
                  if (visit.vehicleNumber != null && visit.vehicleNumber!.isNotEmpty) ...[
                    _buildRowDivider(context),
                    _buildDetailRow(
                      context,
                      icon: Icons.directions_car_outlined,
                      label: 'Vehicle Plate',
                      customValue: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Theme.of(context).dividerColor),
                        ),
                        child: Text(
                          visit.vehicleNumber!,
                          style: const TextStyle(
                            fontFamily: 'Montserrat',
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                    ),
                  ],
                  _buildRowDivider(context),
                  _buildDetailRow(
                    context,
                    icon: Icons.access_time_rounded,
                    label: 'Scheduled Time',
                    value: visit.checkInAt != null
                        ? DateFormat('dd MMM yyyy, hh:mm a').format(visit.checkInAt!)
                        : (visit.createdAt != null
                            ? DateFormat('dd MMM yyyy, hh:mm a').format(visit.createdAt!)
                            : 'Scheduled Visit'),
                  ),
                  if (visit.checkOutAt != null) ...[
                    _buildRowDivider(context),
                    _buildDetailRow(
                      context,
                      icon: Icons.logout_rounded,
                      label: 'Check Out Time',
                      value: DateFormat('dd MMM yyyy, hh:mm a').format(visit.checkOutAt!),
                    ),
                  ],
                ],
              ),
            ),

            // 3. High-Assurance Gate Pass QR Section
            if (visit.statusToken != null && visit.statusToken!.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B).withValues(alpha: 0.35) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Theme.of(context).dividerColor.withValues(alpha: isDark ? 0.3 : 0.8),
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.qr_code_scanner_rounded,
                          size: 16,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'GATE PASS QR VERIFICATION',
                          style: TextStyle(
                            fontFamily: 'Montserrat',
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.8,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Show this QR code at the security checkpoint to scan and verify',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 11,
                        color: isDark ? AsmitaPalette.textDarkModeMuted : AsmitaPalette.textLight,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AsmitaPalette.borderGrey),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.05),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Opacity(
                            opacity: isExpired ? 0.35 : 1.0,
                            child: QrImageView(
                              data: visit.statusToken!,
                              version: QrVersions.auto,
                              size: 140.0,
                              eyeStyle: const QrEyeStyle(
                                eyeShape: QrEyeShape.square,
                                color: AsmitaPalette.deepNavy,
                              ),
                              dataModuleStyle: const QrDataModuleStyle(
                                dataModuleShape: QrDataModuleShape.square,
                                color: AsmitaPalette.deepNavy,
                              ),
                            ),
                          ),
                        ),
                        if (isExpired)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: AsmitaPalette.actionRed.withValues(alpha: 0.9),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.history_toggle_off_rounded, size: 14, color: Colors.white),
                                SizedBox(width: 4),
                                Text(
                                  'PASS EXPIRED',
                                  style: TextStyle(
                                    fontFamily: 'Montserrat',
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11,
                                    color: Colors.white,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 18),

            // 4. Action Buttons
            if (isPending) ...[
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        context.read<IndustrialVisitBloc>().add(
                              DecideVisitEvent(visitId: visit.id, action: 'DENY'),
                            );
                      },
                      icon: const Icon(Icons.close_rounded, size: 18),
                      label: const Text('Deny Entry', style: TextStyle(fontWeight: FontWeight.bold)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AsmitaPalette.actionRed,
                        side: const BorderSide(color: AsmitaPalette.actionRed, width: 1.5),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        context.read<IndustrialVisitBloc>().add(
                              DecideVisitEvent(visitId: visit.id, action: 'APPROVE'),
                            );
                      },
                      icon: const Icon(Icons.check_rounded, size: 18),
                      label: const Text('Approve Entry', style: TextStyle(fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AsmitaPalette.successGreen,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
            ] else if (visit.passCode != null) ...[
              ElevatedButton.icon(
                onPressed: () {
                  final summary = 'Visitor Pass for ${visit.visitorName}\n'
                      'Pass Code: #${visit.passCode}\n'
                      'Status: ${visit.status.label}\n'
                      'Department: ${visit.departmentName ?? "General Campus"}\n'
                      'Host: ${visit.hostName ?? "General"}';
                  Clipboard.setData(ClipboardData(text: summary));
                  HapticFeedback.lightImpact();
                  AsmitaToast.show(
                    context,
                    message: 'Pass details copied to clipboard!',
                    type: AsmitaToastType.success,
                  );
                },
                icon: const Icon(Icons.share_outlined, size: 16),
                label: const Text(
                  'Share Pass Summary',
                  style: TextStyle(
                    fontFamily: 'Montserrat',
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildVisitorPhotoAvatar(IndustrialVisitModel visit, {double size = 48}) {
    final photo = visit.visitorPhotoUrl?.trim();
    final initial = visit.visitorName.isNotEmpty
        ? visit.visitorName[0].toUpperCase()
        : 'V';

    Widget initialsFallback() {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: [
              Colors.white.withValues(alpha: 0.25),
              Colors.white.withValues(alpha: 0.08),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          initial,
          style: TextStyle(
            fontFamily: 'Montserrat',
            fontWeight: FontWeight.bold,
            fontSize: size * 0.45,
            color: Colors.white,
          ),
        ),
      );
    }

    Widget content;
    if (photo == null || photo.isEmpty) {
      content = initialsFallback();
    } else if (photo.startsWith('data:image')) {
      try {
        final commaIndex = photo.indexOf(',');
        final base64Str = commaIndex != -1 ? photo.substring(commaIndex + 1) : photo;
        final bytes = base64Decode(base64Str);
        content = Image.memory(
          bytes,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => initialsFallback(),
        );
      } catch (_) {
        content = initialsFallback();
      }
    } else if (!photo.startsWith('http://') &&
        !photo.startsWith('https://') &&
        !photo.startsWith('/') &&
        photo.length > 200) {
      try {
        final bytes = base64Decode(photo);
        content = Image.memory(
          bytes,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => initialsFallback(),
        );
      } catch (_) {
        content = initialsFallback();
      }
    } else {
      String fullUrl = photo;
      if (photo.startsWith('/')) {
        fullUrl = '${EnvConfig.baseUrl}$photo';
      }
      content = CachedNetworkImage(
        imageUrl: fullUrl,
        width: size,
        height: size,
        fit: BoxFit.cover,
        placeholder: (context, url) => Container(
          width: size,
          height: size,
          color: Colors.white.withValues(alpha: 0.1),
          child: const Center(
            child: SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            ),
          ),
        ),
        errorWidget: (context, url, error) => initialsFallback(),
      );
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.4),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipOval(child: content),
    );
  }

  Widget _buildRowDivider(BuildContext context) {
    return Divider(
      height: 1,
      thickness: 0.6,
      indent: 44,
      endIndent: 12,
      color: Theme.of(context).dividerColor.withValues(alpha: 0.5),
    );
  }

  Widget _buildDetailRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    String? value,
    Widget? customValue,
    Widget? trailing,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: Theme.of(context).colorScheme.primary),
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontFamily: 'Poppins',
              color: AsmitaPalette.textLight,
            ),
          ),
          const Spacer(),
          if (customValue != null)
            customValue
          else if (value != null)
            Text(
              value,
              style: TextStyle(
                fontFamily: 'Montserrat',
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),
          if (trailing != null) ...[
            const SizedBox(width: 4),
            trailing,
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      floatingActionButton: Padding(
        padding: EdgeInsets.only(bottom: 96.0 + MediaQuery.viewPaddingOf(context).bottom + 16.0),
        child: FloatingActionButton.extended(
          heroTag: null,
          onPressed: () => _showPreApproveModal(context),
          backgroundColor: AsmitaPalette.deepNavy,
          foregroundColor: Colors.white,
          elevation: 3,
          icon: const Icon(Icons.add_rounded, size: 20),
          label: const Text(
            'Schedule',
            style: TextStyle(
              fontFamily: 'Montserrat',
              fontWeight: FontWeight.bold,
              fontSize: 13,
              letterSpacing: 0.3,
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // 1. Unified Primary Asmita Header (Property Consistent)
          AsmitaPrimaryHeader(
            subtitleOverride: 'Visits & Passes',
            allowPropertySwitching: false,
            showBackButton: widget.onBack != null || Navigator.canPop(context),
            onBackPressed: widget.onBack,
          ),

          // 2. Scrollable Content Body with Bloc Consumer
          Expanded(
            child: BlocConsumer<IndustrialVisitBloc, IndustrialVisitState>(
              listener: (context, state) {
                if (state.status == IndustrialVisitBlocStatus.actionSuccess &&
                    state.successMessage != null) {
                  AsmitaToast.show(
                    context,
                    message: state.successMessage!,
                    type: AsmitaToastType.success,
                  );
                } else if (state.status == IndustrialVisitBlocStatus.error &&
                    state.errorMessage != null) {
                  AsmitaToast.show(
                    context,
                    message: state.errorMessage!,
                    type: AsmitaToastType.error,
                  );
                }
              },
              builder: (context, state) {
                final isLoading = state.status == IndustrialVisitBlocStatus.loading &&
                    state.visits.isEmpty;

                if (isLoading) {
                  return const Center(
                    child: AsmitaLoadingIndicator(
                      color: AsmitaPalette.deepNavy,
                      size: 32,
                    ),
                  );
                }

                final filteredVisits = state.visits.where((v) {
                  if (_selectedFilter == 'PENDING' && !v.isPending) {
                    return false;
                  }
                  if (_selectedFilter == 'APPROVED' &&
                      v.status != IndustrialVisitStatus.approved) {
                    return false;
                  }
                  if (_selectedFilter == 'INSIDE' &&
                      v.status != IndustrialVisitStatus.checkedIn) {
                    return false;
                  }
                  if (_selectedFilter == 'COMPLETED' &&
                      v.status != IndustrialVisitStatus.checkedOut) {
                    return false;
                  }

                  if (_searchQuery.isNotEmpty) {
                    final q = _searchQuery.toLowerCase();
                    final matchName = v.visitorName.toLowerCase().contains(q);
                    final org = v.deliveryCompany ?? v.purpose ?? '';
                    final matchOrg = org.toLowerCase().contains(q);
                    final matchDept = (v.departmentName ?? '').toLowerCase().contains(q);
                    final matchPass = (v.passCode ?? '').toLowerCase().contains(q);
                    final matchVehicle = (v.vehicleNumber ?? '').toLowerCase().contains(q);
                    return matchName || matchOrg || matchDept || matchPass || matchVehicle;
                  }
                  return true;
                }).toList();

                return CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    AsmitaAnimatedRefresh(
                      onRefresh: () async {
                        final bloc = context.read<IndustrialVisitBloc>();
                        final future = bloc.stream
                            .firstWhere((s) => s.status != IndustrialVisitBlocStatus.loading)
                            .timeout(const Duration(seconds: 4), onTimeout: () => bloc.state);
                        bloc.add(const LoadIndustrialVisits());
                        await future;
                      },
                    ),

                    // Search Box
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
                        child: Container(
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF1E293B) : Theme.of(context).colorScheme.surface,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isDark ? const Color(0xFF334155) : Theme.of(context).dividerColor,
                              width: 1.2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.03),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: TextField(
                            controller: _searchController,
                            onChanged: (val) => setState(() => _searchQuery = val.trim()),
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 13,
                              color: isDark ? Colors.white : AsmitaPalette.textDark,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Search visitor, company, pass code, vehicle...',
                              hintStyle: TextStyle(
                                fontSize: 13,
                                color: isDark ? const Color(0xFF94A3B8) : AsmitaPalette.textLight,
                              ),
                              prefixIcon: Icon(
                                Icons.search_rounded,
                                size: 20,
                                color: isDark ? const Color(0xFF94A3B8) : AsmitaPalette.textLight,
                              ),
                              suffixIcon: _searchQuery.isNotEmpty
                                   ? IconButton(
                                      icon: Icon(
                                        Icons.clear_rounded,
                                        size: 18,
                                        color: isDark ? const Color(0xFF94A3B8) : AsmitaPalette.textLight,
                                      ),
                                      onPressed: () {
                                        _searchController.clear();
                                        setState(() => _searchQuery = '');
                                      },
                                    )
                                  : null,
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Top KPI Stat Metrics Cards (Interactive Filter Cards)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 6, 16, 14),
                        child: _buildKpiMetrics(context, state.visits),
                      ),
                    ),

                    // Visitor Items or Empty State
                    if (filteredVisits.isEmpty)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 20, 16, 200),
                          child: _buildEmptyState(context),
                        ),
                      )
                    else
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 200),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final visit = filteredVisits[index];
                              return _buildVisitItem(context, visit);
                            },
                            childCount: filteredVisits.length,
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKpiMetrics(BuildContext context, List<IndustrialVisitModel> visits) {
    final pendingCount = visits.where((v) => v.isPending).length;
    final approvedCount = visits.where((v) => v.status == IndustrialVisitStatus.approved).length;
    final insideCount = visits.where((v) => v.status == IndustrialVisitStatus.checkedIn).length;
    final totalCount = visits.length;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      children: [
        Expanded(
          child: _buildKpiCard(
            context,
            label: 'Total',
            count: totalCount,
            icon: Icons.groups_rounded,
            accentColor: isDark ? const Color(0xFF60A5FA) : AsmitaPalette.deepNavy,
            filterKey: 'ALL',
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildKpiCard(
            context,
            label: 'Pending',
            count: pendingCount,
            icon: Icons.pending_actions_rounded,
            accentColor: isDark ? const Color(0xFFF87171) : AsmitaPalette.actionRed,
            filterKey: 'PENDING',
            showPulse: pendingCount > 0,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildKpiCard(
            context,
            label: 'Approved',
            count: approvedCount,
            icon: Icons.verified_rounded,
            accentColor: isDark ? const Color(0xFF38BDF8) : const Color(0xFF1E88E5),
            filterKey: 'APPROVED',
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildKpiCard(
            context,
            label: 'Inside',
            count: insideCount,
            icon: Icons.meeting_room_rounded,
            accentColor: isDark ? const Color(0xFF34D399) : AsmitaPalette.successGreen,
            filterKey: 'INSIDE',
          ),
        ),
      ],
    );
  }

  Widget _buildKpiCard(
    BuildContext context, {
    required String label,
    required int count,
    required IconData icon,
    required Color accentColor,
    required String filterKey,
    bool showPulse = false,
  }) {
    final isSelected = _selectedFilter == filterKey;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _selectedFilter = filterKey);
      },
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? accentColor.withValues(alpha: isDark ? 0.22 : 0.12)
              : (isDark ? const Color(0xFF1E293B) : Theme.of(context).colorScheme.surface),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? accentColor
                : (isDark ? const Color(0xFF334155) : Theme.of(context).dividerColor),
            width: isSelected ? 1.5 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.03),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Premium Squircle Icon Container
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: isDark ? 0.22 : 0.10),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: accentColor.withValues(alpha: isSelected ? 0.45 : 0.18),
                  width: 1.0,
                ),
              ),
              child: Center(
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Icon(icon, color: accentColor, size: 18),
                    if (showPulse)
                      Positioned(
                        right: -3,
                        top: -3,
                        child: Container(
                          width: 7,
                          height: 7,
                          decoration: BoxDecoration(
                            color: accentColor,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Theme.of(context).colorScheme.surface,
                              width: 1.5,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '$count',
              style: TextStyle(
                fontFamily: 'Montserrat',
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: isSelected ? accentColor : Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Montserrat',
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? accentColor : AsmitaPalette.textLight,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildEmptyState(BuildContext context) {
    String emptyTitle = 'No Visitors Found';
    String emptySubtitle = 'There are no visitor records matching your filter criteria.';
    IconData emptyIcon = Icons.badge_outlined;

    if (_selectedFilter == 'PENDING') {
      emptyTitle = 'All Caught Up!';
      emptySubtitle = 'There are currently no visitors awaiting entry approval.';
      emptyIcon = Icons.done_all_rounded;
    } else if (_selectedFilter == 'INSIDE') {
      emptyTitle = 'Campus Clear';
      emptySubtitle = 'No active visitors are currently checked inside the premises.';
      emptyIcon = Icons.domain_verification_rounded;
    } else if (_selectedFilter == 'APPROVED') {
      emptyTitle = 'No Approved Passes';
      emptySubtitle = 'No upcoming approved passes found. Schedule a pass in seconds.';
      emptyIcon = Icons.event_available_rounded;
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AsmitaPalette.deepNavy.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                emptyIcon,
                size: 42,
                color: AsmitaPalette.deepNavy,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              emptyTitle,
              style: const TextStyle(
                fontFamily: 'Montserrat',
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              emptySubtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: AsmitaPalette.textLight),
            ),
            const SizedBox(height: 18),
            ElevatedButton.icon(
              onPressed: () => _showPreApproveModal(context),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text(
                'Schedule Visitor',
                style: TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AsmitaPalette.deepNavy,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVisitItem(BuildContext context, IndustrialVisitModel visit) {
    final isPending = visit.isPending;
    final isAck = _acknowledgedIds.contains(visit.id);

    return AsmitaVisitorCard.fromIndustrialVisit(
      visit: visit,
      context: context,
      isAcknowledged: isAck,
      onTap: () => _showVisitDetailsModal(context, visit),
      onApprove: isPending
          ? () {
              context.read<IndustrialVisitBloc>().add(
                    DecideVisitEvent(visitId: visit.id, action: 'APPROVE'),
                  );
            }
          : null,
      onDeny: isPending
          ? () {
              context.read<IndustrialVisitBloc>().add(
                    DecideVisitEvent(visitId: visit.id, action: 'DENY'),
                  );
            }
          : null,
      onAcknowledge: (isPending && !isAck)
          ? () {
              setState(() => _acknowledgedIds.add(visit.id));
              context.read<IndustrialVisitBloc>().add(AcknowledgeVisitEvent(visit.id));
              AsmitaToast.show(
                context,
                message: 'Visitor pass #${visit.passCode ?? visit.id} acknowledged',
                type: AsmitaToastType.success,
              );
            }
          : null,
    );
  }
}

