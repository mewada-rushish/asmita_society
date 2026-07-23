import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:asmita_society/core/constants/design_system.dart';
import 'package:asmita_society/core/widgets/asmita_bottom_sheet.dart';
import '../providers/community_provider.dart';
import 'create_poll_dialog.dart';
import 'contact_picker_bottom_sheet.dart';

class AttachmentBottomSheet extends ConsumerWidget {
  const AttachmentBottomSheet({super.key});

  Future<void> _pickImage(WidgetRef ref, ImageSource source) async {
    final notifier = ref.read(communityProvider.notifier);
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source, imageQuality: 70);
    
    if (pickedFile != null) {
      notifier.sendImageMessage(pickedFile.path);
    }
  }

  Future<void> _pickDocument(WidgetRef ref) async {
    final notifier = ref.read(communityProvider.notifier);
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx', 'txt', 'xls', 'xlsx', 'ppt', 'pptx', 'csv'],
    );

    if (result != null && result.files.single.path != null) {
      final file = result.files.single;
      final fileSize = '${(file.size / 1024 / 1024).toStringAsFixed(2)} MB';
      notifier.sendDocumentMessage(
        file.path!,
        file.name,
        fileSize,
      );
    }
  }

  Future<void> _pickAudio(WidgetRef ref) async {
    final notifier = ref.read(communityProvider.notifier);
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.audio,
    );

    if (result != null && result.files.single.path != null) {
      final file = result.files.single;
      notifier.sendAudioMessage(
        file.path!,
        '0:00', // Mock duration
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
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
                onTap: () => _pickDocument(ref),
              ),
              _buildAttachmentIcon(
                context,
                icon: Icons.camera_alt_rounded,
                color: Colors.pink,
                label: 'Camera',
                onTap: () => _pickImage(ref, ImageSource.camera),
              ),
              _buildAttachmentIcon(
                context,
                icon: Icons.photo_rounded,
                color: Colors.purpleAccent,
                label: 'Gallery',
                onTap: () => _pickImage(ref, ImageSource.gallery),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildAttachmentIcon(
                context,
                icon: Icons.headphones_rounded,
                color: Colors.orange,
                label: 'Audio',
                onTap: () => _pickAudio(ref),
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
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AsmitaPalette.textDark,
                  fontWeight: FontWeight.w500,
                ),
          ),
        ],
      ),
    );
  }
}
