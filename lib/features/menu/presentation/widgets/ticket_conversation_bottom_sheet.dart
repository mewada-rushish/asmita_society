import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../../data/models/support_ticket_model.dart';
import '../../data/models/support_ticket_message_model.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../data/repositories/support_repository.dart';
import 'package:asmita_society/core/di/injection_container.dart' as di;
import 'package:asmita_society/core/utils/date_formatter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:math' as math;

class TicketConversationBottomSheet extends StatefulWidget {
  final SupportTicketModel ticket;

  const TicketConversationBottomSheet({super.key, required this.ticket});

  @override
  State<TicketConversationBottomSheet> createState() => _TicketConversationBottomSheetState();
}

class _TicketConversationBottomSheetState extends State<TicketConversationBottomSheet> {
  final _messageController = TextEditingController();
  bool _isLoading = true;
  bool _isSending = false;
  List<SupportTicketMessageModel> _messages = [];
  String? _error;
  PlatformFile? _selectedAttachment;

  @override
  void initState() {
    super.initState();
    _fetchMessages();
  }

  Future<void> _fetchMessages() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final repo = di.sl<SupportRepository>();
      final rawMessages = await repo.getTicketMessages(widget.ticket.id);
      if (mounted) {
        setState(() {
          _messages = rawMessages.map((e) => SupportTicketMessageModel.fromJson(e)).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  void _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty && _selectedAttachment == null) return;

    setState(() => _isSending = true);
    
    try {
      final repo = di.sl<SupportRepository>();
      final rawMessage = await repo.addTicketMessage(
        widget.ticket.id,
        text,
        attachmentPath: _selectedAttachment?.path,
      );
      
      if (rawMessage != null) {
        final newMessage = SupportTicketMessageModel.fromJson(rawMessage);
        if (mounted) {
          setState(() {
            _messages.add(newMessage);
            _messageController.clear();
            _selectedAttachment = null;
          });
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to send message')));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error sending message')));
      }
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  void _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'mp4', 'mov', 'pdf'],
    );
    if (result != null && mounted) {
      setState(() {
        _selectedAttachment = result.files.single;
      });
    }
  }
  void _openAttachment(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not open attachment')));
      }
    }
  }

  Widget _buildFallbackAttachment(BuildContext context, TextTheme textTheme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.insert_drive_file_rounded, size: 20, color: Theme.of(context).colorScheme.primary),
          ),
          const SizedBox(width: 12),
          Text(
            'View Attachment',
            style: textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.85,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  const SizedBox(height: 16),

          // Average reply time
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.timer_outlined, size: 20, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Average reply time: < 2 hours',
                    style: textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
                  // Messages list
                  Expanded(
                    child: _isLoading 
              ? const Center(child: CircularProgressIndicator())
              : _error != null
                ? Center(child: Text('Error: $_error'))
                : _messages.isEmpty
                  ? Center(
                      child: Text(
                        'No replies yet.',
                        style: textTheme.bodyMedium?.copyWith(color: Colors.grey),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _messages.length,
                      itemBuilder: (context, index) {
                        final msg = _messages[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Theme.of(context).dividerColor, width: 1),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                msg.userName ?? 'Support',
                                style: textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary),
                              ),
                              const SizedBox(height: 4),
                              Builder(
                                builder: (context) {
                                  String msgText = msg.message;
                                  String? attachmentUrl;
                                  final RegExp attachmentRegex = RegExp(r'\[Attachment:\s*(.*?)\]');
                                  final match = attachmentRegex.firstMatch(msgText);
                                  if (match != null) {
                                    attachmentUrl = match.group(1);
                                    msgText = msgText.replaceAll(attachmentRegex, '').trim();
                                  }

                                  final bool isImage = attachmentUrl != null && 
                                    (attachmentUrl.toLowerCase().endsWith('.jpg') || 
                                     attachmentUrl.toLowerCase().endsWith('.jpeg') || 
                                     attachmentUrl.toLowerCase().endsWith('.png'));

                                  return Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      if (msgText.isNotEmpty)
                                        Text(msgText, style: textTheme.bodyMedium),
                                      if (attachmentUrl != null) ...[
                                        if (msgText.isNotEmpty) const SizedBox(height: 8),
                                        GestureDetector(
                                          onTap: () => _openAttachment(attachmentUrl!),
                                          child: isImage
                                            ? ClipRRect(
                                                borderRadius: BorderRadius.circular(8),
                                                child: ConstrainedBox(
                                                  constraints: BoxConstraints(
                                                    maxHeight: 200,
                                                    maxWidth: MediaQuery.of(context).size.width * 0.7,
                                                  ),
                                                  child: CachedNetworkImage(
                                                    imageUrl: attachmentUrl,
                                                    fit: BoxFit.cover,
                                                    errorWidget: (context, error, stackTrace) => _buildFallbackAttachment(context, textTheme),
                                                  ),
                                                ),
                                              )
                                            : _buildFallbackAttachment(context, textTheme),
                                        ),
                                      ],
                                    ],
                                  );
                                },
                              ),
                              if (msg.createdAt != null) ...[
                                const SizedBox(height: 4),
                                Text(
                                  AppDateFormatter.timeAgo(msg.createdAt!),
                                  style: textTheme.bodySmall?.copyWith(color: Colors.grey, fontSize: 10),
                                ),
                              ],
                            ],
                          ),
                        );
                      },
                    ),
          ),
                  // Selected attachment UI
                  if (_selectedAttachment != null)
                    Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.insert_drive_file, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _selectedAttachment!.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, size: 20),
                            onPressed: () => setState(() => _selectedAttachment = null),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
          // Input area
          Container(
            padding: EdgeInsets.fromLTRB(
              16, 
              12, 
              16, 
              12 + math.max(MediaQuery.of(context).viewInsets.bottom, MediaQuery.of(context).padding.bottom)
            ),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).colorScheme.shadow.withValues(alpha: 0.05),
                  offset: const Offset(0, -4),
                  blurRadius: 16,
                ),
              ],
            ),
            child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _messageController,
                  decoration: InputDecoration(
                    hintText: 'Type your reply...',
                    filled: true,
                    fillColor: Theme.of(context).scaffoldBackgroundColor,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide(color: Theme.of(context).dividerColor, width: 1),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide(color: Theme.of(context).dividerColor, width: 1),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 1),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    prefixIcon: IconButton(
                      icon: const Icon(Icons.attach_file, color: Colors.grey),
                      onPressed: _pickFile,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: _isSending ? null : _sendMessage,
                child: CircleAvatar(
                  radius: 24,
                  backgroundColor: _isSending ? Colors.grey : Theme.of(context).colorScheme.primary,
                  child: _isSending 
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.send_rounded, color: Colors.white, size: 20),
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

class TicketConversationHeader extends StatelessWidget {
  final SupportTicketModel ticket;

  const TicketConversationHeader({super.key, required this.ticket});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                ticket.title,
                style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600, fontSize: 18),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: ticket.status.toLowerCase() == 'open'
                    ? Colors.orange.withValues(alpha: 0.1)
                    : Colors.green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                ticket.status,
                style: textTheme.bodySmall?.copyWith(
                  color: ticket.status.toLowerCase() == 'open' ? Colors.orange : Colors.green,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 24), // Spacing for the close button
          ],
        ),
        const SizedBox(height: 8),
        Text(ticket.description, style: textTheme.bodyMedium),
        if (ticket.createdAt != null) ...[
          const SizedBox(height: 8),
          Text(
            'Raised ${AppDateFormatter.timeAgo(ticket.createdAt!)}',
            style: textTheme.bodySmall?.copyWith(color: Colors.grey),
          )
        ],
      ],
    );
  }
}
