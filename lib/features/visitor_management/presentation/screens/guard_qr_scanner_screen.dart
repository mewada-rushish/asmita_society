import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/design_system.dart';
import '../../../../core/widgets/asmita_loading_indicator.dart';
import '../../../../core/widgets/asmita_primary_header.dart';
import '../../bloc/guard_gate_bloc.dart';
import '../../bloc/guard_gate_event.dart';

class GuardQrScannerScreen extends StatefulWidget {
  final VoidCallback onScanComplete;
  final bool isActive;
  final VoidCallback? onBack;

  const GuardQrScannerScreen({
    super.key,
    required this.onScanComplete,
    required this.isActive,
    this.onBack,
  });

  @override
  State<GuardQrScannerScreen> createState() => _GuardQrScannerScreenState();
}

class _GuardQrScannerScreenState extends State<GuardQrScannerScreen> {
  bool _isProcessing = false;
  final TextEditingController _manualCodeController = TextEditingController();
  late final MobileScannerController _scannerController = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    returnImage: false,
    facing: CameraFacing.back,
    autoStart: widget.isActive,
  );

  @override
  void didUpdateWidget(GuardQrScannerScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) {
      // Screen became active, restart scanner
      _scannerController.start();
      setState(() => _isProcessing = false);
    } else if (!widget.isActive && oldWidget.isActive) {
      // Screen became inactive, stop scanner
      _scannerController.stop();
    }
  }

  @override
  void dispose() {
    _manualCodeController.dispose();
    _scannerController.dispose();
    super.dispose();
  }

  void _handleBack() {
    _scannerController.stop();
    if (widget.onBack != null) {
      widget.onBack!();
    } else if (Navigator.canPop(context)) {
      Navigator.of(context).pop();
    }
  }

  void _handleManualSubmit(String rawCode) {
    final code = rawCode.trim().toUpperCase();
    if (code.isEmpty || _isProcessing) return;

    setState(() => _isProcessing = true);
    _scannerController.stop();

    context.read<GuardGateBloc>().add(SearchInviteByCode(code));
    widget.onScanComplete();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_isProcessing) return;
    
    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isNotEmpty) {
      final String code = barcodes.first.rawValue ?? '';
      if (code.isNotEmpty) {
        setState(() {
          _isProcessing = true;
        });
        
        // Pause scanner
        _scannerController.stop();

        // Trigger search bloc
        context.read<GuardGateBloc>().add(SearchInviteByCode(code));

        // Navigate back to home
        widget.onScanComplete();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final canDirectPop = widget.onBack == null && Navigator.canPop(context);
    return PopScope(
      canPop: canDirectPop,
      onPopInvokedWithResult: (didPop, result) {
        _scannerController.stop();
        if (!didPop && widget.onBack != null) {
          widget.onBack!();
        }
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            MobileScanner(
              controller: _scannerController,
              fit: BoxFit.cover,
              onDetect: _onDetect,
            ),
            _buildScannerOverlay(),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: AsmitaPrimaryHeader(
                subtitleOverride: 'Scan QR Code',
                allowPropertySwitching: false,
                showBackButton: true,
                onBackPressed: _handleBack,
                onProfilePressed: () {},
                trailingActions: IconButton(
                  icon: const Icon(Icons.flash_on_rounded, size: 20),
                  tooltip: 'Flashlight',
                  color: Theme.of(context).colorScheme.onSurface,
                  onPressed: () async {
                    try {
                      await _scannerController.toggleTorch();
                    } catch (_) {}
                  },
                ),
              ),
            ),
            if (_isProcessing)
              const Center(
                child: AsmitaLoadingIndicator(color: AsmitaPalette.actionRed, size: 28),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildScannerOverlay() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final scanWindowSize = constraints.maxWidth * 0.7;
        return Stack(
          children: [
            ColorFiltered(
              colorFilter: ColorFilter.mode(
                Colors.black.withValues(alpha: 0.6),
                BlendMode.srcOut,
              ),
              child: Stack(
                children: [
                  Container(
                    decoration: const BoxDecoration(
                      color: Colors.black,
                      backgroundBlendMode: BlendMode.dstOut,
                    ),
                  ),
                  Center(
                    child: Container(
                      height: scanWindowSize,
                      width: scanWindowSize,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Center(
              child: Container(
                height: scanWindowSize,
                width: scanWindowSize,
                decoration: BoxDecoration(
                  border: Border.all(color: AsmitaPalette.actionRed, width: 2),
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
            Positioned(
              bottom: 24,
              left: 20,
              right: 20,
              child: SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Align QR Code within the frame',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        shadows: [
                          Shadow(color: Colors.black54, blurRadius: 4, offset: Offset(0, 1)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Manual Check-in Code Field (fallback when scanner does not work)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.75),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.25),
                          width: 1,
                        ),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black45,
                            blurRadius: 10,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.pin_rounded,
                            color: Colors.white70,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              controller: _manualCodeController,
                              textCapitalization: TextCapitalization.characters,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                letterSpacing: 1.1,
                              ),
                              decoration: const InputDecoration(
                                hintText: 'Enter Pass / Check-in Code',
                                hintStyle: TextStyle(
                                  color: Colors.white38,
                                  fontSize: 12,
                                  fontWeight: FontWeight.normal,
                                ),
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: EdgeInsets.symmetric(vertical: 8),
                              ),
                              onSubmitted: (val) => _handleManualSubmit(val),
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: () => _handleManualSubmit(_manualCodeController.text),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AsmitaPalette.actionRed,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: const Text(
                              'Verify',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
