import 'dart:io';
import 'dart:ui' as ui;
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:asmita_society/core/constants/design_system.dart';

/// Categories of camera failure for user-friendly error recovery.
enum CameraErrorKind {
  permissionDenied,
  hardwareUnavailable,
  noCamerasFound,
  generic,
}

/// An in-app camera viewfinder screen for capturing live visitor/security photos
/// directly within the app without redirecting to the phone's native camera application.
class AsmitaCameraScreen extends StatefulWidget {
  final String title;
  final String subtitle;
  final CameraLensDirection preferredLensDirection;
  final bool defaultMirrored;

  const AsmitaCameraScreen({
    super.key,
    this.title = 'Live Security Photo',
    this.subtitle = 'Position visitor inside the frame and take photo',
    this.preferredLensDirection = CameraLensDirection.back,
    this.defaultMirrored = true,
  });

  /// Static helper to open the camera screen and return the captured [File], or null if cancelled.
  static Future<File?> open(
    BuildContext context, {
    String title = 'Live Security Photo',
    String subtitle = 'Position visitor inside the frame and take photo',
    CameraLensDirection preferredLensDirection = CameraLensDirection.back,
    bool defaultMirrored = true,
  }) {
    return Navigator.of(context).push<File?>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => AsmitaCameraScreen(
          title: title,
          subtitle: subtitle,
          preferredLensDirection: preferredLensDirection,
          defaultMirrored: defaultMirrored,
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
  bool _isMirrored = true;
  String? _errorMessage;
  String _errorTitle = 'Camera Error';
  String? _rawErrorDetails;
  CameraErrorKind _errorKind = CameraErrorKind.generic;
  bool _showTechnicalDetails = false;
  FlashMode _currentFlashMode = FlashMode.auto;

  // Captured preview state before saving
  XFile? _capturedFile;

  @override
  void initState() {
    super.initState();
    _isMirrored = widget.defaultMirrored;
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
      if (_cameras.isNotEmpty && _selectedCameraIndex < _cameras.length) {
        _initCameraController(_cameras[_selectedCameraIndex]);
      }
    }
  }

  void _handleError(
    dynamic error, {
    CameraErrorKind? kind,
    String? customTitle,
    String? customMessage,
  }) {
    final String errStr = error?.toString() ?? '';
    debugPrint('Camera error: $errStr');

    CameraErrorKind resolvedKind = kind ?? CameraErrorKind.generic;
    String title = customTitle ?? 'Camera Error';
    String message =
        customMessage ?? 'An unexpected issue occurred while starting the camera.';

    if (kind == null) {
      final lower = errStr.toLowerCase();
      if (lower.contains('permission') || lower.contains('denied')) {
        resolvedKind = CameraErrorKind.permissionDenied;
        title = 'Camera Access Required';
        message =
            'AsmitA requires access to your device camera to capture live visitor security photos. Please enable camera permissions in your settings.';
      } else if (lower.contains('channel-error') ||
          lower.contains('processcameraprovider') ||
          lower.contains('cameraaccessexception') ||
          lower.contains('cameraexception') ||
          lower.contains('failed to handle')) {
        resolvedKind = CameraErrorKind.hardwareUnavailable;
        title = 'Camera Hardware Unavailable';
        message =
            'Unable to connect to the camera sensor. Another application may be using the camera, or the camera system service needs to reload.';
      } else if (lower.contains('no camera') || lower.contains('not found')) {
        resolvedKind = CameraErrorKind.noCamerasFound;
        title = 'No Camera Detected';
        message = 'No active camera hardware was found on this device.';
      }
    }

    if (mounted) {
      setState(() {
        _isInitializing = false;
        _errorKind = resolvedKind;
        _errorTitle = title;
        _errorMessage = message;
        _rawErrorDetails = errStr.isNotEmpty ? errStr : null;
      });
    }
  }

  Future<void> _initCamera({int retryCount = 0}) async {
    if (!mounted) return;
    setState(() {
      _isInitializing = true;
      _errorMessage = null;
      _rawErrorDetails = null;
    });

    try {
      final status = await Permission.camera.request();
      if (!status.isGranted) {
        _handleError(
          'Camera permission denied',
          kind: CameraErrorKind.permissionDenied,
          customTitle: 'Camera Access Required',
          customMessage:
              'Camera access is required to capture live visitor photos. Please allow camera access in your settings to proceed.',
        );
        return;
      }

      _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        _handleError(
          'availableCameras() returned empty list',
          kind: CameraErrorKind.noCamerasFound,
          customTitle: 'No Camera Detected',
          customMessage: 'No working camera hardware was found on this device.',
        );
        return;
      }

      int targetIndex = _cameras.indexWhere(
        (c) => c.lensDirection == widget.preferredLensDirection,
      );
      if (targetIndex < 0) {
        targetIndex = 0;
      }

      _selectedCameraIndex = targetIndex;
      await _initCameraController(_cameras[_selectedCameraIndex], retryCount: retryCount);
    } catch (e) {
      if (retryCount == 0 && e.toString().contains('channel-error')) {
        debugPrint('CameraX channel-error on first attempt. Retrying in 350ms...');
        await Future.delayed(const Duration(milliseconds: 350));
        if (mounted) {
          return _initCamera(retryCount: 1);
        }
      }
      _handleError(e);
    }
  }

  Future<void> _initCameraController(
    CameraDescription cameraDescription, {
    int retryCount = 0,
  }) async {
    final previousController = _controller;
    await previousController?.dispose();
    _controller = null;

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
          _rawErrorDetails = null;
        });
      }
    } catch (e) {
      if (retryCount == 0 && e.toString().contains('channel-error')) {
        debugPrint('CameraX channel-error during controller init. Retrying in 350ms...');
        await Future.delayed(const Duration(milliseconds: 350));
        if (mounted) {
          return _initCameraController(cameraDescription, retryCount: 1);
        }
      }
      _handleError(e);
    }
  }

  Future<void> _fallbackWithImagePicker(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final XFile? picked = await picker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1280,
        maxHeight: 1280,
      );
      if (picked != null && mounted) {
        File fileToReturn = File(picked.path);
        if (widget.preferredLensDirection == CameraLensDirection.front && _isMirrored) {
          fileToReturn = await _mirrorImageFile(fileToReturn);
        }
        if (!mounted) return;
        Navigator.of(context).pop(fileToReturn);
      }
    } catch (e) {
      debugPrint('Fallback image picker error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Could not open ${source == ImageSource.camera ? "camera" : "gallery"}: $e',
              style: const TextStyle(fontFamily: 'Poppins', fontSize: 13),
            ),
            backgroundColor: AsmitaPalette.actionRed,
          ),
        );
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

      File resultFile = File(file.path);
      if (_isMirrored) {
        resultFile = await _mirrorImageFile(resultFile);
      }

      if (mounted) {
        setState(() {
          _capturedFile = XFile(resultFile.path);
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

  /// Mirrors (flips horizontally) an image file using hardware-accelerated Canvas.
  Future<File> _mirrorImageFile(File inputFile) async {
    try {
      final Uint8List bytes = await inputFile.readAsBytes();
      final ui.Codec codec = await ui.instantiateImageCodec(bytes);
      final ui.FrameInfo frame = await codec.getNextFrame();
      final ui.Image image = frame.image;

      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);

      // Horizontal flip: translate by width, then scale -1 on X-axis
      canvas.translate(image.width.toDouble(), 0);
      canvas.scale(-1.0, 1.0);
      canvas.drawImage(image, Offset.zero, Paint());

      final picture = recorder.endRecording();
      final ui.Image flippedImage =
          await picture.toImage(image.width, image.height);
      final ByteData? byteData =
          await flippedImage.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) {
        return inputFile;
      }

      final Uint8List flippedBytes = byteData.buffer.asUint8List();
      final extMatch = RegExp(r'\.[a-zA-Z0-9]+$').firstMatch(inputFile.path);
      final String mirroredPath = extMatch != null
          ? inputFile.path.replaceAll(RegExp(r'\.[a-zA-Z0-9]+$'), '_mirrored.png')
          : '${inputFile.path}_mirrored.png';
      final File mirroredFile = File(mirroredPath);
      await mirroredFile.writeAsBytes(flippedBytes);
      return mirroredFile;
    } catch (e) {
      debugPrint('Error mirroring image file: $e');
      return inputFile;
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
              if (_errorMessage == null)
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
                onPressed: () {
                  setState(() => _isMirrored = !_isMirrored);
                  HapticFeedback.lightImpact();
                },
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _isMirrored
                        ? AsmitaPalette.actionRed.withValues(alpha: 0.85)
                        : Colors.black.withValues(alpha: 0.45),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.flip_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                tooltip: _isMirrored ? 'Mirroring ON' : 'Mirroring OFF',
              ),
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
    final preview = CameraPreview(_controller!);
    return Stack(
      fit: StackFit.expand,
      children: [
        Center(
          child: _isMirrored
              ? Transform.scale(
                  scaleX: -1.0,
                  alignment: Alignment.center,
                  child: preview,
                )
              : preview,
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
    final bool isPermission = _errorKind == CameraErrorKind.permissionDenied;
    final bool showSystemCamera =
        _errorKind != CameraErrorKind.noCamerasFound && !isPermission;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 26),
          decoration: BoxDecoration(
            color: const Color(0xFF161A22),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.6),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon with soft circular background
              Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  color: isPermission
                      ? Colors.amber.withValues(alpha: 0.15)
                      : AsmitaPalette.actionRed.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Icon(
                    isPermission
                        ? Icons.security_rounded
                        : Icons.no_photography_rounded,
                    color: isPermission ? Colors.amberAccent : AsmitaPalette.actionRed,
                    size: 32,
                  ),
                ),
              ),
              const SizedBox(height: 18),

              // Title
              Text(
                _errorTitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 10),

              // Clear user explanation
              Text(
                _errorMessage ??
                    'Unable to start the camera viewfinder. Please retry or take a photo using your device camera.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 13,
                  color: Colors.white.withValues(alpha: 0.8),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 22),

              // Primary Action Button (Retry or Open Settings)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    if (isPermission) {
                      openAppSettings();
                    } else {
                      _initCamera();
                    }
                  },
                  icon: Icon(
                    isPermission ? Icons.settings_rounded : Icons.refresh_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                  label: Text(
                    isPermission ? 'Open Device Settings' : 'Retry Camera',
                    style: const TextStyle(
                      fontFamily: 'Montserrat',
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AsmitaPalette.actionRed,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 3,
                  ),
                ),
              ),

              // Secondary Fallback: Use System Camera
              if (showSystemCamera) ...[
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _fallbackWithImagePicker(ImageSource.camera),
                    icon: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 18),
                    label: const Text(
                      'Take Photo with System Camera',
                      style: TextStyle(
                        fontFamily: 'Montserrat',
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.white.withValues(alpha: 0.3)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],

              // Tertiary Fallback: Pick from Gallery
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: () => _fallbackWithImagePicker(ImageSource.gallery),
                icon: Icon(
                  Icons.photo_library_outlined,
                  color: Colors.white.withValues(alpha: 0.7),
                  size: 16,
                ),
                label: Text(
                  'Choose from Gallery',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withValues(alpha: 0.75),
                  ),
                ),
              ),

              // Collapsible Technical Exception details for developers / debugging
              if (_rawErrorDetails != null) ...[
                const SizedBox(height: 6),
                InkWell(
                  onTap: () {
                    setState(() {
                      _showTechnicalDetails = !_showTechnicalDetails;
                    });
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _showTechnicalDetails ? 'Hide technical details' : 'Show technical details',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 11,
                            color: Colors.white.withValues(alpha: 0.4),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          _showTechnicalDetails ? Icons.expand_less : Icons.expand_more,
                          size: 14,
                          color: Colors.white.withValues(alpha: 0.4),
                        ),
                      ],
                    ),
                  ),
                ),
                if (_showTechnicalDetails) ...[
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                    ),
                    child: Text(
                      _rawErrorDetails!,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 10.5,
                        color: Colors.white54,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}
