import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:asmita_society/core/widgets/asmita_loading_indicator.dart';
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
  CommunityNotifier? _notifier;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _notifier = ref.read(communityProvider.notifier);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authState = context.read<AuthBloc>().state;
      int? userId;
      String? userName;
      if (authState is AuthAuthenticated) {
        userId = authState.user.userId;
        userName = authState.user.fullName;
      }
      _notifier?.loadMessages(currentUserId: userId, currentUserName: userName);
    });

    _notifier?.startPolling(
      isAtBottom: () {
        if (!mounted) return false;
        if (_scrollController.hasClients) {
          return _scrollController.position.pixels <=
              _scrollController.position.minScrollExtent + 150;
        }
        return true;
      },
    );
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
          _notifier?.loadMoreMessages();
        }
      }
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _notifier?.stopPolling();
    super.dispose();
  }

  PreferredSizeWidget _buildAppBar(CommunityState state) {
    return const PreferredSize(
      preferredSize: Size.fromHeight(85),
      child: AsmitaPrimaryHeader(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(communityProvider);

    return Scaffold(
      extendBodyBehindAppBar: true,
      extendBody: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: _buildAppBar(state),
      body: Column(
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
                  const SliverToBoxAdapter(child: SizedBox(height: 16.0)),
                  if (state is CommunityLoaded)
                    ChatListSliver(
                      messages: state.messages,
                      isLoadingMore: state.isLoadingMore,
                    )
                  else if (state is CommunityLoading ||
                      state is CommunityInitial)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: AsmitaLoadingIndicator(
                          color: Theme.of(context).colorScheme.primary,
                          size: 28,
                        ),
                      ),
                    )
                  else if (state is CommunityError)
                    SliverFillRemaining(
                      child: RotatedBox(
                        quarterTurns: 2,
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                state.error,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton.icon(
                                onPressed: () {
                                  final authState = context
                                      .read<AuthBloc>()
                                      .state;
                                  int? currentUserId;
                                  String? currentUserName;
                                  if (authState is AuthAuthenticated) {
                                    currentUserId = authState.user.userId;
                                    currentUserName = authState.user.fullName;
                                  }
                                  ref
                                      .read(communityProvider.notifier)
                                      .loadMessages(
                                        currentUserId: currentUserId,
                                        currentUserName: currentUserName,
                                      );
                                },
                                icon: const Icon(Icons.refresh),
                                label: const Text('Retry'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Theme.of(
                                    context,
                                  ).colorScheme.primary,
                                  foregroundColor: Theme.of(
                                    context,
                                  ).colorScheme.surface,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  const SliverToBoxAdapter(child: SizedBox(height: 160.0)),
                ],
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
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
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.primary,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface
                                          .withValues(alpha: 0.1),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  '',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.surface,
                                    fontFamily: 'Poppins',
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.surface,
                                  borderRadius: BorderRadius.circular(30),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface
                                          .withValues(alpha: 0.1),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    _buildFloatingAction(
                                      icon: Icons.copy_rounded,
                                      onTap: () {
                                        final selectedTexts = state.messages
                                            .where(
                                              (m) => state.selectedMessageIds
                                                  .contains(m.id),
                                            )
                                            .map((m) => m.content)
                                            .join('\n');
                                        if (selectedTexts.isNotEmpty) {
                                          Clipboard.setData(
                                            ClipboardData(text: selectedTexts),
                                          );
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                'Copied to clipboard',
                                              ),
                                              behavior:
                                                  SnackBarBehavior.floating,
                                            ),
                                          );
                                          ref
                                              .read(communityProvider.notifier)
                                              .clearSelection();
                                        }
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
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingAction({
    required IconData icon,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    final bgColor = isDestructive
        ? Theme.of(context).colorScheme.error.withValues(alpha: 0.1)
        : Theme.of(context).colorScheme.primary.withValues(alpha: 0.1);
    final iconColor = isDestructive
        ? Theme.of(context).colorScheme.primary
        : Theme.of(context).colorScheme.primary;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: EdgeInsets.all(10.0),
        decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
        child: Icon(icon, size: 22, color: iconColor),
      ),
    );
  }
}
