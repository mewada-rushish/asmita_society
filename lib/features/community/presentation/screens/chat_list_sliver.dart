import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/widgets/asmita_loading_indicator.dart';
import '../../data/models/chat_message_model.dart';
import '../messages/message_bubble_factory.dart';
import '../messages/image_grid_bubble.dart';
import '../../bloc/community_bloc.dart';
import '../../bloc/community_state.dart';
import '../../bloc/community_event.dart';

class MessageGroup {
  final List<ChatMessageModel> messages;
  final bool isImageGrid;

  MessageGroup(this.messages, {this.isImageGrid = false});
}

class ChatListSliver extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return BlocBuilder<CommunityBloc, CommunityState>(
      builder: (context, state) {
        final selectedIds = state is CommunityLoaded ? state.selectedMessageIds : <String>{};
        final isSelectionMode = selectedIds.isNotEmpty;

    final groupedMessages = _groupMessages(messages);

    return SliverPadding(
      padding: EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 20,
      ),
      sliver: SliverList.builder(
        itemCount: groupedMessages.length + (isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == groupedMessages.length) {
            return Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: SizedBox(
                    height: 24,
                    width: 24,
                    child: AsmitaLoadingIndicator(
                      color: Theme.of(context).colorScheme.primary,
                      size: 24,
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
                context.read<CommunityBloc>().add(ToggleMessageSelection(msg.id));
              },
              onTap: isSelectionMode ? () {
                context.read<CommunityBloc>().add(ToggleMessageSelection(msg.id));
              } : null,
              onSwipeReply: isSelectionMode ? null : () {
                context.read<CommunityBloc>().add(SetReplyToMessage(msg));
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
              isFailed: msg.isFailed,
              isSelected: selectedIds.contains(msg.id),
              onLongPress: () {
                context.read<CommunityBloc>().add(ToggleMessageSelection(msg.id));
              },
              onTap: isSelectionMode ? () {
                context.read<CommunityBloc>().add(ToggleMessageSelection(msg.id));
              } : null,
              onSwipeReply: isSelectionMode ? null : () {
                context.read<CommunityBloc>().add(SetReplyToMessage(msg));
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
                  SizedBox(height: 16),
                  Center(
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context).dividerColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        msg.time.contains('|') ? msg.time.split('|')[0] : 'Today',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).textTheme.bodyLarge?.color,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 16),
                ] else ...[
                  SizedBox(height: 12),
                ],
                bubbleContent,
              ],
            ),
          );
        },
      ),
    );
      },
    );
  }
}
