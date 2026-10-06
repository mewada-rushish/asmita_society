import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../bloc/community_bloc.dart';
import '../../bloc/community_event.dart';
import 'package:flutter/foundation.dart' as foundation;
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'dart:async';
import 'dart:io';
import 'dart:ui';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../bloc/community_state.dart';
import '../attachments/attachment_bottom_sheet.dart';

class ChatComposer extends StatefulWidget {
  const ChatComposer({super.key});

  @override
  State<ChatComposer> createState() => _ChatComposerState();
}

class _ChatComposerState extends State<ChatComposer>
    with TickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _isTyping = false;
  bool _emojiShowing = false;
  late final AnimationController _emojiAnimController;
  late final Animation<double> _emojiAnim;

  final _audioRecorder = AudioRecorder();
  bool _isRecording = false;
  int _recordingDuration = 0;
  Timer? _recordingTimer;
  String? _recordingPath;

  // Hold-to-record WhatsApp style state
  double _dragOffset = 0.0;
  bool _isCancelled = false;
  late final AnimationController _micScaleController;
  late final AnimationController _blinkController;

  @override
  void initState() {
    super.initState();
    _emojiAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _emojiAnim = CurvedAnimation(
      parent: _emojiAnimController,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
    _micScaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
      lowerBound: 1.0,
      upperBound: 1.5,
    );
    _blinkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);
    _controller.addListener(() {
      setState(() {
        _isTyping = _controller.text.trim().isNotEmpty;
      });
    });
    _focusNode.addListener(() {
      if (_focusNode.hasFocus && _emojiShowing) {
        setState(() {
          _emojiShowing = false;
        });
        _emojiAnimController.reverse();
      }
    });
  }

  @override
  void dispose() {
    _emojiAnimController.dispose();
    _micScaleController.dispose();
    _blinkController.dispose();
    _recordingTimer?.cancel();
    _audioRecorder.dispose();
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _handleSend() {
    if (_controller.text.trim().isEmpty) return;

    final state = context.read<CommunityBloc>().state;
    String? replyToId;
    String? replyToContent;

    if (state is CommunityLoaded) {
      if (state.replyingToMessage != null) {
        final replMsg = state.replyingToMessage!;
        replyToId = replMsg.id;

        final filename = replMsg.content.split('/').last;
        replyToContent = replMsg.type == 'image'
            ? '📷 $filename'
            : replMsg.type == 'audio'
            ? '🎵 $filename'
            : replMsg.type == 'video'
            ? '🎬 $filename'
            : replMsg.type == 'document'
            ? '📄 $filename'
            : replMsg.content;
      }
    }

    context.read<CommunityBloc>().add(
      SendTextMessage(
        _controller.text.trim(),
        replyToMessageId: replyToId,
        replyToContent: replyToContent,
      ),
    );

    context.read<CommunityBloc>().add(ClearReplyToMessage());
    _controller.clear();
  }

  Future<void> _startRecording() async {
    try {
      if (await _audioRecorder.hasPermission()) {
        final dir = await getTemporaryDirectory();
        _recordingPath =
            '${dir.path}/audio_${DateTime.now().millisecondsSinceEpoch}.m4a';

        await _audioRecorder.start(
          const RecordConfig(encoder: AudioEncoder.aacLc),
          path: _recordingPath!,
        );

        setState(() {
          _isRecording = true;
          _isCancelled = false;
          _dragOffset = 0.0;
          _recordingDuration = 0;
          _emojiShowing = false;
        });

        _focusNode.unfocus();
        _micScaleController.forward();

        _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
          setState(() {
            _recordingDuration++;
          });
        });
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Microphone permission is required to record audio.'),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error starting record: $e');
    }
  }

  Future<void> _stopRecording({bool cancel = false}) async {
    _recordingTimer?.cancel();
    final path = await _audioRecorder.stop();

    final durationSeconds = _recordingDuration;

    setState(() {
      _isRecording = false;
      _recordingDuration = 0;
      _dragOffset = 0.0;
      _isCancelled = false;
    });

    _micScaleController.reverse();

    if (cancel) {
      if (path != null) {
        final file = File(path);
        if (await file.exists()) {
          await file.delete();
        }
      }
    } else if (path != null) {
      final formattedDuration =
          '${(durationSeconds ~/ 60)}:${(durationSeconds % 60).toString().padLeft(2, '0')}';
      if (!mounted) return;
      final state = context.read<CommunityBloc>().state;
      String? replyToId;
      String? replyToContentStr;
      if (state is CommunityLoaded && state.replyingToMessage != null) {
        replyToId = state.replyingToMessage!.id;
        final filename = state.replyingToMessage!.content.split('/').last;
        replyToContentStr = state.replyingToMessage!.type == 'image'
            ? '📷 $filename'
            : state.replyingToMessage!.type == 'audio'
            ? '🎵 $filename'
            : state.replyingToMessage!.type == 'video'
            ? '🎬 $filename'
            : state.replyingToMessage!.type == 'document'
            ? '📄 $filename'
            : state.replyingToMessage!.content;
      }
      context.read<CommunityBloc>().add(
        SendAudioMessage(
          formattedDuration,
          path,
          replyToMessageId: replyToId,
          replyToContent: replyToContentStr,
        ),
      );
      context.read<CommunityBloc>().add(ClearReplyToMessage());
    }
  }

  Future<void> _openCamera() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 70,
      );

      if (pickedFile != null) {
        if (!mounted) return;
        final state = context.read<CommunityBloc>().state;
        String? replyToId;
        String? replyToContentStr;
        if (state is CommunityLoaded && state.replyingToMessage != null) {
          replyToId = state.replyingToMessage!.id;
          final filename = state.replyingToMessage!.content.split('/').last;
          replyToContentStr = state.replyingToMessage!.type == 'image'
              ? '📷 $filename'
              : state.replyingToMessage!.type == 'audio'
              ? '🎵 $filename'
              : state.replyingToMessage!.type == 'video'
              ? '🎬 $filename'
              : state.replyingToMessage!.type == 'document'
              ? '📄 $filename'
              : state.replyingToMessage!.content;
        }
        context.read<CommunityBloc>().add(
          SendImageMessage(
            pickedFile.path,
            replyToMessageId: replyToId,
            replyToContent: replyToContentStr,
          ),
        );
        context.read<CommunityBloc>().add(ClearReplyToMessage());
      }
    } catch (e) {
      debugPrint('Error opening camera: $e');
    }
  }

  void _showAttachmentMenu() {
    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final offset = renderBox.localToGlobal(Offset.zero);
    final bottomPadding = MediaQuery.of(context).size.height - offset.dy;

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss',
      barrierColor: Colors.black.withValues(alpha: 0.1),
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (context, animation, secondaryAnimation) {
        return Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: EdgeInsets.only(bottom: bottomPadding),
            child: const Material(
              color: Colors.transparent,
              child: AttachmentBottomSheet(),
            ),
          ),
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return SlideTransition(
          position:
              Tween<Offset>(
                begin: const Offset(0, 0.05),
                end: Offset.zero,
              ).animate(
                CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
              ),
          child: FadeTransition(opacity: animation, child: child),
        );
      },
    );
  }

  Widget _buildReplyDock(CommunityState state) {
    if (state is! CommunityLoaded) return const SizedBox.shrink();
    final msg = state.replyingToMessage;
    if (msg == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F8FB),
        border: Border(
          top: BorderSide(color: Colors.black.withValues(alpha: 0.05)),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 4,
            height: 40,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  msg.isMe ? 'You' : msg.sender,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                Text(
                  msg.type == 'image'
                      ? '📷 ${msg.content.split('/').last}'
                      : msg.type == 'audio'
                      ? '🎵 ${msg.content.split('/').last}'
                      : msg.type == 'video'
                      ? '🎬 ${msg.content.split('/').last}'
                      : msg.type == 'document'
                      ? '📄 ${msg.content.split('/').last}'
                      : msg.content,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    color: Theme.of(context).textTheme.bodySmall?.color,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 20),
            color: Theme.of(context).textTheme.bodySmall?.color,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: () {
              context.read<CommunityBloc>().add(ClearReplyToMessage());
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CommunityBloc, CommunityState>(
      builder: (context, state) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildReplyDock(state),
            ClipRRect(
              child: BackdropFilter(
                filter: Theme.of(context).brightness == Brightness.dark
                    ? ImageFilter.blur(sigmaX: 0.0, sigmaY: 0.0)
                    : ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.transparent
                        : Theme.of(
                            context,
                          ).colorScheme.surface.withValues(alpha: 0.85),
                    border: Theme.of(context).brightness == Brightness.dark
                        ? null
                        : Border(
                            top: BorderSide(
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurface.withValues(alpha: 0.05),
                              width: 1.0,
                            ),
                          ),
                    boxShadow: Theme.of(context).brightness == Brightness.dark
                        ? null
                        : [
                            if (!_emojiShowing)
                              BoxShadow(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withValues(alpha: 0.05),
                                blurRadius: 10,
                                offset: const Offset(0, -2),
                              ),
                          ],
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Stack(
                          clipBehavior: Clip.none,
                          alignment: Alignment.bottomRight,
                          children: [
                            // Normal text input field
                            AnimatedOpacity(
                              opacity: _isRecording ? 0.0 : 1.0,
                              duration: const Duration(milliseconds: 200),
                              child: IgnorePointer(
                                ignoring: _isRecording,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.surfaceContainerHighest,
                                    borderRadius: BorderRadius.circular(24),
                                  ),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      IconButton(
                                        icon: Icon(
                                          _emojiShowing
                                              ? Icons.keyboard_rounded
                                              : Icons.emoji_emotions_outlined,
                                        ),
                                        color: Theme.of(
                                          context,
                                        ).textTheme.bodySmall?.color,
                                        onPressed: () {
                                          setState(() {
                                            _emojiShowing = !_emojiShowing;
                                          });
                                          if (_emojiShowing) {
                                            _focusNode.unfocus();
                                            _emojiAnimController.forward();
                                          } else {
                                            _focusNode.requestFocus();
                                            _emojiAnimController.reverse();
                                          }
                                        },
                                      ),
                                      Expanded(
                                        child: Padding(
                                          padding: const EdgeInsets.only(
                                            top: 12,
                                            bottom: 14,
                                          ),
                                          child: TextField(
                                            controller: _controller,
                                            focusNode: _focusNode,
                                            minLines: 1,
                                            maxLines: 6,
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodyLarge
                                                ?.copyWith(
                                                  color: Theme.of(
                                                    context,
                                                  ).colorScheme.onSurface,
                                                ),
                                            decoration: InputDecoration(
                                              hintText: 'Message...',
                                              hintStyle: TextStyle(
                                                color: Theme.of(
                                                  context,
                                                ).colorScheme.onSurfaceVariant,
                                              ),
                                              border: InputBorder.none,
                                              isDense: true,
                                              contentPadding: EdgeInsets.zero,
                                            ),
                                          ),
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.attach_file_rounded,
                                        ),
                                        color: Theme.of(
                                          context,
                                        ).textTheme.bodySmall?.color,
                                        onPressed: _showAttachmentMenu,
                                      ),
                                      if (!_isTyping)
                                        IconButton(
                                          icon: const Icon(
                                            Icons.camera_alt_outlined,
                                          ),
                                          color: Theme.of(
                                            context,
                                          ).textTheme.bodySmall?.color,
                                          onPressed: _openCamera,
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            ),

                            // Recording active bar
                            if (_isRecording)
                              Positioned.fill(
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.surfaceContainerHighest,
                                    borderRadius: BorderRadius.circular(24),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                  ),
                                  child: Row(
                                    children: [
                                      FadeTransition(
                                        opacity: _blinkController,
                                        child: Container(
                                          width: 10,
                                          height: 10,
                                          decoration: BoxDecoration(
                                            color: Theme.of(
                                              context,
                                            ).colorScheme.error,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        '${(_recordingDuration ~/ 60)}:${(_recordingDuration % 60).toString().padLeft(2, '0')}',
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.onSurface,
                                        ),
                                      ),
                                      const Spacer(),
                                      AnimatedOpacity(
                                        opacity: (_dragOffset < -50)
                                            ? 0.0
                                            : 1.0,
                                        duration: const Duration(
                                          milliseconds: 200,
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.chevron_left_rounded,
                                              color: Theme.of(
                                                context,
                                              ).textTheme.bodySmall?.color,
                                              size: 20,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              'Slide to cancel',
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: Theme.of(context)
                                                    .textTheme
                                                    .bodySmall
                                                    ?.color
                                                    ?.withValues(alpha: 0.8),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      // padding on right so the mic icon has space to move
                                      const SizedBox(width: 40),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Mic / Send button
                      if (_isTyping)
                        GestureDetector(
                          onTap: _handleSend,
                          child: Container(
                            height: 48,
                            width: 48,
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.send_rounded,
                              color: Theme.of(context).colorScheme.onPrimary,
                              size: 24,
                            ),
                          ),
                        )
                      else
                        GestureDetector(
                          onLongPressStart: (details) {
                            _startRecording();
                          },
                          onLongPressMoveUpdate: (details) {
                            if (!_isRecording) return;
                            // Track left drag
                            if (details.localOffsetFromOrigin.dx < 0) {
                              setState(() {
                                _dragOffset = details.localOffsetFromOrigin.dx;
                              });

                              // Cancel threshold: -100 pixels
                              if (_dragOffset < -100 && !_isCancelled) {
                                _isCancelled = true;
                                _stopRecording(cancel: true);
                              }
                            }
                          },
                          onLongPressEnd: (details) {
                            if (_isRecording && !_isCancelled) {
                              _stopRecording(cancel: false);
                            }
                          },
                          child: Transform.translate(
                            offset: Offset(_dragOffset, 0),
                            child: ScaleTransition(
                              scale: _micScaleController,
                              child: Container(
                                height: 48,
                                width: 48,
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.primary,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.mic_rounded,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onPrimary,
                                  size: 24,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            SizeTransition(
              sizeFactor: _emojiAnim,
              alignment: Alignment.topCenter,
              child: Container(
                color: Colors.white,
                child: RepaintBoundary(
                  child: SizedBox(
                    height: 250,
                    child: EmojiPicker(
                      textEditingController: _controller,
                      config: Config(
                        bottomActionBarConfig: const BottomActionBarConfig(
                          showBackspaceButton: false,
                          showSearchViewButton: false,
                        ),
                        categoryViewConfig: CategoryViewConfig(
                          backgroundColor: Colors.white,
                          iconColor:
                              Theme.of(context).textTheme.bodySmall?.color ??
                              Theme.of(context).colorScheme.onSurface,
                          iconColorSelected: Theme.of(
                            context,
                          ).colorScheme.primary,
                          indicatorColor: Theme.of(context).colorScheme.primary,
                          dividerColor: Colors.black12,
                        ),
                        emojiViewConfig: EmojiViewConfig(
                          backgroundColor: Colors.white,
                          columns: 7,
                          emojiSizeMax:
                              28 *
                              (foundation.defaultTargetPlatform ==
                                      TargetPlatform.iOS
                                  ? 1.30
                                  : 1.0),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(height: MediaQuery.paddingOf(context).bottom),
          ],
        );
      },
    );
  }
}
