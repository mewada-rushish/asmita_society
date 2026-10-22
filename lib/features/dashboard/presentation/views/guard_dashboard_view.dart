import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:asmita_society/core/config/env_config.dart';
import 'package:asmita_society/core/utils/date_formatter.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/constants/design_system.dart';
import '../../../../../core/widgets/asmita_loading_indicator.dart';
import '../../../../core/widgets/asmita_primary_header.dart';
import '../../../../core/widgets/asmita_dialog.dart';
import '../../../../core/widgets/asmita_animated_refresh.dart';
import '../../../../core/widgets/asmita_toast.dart';
import '../../../visitor_management/bloc/guard_gate_bloc.dart';
import '../../../visitor_management/bloc/guard_gate_event.dart';
import '../../../visitor_management/bloc/guard_gate_state.dart';
import '../../widgets/asmita_pre_approve_wizard.dart';
import '../../../visitor_management/presentation/screens/guard_pass_check_in_screen.dart';
import '../../../visitor_management/presentation/screens/guard_vehicle_draft_screen.dart';
import '../../../visitor_management/presentation/screens/guard_delivery_entry_screen.dart';
import '../../../visitor_management/presentation/widgets/manual_override_dialog.dart';
import '../../../visitor_management/data/models/industrial_visit_model.dart';

class GuardDashboardView extends StatefulWidget {
  final VoidCallback onNavigateToMenu;
  final VoidCallback onNavigateToHistory;
  final VoidCallback onNavigateToScanner;

  const GuardDashboardView({
    super.key,
    required this.onNavigateToMenu,
    required this.onNavigateToHistory,
    required this.onNavigateToScanner,
  });

  @override
  State<GuardDashboardView> createState() => _GuardDashboardViewState();
}

class _GuardDashboardViewState extends State<GuardDashboardView> {
  final TextEditingController _codeController = TextEditingController();
  int _selectedGateId = 1;

  @override
  void initState() {
    super.initState();
    context.read<GuardGateBloc>().add(LoadExpectedInvites());
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  void _searchCode() {
    final code = _codeController.text.trim();
    if (code.length == 6) {
      context.read<GuardGateBloc>().add(SearchInviteByCode(code));
    } else {
      AsmitaToast.show(
        context,
        message: 'Please enter a 6-digit access code',
        type: AsmitaToastType.error,
      );
    }
  }

  void _showCheckInDialog(Map<String, dynamic> invite) {
    showDialog(
      context: context,
      barrierColor: Theme.of(context).colorScheme.scrim.withValues(alpha: 0.4),
      builder: (ctx) => _PreApprovedCheckInDialog(
        invite: invite,
        onConfirm: (photoBase64) {
          final isPreApproved =
              invite['record_type'] == null ||
              invite['record_type'] == 'PRE_APPROVED';
          context.read<GuardGateBloc>().add(
            CheckInPreApprovedVisitor(
              invite['id']?.toString() ?? '0',
              isPreApproved: isPreApproved,
              photoBase64: photoBase64,
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          Container(
            color: Theme.of(context).scaffoldBackgroundColor,
            child: BlocConsumer<GuardGateBloc, GuardGateState>(
              listener: (context, state) {
                if (state.status == GuardGateStatus.error &&
                    state.errorMessage != null) {
                  AsmitaToast.show(
                    context,
                    message: state.errorMessage!,
                    type: AsmitaToastType.error,
                  );
                } else if (state.searchResult != null) {
                  _showCheckInDialog(state.searchResult!);
                } else if (state.status == GuardGateStatus.success &&
                    state.successMessage != null) {
                  AsmitaToast.show(
                    context,
                    message: state.successMessage!,
                    type: AsmitaToastType.success,
                  );
                  _codeController.clear();
                }
              },
              builder: (context, state) {
                return CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics(),
                  ),
                  slivers: [
                    SliverPadding(
                      padding: EdgeInsets.only(
                        top:
                            MediaQuery.viewPaddingOf(context).top +
                            72 +
                            24, // Estimate header height
                      ),
                      sliver: AsmitaAnimatedRefresh(
                        onRefresh: () async {
                          final bloc = context.read<GuardGateBloc>();
                          bloc.add(LoadExpectedInvites());

                          await Future.wait([
                            Future.delayed(const Duration(milliseconds: 800)),
                            bloc.stream
                                .firstWhere((state) => !state.isLoadingExpected)
                                .catchError((_) => const GuardGateState()),
                          ]);
                        },
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.all(16),
                      sliver: SliverToBoxAdapter(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildGatePostSelector(),
                            _buildSearchSection(state.isSubmitting),
                            const SizedBox(height: 24),
                            _buildNewVisitorAction(context),
                            const SizedBox(height: 24),
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.surface,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Colors.black12,
                                    blurRadius: 4,
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Expected Today',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 12),
                                  _buildExpectedList(state),
                                ],
                              ),
                            ),
                            const SizedBox(height: 160),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: AsmitaPrimaryHeader(
              subtitleOverride: 'Security Guard',
              allowPropertySwitching: false,
              onProfilePressed: widget.onNavigateToMenu,
              onHistoryPressed: widget.onNavigateToHistory,
              onScannerPressed: widget.onNavigateToScanner,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGatePostSelector() {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Gate Assignment',
                style: TextStyle(fontFamily: 'Montserrat', fontSize: 15, fontWeight: FontWeight.bold),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AsmitaPalette.successGreen.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.fiber_manual_record, color: AsmitaPalette.successGreen, size: 10),
                    SizedBox(width: 4),
                    Text('On Duty', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AsmitaPalette.successGreen)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ChoiceChip(
                  avatar: Icon(
                    Icons.directions_walk,
                    size: 16,
                    color: _selectedGateId == 1 ? Colors.white : AsmitaPalette.textDark,
                  ),
                  label: const Text('Gate 1 (Pedestrian)', overflow: TextOverflow.ellipsis),
                  selected: _selectedGateId == 1,
                  selectedColor: AsmitaPalette.deepNavy,
                  labelStyle: TextStyle(
                    color: _selectedGateId == 1 ? Colors.white : AsmitaPalette.textDark,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                  onSelected: (val) {
                    if (val) setState(() => _selectedGateId = 1);
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ChoiceChip(
                  avatar: Icon(
                    Icons.directions_car,
                    size: 16,
                    color: _selectedGateId == 2 ? Colors.white : AsmitaPalette.textDark,
                  ),
                  label: const Text('Gate 2 (Parking)', overflow: TextOverflow.ellipsis),
                  selected: _selectedGateId == 2,
                  selectedColor: AsmitaPalette.deepNavy,
                  labelStyle: TextStyle(
                    color: _selectedGateId == 2 ? Colors.white : AsmitaPalette.textDark,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                  onSelected: (val) {
                    if (val) setState(() => _selectedGateId = 2);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (_selectedGateId == 1) ...[
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const GuardPassCheckInScreen(gateId: 1),
                        ),
                      );
                    },
                    icon: const Icon(Icons.qr_code_scanner, size: 16, color: AsmitaPalette.deepNavy),
                    label: const Text('Verify Pass', style: TextStyle(fontSize: 12, color: AsmitaPalette.deepNavy)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AsmitaPalette.deepNavy),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const GuardDeliveryEntryScreen(gateId: 1),
                        ),
                      );
                    },
                    icon: const Icon(Icons.local_shipping, size: 16, color: AsmitaPalette.deepNavy),
                    label: const Text('Delivery Intake', style: TextStyle(fontSize: 12, color: AsmitaPalette.deepNavy)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AsmitaPalette.deepNavy),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () {
                ManualOverrideDialog.show(
                  context,
                  visit: const IndustrialVisitModel(
                    id: 0,
                    requestNumber: 'OVERRIDE',
                    propertyId: 114,
                    visitorName: 'Manual Guest',
                    status: IndustrialVisitStatus.awaitingHost,
                  ),
                  shiftOverridesUsed: 1,
                  shiftCap: 5,
                  onConfirmOverride: (reason, photo) {
                    AsmitaToast.show(context, message: 'Supervisor override executed.', type: AsmitaToastType.success);
                  },
                );
              },
              icon: const Icon(Icons.shield_outlined, size: 16, color: AsmitaPalette.actionRed),
              label: const Text('Manual Security Override (Cap: 5)', style: TextStyle(fontSize: 12, color: AsmitaPalette.actionRed)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AsmitaPalette.actionRed),
                padding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ] else ...[
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const GuardVehicleDraftScreen(gateId: 2),
                  ),
                );
              },
              icon: const Icon(Icons.qr_code, color: Colors.white, size: 18),
              label: const Text('Generate Vehicle Draft Slip (QR)'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AsmitaPalette.deepNavy,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSearchSection(bool isSubmitting) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Scan or Enter Pass Code',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _codeController,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  decoration: InputDecoration(
                    counterText: '',
                    hintText: 'e.g. 123456',
                    hintStyle: TextStyle(
                      color: Theme.of(context).hintColor,
                      fontSize: 14,
                    ),
                    prefixIcon: Icon(
                      Icons.numbers,
                      color: Theme.of(context).iconTheme.color,
                      size: 20,
                    ),
                    filled: true,
                    fillColor: Theme.of(context).scaffoldBackgroundColor,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Theme.of(context).colorScheme.primary,
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: widget.onNavigateToScanner,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(
                    context,
                  ).colorScheme.primary.withValues(alpha: 0.1),
                  elevation: 0,
                  padding: const EdgeInsets.all(16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Icon(
                  Icons.qr_code_scanner,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: isSubmitting ? null : _searchCode,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AsmitaPalette.deepNavy,
                  padding: const EdgeInsets.all(16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: isSubmitting
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: AsmitaLoadingIndicator(
                          color: Colors.white,
                          size: 24,
                        ),
                      )
                    : const Icon(Icons.search, color: Colors.white),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showNewVisitorModal(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const AsmitaDialog(
        title: 'New Walk-in Visitor',
        content: AsmitaPreApproveWizard(isGuardMode: true),
      ),
    );
  }

  Widget _buildNewVisitorAction(BuildContext context) {
    return InkWell(
      onTap: () {
        _showNewVisitorModal(context);
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AsmitaPalette.deepNavy,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.person_add, color: Colors.white),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'New Walk-in Visitor',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                  ),
                  Text(
                    'Record details for unannounced guests',
                    style: TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: Theme.of(context).colorScheme.primary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpectedList(GuardGateState state) {
    if ((state.status == GuardGateStatus.initial || state.isLoadingExpected) &&
        state.expectedInvites.isEmpty) {
      return Center(
        child: AsmitaLoadingIndicator(
          color: Theme.of(context).colorScheme.primary,
          size: 28,
        ),
      );
    }

    final today = DateTime.now();
    final startOfToday = DateTime(today.year, today.month, today.day);
    final validInvites = state.expectedInvites.where((invite) {
      if (invite['valid_to'] != null) {
        try {
          final validTo = DateTime.parse(invite['valid_to']);
          if (validTo.isBefore(startOfToday)) return false;
        } catch (_) {}
      }
      return true;
    }).toList();

    if (validInvites.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        alignment: Alignment.center,
        child: Column(
          children: [
            Icon(Icons.event_available, size: 48, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            const Text(
              'No expected visitors for today',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      itemCount: validInvites.length,
      itemBuilder: (context, index) {
        final invite = validInvites[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _buildInviteIcon(invite),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              _getInviteTitle(invite),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Theme.of(
                                  context,
                                ).textTheme.bodyLarge?.color,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AsmitaPalette.deepNavy.withValues(
                                alpha: 0.1,
                              ),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              (invite['invite_type']?.toString() ?? 'Guest')
                                  .toUpperCase(),
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      _buildInviteSubtitle(invite),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                state.isSubmitting &&
                        state.submittingVisitorId == (invite['id']?.toString() ?? '')
                    ? const SizedBox(
                        width: 28,
                        height: 28,
                        child: Center(
                          child: AsmitaLoadingIndicator(
                            color: AsmitaPalette.deepNavy,
                            size: 20,
                          ),
                        ),
                      )
                    : (invite['status']?.toString().toUpperCase() ==
                              'PENDING' ||
                          invite['action']?.toString().toUpperCase() ==
                              'PENDING')
                    ? _PendingOrCheckInButton(
                        invite: invite,
                        onCheckIn: () => _showCheckInDialog(invite),
                      )
                    : IconButton(
                        icon: Icon(
                          Icons.check_circle,
                          color: Theme.of(context).colorScheme.primary,
                          size: 28,
                        ),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () {
                          _showCheckInDialog(invite);
                        },
                      ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInviteIcon(Map<String, dynamic> invite) {
    final photoUrl = invite['photo_url']?.toString().trim();
    final companyName = invite['company_name']?.toString();
    final isDelivery =
        invite['invite_type']?.toString().toLowerCase() == 'delivery';

    if (photoUrl != null && photoUrl.isNotEmpty) {
      final fullUrl = photoUrl.startsWith('http')
          ? photoUrl
          : '${EnvConfig.baseUrl}$photoUrl';
      return Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: AsmitaPalette.successGreen.withValues(alpha: 0.5),
                width: 1.5,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: CachedNetworkImage(
                imageUrl: fullUrl,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: Colors.grey.shade100,
                  child: const Center(
                    child: AsmitaLoadingIndicator(size: 16),
                  ),
                ),
                errorWidget: (context, error, stackTrace) =>
                    _defaultIcon(isDelivery),
              ),
            ),
          ),
          Positioned(
            right: -2,
            bottom: -2,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: const BoxDecoration(
                color: AsmitaPalette.successGreen,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check, size: 8, color: Colors.white),
            ),
          ),
        ],
      );
    }

    if (companyName != null && companyName.isNotEmpty) {
      final fileName = companyName.toLowerCase().replaceAll(
        ' ',
        (companyName.contains(' ') &&
                ![
                  'amazon prime now',
                  'apollo 24-7',
                  'bharat gas',
                  'big basket',
                  'blue dart',
                  'country delight',
                  'india post',
                  'eat club',
                  'ecom express',
                  'fresh menu',
                  'fresh to home',
                  'hdfc bank',
                  'hp gas',
                  'milk basket',
                  'natures basket',
                  'pizza hut',
                  'professional courier',
                  'swiggy instamart',
                  'tata 1mg',
                  'tata play',
                  'urban company',
                ].contains(companyName.toLowerCase()))
            ? ''
            : ' ',
      );
      return Container(
        width: 44,
        height: 44,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade300, width: 0.5),
        ),
        child: Image.asset(
          'assets/images/logos/$fileName.png',
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) =>
              _defaultIcon(isDelivery),
        ),
      );
    }
    return _defaultIcon(isDelivery);
  }

  Widget _defaultIcon(bool isDelivery) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: AsmitaPalette.deepNavy.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        isDelivery ? Icons.local_shipping : Icons.person,
        color: AsmitaPalette.deepNavy,
      ),
    );
  }

  String _getInviteTitle(Map<String, dynamic> invite) {
    if (invite['visitor_name'] != null &&
        invite['visitor_name'].toString().isNotEmpty) {
      return invite['visitor_name'];
    }
    if (invite['company_name'] != null &&
        invite['company_name'].toString().isNotEmpty) {
      return invite['company_name'];
    }
    return invite['title'] ?? 'Unknown';
  }

  String _formatTime(String dateStr) {
    try {
      final dt = DateTime.parse(dateStr).toLocal();
      final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
      final ampm = dt.hour >= 12 ? 'PM' : 'AM';
      final minute = dt.minute.toString().padLeft(2, '0');
      return '$hour:$minute $ampm';
    } catch (_) {
      return '';
    }
  }

  Widget _buildInviteSubtitle(Map<String, dynamic> invite) {
    final photoUrl = invite['photo_url']?.toString().trim();
    final hasPhoto = photoUrl != null && photoUrl.isNotEmpty;
    final isDelivery =
        invite['invite_type']?.toString().toLowerCase() == 'delivery';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (invite['tower_name'] != null && invite['flat_number'] != null) ...[
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(
                Icons.meeting_room,
                size: 16,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  '${invite['tower_name']} - ${invite['flat_number']}',
                  style: TextStyle(
                    fontSize: 13,
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
        if (invite['valid_to'] != null) ...[
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(
                Icons.watch_later,
                size: 14,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  '${AppDateFormatter.formatDate(invite['valid_to'])} • ${_formatTime(invite['valid_to'])}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
        if (!isDelivery) ...[
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(
                hasPhoto ? Icons.verified : Icons.camera_alt_outlined,
                size: 13,
                color: hasPhoto ? AsmitaPalette.successGreen : Colors.orange.shade800,
              ),
              const SizedBox(width: 4),
              Text(
                hasPhoto ? 'Photo on File' : 'Photo Required at Gate',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: hasPhoto ? AsmitaPalette.successGreen : Colors.orange.shade800,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _PendingOrCheckInButton extends StatefulWidget {
  final Map<String, dynamic> invite;
  final VoidCallback onCheckIn;

  const _PendingOrCheckInButton({
    required this.invite,
    required this.onCheckIn,
  });

  @override
  _PendingOrCheckInButtonState createState() => _PendingOrCheckInButtonState();
}

class _PendingOrCheckInButtonState extends State<_PendingOrCheckInButton> {
  bool _canCheckIn = false;
  int _remainingSeconds = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _checkStatus();
  }

  void _checkStatus() {
    final createdAtStr =
        widget.invite['created_at']?.toString() ??
        widget.invite['requested_at']?.toString();
    if (createdAtStr == null) {
      _canCheckIn = true;
      return;
    }

    final createdAt = DateTime.tryParse(createdAtStr)?.toLocal();
    if (createdAt == null) {
      _canCheckIn = true;
      return;
    }

    final diff = DateTime.now().difference(createdAt).inSeconds;
    if (diff >= 30) {
      _canCheckIn = true;
    } else {
      _canCheckIn = false;
      _remainingSeconds = 30 - diff;
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (!mounted) {
          timer.cancel();
          return;
        }
        setState(() {
          if (_remainingSeconds > 0) {
            _remainingSeconds--;
          } else {
            _canCheckIn = true;
            timer.cancel();
          }
        });
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_canCheckIn) {
      return IconButton(
        icon: Icon(
          Icons.check_circle,
          color: Theme.of(context).colorScheme.primary,
          size: 28,
        ),
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(),
        onPressed: widget.onCheckIn,
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.5)),
      ),
      child: Text(
        'PENDING (${_remainingSeconds}s)',
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: Colors.orange,
        ),
      ),
    );
  }
}

class _PreApprovedCheckInDialog extends StatefulWidget {
  final Map<String, dynamic> invite;
  final void Function(String? photoBase64) onConfirm;

  const _PreApprovedCheckInDialog({
    required this.invite,
    required this.onConfirm,
  });

  @override
  State<_PreApprovedCheckInDialog> createState() =>
      _PreApprovedCheckInDialogState();
}

class _PreApprovedCheckInDialogState extends State<_PreApprovedCheckInDialog> {
  File? _capturedImage;
  String? _capturedBase64;
  bool _isCapturing = false;
  bool _photoMandatoryAlert = false;

  String? get _existingPhotoUrl {
    final raw = widget.invite['photo_url']?.toString().trim();
    if (raw == null || raw.isEmpty) return null;
    if (raw.startsWith('http://') || raw.startsWith('https://')) return raw;
    return '${EnvConfig.baseUrl}$raw';
  }

  bool get _hasPhotoOnRecord => _existingPhotoUrl != null;

  Future<void> _takePhoto() async {
    setState(() => _isCapturing = true);
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 80,
      );
      if (picked != null) {
        final bytes = await picked.readAsBytes();
        final b64 = 'data:image/jpeg;base64,${base64Encode(bytes)}';
        setState(() {
          _capturedImage = File(picked.path);
          _capturedBase64 = b64;
          _photoMandatoryAlert = false;
        });
      }
    } catch (e) {
      if (mounted) {
        AsmitaToast.show(
          context,
          message: 'Camera error: $e',
          type: AsmitaToastType.error,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isCapturing = false);
      }
    }
  }

  void _handleConfirm() {
    final hasPhoto = _hasPhotoOnRecord || _capturedImage != null;
    if (!hasPhoto && !_photoMandatoryAlert) {
      setState(() => _photoMandatoryAlert = true);
      AsmitaToast.show(
        context,
        message: 'Visitor photo required. Please take photo before check-in.',
        type: AsmitaToastType.error,
      );
      return;
    }

    Navigator.pop(context);
    widget.onConfirm(_capturedBase64);
  }

  Widget _buildRow(String label, String value, {bool highlight = false}) {
    return Container(
      color: highlight
          ? AsmitaPalette.deepNavy.withValues(alpha: 0.05)
          : Colors.transparent,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(
              color: Theme.of(context).colorScheme.primary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 10),
              height: 1,
              color: Colors.grey.shade300,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: highlight ? FontWeight.bold : FontWeight.w600,
              fontSize: highlight ? 14 : 12,
              color: highlight
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).textTheme.bodyLarge?.color,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final invite = widget.invite;
    final visitorName = (invite['visitor_name'] == null ||
            invite['visitor_name'].toString().isEmpty)
        ? (invite['company_name'] ?? invite['title'] ?? 'Visitor')
        : invite['visitor_name'];
    final phone = invite['visitor_phone'] ?? invite['mobile_number'];

    return AsmitaDialog(
      title: 'Verify Visitor & Entry',
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$visitorName',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).textTheme.bodyLarge?.color,
                        ),
                      ),
                      if (phone != null && phone.toString().isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          'Contact: $phone',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: AsmitaPalette.deepNavy.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    (invite['invite_type']?.toString() ?? 'Guest').toUpperCase(),
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: AsmitaPalette.deepNavy,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            _buildPhotoSection(),

            const SizedBox(height: 14),

            Container(
              clipBehavior: Clip.hardEdge,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (invite['tower_name'] != null &&
                      invite['flat_number'] != null)
                    _buildRow(
                      'Destination',
                      '${invite['tower_name']} - ${invite['flat_number']}',
                      highlight: true,
                    ),
                  if (invite['vehicle_number'] != null &&
                      invite['vehicle_number'].toString().isNotEmpty)
                    _buildRow('Vehicle', invite['vehicle_number'].toString()),
                  _buildRow(
                    'Valid From',
                    invite['valid_from'] != null
                        ? AppDateFormatter.formatDate(invite['valid_from'])
                        : 'N/A',
                  ),
                  _buildRow(
                    'Valid Till',
                    invite['valid_to'] != null
                        ? AppDateFormatter.formatDate(invite['valid_to'])
                        : 'N/A',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(Icons.info_outline, size: 13, color: Colors.grey.shade500),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    _hasPhotoOnRecord || _capturedImage != null
                        ? 'Match visitor photo before confirming gate entry.'
                        : 'Mandatory photo capture attaches to contact profile.',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade600,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          style: TextButton.styleFrom(foregroundColor: Colors.grey.shade700),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _handleConfirm,
          style: ElevatedButton.styleFrom(
            backgroundColor: AsmitaPalette.deepNavy,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          ),
          child: Text(
            (!_hasPhotoOnRecord && _capturedImage == null && _photoMandatoryAlert)
                ? 'Check In (Bypass Photo)'
                : 'Confirm Check-in',
          ),
        ),
      ],
    );
  }

  Widget _buildPhotoSection() {
    if (_capturedImage != null) {
      return Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AsmitaPalette.deepNavy.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: AsmitaPalette.deepNavy.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.file(
                _capturedImage!,
                width: 58,
                height: 58,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(
                        Icons.check_circle,
                        size: 15,
                        color: AsmitaPalette.successGreen,
                      ),
                      SizedBox(width: 4),
                      Text(
                        'New Photo Captured',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AsmitaPalette.successGreen,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Stored permanently under this contact number.',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
                  ),
                ],
              ),
            ),
            TextButton.icon(
              onPressed: _isCapturing ? null : _takePhoto,
              icon: const Icon(Icons.refresh, size: 14),
              label: const Text('Retake', style: TextStyle(fontSize: 11)),
              style: TextButton.styleFrom(
                foregroundColor: AsmitaPalette.deepNavy,
                padding: const EdgeInsets.symmetric(horizontal: 8),
              ),
            ),
          ],
        ),
      );
    }

    if (_hasPhotoOnRecord) {
      return Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AsmitaPalette.successGreen.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: AsmitaPalette.successGreen.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: CachedNetworkImage(
                imageUrl: _existingPhotoUrl!,
                width: 58,
                height: 58,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  width: 58,
                  height: 58,
                  color: Colors.grey.shade200,
                  child: const Center(
                    child: AsmitaLoadingIndicator(size: 16),
                  ),
                ),
                errorWidget: (context, url, error) => Container(
                  width: 58,
                  height: 58,
                  color: Colors.grey.shade200,
                  child: const Icon(Icons.person, color: Colors.grey),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(
                        Icons.verified,
                        size: 15,
                        color: AsmitaPalette.successGreen,
                      ),
                      SizedBox(width: 4),
                      Text(
                        'Photo on File (Verified)',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AsmitaPalette.successGreen,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Matched by contact number from prior visits.',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
                  ),
                ],
              ),
            ),
            TextButton.icon(
              onPressed: _isCapturing ? null : _takePhoto,
              icon: const Icon(Icons.camera_alt_outlined, size: 14),
              label: const Text('Update', style: TextStyle(fontSize: 11)),
              style: TextButton.styleFrom(
                foregroundColor: AsmitaPalette.deepNavy,
                padding: const EdgeInsets.symmetric(horizontal: 8),
              ),
            ),
          ],
        ),
      );
    }

    // Photo NOT on record
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _photoMandatoryAlert
            ? AsmitaPalette.actionRed.withValues(alpha: 0.06)
            : Colors.orange.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: _photoMandatoryAlert
              ? AsmitaPalette.actionRed
              : Colors.orange.withValues(alpha: 0.5),
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: (_photoMandatoryAlert
                          ? AsmitaPalette.actionRed
                          : Colors.orange)
                      .withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.add_a_photo,
                  size: 18,
                  color: _photoMandatoryAlert
                      ? AsmitaPalette.actionRed
                      : Colors.amber.shade900,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _photoMandatoryAlert
                          ? 'Photo Mandatory Before Check-in'
                          : 'Photo Required (Not Stored)',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: _photoMandatoryAlert
                            ? AsmitaPalette.actionRed
                            : Colors.amber.shade900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'No prior image for this contact. Guard must take photo before entry.',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isCapturing ? null : _takePhoto,
              icon: _isCapturing
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.camera_alt, size: 16),
              label: Text(
                _isCapturing ? 'Opening Camera...' : 'Take Visitor Photo Now',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AsmitaPalette.deepNavy,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
