import 'package:flutter/material.dart';
import 'package:asmita_society/core/widgets/asmita_loading_indicator.dart';
import 'package:asmita_society/features/community/data/models/chat_message_model.dart';
import '../widgets/swipe_to_reply.dart';
import 'text_message_bubble.dart';
import 'image_message_bubble.dart';
import 'audio_message_bubble.dart';
import 'document_message_bubble.dart';
import 'poll_message_bubble.dart';
import 'video_message_bubble.dart';
import 'contact_message_bubble.dart';

class MessageBubbleFactory extends StatelessWidget {
  final String messageId;
  final String sender;
  final bool isMe;
  final String time;
  final String type;
  final String content;
  final String? replyToMessageId;
  final String? replyToContent;
  final String? replyToSenderName;
  final Map<String, int>? pollOptions;
  final List<String> votedOptions;
  final bool isManagement;
  final VoidCallback? onSwipeReply;
  final bool isSelected;
  final VoidCallback? onLongPress;
  final VoidCallback? onTap;
  final bool isFailed;

  // Audio specific
  final bool isPlaying;
  final int playProgress;
  final VoidCallback onTogglePlayback;

  const MessageBubbleFactory({
    super.key,
    required this.messageId,
    required this.sender,
    required this.isMe,
    required this.time,
    required this.type,
    required this.content,
    this.replyToMessageId,
    this.replyToContent,
    this.replyToSenderName,
    this.pollOptions,
    this.votedOptions = const [],
    this.isManagement = false,
    this.onSwipeReply,
    this.isSelected = false,
    this.onLongPress,
    this.onTap,
    this.isFailed = false,
    this.isPlaying = false,
    this.playProgress = 0,
    required this.onTogglePlayback,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

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
              ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.1)
              : Colors.transparent,
          padding: EdgeInsets.symmetric(vertical: 2),
          child: Align(
            alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.sizeOf(context).width * 0.75,
              ),
              child: Column(
                crossAxisAlignment: isMe
                    ? CrossAxisAlignment.end
                    : CrossAxisAlignment.start,
                children: [
                  if (!isMe)
                    Padding(
                      padding: EdgeInsets.only(left: 4, bottom: 4),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            sender,
                            style: textTheme.bodyLarge?.copyWith(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: isManagement
                                  ? Theme.of(context).colorScheme.primary
                                  : Theme.of(context).colorScheme.primary,
                            ),
                          ),
                          if (isManagement) ...[
                            SizedBox(width: 4),
                            Icon(
                              Icons.verified_rounded,
                              color: Theme.of(context).colorScheme.primary,
                              size: 12,
                            ),
                          ],
                        ],
                      ),
                    ),
                  Container(
                    decoration: BoxDecoration(
                      color: isMe 
                          ? (Theme.of(context).brightness == Brightness.dark
                              ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.2)
                              : const Color(0xFFE6EEFA))
                          : Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(16),
                        topRight: const Radius.circular(16),
                        bottomLeft: Radius.circular(isMe ? 16 : 4),
                        bottomRight: Radius.circular(isMe ? 4 : 16),
                      ),
                      border: Border.all(
                        color: isMe
                            ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.15)
                            : Theme.of(context).dividerColor,
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.02),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    padding: EdgeInsets.all(12),
                    child: IntrinsicWidth(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (replyToContent != null)
                            Padding(
                              padding: EdgeInsets.only(bottom: 8),
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1),
                                    width: 0.5,
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      replyToSenderName ?? 'Message',
                                      style: textTheme.bodySmall?.copyWith(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        color: Theme.of(context).colorScheme.primary,
                                      ),
                                    ),
                                    SizedBox(height: 2),
                                    Text(
                                      replyToContent!,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: textTheme.bodySmall?.copyWith(
                                        color: Theme.of(context).textTheme.bodyLarge?.color,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          if (type == 'text')
                            TextMessageBubble(content: content),
                          if (type == 'image')
                            ImageMessageBubble(
                              imagePath: content,
                              messageId: messageId,
                            ),
                          if (type == 'audio')
                            AudioMessageBubble(
                              content: content,
                              isMe: isMe,
                            ),
                          if (type == 'video')
                            VideoMessageBubble(content: content, isMe: isMe),
                          if (type == 'document')
                            DocumentMessageBubble(content: content, isMe: isMe),
                          if (type == 'contact')
                            ContactMessageBubble(
                              message: ChatMessageModel.createMessage(
                                id: messageId,
                                sender: sender,
                                isMe: isMe,
                                time: time,
                                type: type,
                                content: content,
                              ),
                              onReply: () => onSwipeReply?.call(),
                              onStar: () {},
                              onPin: () {},
                            ),
                          if (type == 'poll' && pollOptions != null)
                            PollMessageBubble(
                              messageId: messageId,
                              question: content,
                              options: pollOptions!,
                              votedOptions: votedOptions,
                              isMe: isMe,
                            ),
                          SizedBox(height: 6),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              if (isFailed)
                                Text(
                                  'Failed to send - Tap to retry ',
                                  style: textTheme.bodyMedium?.copyWith(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w600,
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                                ),
                              Text(
                                time,
                                style: textTheme.bodyMedium?.copyWith(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w600,
                                  color: Theme.of(context).textTheme.bodyMedium?.color,
                                ),
                              ),
                              if (isMe) ...[
                                SizedBox(width: 4),
                                if (isFailed)
                                  Icon(
                                    Icons.error_outline_rounded,
                                    color: Theme.of(context).colorScheme.primary,
                                    size: 12,
                                  )
                                else if (messageId.startsWith('temp_'))
                                  SizedBox(
                                    height: 12,
                                    width: 12,
                                    child: AsmitaLoadingIndicator(
                                        color: Theme.of(context).colorScheme.primary,
                                        size: 12,
                                    ),
                                  )
                                else
                                  Icon(
                                    Icons.done_all_rounded,
                                    color: Theme.of(context).colorScheme.primary,
                                    size: 12,
                                  ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
