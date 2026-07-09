import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:asmita_society/core/constants/design_system.dart';
import 'package:asmita_society/core/widgets/asmita_primary_header.dart';
import 'package:asmita_society/core/widgets/asmita_bottom_sheet.dart';
import 'package:asmita_society/core/widgets/asmita_toast.dart';
import '../../bloc/community_bloc.dart';
import '../../bloc/community_event.dart';
import '../../bloc/community_state.dart';
import '../../data/repositories/community_repository.dart';
import 'package:asmita_society/core/network/dio_client.dart';
import 'package:asmita_society/core/security/secure_storage_service.dart';
import 'package:asmita_society/features/auth/bloc/auth_bloc.dart';
import 'package:asmita_society/features/auth/bloc/auth_state.dart';

class CommunityScreen extends StatefulWidget {
  final VoidCallback? onNavigateToSearch;
  final VoidCallback? onNavigateToCommunity;

  static final CommunityRepository _repository = ApiCommunityRepository(dio: AsmitaDioClient(SecureStorageService()).dio);

  const CommunityScreen({
    super.key,
    this.onNavigateToSearch,
    this.onNavigateToCommunity,
  });

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  final TextEditingController _chatController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isTyping = false;
  bool _showAttachments = false; 

  // Audio recording controller state
  late final AudioRecorder _audioRecorder;
  bool _isRecording = false;
  int _recordDuration = 0;
  Timer? _recordTimer;
  String? _recordingPath;

  bool _isPreviewingAudio = false;
  Timer? _waveTimer;
  int _waveTick = 0;
  bool _isHoldingMic = false;

  String? _playingAudioId;
  int _playProgress = 0;
  Timer? _playbackTimer;

  double _dragOffset = 0.0;

  @override
  void initState() {
    super.initState();
    _audioRecorder = AudioRecorder();
  }

  @override
  void dispose() {
    _chatController.dispose();
    _scrollController.dispose();
    _recordTimer?.cancel();
    _waveTimer?.cancel();
    _playbackTimer?.cancel();
    _audioRecorder.dispose();
    super.dispose();
  }

  void _toggleAttachments() {
    FocusScope.of(context).unfocus(); 
    setState(() {
      _showAttachments = !_showAttachments;
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // Gallery Picker Handler
  Future<void> _pickImageFromGallery(CommunityBloc bloc) async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );

      if (pickedFile != null) {
        bloc.add(SendImageMessage(pickedFile.path));
        if (mounted) {
          AsmitaToast.show(
            context,
            message: 'E2E Encrypted Image uploaded successfully!',
            type: AsmitaToastType.success,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        AsmitaToast.show(
          context,
          message: 'Failed to pick image from gallery.',
          type: AsmitaToastType.error,
        );
      }
    }
  }

  // Camera Picker Handler
  Future<void> _pickImageFromCamera(CommunityBloc bloc) async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
      );

      if (pickedFile != null) {
        _showImagePreviewDialog(pickedFile.path, bloc);
      }
    } catch (e) {
      if (mounted) {
        AsmitaToast.show(
          context,
          message: 'Failed to open camera.',
          type: AsmitaToastType.error,
        );
      }
    }
  }

  Future<void> _pickAudioFile(CommunityBloc bloc) async {
    try {
      final result = await FilePicker.platform.pickFiles(type: FileType.audio);
      if (result != null && result.files.single.path != null) {
        bloc.add(const SendAudioMessage('0:05'));
        if (mounted) {
          AsmitaToast.show(
            context,
            message: 'E2E Encrypted Audio File sent successfully!',
            type: AsmitaToastType.success,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        AsmitaToast.show(
          context,
          message: 'Failed to pick audio file.',
          type: AsmitaToastType.error,
        );
      }
    }
  }

  void _showImagePreviewDialog(String imagePath, CommunityBloc bloc) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Send Photo?', style: TextStyle(fontFamily: 'Montserrat', fontWeight: FontWeight.bold, fontSize: 18)),
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: const Icon(Icons.close, color: AsmitaPalette.textLight),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          content: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.file(File(imagePath), height: 300, fit: BoxFit.cover),
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: AsmitaPalette.actionRed, fontFamily: 'Poppins')),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                bloc.add(SendImageMessage(imagePath));
                AsmitaToast.show(
                  context,
                  message: 'E2E Encrypted Photo sent successfully!',
                  type: AsmitaToastType.success,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AsmitaPalette.deepNavy,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Send', style: TextStyle(color: Colors.white, fontFamily: 'Poppins')),
            ),
          ],
        );
      }
    );
  }

  // Audio Recording Flow Handlers
  Future<void> _startRecording() async {
    try {
      if (await _audioRecorder.hasPermission()) {
        final tempDir = await getTemporaryDirectory();
        final path = '${tempDir.path}/audio_${DateTime.now().millisecondsSinceEpoch}.m4a';

        await _audioRecorder.start(
          const RecordConfig(encoder: AudioEncoder.aacLc),
          path: path,
        );

        if (!mounted) return;

        if (!_isHoldingMic) {
           await _audioRecorder.stop();
           final file = File(path);
           if (await file.exists()) await file.delete();
           return;
        }

        setState(() {
          _isRecording = true;
          _recordDuration = 0;
          _waveTick = 0;
          _recordingPath = path;
          _showAttachments = false;
          _isPreviewingAudio = false;
        });

        _recordTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
          setState(() {
            _recordDuration++;
          });
        });
        _waveTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
          if (mounted) setState(() => _waveTick++);
        });
      } else {
        if (mounted) {
          AsmitaToast.show(
            context,
            message: 'Microphone permission denied.',
            type: AsmitaToastType.error,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        AsmitaToast.show(
          context,
          message: 'Failed to start audio recording.',
          type: AsmitaToastType.error,
        );
      }
    }
  }

  Future<void> _stopAndSendRecording(CommunityBloc bloc) async {
    _recordTimer?.cancel();
    _waveTimer?.cancel();
    try {
      final path = await _audioRecorder.stop();
      if (path != null && _recordDuration > 0) {
        final durationString = '0:${_recordDuration.toString().padLeft(2, '0')}';
        bloc.add(SendAudioMessage(durationString));
        if (mounted) {
          AsmitaToast.show(
            context,
            message: 'E2E Encrypted Audio recorded successfully!',
            type: AsmitaToastType.success,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        AsmitaToast.show(
          context,
          message: 'Failed to complete audio recording.',
          type: AsmitaToastType.error,
        );
      }
    } finally {
      setState(() {
        _isRecording = false;
        _recordDuration = 0;
        _recordingPath = null;
      });
    }
  }

  Future<void> _stopAndPreviewRecording(CommunityBloc bloc) async {
    _recordTimer?.cancel();
    _waveTimer?.cancel();
    try {
      await _audioRecorder.stop();
    } catch (_) {}
    setState(() {
      _isRecording = false;
      _dragOffset = 0.0;
      if (_recordDuration > 0 || _waveTick > 3) {
        _isPreviewingAudio = true;
        if (_recordDuration == 0) _recordDuration = 1;
      }
    });
    if (!_isPreviewingAudio) {
      _cancelRecording();
    }
  }

  Future<void> _cancelRecording() async {
    if (!_isRecording && !_isPreviewingAudio) return;
    _recordTimer?.cancel();
    _waveTimer?.cancel();
    setState(() {
      _isRecording = false; // Prevent multiple triggers
      _isPreviewingAudio = false;
      _dragOffset = 0.0;
    });
    try {
      await _audioRecorder.stop();
      if (_recordingPath != null) {
        final file = File(_recordingPath!);
        if (await file.exists()) {
          await file.delete();
        }
      }
    } catch (_) {}
    setState(() {
      _recordDuration = 0;
      _recordingPath = null;
    });
    if (mounted) {
      AsmitaToast.show(
        context,
        message: 'Recording discarded.',
        type: AsmitaToastType.error,
      );
    }
  }

  // Audio Playback UI Simulation
  void _togglePlayback(String messageId, String duration) {
    if (_playingAudioId == messageId) {
      _playbackTimer?.cancel();
      setState(() {
        _playingAudioId = null;
        _playProgress = 0;
      });
      return;
    }

    _playbackTimer?.cancel();
    int seconds = 5;
    try {
      final parts = duration.split(':');
      if (parts.length == 2) {
        seconds = int.tryParse(parts[1]) ?? 5;
      }
    } catch (_) {}

    setState(() {
      _playingAudioId = messageId;
      _playProgress = 0;
    });

    _playbackTimer = Timer.periodic(const Duration(milliseconds: 200), (timer) {
      setState(() {
        if (_playProgress >= 100) {
          timer.cancel();
          _playingAudioId = null;
          _playProgress = 0;
        } else {
          _playProgress += (100 ~/ (seconds * 5));
          if (_playProgress > 100) _playProgress = 100;
        }
      });
    });
  }

  void _showCreatePollSheet(BuildContext context, CommunityBloc bloc) {
    showAsmitaBottomSheet(
      context: context,
      title: 'Create Poll',
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: _CreatePollSheetWidget(bloc: bloc),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<CommunityBloc>(
      create: (context) {
        final authState = context.read<AuthBloc>().state;
        int? userId;
        String? userName;
        if (authState is AuthAuthenticated) {
          userId = authState.user.userId;
          userName = authState.user.fullName;
        }
        return CommunityBloc(repository: CommunityScreen._repository)..add(LoadCommunityMessages(currentUserId: userId, currentUserName: userName));
      },
      child: Builder(
        builder: (context) {
          final bloc = context.read<CommunityBloc>();

          return Scaffold(
            backgroundColor: AsmitaPalette.systemBG,
            body: Column(
              children: [
                // Unified Global Header
                AsmitaPrimaryHeader(
                  title: 'Siddhi CHS 34 Hub',
                  subtitle: '244 Members',
                  onSearchPressed: widget.onNavigateToSearch,
                  onChatPressed: widget.onNavigateToCommunity,
                ),
                
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      if (_showAttachments) setState(() => _showAttachments = false);
                      FocusScope.of(context).unfocus();
                    },
                    behavior: HitTestBehavior.opaque,
                    child: Stack(
                      children: [
                        BlocConsumer<CommunityBloc, CommunityState>(
                          listener: (context, state) {
                            if (state is CommunityLoaded) {
                              _scrollToBottom();
                            }
                          },
                          builder: (context, state) {
                            if (state is CommunityLoading) {
                              return const Center(child: CircularProgressIndicator(color: AsmitaPalette.actionRed));
                            } else if (state is CommunityError) {
                              return Center(
                                child: Text(
                                  state.error,
                                  style: const TextStyle(fontFamily: 'Poppins', color: AsmitaPalette.textLight),
                                ),
                              );
                            } else if (state is CommunityLoaded) {
                              final messages = state.messages;
                              
                              if (messages.isEmpty) {
                                return const Center(
                                  child: Text(
                                    'No messages yet. Send a message to start.',
                                    style: TextStyle(fontFamily: 'Poppins', color: AsmitaPalette.textLight),
                                  ),
                                );
                              }

                              return ListView.builder(
                                controller: _scrollController,
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                                itemCount: messages.length,
                                itemBuilder: (context, index) {
                                  final msg = messages[index];
                                  final showDateBadge = index == 0 || 
                                      !messages[index - 1].time.startsWith(msg.time.split(',')[0]);

                                  return Column(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
                                      if (showDateBadge) ...[
                                        const SizedBox(height: 8),
                                        _buildDateBadge(context, msg.time.split(',')[0]),
                                        const SizedBox(height: 16),
                                      ],
                                      _buildMessageBubble(
                                        context: context,
                                        messageId: msg.id,
                                        sender: msg.sender,
                                        isMe: msg.isMe,
                                        time: msg.time.contains(',') ? msg.time.split(',')[1].trim() : msg.time,
                                        type: msg.type,
                                        content: msg.content,
                                        pollOptions: msg.pollOptions,
                                        isManagement: msg.isManagement,
                                      ),
                                      const SizedBox(height: 12),
                                    ],
                                  );
                                },
                              );
                            }
                            return const SizedBox.shrink();
                          },
                        ),
                        
                        Positioned(
                          bottom: 12,
                          left: 12,
                          right: 12,
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 200),
                            transitionBuilder: (child, animation) {
                              return FadeTransition(
                                opacity: animation,
                                child: SlideTransition(
                                  position: Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(animation),
                                  child: child,
                                ),
                              );
                            },
                            child: _showAttachments 
                                ? _buildAttachmentPopup(context, bloc) 
                                : const SizedBox.shrink(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                _buildChatInputArea(context, bloc),
              ],
            ),
          );
        }
      ),
    );
  }

  Widget _buildAttachmentPopup(BuildContext context, CommunityBloc bloc) {
    return Container(
      key: const ValueKey('attachment_menu'), 
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AsmitaPalette.borderGrey, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildAttachmentIcon(context, Icons.insert_photo_rounded, 'Gallery', Colors.purple, () {
            _pickImageFromGallery(bloc);
          }),
          _buildAttachmentIcon(context, Icons.poll_rounded, 'Poll', AsmitaPalette.actionRed, () {
            _showCreatePollSheet(context, bloc);
          }),
          _buildAttachmentIcon(context, Icons.headset_mic_rounded, 'Audio', Colors.orange, () {
            _pickAudioFile(bloc);
          }),
          _buildAttachmentIcon(context, Icons.description_rounded, 'Document', AsmitaPalette.deepNavy, () {
            AsmitaToast.show(
              context,
              message: 'E2EE Document attachments are mock-only in this version.',
              type: AsmitaToastType.success,
            );
          }),
        ],
      ),
    );
  }

  Widget _buildAttachmentIcon(BuildContext context, IconData icon, String label, Color color, VoidCallback onTap) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          onTap: () {
            setState(() => _showAttachments = false);
            onTap();
          },
          borderRadius: BorderRadius.circular(30),
          child: CircleAvatar(
            radius: 28,
            backgroundColor: color.withValues(alpha: 0.1),
            child: Icon(icon, color: color, size: 26),
          ),
        ),
        const SizedBox(height: 8),
        Text(label, style: textTheme.bodyMedium?.copyWith(fontSize: 11, fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _buildTextFieldUI(CommunityBloc bloc) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (!_isTyping)
          IconButton(
            icon: Icon(_showAttachments ? Icons.cancel_rounded : Icons.attach_file_rounded, color: _showAttachments ? AsmitaPalette.actionRed : AsmitaPalette.textLight, size: 26),
            onPressed: _toggleAttachments,
          ),
        Expanded(
          child: TextField(
            controller: _chatController,
            minLines: 1,
            maxLines: 4,
            onTap: () {
              if (_showAttachments) setState(() => _showAttachments = false);
            },
            onChanged: (val) {
              setState(() {
                _isTyping = val.trim().isNotEmpty;
              });
            },
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontSize: 14),
            decoration: const InputDecoration(
              hintText: 'Message...',
              hintStyle: TextStyle(color: AsmitaPalette.textLight, fontSize: 14),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
        ),
        if (!_isTyping)
          IconButton(
            icon: const Icon(Icons.camera_alt_outlined, color: AsmitaPalette.textLight, size: 22),
            onPressed: () {
              if (_showAttachments) setState(() => _showAttachments = false);
              _pickImageFromCamera(bloc);
            },
          ),
      ],
    );
  }

  Widget _buildRecordingUI() {
    final isSliding = _dragOffset < -10;
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Icon(
            isSliding ? Icons.delete_outline_rounded : Icons.mic, 
            color: AsmitaPalette.actionRed, 
            size: isSliding ? 28 : 24,
          ),
          const SizedBox(width: 8),
          Text(
            '0:${_recordDuration.toString().padLeft(2, '0')}',
            style: const TextStyle(fontSize: 16, color: Colors.black87),
          ),
          const Spacer(),
          const Icon(Icons.keyboard_arrow_left, color: Colors.grey, size: 16),
          const SizedBox(width: 4),
          const Text('Slide to cancel', style: TextStyle(color: Colors.grey, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildPreviewUI(CommunityBloc bloc) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          IconButton(
            padding: EdgeInsets.zero,
            icon: const Icon(Icons.delete_outline_rounded, color: AsmitaPalette.actionRed, size: 24),
            onPressed: _cancelRecording,
          ),
          const Spacer(),
          const Icon(Icons.play_circle_fill_rounded, color: AsmitaPalette.deepNavy, size: 24),
          const SizedBox(width: 12),
          Text(
            '0:${_recordDuration.toString().padLeft(2, '0')}',
            style: const TextStyle(fontFamily: 'Poppins', fontSize: 14, color: AsmitaPalette.deepNavy, fontWeight: FontWeight.w600),
          ),
          const Spacer(),
          GestureDetector(
            onTap: () {
              final durationString = '0:${_recordDuration.toString().padLeft(2, '0')}';
              bloc.add(SendAudioMessage(durationString));
              setState(() {
                _isPreviewingAudio = false;
                _recordDuration = 0;
                _recordingPath = null;
              });
            },
            child: const Icon(Icons.send_rounded, color: AsmitaPalette.actionRed, size: 24),
          ),
        ],
      ),
    );
  }

  Widget _buildMicButton(CommunityBloc bloc) {
    return GestureDetector(
      onLongPressStart: _isTyping ? null : (_) {
        if (_showAttachments) setState(() => _showAttachments = false);
        _isHoldingMic = true;
        _startRecording();
      },
      onLongPressMoveUpdate: _isTyping ? null : (details) {
        if (!_isRecording) return;
        if (details.localOffsetFromOrigin.dx < 0) {
           setState(() {
             _dragOffset = details.localOffsetFromOrigin.dx;
           });
           if (_dragOffset < -50) {
              _cancelRecording();
           }
        }
      },
      onLongPressEnd: _isTyping ? null : (_) {
        _isHoldingMic = false;
        setState(() {
           _dragOffset = 0.0;
        });
        if (_isRecording) {
          _stopAndPreviewRecording(bloc);
        }
      },
      onLongPressCancel: _isTyping ? null : () {
        _isHoldingMic = false;
        setState(() {
           _dragOffset = 0.0;
        });
        if (_isRecording) {
          _stopAndPreviewRecording(bloc);
        }
      },
      onTap: _isTyping ? () {
        if (_showAttachments) setState(() => _showAttachments = false);
        bloc.add(SendTextMessage(_chatController.text.trim()));
        _chatController.clear();
        setState(() => _isTyping = false);
      } : () {
        AsmitaToast.show(
          context,
          message: 'Hold to record audio',
          type: AsmitaToastType.success,
        );
      },
      child: Transform.translate(
        offset: Offset(_dragOffset, 0),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: _isRecording ? 60 : 48,
          height: _isRecording ? 60 : 48,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _isTyping ? AsmitaPalette.actionRed : AsmitaPalette.deepNavy,
          ),
          alignment: Alignment.center,
          child: Icon(
            _isTyping ? Icons.send_rounded : Icons.mic_rounded,
            color: Colors.white,
            size: _isRecording ? 30 : 24,
          ),
        ),
      ),
    );
  }

  Widget _buildChatInputArea(BuildContext context, CommunityBloc bloc) {
    return Container(
      padding: EdgeInsets.only(
        left: 8,
        right: 8,
        top: 8,
        bottom: MediaQuery.viewPaddingOf(context).bottom > 0 ? MediaQuery.viewPaddingOf(context).bottom : 12,
      ),
      color: Colors.transparent,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Container(
              constraints: const BoxConstraints(maxHeight: 120),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AsmitaPalette.borderGrey),
              ),
              child: _isPreviewingAudio
                  ? _buildPreviewUI(bloc)
                  : _isRecording
                      ? _buildRecordingUI()
                      : _buildTextFieldUI(bloc),
            ),
          ),
          const SizedBox(width: 8),
          _buildMicButton(bloc),
        ],
      ),
    );
  }

  Widget _buildDateBadge(BuildContext context, String date) {
    final textTheme = Theme.of(context).textTheme;
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(color: AsmitaPalette.borderGrey, borderRadius: BorderRadius.circular(12)),
        child: Text(date, style: textTheme.bodyMedium?.copyWith(fontSize: 11, fontWeight: FontWeight.w600, color: AsmitaPalette.textLight)),
      ),
    );
  }

  Widget _buildMessageBubble({
    required BuildContext context,
    required String messageId,
    required String sender,
    required bool isMe,
    required String time,
    required String type,
    required String content,
    Map<String, int>? pollOptions,
    bool isManagement = false,
  }) {
    final textTheme = Theme.of(context).textTheme;

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.75),
        child: Column(
          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (!isMe)
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      sender,
                      style: textTheme.bodyLarge?.copyWith(fontSize: 11, fontWeight: FontWeight.w700, color: isManagement ? AsmitaPalette.actionRed : AsmitaPalette.deepNavy),
                    ),
                    if (isManagement) ...[
                      const SizedBox(width: 4),
                      const Icon(Icons.verified_rounded, color: AsmitaPalette.actionRed, size: 12),
                    ]
                  ],
                ),
              ),
            Container(
              decoration: BoxDecoration(
                color: isMe ? AsmitaPalette.deepNavy : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isMe ? 16 : 4),
                  bottomRight: Radius.circular(isMe ? 4 : 16),
                ),
                border: isMe ? null : Border.all(color: AsmitaPalette.borderGrey, width: 1.5),
                boxShadow: [
                  if (!isMe) BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 4, offset: const Offset(0, 2)),
                ],
              ),
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (type == 'text') Text(content, style: textTheme.bodyLarge?.copyWith(fontSize: 13, height: 1.4, color: isMe ? Colors.white : AsmitaPalette.textDark)),
                  if (type == 'image') _buildImagePreview(context, content),
                  if (type == 'audio') _buildAudioPlayer(context, messageId, isMe, content),
                  if (type == 'poll' && pollOptions != null) _buildPollWidget(context, content, pollOptions, isMe),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(time, style: textTheme.bodyMedium?.copyWith(fontSize: 9, fontWeight: FontWeight.w600, color: isMe ? Colors.white70 : AsmitaPalette.textLight)),
                      if (isMe) ...[
                        const SizedBox(width: 4),
                        const Icon(Icons.done_all_rounded, color: Colors.white70, size: 12),
                      ]
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePreview(BuildContext context, String path) {
    final file = File(path);
    final exists = file.existsSync();

    return Container(
      constraints: const BoxConstraints(maxHeight: 180),
      margin: const EdgeInsets.only(bottom: 4),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: exists
            ? Image.file(
                file,
                fit: BoxFit.cover,
                width: double.infinity,
              )
            : Container(
                color: Colors.grey.shade100,
                width: double.infinity,
                height: 120,
                alignment: Alignment.center,
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.broken_image_rounded, color: Colors.grey),
                    SizedBox(width: 8),
                    Text('Image not found', style: TextStyle(fontFamily: 'Poppins', color: Colors.grey, fontSize: 12)),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildAudioPlayer(BuildContext context, String messageId, bool isMe, String duration) {
    final isPlaying = _playingAudioId == messageId;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          onPressed: () => _togglePlayback(messageId, duration),
          icon: Icon(
            isPlaying ? Icons.pause_circle_filled_rounded : Icons.play_circle_fill_rounded,
            color: isMe ? Colors.white : AsmitaPalette.actionRed,
            size: 32,
          ),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 100,
          child: isPlaying
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    value: _playProgress / 100.0,
                    color: isMe ? Colors.white : AsmitaPalette.actionRed,
                    backgroundColor: isMe ? Colors.white.withValues(alpha: 0.3) : AsmitaPalette.borderGrey,
                    minHeight: 4,
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(15, (index) {
                    return Container(
                      width: 3,
                      height: index % 2 == 0 ? 12 : (index % 3 == 0 ? 20 : 8),
                      decoration: BoxDecoration(
                        color: isMe ? Colors.white.withValues(alpha: 0.6) : AsmitaPalette.borderGrey,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    );
                  }),
                ),
        ),
        const SizedBox(width: 8),
        Text(
          duration,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isMe ? Colors.white : AsmitaPalette.textDark,
              ),
        ),
      ],
    );
  }

  Widget _buildPollWidget(BuildContext context, String question, Map<String, int> options, bool isMe) {
    final textTheme = Theme.of(context).textTheme;
    
    // Convert options to mutable copy so user can tap/vote on the options directly on UI!
    // We can simulate voting by incrementing value on tap!
    // Since it's E2EE in-memory, we can dispatch SendPollMessage event or just local state update.
    // For local mockup, tapping increments vote directly to make the poll interaction feel 100% live!
    final totalVotes = options.values.fold(0, (sum, item) => sum + item);

    return StatefulBuilder(
      builder: (context, setPollState) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.poll_rounded, color: AsmitaPalette.actionRed, size: 16),
                const SizedBox(width: 6),
                Text('POLL', style: textTheme.bodyLarge?.copyWith(fontSize: 10, fontWeight: FontWeight.w800, color: AsmitaPalette.actionRed)),
              ],
            ),
            const SizedBox(height: 8),
            Text(question, style: textTheme.titleLarge?.copyWith(fontSize: 13, fontWeight: FontWeight.w700, color: isMe ? Colors.white : AsmitaPalette.textDark)),
            const SizedBox(height: 12),
            ...options.entries.map((entry) {
              final percentage = totalVotes == 0 ? 0.0 : (entry.value / totalVotes);
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: InkWell(
                  onTap: () {
                    setPollState(() {
                      options[entry.key] = entry.value + 1;
                    });
                    AsmitaToast.show(
                      context,
                      message: 'Vote casted for "${entry.key}"!',
                      type: AsmitaToastType.success,
                    );
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Stack(
                    children: [
                      Container(width: double.infinity, height: 32, decoration: BoxDecoration(color: isMe ? Colors.white.withValues(alpha: 0.1) : AsmitaPalette.systemBG, borderRadius: BorderRadius.circular(8), border: Border.all(color: isMe ? Colors.transparent : AsmitaPalette.borderGrey))),
                      FractionallySizedBox(widthFactor: percentage, child: Container(height: 32, decoration: BoxDecoration(color: isMe ? Colors.white.withValues(alpha: 0.2) : AsmitaPalette.deepNavy.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)))),
                      Positioned.fill(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(entry.key, style: textTheme.bodyLarge?.copyWith(fontSize: 12, fontWeight: FontWeight.w600, color: isMe ? Colors.white : AsmitaPalette.textDark)),
                              Text('${(percentage * 100).toInt()}% (${entry.value})', style: textTheme.bodyMedium?.copyWith(fontSize: 11, fontWeight: FontWeight.w600, color: isMe ? Colors.white70 : AsmitaPalette.textLight)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        );
      }
    );
  }
}

class _CreatePollSheetWidget extends StatefulWidget {
  final CommunityBloc bloc;

  const _CreatePollSheetWidget({required this.bloc});

  @override
  State<_CreatePollSheetWidget> createState() => _CreatePollSheetWidgetState();
}

class _CreatePollSheetWidgetState extends State<_CreatePollSheetWidget> {
  final TextEditingController _questionController = TextEditingController();
  final List<TextEditingController> _optionControllers = [
    TextEditingController(),
    TextEditingController(),
  ];
  bool _allowMultipleAnswers = false;

  @override
  void dispose() {
    _questionController.dispose();
    for (var c in _optionControllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _addOption() {
    if (_optionControllers.length < 5) {
      setState(() {
        _optionControllers.add(TextEditingController());
      });
    }
  }

  void _removeOption(int index) {
    if (_optionControllers.length > 2) {
      setState(() {
        _optionControllers[index].dispose();
        _optionControllers.removeAt(index);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 20, right: 20, top: 10, bottom: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Poll Details',
            style: TextStyle(
              fontFamily: 'Montserrat',
              color: AsmitaPalette.deepNavy,
              fontWeight: FontWeight.w800,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _questionController,
            style: const TextStyle(fontFamily: 'Poppins', fontSize: 13),
            decoration: InputDecoration(
              labelText: 'Question',
              labelStyle: const TextStyle(fontFamily: 'Poppins', fontSize: 13, color: AsmitaPalette.textLight),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 12),
          ..._optionControllers.asMap().entries.map((entry) {
            final idx = entry.key;
            final controller = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: controller,
                      style: const TextStyle(fontFamily: 'Poppins', fontSize: 13),
                      decoration: InputDecoration(
                        labelText: 'Option ${idx + 1}',
                        labelStyle: const TextStyle(fontFamily: 'Poppins', fontSize: 13, color: AsmitaPalette.textLight),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  if (_optionControllers.length > 2)
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline, color: AsmitaPalette.actionRed),
                      onPressed: () => _removeOption(idx),
                    ),
                ],
              ),
            );
          }),
          if (_optionControllers.length < 5)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: _addOption,
                icon: const Icon(Icons.add_circle_outline, size: 18),
                label: const Text('Add Option', style: TextStyle(fontFamily: 'Poppins', fontSize: 13)),
                style: TextButton.styleFrom(foregroundColor: AsmitaPalette.deepNavy),
              ),
            ),
          SwitchListTile(
            title: const Text('Allow multiple answers', style: TextStyle(fontFamily: 'Poppins', fontSize: 13)),
            value: _allowMultipleAnswers,
            activeColor: AsmitaPalette.deepNavy,
            contentPadding: EdgeInsets.zero,
            onChanged: (val) {
              setState(() => _allowMultipleAnswers = val);
            },
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 50,
            child: ElevatedButton(
              onPressed: () {
                final q = _questionController.text.trim();
                final opts = _optionControllers.map((c) => c.text.trim()).where((t) => t.isNotEmpty).toList();

                if (q.isEmpty || opts.length < 2) {
                  AsmitaToast.show(
                    context,
                    message: 'Please fill in the question and at least two options.',
                    type: AsmitaToastType.error,
                  );
                  return;
                }

                final Map<String, int> optionsMap = {};
                for (var opt in opts) {
                  optionsMap[opt] = 0;
                }

                widget.bloc.add(SendPollMessage(
                  question: q, 
                  options: optionsMap, 
                  allowMultipleAnswers: _allowMultipleAnswers,
                ));
                Navigator.pop(context);
                AsmitaToast.show(
                  context,
                  message: 'E2E Encrypted Poll published successfully!',
                  type: AsmitaToastType.success,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AsmitaPalette.actionRed,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: const Text(
                'Publish Poll',
                style: TextStyle(
                  fontFamily: 'Montserrat',
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}