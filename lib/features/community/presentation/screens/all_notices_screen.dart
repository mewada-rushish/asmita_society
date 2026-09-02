import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:asmita_society/core/constants/design_system.dart';
import 'package:asmita_society/core/widgets/asmita_primary_header.dart';
import 'package:asmita_society/features/community/bloc/community_post_bloc.dart';
import 'package:asmita_society/features/community/bloc/community_post_state.dart';
import 'package:asmita_society/features/community/presentation/widgets/community_post_item.dart';
import 'package:asmita_society/features/community/presentation/widgets/add_community_post_modal.dart';
import 'package:asmita_society/core/widgets/asmita_bottom_nav_bar.dart';
import 'package:asmita_society/core/widgets/asmita_bottom_sheet.dart';
import 'package:asmita_society/core/widgets/asmita_dialog.dart';
import 'package:asmita_society/core/widgets/asmita_toast.dart';
import 'package:asmita_society/features/community/bloc/community_post_event.dart';
import 'package:asmita_society/core/widgets/asmita_sub_header.dart';
import 'package:asmita_society/core/widgets/asmita_animated_refresh.dart';

class AllNoticesScreen extends StatefulWidget {
  final ValueChanged<int>? onNavigateToTab;
  final VoidCallback? onNavigateToCommunity;
  final VoidCallback? onNavigateToSearch;

  const AllNoticesScreen({
    super.key,
    this.onNavigateToTab,
    this.onNavigateToCommunity,
    this.onNavigateToSearch,
  });

  @override
  State<AllNoticesScreen> createState() => _AllNoticesScreenState();
}

class _AllNoticesScreenState extends State<AllNoticesScreen> {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AsmitaPalette.systemBG,
      bottomNavigationBar: AsmitaBottomNavBar(
        currentIndex: -1,
        onTap: (index) {
          if (index == 0) {
            Navigator.pop(context);
            return;
          }
          if (widget.onNavigateToTab != null) {
            widget.onNavigateToTab!(index);
          } else {
            Navigator.pop(context);
          }
        },
      ),
      body: Column(
        children: [
          AsmitaPrimaryHeader(
            showBackButton: false,
            onSearchPressed: widget.onNavigateToSearch,
            onChatPressed: widget.onNavigateToCommunity,
          ),
          AsmitaSubHeader(
            title: 'Community Posts',
            trailing: OutlinedButton.icon(
              onPressed: () {
                showAsmitaBottomSheet(
                  context: context,
                  title: 'New Community Post',
                  isScrollControlled: true,
                  child: const AddCommunityPostModal(),
                );
              },
              icon: const Icon(Icons.edit_note_rounded, size: 16, color: AsmitaPalette.actionRed),
              label: Text("New Post", style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AsmitaPalette.actionRed, fontSize: 12, fontWeight: FontWeight.w600)),
              style: OutlinedButton.styleFrom(
                foregroundColor: AsmitaPalette.actionRed,
                side: const BorderSide(color: AsmitaPalette.actionRed, width: 1.2),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              ),
            ),
          ),
          Expanded(
            child: BlocBuilder<CommunityPostBloc, CommunityPostState>(
              builder: (context, state) {
                if (state.status == CommunityPostStatus.loading) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (state.status == CommunityPostStatus.loaded) {
                  final activePosts = state.activePosts;

                  return CustomScrollView(
                    physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                    slivers: [
                      AsmitaAnimatedRefresh(
                        onRefresh: () async {
                          context.read<CommunityPostBloc>().add(LoadCommunityPosts());
                          await Future.delayed(const Duration(milliseconds: 1000));
                        },
                      ),
                      if (activePosts.isEmpty)
                        const SliverFillRemaining(
                          child: Center(child: Text("No active notices right now.")),
                        )
                      else
                        SliverPadding(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          sliver: SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                return Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  child: Dismissible(
                                    key: Key(activePosts[index].id),
                                    direction: DismissDirection.endToStart,
                                    background: Container(
                                      alignment: Alignment.centerRight,
                                      padding: const EdgeInsets.only(right: 20),
                                      decoration: BoxDecoration(
                                        color: AsmitaPalette.actionRed,
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: const Icon(Icons.delete_outline, color: Colors.white, size: 28),
                                    ),
                                    confirmDismiss: (direction) async {
                                      final confirm = await AsmitaDialog.show<bool>(
                                        context: context,
                                        title: 'Delete Post',
                                        content: const Text('Are you sure you want to delete this post?'),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.pop(context, false),
                                            child: const Text('Cancel', style: TextStyle(color: AsmitaPalette.deepNavy)),
                                          ),
                                          ElevatedButton(
                                            onPressed: () => Navigator.pop(context, true),
                                            style: ElevatedButton.styleFrom(backgroundColor: AsmitaPalette.actionRed),
                                            child: const Text('Delete', style: TextStyle(color: Colors.white)),
                                          ),
                                        ],
                                      );
                                      return confirm ?? false;
                                    },
                                    onDismissed: (direction) {
                                      context.read<CommunityPostBloc>().add(DeleteCommunityPost(activePosts[index].id));
                                      AsmitaToast.show(context, message: 'Post deleted', type: AsmitaToastType.success);
                                    },
                                    child: CommunityPostItem(post: activePosts[index]),
                                  ),
                                );
                              },
                              childCount: activePosts.length,
                            ),
                          ),
                        ),
                    ],
                  );
                }
                return const Center(child: Text('Failed to load notices.'));
              },
            ),
          ),
        ],
      ),
    );
  }
}
