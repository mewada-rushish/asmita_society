import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/security/secure_storage_service.dart';

import '../../bloc/community_bloc.dart';
import '../../bloc/community_state.dart';
import '../../bloc/community_event.dart';
import '../screens/full_screen_image_viewer.dart';

class ImageMessageBubble extends StatelessWidget {
  final String imagePath;
  final String messageId;

  const ImageMessageBubble({
    super.key,
    required this.imagePath,
    required this.messageId,
  });

  @override
  Widget build(BuildContext context) {
    Widget imageWidget;
    Widget placeholder = Container(
      color: Colors.grey.shade100,
      height: 120,
      alignment: Alignment.center,
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.broken_image_rounded, color: Colors.grey),
          SizedBox(width: 8),
          Text(
            'Image not found',
            style: TextStyle(
              fontFamily: 'Poppins',
              color: Colors.grey,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );

    if (imagePath.startsWith('http')) {
      imageWidget = FutureBuilder<String?>(
        future: sl<SecureStorageService>().getToken(),
        builder: (context, snapshot) {
          return CachedNetworkImage(
            imageUrl: imagePath,
            httpHeaders: snapshot.hasData ? {'Authorization': 'Bearer ${snapshot.data}'} : null,
            fit: BoxFit.cover,
            placeholder: (context, url) =>
                Container(color: Colors.grey.shade100, height: 120),
            errorWidget: (context, url, error) => placeholder,
          );
        }
      );
    } else {
      final file = File(imagePath);
      if (file.existsSync()) {
        imageWidget = Image.file(
          file,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => placeholder,
        );
      } else {
        imageWidget = placeholder;
      }
    }

    return GestureDetector(
      onTap: () {
        final state = context.read<CommunityBloc>().state;
        if (state is CommunityLoaded) {
          final imageMessages = state.messages
              .where((m) => m.type == 'image')
              .toList()
              .reversed
              .toList();
          final index = imageMessages.indexWhere((m) => m.id == messageId);
          if (index != -1) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => FullScreenImageViewer(
                  imageMessages: imageMessages,
                  initialIndex: index,
                  onReply: (message) {
                    context.read<CommunityBloc>().add(SetReplyToMessage(message));
                  },
                ),
              ),
            );
          }
        }
      },
      child: Container(
        constraints: const BoxConstraints(maxHeight: 180),
        margin: EdgeInsets.only(bottom: 4),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Hero(tag: 'chat_image_$messageId', child: imageWidget),
        ),
      ),
    );
  }
}
