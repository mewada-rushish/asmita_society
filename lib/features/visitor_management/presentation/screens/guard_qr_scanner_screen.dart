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

  const GuardQrScannerScreen({
    super.key,
    required this.onScanComplete,
    required this.isActive,
  });

  @override
  State<GuardQrScannerScreen> createState() => _GuardQrScannerScreenState();
}

class _GuardQrScannerScreenState extends State<GuardQrScannerScreen> {
  bool _isProcessing = false;
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
    _scannerController.dispose();
    super.dispose();
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
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          MobileScanner(
            controller: _scannerController,
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
              onProfilePressed: () {},
              trailingActions: const SizedBox(),
            ),
          ),
          if (_isProcessing)
            const Center(
              child: AsmitaLoadingIndicator(color: AsmitaPalette.actionRed, size: 28),
            ),
        ],
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
              bottom: 100,
              left: 0,
              right: 0,
              child: const Text(
                'Align QR Code within the frame',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
