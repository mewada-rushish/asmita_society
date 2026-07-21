import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:asmita_society/core/constants/design_system.dart';
import 'package:asmita_society/core/widgets/asmita_primary_header.dart';
import 'package:asmita_society/features/auth/bloc/auth_bloc.dart';
import 'package:asmita_society/features/auth/bloc/auth_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart' as bloc;

import '../../bloc/community_state.dart';
import '../providers/community_provider.dart';
import 'chat_list_sliver.dart';
import '../composer/chat_composer.dart';

class CommunityScreen extends ConsumerStatefulWidget {
  final VoidCallback? onNavigateToSearch;
  final VoidCallback? onNavigateToCommunity;

  const CommunityScreen({
    super.key,
    this.onNavigateToSearch,
    this.onNavigateToCommunity,
  });

  @override
  ConsumerState<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends ConsumerState<CommunityScreen> {
  final ScrollController _scrollController = ScrollController();
  Timer? _pollingTimer;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authState = context.read<AuthBloc>().state;
      int? userId;
      String? userName;
      if (authState is AuthAuthenticated) {
        userId = authState.user.userId;
        userName = authState.user.fullName;
      }
      ref
          .read(communityProvider.notifier)
          .loadMessages(currentUserId: userId, currentUserName: userName);
    });

    _pollingTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (!mounted) return;

      bool isAtBottom = true;
      if (_scrollController.hasClients) {
        // minScrollExtent (0) is the BOTTOM of the physical screen
        isAtBottom =
            (_scrollController.position.pixels <=
            _scrollController.position.minScrollExtent + 150);
      }

      if (isAtBottom) {
        ref.read(communityProvider.notifier).pollNewMessages();
      }
    });
  }

  void _onScroll() {
    if (_scrollController.hasClients) {
      // maxScrollExtent is the TOP of the physical screen (oldest messages)
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 100) {
        final state = ref.read(communityProvider);
        if (state is CommunityLoaded &&
            !state.hasReachedMax &&
            !state.isLoadingMore) {
          ref.read(communityProvider.notifier).loadMoreMessages();
        }
      }
    }
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  PreferredSizeWidget _buildAppBar(CommunityState state) {
    return const PreferredSize(
      preferredSize: Size.fromHeight(70),
      child: AsmitaPrimaryHeader(title: 'Community Chat'),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(communityProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F8FB),
      appBar: _buildAppBar(state),
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                Expanded(
                  child: RotatedBox(
                    quarterTurns: 2,
                    child: CustomScrollView(
                      controller: _scrollController,
                      physics: const BouncingScrollPhysics(
                        parent: AlwaysScrollableScrollPhysics(),
                      ),
                      slivers: [
                        if (state is CommunityLoaded)
                          ChatListSliver(
                            messages: state.messages,
                            isLoadingMore: state.isLoadingMore,
                          )
                        else if (state is CommunityLoading ||
                            state is CommunityInitial)
                          const SliverFillRemaining(
                            hasScrollBody: false,
                            child: Center(
                              child: CircularProgressIndicator(
                                color: AsmitaPalette.deepNavy,
                              ),
                            ),
                          )
                        else if (state is CommunityError)
                          SliverFillRemaining(
                            child: RotatedBox(
                              quarterTurns: 2,
                              child: Center(
                                child: Text(
                                  state.error,
                                  style: const TextStyle(
                                    color: AsmitaPalette.actionRed,
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                AnimatedSwitcher(
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
                  child:
                      (state is CommunityLoaded &&
                          state.selectedMessageIds.isNotEmpty)
                      ? Padding(
                          key: const ValueKey('selection_bar'),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Circular Number Badge
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: AsmitaPalette.deepNavy,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: 0.1,
                                      ),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  '${state.selectedMessageIds.length}',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                    fontFamily: 'Poppins',
                                  ),
                                ),
                              ),
                              const SizedBox(
                                width: 8,
                              ), // Tiny space between them
                              // Actions Pill
                              Container(
                                padding: const EdgeInsets.all(
                                  4,
                                ), // Equal padding for perfectly matching circular edges
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(30),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: 0.1,
                                      ),
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
                                        ref
                                            .read(communityProvider.notifier)
                                            .clearSelection();
                                      },
                                    ),
                                    if (state.selectedMessageIds.length ==
                                        1) ...[
                                      const SizedBox(width: 4),
                                      _buildFloatingAction(
                                        icon: Icons.reply_rounded,
                                        onTap: () {
                                          final msgId =
                                              state.selectedMessageIds.first;
                                          final msg = state.messages.firstWhere(
                                            (m) => m.id == msgId,
                                          );
                                          ref
                                              .read(communityProvider.notifier)
                                              .setReplyTo(msg);
                                          ref
                                              .read(communityProvider.notifier)
                                              .clearSelection();
                                        },
                                      ),
                                    ],
                                    const SizedBox(width: 4),
                                    _buildFloatingAction(
                                      icon: Icons.copy_rounded,
                                      onTap: () {
                                        ref
                                            .read(communityProvider.notifier)
                                            .clearSelection();
                                      },
                                    ),
                                    const SizedBox(width: 4),
                                    _buildFloatingAction(
                                      icon: Icons.delete_outline_rounded,
                                      onTap: () {
                                        ref
                                            .read(communityProvider.notifier)
                                            .deleteSelectedMessages();
                                      },
                                      isDestructive: true,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
                const ChatComposer(),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingAction({
    required IconData icon,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    final bgColor = isDestructive
        ? AsmitaPalette.actionRed.withValues(alpha: 0.1)
        : AsmitaPalette.deepNavy.withValues(alpha: 0.1);
    final iconColor = isDestructive
        ? AsmitaPalette.actionRed
        : AsmitaPalette.deepNavy;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.all(10.0),
        decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
        child: Icon(icon, size: 22, color: iconColor),
      ),
    );
  }
}
