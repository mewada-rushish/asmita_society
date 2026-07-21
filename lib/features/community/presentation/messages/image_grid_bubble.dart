import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../data/models/chat_message_model.dart';
import '../providers/community_provider.dart';
import '../screens/full_screen_image_viewer.dart';
import '../widgets/swipe_to_reply.dart';

class ImageGridBubble extends ConsumerWidget {
  final List<ChatMessageModel> messages;
  final bool isMe;
  final String sender;
  final bool isSelected;
  final VoidCallback? onLongPress;
  final VoidCallback? onTap;
  final VoidCallback? onSwipeReply;

  const ImageGridBubble({
    super.key,
    required this.messages,
    required this.isMe,
    required this.sender,
    this.isSelected = false,
    this.onLongPress,
    this.onTap,
    this.onSwipeReply,
  });

  void _openSlideshow(BuildContext context, WidgetRef ref, int initialIndex) {
    // We reverse the messages so they appear oldest to newest in the slideshow
    final chronologicalMessages = messages.reversed.toList();
    // Since we reversed, we need to adjust the initial index
    final adjustedIndex = messages.length - 1 - initialIndex;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FullScreenImageViewer(
          imageMessages: chronologicalMessages,
          initialIndex: adjustedIndex,
          onReply: (message) {
            ref.read(communityProvider.notifier).setReplyTo(message);
          },
        ),
      ),
    );
  }

  Widget _buildImageItem(
    BuildContext context,
    WidgetRef ref,
    ChatMessageModel msg,
    int index,
    int count,
  ) {
    Widget imageWidget;
    Widget placeholder = Container(
      color: Colors.grey.shade200,
      child: const Icon(Icons.broken_image, color: Colors.grey),
    );

    if (msg.content.startsWith('http')) {
      imageWidget = CachedNetworkImage(
        imageUrl: msg.content,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        placeholder: (context, url) => Container(color: Colors.grey.shade200),
        errorWidget: (context, url, error) => placeholder,
      );
    } else {
      final file = File(msg.content);
      if (file.existsSync()) {
        imageWidget = Image.file(
          file,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          errorBuilder: (context, error, stackTrace) => placeholder,
        );
      } else {
        imageWidget = placeholder;
      }
    }

    if (index == 3 && count > 4) {
      return GestureDetector(
        onTap: () => _openSlideshow(context, ref, messages.length - 1 - index),
        child: Stack(
          fit: StackFit.expand,
          children: [
            imageWidget,
            Container(
              color: Colors.black54,
              alignment: Alignment.center,
              child: Text(
                '+${count - 4}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return GestureDetector(
      onLongPress: onLongPress,
      onTap:
          onTap ??
          () => _openSlideshow(context, ref, messages.length - 1 - index),
      child: imageWidget,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chronoMessages = messages.reversed.toList();
    final int count = chronoMessages.length;

    // Explicit fixed width so IntrinsicWidth works perfectly without throwing hasSize assertion
    final double gridWidth = count == 1 ? 220 : 260;
    final double gridHeight = count <= 2 ? 180 : 260;

    return SwipeToReply(
      isMe: isMe,
      onSwipeReply: () {
        if (onSwipeReply != null) onSwipeReply!();
      },
      child: GestureDetector(
        onLongPress: onLongPress,
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          color: isSelected
              ? const Color(0xFF142E5C).withValues(alpha: 0.1)
              : Colors.transparent, // AsmitaPalette.primary
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Align(
            alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(
              width: gridWidth + 8, // add padding space
              height: count == 1 ? gridHeight + 8 : null,
              margin: const EdgeInsets.only(bottom: 4),
              padding: const EdgeInsets.all(4), // inner padding around images
              decoration: BoxDecoration(
                color: isMe ? const Color(0xFFE6EEFA) : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isMe ? 16 : 4),
                  bottomRight: Radius.circular(isMe ? 4 : 16),
                ),
                border: Border.all(
                  color: isMe
                      ? const Color(0xFF142E5C).withValues(
                          alpha: 0.15,
                        ) // AsmitaPalette.deepNavy
                      : const Color(0xFFE0E0E0), // AsmitaPalette.borderGrey
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: _buildGrid(
                  context,
                  ref,
                  chronoMessages,
                  count,
                  gridHeight,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGrid(
    BuildContext context,
    WidgetRef ref,
    List<ChatMessageModel> chronoMessages,
    int count,
    double totalHeight,
  ) {
    if (count == 1) {
      return _buildImageItem(context, ref, chronoMessages[0], 0, count);
    }

    if (count == 2) {
      return SizedBox(
        height: 130, // half height roughly
        child: Row(
          children: [
            Expanded(
              child: _buildImageItem(context, ref, chronoMessages[0], 0, count),
            ),
            const SizedBox(width: 2),
            Expanded(
              child: _buildImageItem(context, ref, chronoMessages[1], 1, count),
            ),
          ],
        ),
      );
    }

    if (count == 3) {
      return SizedBox(
        height: totalHeight,
        child: Column(
          children: [
            Expanded(
              child: Row(
                children: [
                  Expanded(
                    child: _buildImageItem(
                      context,
                      ref,
                      chronoMessages[0],
                      0,
                      count,
                    ),
                  ),
                  const SizedBox(width: 2),
                  Expanded(
                    child: _buildImageItem(
                      context,
                      ref,
                      chronoMessages[1],
                      1,
                      count,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 2),
            Expanded(
              child: _buildImageItem(
                context,
                ref,
                chronoMessages[2],
                2,
                count,
              ), // Full width bottom
            ),
          ],
        ),
      );
    }

    // 4 or more
    return SizedBox(
      height: totalHeight,
      child: Column(
        children: [
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: _buildImageItem(
                    context,
                    ref,
                    chronoMessages[0],
                    0,
                    count,
                  ),
                ),
                const SizedBox(width: 2),
                Expanded(
                  child: _buildImageItem(
                    context,
                    ref,
                    chronoMessages[1],
                    1,
                    count,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 2),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: _buildImageItem(
                    context,
                    ref,
                    chronoMessages[2],
                    2,
                    count,
                  ),
                ),
                const SizedBox(width: 2),
                Expanded(
                  child: _buildImageItem(
                    context,
                    ref,
                    chronoMessages[3],
                    3,
                    count,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
