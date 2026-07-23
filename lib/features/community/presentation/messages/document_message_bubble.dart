import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:asmita_society/core/constants/design_system.dart';
import 'package:asmita_society/core/widgets/asmita_toast.dart';

class DocumentMessageBubble extends StatefulWidget {
  final String content;
  final bool isMe;

  const DocumentMessageBubble({
    super.key,
    required this.content,
    required this.isMe,
  });

  @override
  State<DocumentMessageBubble> createState() => _DocumentMessageBubbleState();
}

class _DocumentMessageBubbleState extends State<DocumentMessageBubble> {
  bool _isDownloading = false;
  @override
  Widget build(BuildContext context) {
    String url = '';
    String fileName = 'Document';
    String fileSize = 'Unknown Size';
    
    if (widget.content.contains('|')) {
      final parts = widget.content.split('|');
      if (parts.isNotEmpty) url = parts[0];
      if (parts.length > 1) fileName = parts[1];
      if (parts.length > 2) fileSize = parts[2];
    } else {
      url = widget.content;
    }

    final ext = fileName.split('.').last.toLowerCase();
    IconData fileIcon = Icons.insert_drive_file_rounded;
    Color iconColor = widget.isMe ? AsmitaPalette.deepNavy : AsmitaPalette.textDark;

    if (['pdf'].contains(ext)) {
      fileIcon = Icons.picture_as_pdf_rounded;
      iconColor = AsmitaPalette.actionRed;
    } else if (['doc', 'docx'].contains(ext)) {
      fileIcon = Icons.description_rounded;
      iconColor = Colors.blueAccent;
    } else if (['xls', 'xlsx'].contains(ext)) {
      fileIcon = Icons.table_chart_rounded;
      iconColor = Colors.green;
    } else if (['png', 'jpg', 'jpeg', 'gif'].contains(ext)) {
      fileIcon = Icons.image_rounded;
      iconColor = Colors.orange;
    } else if (['mp4', 'mov', 'avi'].contains(ext)) {
      fileIcon = Icons.video_file_rounded;
      iconColor = Colors.purple;
    }

    return GestureDetector(
      onTap: () async {
        if (_isDownloading) return;
        
        if (url.startsWith('http')) {
          setState(() => _isDownloading = true);
          try {
            final tempDir = await getTemporaryDirectory();
            final filePath = '${tempDir.path}/$fileName';
            final file = File(filePath);
            
            // If already downloaded, just open it
            if (await file.exists()) {
              final result = await OpenFilex.open(filePath);
              if (result.type != ResultType.done && context.mounted) {
                AsmitaToast.show(context, message: 'No compatible app found to open this file', type: AsmitaToastType.error);
              }
              setState(() => _isDownloading = false);
              return;
            }
            
            // Download the file
            await Dio().download(url, filePath);
            final result = await OpenFilex.open(filePath);
            if (result.type != ResultType.done && context.mounted) {
              AsmitaToast.show(context, message: 'No compatible app found to open this file', type: AsmitaToastType.error);
            }
          } catch (e) {
            if (context.mounted) {
              AsmitaToast.show(context, message: 'Could not download or open document', type: AsmitaToastType.error);
            }
          } finally {
            if (mounted) setState(() => _isDownloading = false);
          }
        } else {
          final result = await OpenFilex.open(url);
          if (result.type != ResultType.done && context.mounted) {
            AsmitaToast.show(context, message: 'No compatible app found to open this file', type: AsmitaToastType.error);
          }
        }
      },
      child: Container(
        width: MediaQuery.sizeOf(context).width * 0.65,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: widget.isMe ? Colors.white.withValues(alpha: 0.5) : AsmitaPalette.borderGrey.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: widget.isMe ? AsmitaPalette.deepNavy.withValues(alpha: 0.2) : AsmitaPalette.borderGrey,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            _isDownloading
                ? SizedBox(
                    width: 32,
                    height: 32,
                    child: CircularProgressIndicator(strokeWidth: 3, color: widget.isMe ? AsmitaPalette.deepNavy : AsmitaPalette.actionRed),
                  )
                : Icon(fileIcon, color: iconColor, size: 32),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    fileName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Montserrat',
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: widget.isMe ? AsmitaPalette.deepNavy : AsmitaPalette.textDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    fileSize,
                    style: TextStyle(
                      fontFamily: 'Montserrat',
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: widget.isMe ? AsmitaPalette.deepNavy.withValues(alpha: 0.7) : AsmitaPalette.textLight,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
