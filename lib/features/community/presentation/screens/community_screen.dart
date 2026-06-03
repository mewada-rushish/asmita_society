import 'package:flutter/material.dart';
import 'package:asmita_society/core/constants/design_system.dart';

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  final TextEditingController _chatController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isTyping = false;
  bool _showAttachments = false; 

  @override
  void dispose() {
    _chatController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _toggleAttachments() {
    FocusScope.of(context).unfocus(); 
    setState(() {
      _showAttachments = !_showAttachments;
    });
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AsmitaPalette.systemBG,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        shadowColor: Colors.black.withValues(alpha: 0.05),
        automaticallyImplyLeading: false, // Prevents default back button
        titleSpacing: 16, // Aligns title cleanly to the left edge
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: AsmitaPalette.systemBG,
              child: const Icon(Icons.domain_rounded, color: AsmitaPalette.actionRed, size: 20),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Siddhi CHS 34 Hub', style: textTheme.titleLarge?.copyWith(fontSize: 15, fontWeight: FontWeight.w700)),
                Text('244 Members', style: textTheme.bodyMedium?.copyWith(fontSize: 11, fontWeight: FontWeight.w500)),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(icon: const Icon(Icons.search_rounded, color: AsmitaPalette.deepNavy), onPressed: () {}),
          IconButton(icon: const Icon(Icons.more_vert_rounded, color: AsmitaPalette.deepNavy), onPressed: () {}),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () {
                if (_showAttachments) setState(() => _showAttachments = false);
                FocusScope.of(context).unfocus();
              },
              behavior: HitTestBehavior.opaque,
              child: Stack(
                children: [
                  ListView(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                    children: [
                      _buildDateBadge(context, 'Yesterday'),
                      const SizedBox(height: 16),
                      _buildMessageBubble(
                        context: context,
                        sender: 'Management',
                        isMe: false,
                        time: '10:00 AM',
                        type: 'text',
                        content: 'The AGM is scheduled for this coming Sunday at 10:00 AM in the clubhouse. Attendance is mandatory.',
                        isManagement: true,
                      ),
                      const SizedBox(height: 12),
                      _buildMessageBubble(
                        context: context,
                        sender: 'Amit Khan (B-202)',
                        isMe: false,
                        time: '10:15 AM',
                        type: 'poll',
                        content: 'What should be the timing for the upcoming Diwali event?',
                        pollOptions: {'6:00 PM': 45, '7:30 PM': 80, '8:00 PM': 12},
                      ),
                      const SizedBox(height: 16),
                      _buildDateBadge(context, 'Today'),
                      const SizedBox(height: 16),
                      _buildMessageBubble(
                        context: context,
                        sender: 'You',
                        isMe: true,
                        time: '09:30 AM',
                        type: 'audio',
                        content: '0:14',
                      ),
                      const SizedBox(height: 12),
                      _buildMessageBubble(
                        context: context,
                        sender: 'Kavana (B-105)',
                        isMe: false,
                        time: '09:32 AM',
                        type: 'text',
                        content: 'Noted, we will join by 7:30 PM.',
                      ),
                    ],
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
                      child: _showAttachments ? _buildAttachmentPopup(context) : const SizedBox.shrink(),
                    ),
                  ),
                ],
              ),
            ),
          ),
          _buildChatInputArea(context),
        ],
      ),
    );
  }

  Widget _buildAttachmentPopup(BuildContext context) {
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
          _buildAttachmentIcon(context, Icons.insert_photo_rounded, 'Gallery', Colors.purple),
          _buildAttachmentIcon(context, Icons.poll_rounded, 'Poll', AsmitaPalette.actionRed),
          _buildAttachmentIcon(context, Icons.headset_mic_rounded, 'Audio', Colors.orange),
          _buildAttachmentIcon(context, Icons.description_rounded, 'Document', AsmitaPalette.deepNavy),
        ],
      ),
    );
  }

  Widget _buildAttachmentIcon(BuildContext context, IconData icon, String label, Color color) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          onTap: () {
            setState(() => _showAttachments = false);
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

  Widget _buildChatInputArea(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 12,
        right: 12,
        top: 12,
        bottom: MediaQuery.viewPaddingOf(context).bottom > 0 ? MediaQuery.viewPaddingOf(context).bottom : 20,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AsmitaPalette.borderGrey, width: 1.5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          IconButton(
            icon: Icon(
              _showAttachments ? Icons.cancel_rounded : Icons.add_circle_outline_rounded, 
              color: _showAttachments ? AsmitaPalette.actionRed : AsmitaPalette.textLight, 
              size: 26,
            ),
            onPressed: _toggleAttachments,
          ),
          Expanded(
            child: Container(
              constraints: const BoxConstraints(maxHeight: 120),
              decoration: BoxDecoration(
                color: AsmitaPalette.systemBG,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AsmitaPalette.borderGrey),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
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
                      },
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          CircleAvatar(
            radius: 22,
            backgroundColor: _isTyping ? AsmitaPalette.actionRed : AsmitaPalette.deepNavy,
            child: IconButton(
              icon: Icon(
                _isTyping ? Icons.send_rounded : Icons.mic_none_rounded,
                color: Colors.white,
                size: 20,
              ),
              onPressed: () {
                if (_showAttachments) setState(() => _showAttachments = false);
                
                if (_isTyping) {
                  _chatController.clear();
                  setState(() => _isTyping = false);
                }
              },
            ),
          ),
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
                  if (type == 'audio') _buildAudioPlayer(context, isMe, content),
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

  Widget _buildAudioPlayer(BuildContext context, bool isMe, String duration) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.play_circle_fill_rounded, color: isMe ? Colors.white : AsmitaPalette.actionRed, size: 32),
        const SizedBox(width: 8),
        SizedBox(
          width: 100,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(15, (index) {
              return Container(
                width: 3,
                height: index % 2 == 0 ? 12 : (index % 3 == 0 ? 20 : 8),
                decoration: BoxDecoration(color: isMe ? Colors.white.withValues(alpha: 0.6) : AsmitaPalette.borderGrey, borderRadius: BorderRadius.circular(2)),
              );
            }),
          ),
        ),
        const SizedBox(width: 8),
        Text(duration, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 11, fontWeight: FontWeight.w600, color: isMe ? Colors.white : AsmitaPalette.textDark)),
      ],
    );
  }

  Widget _buildPollWidget(BuildContext context, String question, Map<String, int> options, bool isMe) {
    final textTheme = Theme.of(context).textTheme;
    final totalVotes = options.values.fold(0, (sum, item) => sum + item);

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
                        Text('${(percentage * 100).toInt()}%', style: textTheme.bodyMedium?.copyWith(fontSize: 11, fontWeight: FontWeight.w600, color: isMe ? Colors.white70 : AsmitaPalette.textLight)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}