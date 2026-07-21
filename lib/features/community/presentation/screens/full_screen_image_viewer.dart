import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:asmita_society/features/community/data/models/chat_message_model.dart';
import 'package:gal/gal.dart';
import 'package:dio/dio.dart';

class FullScreenImageViewer extends StatefulWidget {
  final List<ChatMessageModel> imageMessages;
  final int initialIndex;
  final void Function(String messageId)? onShowInChat;
  final void Function(String messageId)? onDelete;
  final void Function(ChatMessageModel message)? onReply;

  const FullScreenImageViewer({
    super.key,
    required this.imageMessages,
    this.initialIndex = 0,
    this.onShowInChat,
    this.onDelete,
    this.onReply,
  });

  @override
  State<FullScreenImageViewer> createState() => _FullScreenImageViewerState();
}

class _FullScreenImageViewerState extends State<FullScreenImageViewer> {
  late PageController _pageController;
  late int _currentIndex;
  late ScrollController _thumbnailScrollController;
  bool _isDownloading = false;
  final Set<String> _selectedImageIds = {};

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
    _thumbnailScrollController = ScrollController();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToThumbnail(_currentIndex);
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _thumbnailScrollController.dispose();
    super.dispose();
  }

  void _scrollToThumbnail(int index) {
    if (_thumbnailScrollController.hasClients) {
      final double targetOffset =
          (index * 68.0) - (MediaQuery.of(context).size.width / 2) + 34.0;
      _thumbnailScrollController.animateTo(
        targetOffset.clamp(
          0.0,
          _thumbnailScrollController.position.maxScrollExtent,
        ),
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _downloadImages(List<String> paths) async {
    setState(() {
      _isDownloading = true;
    });
    try {
      final hasAccess = await Gal.hasAccess(toAlbum: true);
      if (!hasAccess) {
        await Gal.requestAccess(toAlbum: true);
      }

      for (final path in paths) {
        if (path.startsWith('http')) {
          final tempDir = Directory.systemTemp;
          final savePath =
              '${tempDir.path}/downloaded_image_${DateTime.now().microsecondsSinceEpoch}.jpg';
          await Dio().download(path, savePath);
          await Gal.putImage(savePath);
        } else {
          await Gal.putImage(path);
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${paths.length} image(s) saved to gallery!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to save images: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isDownloading = false;
          _selectedImageIds.clear();
        });
      }
    }
  }

  Widget _buildFloatingAction({
    required IconData icon,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDestructive
              ? Colors.redAccent.withValues(alpha: 0.1)
              : const Color(0xFF142E5C).withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          size: 20,
          color: isDestructive ? Colors.redAccent : const Color(0xFF142E5C),
        ),
      ),
    );
  }

  Widget _buildSelectionBar() {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 60,
      left: 0,
      right: 0,
      child: SafeArea(
        child: Center(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            switchInCurve: Curves.easeOutBack,
            switchOutCurve: Curves.easeInCubic,
            transitionBuilder: (child, animation) {
              return SizeTransition(
                sizeFactor: animation,
                alignment: Alignment.bottomCenter,
                child: FadeTransition(opacity: animation, child: child),
              );
            },
            child: _selectedImageIds.isNotEmpty
                ? Padding(
                    key: const ValueKey('selection_bar'),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Circular Number Badge
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: const Color(0xFF142E5C),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            '${_selectedImageIds.length}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                              fontFamily: 'Poppins',
                            ),
                          ),
                        ),
                        const SizedBox(width: 8), // Tiny space between them
                        
                        // Actions Pill
                        Container(
                          padding: const EdgeInsets.all(4), // Equal padding
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(30),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _buildFloatingAction(
                                icon: Icons.close_rounded,
                                onTap: () {
                                  setState(() {
                                    _selectedImageIds.clear();
                                  });
                                },
                              ),
                              if (_isDownloading)
                                const Padding(
                                  padding: EdgeInsets.all(12.0),
                                  child: SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Color(0xFF142E5C),
                                    ),
                                  ),
                                )
                              else
                                _buildFloatingAction(
                                  icon: Icons.download_rounded,
                                  onTap: () {
                                    final selectedPaths = widget.imageMessages
                                        .where((msg) => _selectedImageIds.contains(msg.id))
                                        .map((msg) => msg.content)
                                        .toList();
                                    _downloadImages(selectedPaths);
                                  },
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  )
                : const SizedBox.shrink(key: ValueKey('empty_selection_bar')),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.imageMessages.isEmpty) return const SizedBox.shrink();

    final currentMessage = widget.imageMessages[_currentIndex];

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black.withValues(alpha: 0.5),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          '${_currentIndex + 1} / ${widget.imageMessages.length}',
          style: const TextStyle(color: Colors.white, fontSize: 16),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.chat_bubble_outline),
            tooltip: 'Show in Chat',
            onPressed: () {
              Navigator.pop(context);
              if (widget.onShowInChat != null) {
                widget.onShowInChat!(currentMessage.id);
              }
            },
          ),
          if (widget.onReply != null)
            IconButton(
              icon: const Icon(Icons.reply_rounded),
              tooltip: 'Reply',
              onPressed: () {
                Navigator.pop(context);
                widget.onReply!(currentMessage);
              },
            ),
          if (_isDownloading && _selectedImageIds.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              ),
            )
          else if (_selectedImageIds.isEmpty)
            IconButton(
              icon: const Icon(Icons.download),
              tooltip: 'Download',
              onPressed: () => _downloadImages([currentMessage.content]),
            ),
          if (currentMessage.isMe && widget.onDelete != null)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
              tooltip: 'Delete Message',
              onPressed: () {
                Navigator.pop(context);
                widget.onDelete!(currentMessage.id);
              },
            ),
        ],
      ),
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: widget.imageMessages.length,
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
              });
              _scrollToThumbnail(index);
            },
            itemBuilder: (context, index) {
              final msg = widget.imageMessages[index];
              final imagePath = msg.content;
              final heroTag = 'chat_image_${msg.id}';
              final isNetwork = imagePath.startsWith('http');
              final file = isNetwork ? null : File(imagePath);

              return InteractiveViewer(
                panEnabled: true,
                minScale: 0.5,
                maxScale: 4.0,
                child: Center(
                  child: Hero(
                    tag: heroTag,
                    child: isNetwork
                        ? CachedNetworkImage(
                            imageUrl: imagePath,
                            fit: BoxFit.contain,
                            placeholder: (context, url) => const Center(
                              child: CircularProgressIndicator(
                                color: Colors.white,
                              ),
                            ),
                            errorWidget: (context, url, error) => const Center(
                              child: Icon(
                                Icons.broken_image_rounded,
                                color: Colors.white,
                                size: 50,
                              ),
                            ),
                          )
                        : Image.file(file!, fit: BoxFit.contain),
                  ),
                ),
              );
            },
          ),

          _buildSelectionBar(),

          // Thumbnail bottom bar
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 100,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.8),
                    Colors.transparent,
                  ],
                ),
              ),
              child: SafeArea(
                child: ListView.builder(
                  controller: _thumbnailScrollController,
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  itemCount: widget.imageMessages.length,
                  itemBuilder: (context, index) {
                    final msg = widget.imageMessages[index];
                    final imagePath = msg.content;
                    final isNetwork = imagePath.startsWith('http');
                    final isSelected = index == _currentIndex;
                    final isMultiSelected = _selectedImageIds.contains(msg.id);

                    return GestureDetector(
                      onTap: () {
                        if (_selectedImageIds.isNotEmpty) {
                          setState(() {
                            if (isMultiSelected) {
                              _selectedImageIds.remove(msg.id);
                            } else {
                              _selectedImageIds.add(msg.id);
                            }
                          });
                        } else {
                          _pageController.animateToPage(
                            index,
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        }
                      },
                      onLongPress: () {
                        setState(() {
                          _selectedImageIds.add(msg.id);
                        });
                      },
                      child: Stack(
                        children: [
                          Container(
                            width: 60,
                            margin: const EdgeInsets.only(right: 8),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: isSelected && _selectedImageIds.isEmpty
                                    ? Colors.redAccent
                                    : Colors.transparent,
                                width: 2,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: isNetwork
                                  ? CachedNetworkImage(
                                      imageUrl: imagePath,
                                      fit: BoxFit.cover,
                                    )
                                  : Image.file(
                                      File(imagePath),
                                      fit: BoxFit.cover,
                                    ),
                            ),
                          ),
                          if (isMultiSelected)
                            Positioned(
                              top: 4,
                              right: 12,
                              child: Container(
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.check_circle,
                                  color: Colors.blueAccent,
                                  size: 20,
                                ),
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
