
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:asmita_society/core/widgets/asmita_toast.dart';
import 'package:asmita_society/features/community/bloc/community_bloc.dart';
import 'package:asmita_society/features/community/bloc/community_event.dart';

class PollMessageBubble extends StatelessWidget {
  final String messageId;
  final String question;
  final Map<String, int> options;
  final List<String> votedOptions;
  final bool isMe;

  const PollMessageBubble({
    super.key,
    required this.messageId,
    required this.question,
    required this.options,
    this.votedOptions = const [],
    required this.isMe,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    final totalVotes = options.values.fold(0, (sum, item) => sum + item);

    return SizedBox(
      width: MediaQuery.sizeOf(context).width * 0.65,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.poll_rounded,
                color: Theme.of(context).colorScheme.primary,
                size: 16,
              ),
              SizedBox(width: 6),
              Text(
                'POLL',
                style: textTheme.bodyLarge?.copyWith(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            question,
            style: textTheme.titleLarge?.copyWith(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ),
          ),
          SizedBox(height: 12),
          ...options.entries.map((entry) {
            final isVoted = votedOptions.contains(entry.key);
            final percentage = totalVotes == 0
                ? 0.0
                : (entry.value / totalVotes);
            return Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: InkWell(
                onTap: () {
                  context.read<CommunityBloc>().add(VoteOnPollMessage(messageId: messageId, option: entry.key));
                  AsmitaToast.show(
                    context,
                    message: 'Vote casted for "${entry.key}"!',
                    type: AsmitaToastType.success,
                  );
                },
                borderRadius: BorderRadius.circular(8),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          color: isMe ? Theme.of(context).colorScheme.surface : Theme.of(context).scaffoldBackgroundColor,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isVoted ? Theme.of(context).colorScheme.primary : (isMe ? Colors.transparent : Theme.of(context).dividerColor),
                            width: isVoted ? 1.5 : 1.0,
                          ),
                        ),
                      ),
                    ),
                    Positioned.fill(
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: percentage,
                        child: Container(
                          decoration: BoxDecoration(
                            color: isVoted ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.3) : Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    Container(
                      height: 32,
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            entry.key,
                            style: textTheme.bodyLarge?.copyWith(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).textTheme.bodyLarge?.color,
                            ),
                          ),
                          Text(
                            '${(percentage * 100).toInt()}% (${entry.value})',
                            style: textTheme.bodyMedium?.copyWith(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).textTheme.bodyMedium?.color,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
