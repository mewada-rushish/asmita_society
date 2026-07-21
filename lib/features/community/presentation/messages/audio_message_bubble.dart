import 'dart:async';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:asmita_society/core/constants/design_system.dart';

class AudioMessageBubble extends StatefulWidget {
  final String content; // URL or local path
  final bool isMe;

  const AudioMessageBubble({
    super.key,
    required this.content,
    required this.isMe,
  });

  @override
  State<AudioMessageBubble> createState() => _AudioMessageBubbleState();
}

class _AudioMessageBubbleState extends State<AudioMessageBubble> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  StreamSubscription? _playerStateSubscription;
  StreamSubscription? _durationSubscription;
  StreamSubscription? _positionSubscription;

  @override
  void initState() {
    super.initState();
    _initAudioPlayer();
  }

  Future<void> _initAudioPlayer() async {
    _playerStateSubscription = _audioPlayer.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() {
          _isPlaying = state == PlayerState.playing;
        });
      }
    });

    _durationSubscription = _audioPlayer.onDurationChanged.listen((newDuration) {
      if (mounted) {
        setState(() {
          _duration = newDuration;
        });
      }
    });

    _positionSubscription = _audioPlayer.onPositionChanged.listen((newPosition) {
      if (mounted) {
        setState(() {
          _position = newPosition;
        });
      }
    });
    
    // Set the source
    try {
      final path = widget.content.split('|').first; // Handle our "path|duration" format if present
      if (path.startsWith('http')) {
        await _audioPlayer.setSourceUrl(path);
      } else {
        await _audioPlayer.setSourceDeviceFile(path);
      }
    } catch (e) {
      debugPrint('Error setting audio source: $e');
    }
  }

  @override
  void dispose() {
    _playerStateSubscription?.cancel();
    _durationSubscription?.cancel();
    _positionSubscription?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _togglePlayback() async {
    if (_isPlaying) {
      await _audioPlayer.pause();
    } else {
      await _audioPlayer.resume();
    }
  }

  @override
  Widget build(BuildContext context) {
    // If the widget content has a predefined duration string like "path|0:05", use it initially
    String displayDuration = '';
    if (_duration.inMilliseconds > 0) {
      displayDuration = '${(_duration.inSeconds ~/ 60)}:${(_duration.inSeconds % 60).toString().padLeft(2, '0')}';
    } else if (widget.content.contains('|')) {
      final parts = widget.content.split('|');
      displayDuration = parts.length > 1 ? parts[1] : '0:00';
    } else {
      displayDuration = '0:00';
    }
    
    // Calculate progress percentage 0 to 100
    int playProgress = 0;
    if (_duration.inMilliseconds > 0) {
      playProgress = (_position.inMilliseconds / _duration.inMilliseconds * 100).toInt();
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          onPressed: _togglePlayback,
          icon: Icon(
            _isPlaying
                ? Icons.pause_circle_filled_rounded
                : Icons.play_circle_fill_rounded,
            color: widget.isMe ? AsmitaPalette.deepNavy : AsmitaPalette.actionRed,
            size: 32,
          ),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 100,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(15, (index) {
              final progressThreshold = (index / 15) * 100;
              final isActive = playProgress > progressThreshold;
              
              return Container(
                width: 3,
                height: index % 2 == 0 ? 12 : (index % 3 == 0 ? 20 : 8),
                decoration: BoxDecoration(
                  color: isActive
                      ? (widget.isMe ? AsmitaPalette.deepNavy : AsmitaPalette.actionRed)
                      : (widget.isMe
                          ? AsmitaPalette.deepNavy.withValues(alpha: 0.3)
                          : AsmitaPalette.borderGrey),
                  borderRadius: BorderRadius.circular(2),
                ),
              );
            }),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          displayDuration,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: widget.isMe ? AsmitaPalette.deepNavy : AsmitaPalette.textDark,
          ),
        ),
      ],
    );
  }
}
