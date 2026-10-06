import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:asmita_society/core/widgets/asmita_bottom_sheet.dart';
import '../../bloc/community_bloc.dart';
import '../../bloc/community_event.dart';
import '../../bloc/community_state.dart';
import 'create_poll_dialog.dart';
import 'contact_picker_bottom_sheet.dart';

class AttachmentBottomSheet extends StatelessWidget {
  const AttachmentBottomSheet({super.key});

  Map<String, String?> _getReplyData(BuildContext context) {
    final state = context.read<CommunityBloc>().state;
    if (state is CommunityLoaded && state.replyingToMessage != null) {
      final replMsg = state.replyingToMessage!;
      final filename = replMsg.content.split('/').last;
      final replyContent = replMsg.type == 'image'
          ? '📷 $filename'
          : replMsg.type == 'audio'
          ? '🎵 $filename'
          : replMsg.type == 'video'
          ? '🎬 $filename'
          : replMsg.type == 'document'
          ? '📄 $filename'
          : replMsg.content;
      return {'id': replMsg.id, 'content': replyContent};
    }
    return {'id': null, 'content': null};
  }

  Future<void> _pickImage(BuildContext context, ImageSource source) async {
    final bloc = context.read<CommunityBloc>();
    final replyData = _getReplyData(context);
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source, imageQuality: 70);

    if (pickedFile != null) {
      bloc.add(
        SendImageMessage(
          pickedFile.path,
          replyToMessageId: replyData['id'],
          replyToContent: replyData['content'],
        ),
      );
      bloc.add(ClearReplyToMessage());
    }
  }

  Future<void> _pickDocument(BuildContext context) async {
    final bloc = context.read<CommunityBloc>();
    final replyData = _getReplyData(context);
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: [
        'pdf',
        'doc',
        'docx',
        'txt',
        'xls',
        'xlsx',
        'ppt',
        'pptx',
        'csv',
      ],
    );

    if (result != null && result.files.single.path != null) {
      final file = result.files.single;
      final fileSize = '${(file.size / 1024 / 1024).toStringAsFixed(2)} MB';
      bloc.add(
        SendDocumentMessage(
          file.path!,
          file.name,
          fileSize,
          replyToMessageId: replyData['id'],
          replyToContent: replyData['content'],
        ),
      );
      bloc.add(ClearReplyToMessage());
    }
  }

  Future<void> _pickAudio(BuildContext context) async {
    final bloc = context.read<CommunityBloc>();
    final replyData = _getReplyData(context);
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.audio,
    );

    if (result != null && result.files.single.path != null) {
      final file = result.files.single;
      bloc.add(
        SendAudioMessage(
          '0:00',
          file.path!,
          replyToMessageId: replyData['id'],
          replyToContent: replyData['content'],
        ),
      );
      bloc.add(ClearReplyToMessage());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      padding: EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildAttachmentIcon(
                context,
                icon: Icons.insert_drive_file_rounded,
                color: Colors.deepPurple,
                label: 'Document',
                onTap: () => _pickDocument(context),
              ),
              _buildAttachmentIcon(
                context,
                icon: Icons.camera_alt_rounded,
                color: Colors.pink,
                label: 'Camera',
                onTap: () => _pickImage(context, ImageSource.camera),
              ),
              _buildAttachmentIcon(
                context,
                icon: Icons.photo_rounded,
                color: Colors.purpleAccent,
                label: 'Gallery',
                onTap: () => _pickImage(context, ImageSource.gallery),
              ),
            ],
          ),
          SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildAttachmentIcon(
                context,
                icon: Icons.headphones_rounded,
                color: Colors.orange,
                label: 'Audio',
                onTap: () => _pickAudio(context),
              ),
              _buildAttachmentIcon(
                context,
                icon: Icons.person_rounded,
                color: Colors.blue,
                label: 'Contact',
                onTap: () {
                  Navigator.pop(context); // Close attachment menu
                  showAsmitaBottomSheet(
                    context: context,
                    title: 'Select Contact',
                    child: const ContactPickerBottomSheet(),
                  );
                },
              ),
              _buildAttachmentIcon(
                context,
                icon: Icons.poll_rounded,
                color: Colors.teal,
                label: 'Poll',
                onTap: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (context) => const CreatePollDialog(),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAttachmentIcon(
    BuildContext context, {
    required IconData icon,
    required Color color,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
        onTap();
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 60,
            width: 60,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            child: Icon(
              icon,
              color: Theme.of(context).colorScheme.surface,
              size: 28,
            ),
          ),
          SizedBox(height: 8),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).textTheme.bodyLarge?.color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
