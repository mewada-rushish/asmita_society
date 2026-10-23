import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:asmita_society/core/constants/design_system.dart';

/// An in-app camera viewfinder screen for capturing live visitor/security photos
/// directly within the app without redirecting to the phone's native camera application.
class AsmitaCameraScreen extends StatefulWidget {
  final String title;
  final String subtitle;
  final CameraLensDirection preferredLensDirection;

  const AsmitaCameraScreen({
    super.key,
    this.title = 'Live Security Photo',
    this.subtitle = 'Position visitor inside the frame and take photo',
    this.preferredLensDirection = CameraLensDirection.back,
  });

  /// Static helper to open the camera screen and return the captured [File], or null if cancelled.
  static Future<File?> open(
    BuildContext context, {
    String title = 'Live Security Photo',
    String subtitle = 'Position visitor inside the frame and take photo',
    CameraLensDirection preferredLensDirection = CameraLensDirection.back,
  }) {
    return Navigator.of(context).push<File?>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => AsmitaCameraScreen(
          title: title,
          subtitle: subtitle,
          preferredLensDirection: preferredLensDirection,
        ),
      ),
    );
  }

  @override
  State<AsmitaCameraScreen> createState() => _AsmitaCameraScreenState();
}

class _AsmitaCameraScreenState extends State<AsmitaCameraScreen>
    with WidgetsBindingObserver {
  List<CameraDescription> _cameras = [];
  CameraController? _controller;
  int _selectedCameraIndex = 0;
  bool _isInitializing = true;
  bool _isTakingPicture = false;
  String? _errorMessage;
  FlashMode _currentFlashMode = FlashMode.auto;

  // Captured preview state before saving
  XFile? _capturedFile;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final CameraController? cameraController = _controller;
    if (cameraController == null || !cameraController.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive) {
      cameraController.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initCameraController(_cameras[_selectedCameraIndex]);
    }
  }

  Future<void> _initCamera() async {
    setState(() {
      _isInitializing = true;
      _errorMessage = null;
    });

    try {
      final status = await Permission.camera.request();
      if (!status.isGranted) {
        setState(() {
          _isInitializing = false;
          _errorMessage =
              'Camera permission is required to capture live visitor photos.';
        });
        return;
      }

      _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        setState(() {
          _isInitializing = false;
          _errorMessage = 'No camera found on this device.';
        });
        return;
      }

      int targetIndex = _cameras.indexWhere(
        (c) => c.lensDirection == widget.preferredLensDirection,
      );
      if (targetIndex < 0) {
        targetIndex = 0;
      }

      _selectedCameraIndex = targetIndex;
      await _initCameraController(_cameras[_selectedCameraIndex]);
    } catch (e) {
      setState(() {
        _isInitializing = false;
        _errorMessage = 'Failed to initialize camera: $e';
      });
    }
  }

  Future<void> _initCameraController(CameraDescription cameraDescription) async {
    final previousController = _controller;
    await previousController?.dispose();

    final CameraController cameraController = CameraController(
      cameraDescription,
      ResolutionPreset.high,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );

    _controller = cameraController;

    try {
      await cameraController.initialize();
      await cameraController.setFlashMode(_currentFlashMode);
      if (mounted) {
        setState(() {
          _isInitializing = false;
          _errorMessage = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isInitializing = false;
          _errorMessage = 'Error initializing camera: $e';
        });
      }
    }
  }

  Future<void> _switchCamera() async {
    if (_cameras.length < 2 || _isTakingPicture) return;

    final nextIndex = (_selectedCameraIndex + 1) % _cameras.length;
    _selectedCameraIndex = nextIndex;
    setState(() => _isInitializing = true);
    await _initCameraController(_cameras[nextIndex]);
  }

  Future<void> _toggleFlash() async {
    if (_controller == null || !_controller!.value.isInitialized) return;

    final modes = [FlashMode.auto, FlashMode.always, FlashMode.off];
    final currentIndex = modes.indexOf(_currentFlashMode);
    final nextMode = modes[(currentIndex + 1) % modes.length];

    try {
      await _controller!.setFlashMode(nextMode);
      setState(() => _currentFlashMode = nextMode);
    } catch (_) {}
  }

  Future<void> _takePicture() async {
    final controller = _controller;
    if (controller == null ||
        !controller.value.isInitialized ||
        _isTakingPicture) {
      return;
    }

    try {
      setState(() => _isTakingPicture = true);
      HapticFeedback.mediumImpact();

      final file = await controller.takePicture();

      if (mounted) {
        setState(() {
          _capturedFile = file;
          _isTakingPicture = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isTakingPicture = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to take photo: $e'),
            backgroundColor: AsmitaPalette.actionRed,
          ),
        );
      }
    }
  }

  void _confirmAndSave() {
    if (_capturedFile != null) {
      Navigator.of(context).pop(File(_capturedFile!.path));
    }
  }

  void _retake() {
    setState(() {
      _capturedFile = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: SafeArea(
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Main Camera / Captured Preview View
              if (_capturedFile != null)
                _buildCapturedPreview()
              else if (_errorMessage != null)
                _buildErrorView()
              else if (_isInitializing || _controller == null || !_controller!.value.isInitialized)
                _buildLoadingView()
              else
                _buildCameraView(),

              // Top Controls Header
              Positioned(
                top: 8,
                left: 12,
                right: 12,
                child: _buildTopBar(),
              ),

              // Bottom Action Controls Bar
              Positioned(
                bottom: 16,
                left: 0,
                right: 0,
                child: _capturedFile != null
                    ? _buildConfirmControls()
                    : _buildCaptureControls(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          onPressed: () => Navigator.of(context).pop(null),
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.45),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.close_rounded, color: Colors.white, size: 22),
          ),
        ),
        if (_capturedFile == null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.45),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              widget.title,
              style: const TextStyle(
                fontFamily: 'Montserrat',
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        if (_capturedFile == null)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                onPressed: _toggleFlash,
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.45),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _currentFlashMode == FlashMode.auto
                        ? Icons.flash_auto_rounded
                        : _currentFlashMode == FlashMode.always
                            ? Icons.flash_on_rounded
                            : Icons.flash_off_rounded,
                    color: _currentFlashMode != FlashMode.off
                        ? Colors.amber
                        : Colors.white,
                    size: 20,
                  ),
                ),
              ),
              if (_cameras.length > 1)
                IconButton(
                  onPressed: _switchCamera,
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.45),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.cameraswitch_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
            ],
          )
        else
          const SizedBox(width: 48),
      ],
    );
  }

  Widget _buildCameraView() {
    return Stack(
      fit: StackFit.expand,
      children: [
        Center(
          child: CameraPreview(_controller!),
        ),

        // Framing guide overlay
        Center(
          child: Container(
            width: 260,
            height: 320,
            decoration: BoxDecoration(
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.7),
                width: 2.0,
              ),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Stack(
              children: [
                Positioned(
                  top: 12,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'Align visitor face here',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 11,
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Subtitle guide at top
        Positioned(
          top: 64,
          left: 20,
          right: 20,
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                widget.subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCapturedPreview() {
    return Stack(
      fit: StackFit.expand,
      children: [
        Center(
          child: Image.file(
            File(_capturedFile!.path),
            fit: BoxFit.contain,
          ),
        ),
        Positioned(
          top: 64,
          left: 20,
          right: 20,
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle_rounded, color: Colors.greenAccent, size: 16),
                  SizedBox(width: 6),
                  Text(
                    'Photo Captured! Save or Retake',
                    style: TextStyle(
                      fontFamily: 'Montserrat',
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCaptureControls() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: _isTakingPicture ? null : _takePicture,
          child: Container(
            width: 78,
            height: 78,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 4),
              color: Colors.transparent,
            ),
            padding: const EdgeInsets.all(5),
            child: Container(
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
              ),
              child: _isTakingPicture
                  ? Center(
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: AsmitaPalette.deepNavy,
                        ),
                      ),
                    )
                  : Center(
                      child: Icon(
                        Icons.camera_alt_rounded,
                        color: AsmitaPalette.deepNavy,
                        size: 32,
                      ),
                    ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          'Tap to Click & Save',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 12,
            color: Colors.white70,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildConfirmControls() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          // Retake button
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _retake,
              icon: const Icon(Icons.refresh_rounded, color: Colors.white),
              label: const Text(
                'Retake',
                style: TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.white60, width: 1.5),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Save and Use button
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _confirmAndSave,
              icon: const Icon(Icons.check_rounded, color: Colors.white),
              label: const Text(
                'Save Photo',
                style: TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AsmitaPalette.actionRed,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingView() {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(
            color: Colors.white,
            strokeWidth: 2.5,
          ),
          SizedBox(height: 16),
          Text(
            'Starting Camera...',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 13,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.videocam_off_outlined, color: Colors.white70, size: 54),
            const SizedBox(height: 16),
            Text(
              _errorMessage ?? 'Camera error occurred',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 14,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _initCamera,
              style: ElevatedButton.styleFrom(
                backgroundColor: AsmitaPalette.actionRed,
                foregroundColor: Colors.white,
              ),
              child: const Text('Retry Camera'),
            ),
          ],
        ),
      ),
    );
  }
}
