import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:asmita_society/core/constants/design_system.dart';
import '../../data/models/chat_message_model.dart';
import '../messages/message_bubble_factory.dart';
import '../messages/image_grid_bubble.dart';
import '../providers/community_provider.dart';
import '../../bloc/community_state.dart';

class MessageGroup {
  final List<ChatMessageModel> messages;
  final bool isImageGrid;

  MessageGroup(this.messages, {this.isImageGrid = false});
}

class ChatListSliver extends ConsumerWidget {
  final List<ChatMessageModel> messages;
  final bool isLoadingMore;

  const ChatListSliver({
    super.key,
    required this.messages,
    this.isLoadingMore = false,
  });

  List<MessageGroup> _groupMessages(List<ChatMessageModel> rawMessages) {
    if (rawMessages.isEmpty) return [];

    final List<MessageGroup> groups = [];
    List<ChatMessageModel> currentImageGroup = [];

    for (int i = 0; i < rawMessages.length; i++) {
      final msg = rawMessages[i];

      if (msg.type == 'image' && msg.replyToMessageId == null) {
        if (currentImageGroup.isEmpty) {
          currentImageGroup.add(msg);
        } else {
          final lastMsgInGroup = currentImageGroup.last;
          if (msg.sender == lastMsgInGroup.sender &&
              msg.isMe == lastMsgInGroup.isMe) {
            currentImageGroup.add(msg);
          } else {
            groups.add(
              MessageGroup(List.from(currentImageGroup), isImageGrid: true),
            );
            currentImageGroup = [msg];
          }
        }
      } else {
        if (currentImageGroup.isNotEmpty) {
          groups.add(
            MessageGroup(List.from(currentImageGroup), isImageGrid: true),
          );
          currentImageGroup.clear();
        }
        groups.add(MessageGroup([msg], isImageGrid: false));
      }
    }

    if (currentImageGroup.isNotEmpty) {
      groups.add(MessageGroup(currentImageGroup, isImageGrid: true));
    }

    return groups;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(communityProvider);
    final selectedIds = state is CommunityLoaded ? state.selectedMessageIds : <String>{};
    final isSelectionMode = selectedIds.isNotEmpty;

    final groupedMessages = _groupMessages(messages);

    return SliverPadding(
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 20,
      ),
      sliver: SliverList.builder(
        itemCount: groupedMessages.length + (isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == groupedMessages.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: SizedBox(
                  height: 24,
                  width: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AsmitaPalette.deepNavy,
                  ),
                ),
              ),
            );
          }

          final group = groupedMessages[index];
          final msg = group.messages.first;

          final showDateBadge =
              index == groupedMessages.length - 1 ||
              !groupedMessages[index + 1].messages.first.time.startsWith(
                msg.time.split('|')[0],
              );

          Widget bubbleContent;
          if (group.isImageGrid) {
            bubbleContent = ImageGridBubble(
              messages: group.messages,
              isMe: group.messages.first.isMe,
              sender: group.messages.first.sender,
              isSelected: selectedIds.contains(msg.id),
              onLongPress: () {
                ref.read(communityProvider.notifier).toggleSelection(msg.id);
              },
              onTap: isSelectionMode ? () {
                ref.read(communityProvider.notifier).toggleSelection(msg.id);
              } : null,
              onSwipeReply: isSelectionMode ? null : () {
                ref.read(communityProvider.notifier).setReplyTo(msg);
              },
            );
          } else {
            bubbleContent = MessageBubbleFactory(
              messageId: msg.id,
              sender: msg.sender,
              isMe: msg.isMe,
              time: msg.time.contains('|') ? msg.time.split('|')[1] : msg.time,
              type: msg.type,
              content: msg.content,
              replyToMessageId: msg.replyToMessageId,
              replyToContent: msg.replyToContent,
              pollOptions: msg.pollOptions,
              isManagement: msg.sender.toLowerCase().contains('admin') ||
                  msg.sender.toLowerCase().contains('security'),
              isSelected: selectedIds.contains(msg.id),
              onLongPress: () {
                ref.read(communityProvider.notifier).toggleSelection(msg.id);
              },
              onTap: isSelectionMode ? () {
                ref.read(communityProvider.notifier).toggleSelection(msg.id);
              } : null,
              onSwipeReply: isSelectionMode ? null : () {
                ref.read(communityProvider.notifier).setReplyTo(msg);
              },
              onTogglePlayback: () {}, // Handle audio logic later
            );
          }

          return RotatedBox(
            quarterTurns: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (showDateBadge) ...[
                  const SizedBox(height: 16),
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AsmitaPalette.borderGrey,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        msg.time.contains('|') ? msg.time.split('|')[0] : 'Today',
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: AsmitaPalette.textDark,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ] else ...[
                  const SizedBox(height: 12),
                ],
                bubbleContent,
              ],
            ),
          );
        },
      ),
    );
  }
}
