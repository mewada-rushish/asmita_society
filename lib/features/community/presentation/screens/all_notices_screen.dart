import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:asmita_society/core/constants/design_system.dart';
import 'package:asmita_society/core/widgets/asmita_primary_header.dart';
import 'package:asmita_society/features/community/bloc/community_post_bloc.dart';
import 'package:asmita_society/features/community/bloc/community_post_state.dart';
import 'package:asmita_society/features/community/presentation/widgets/community_post_item.dart';
import 'package:asmita_society/core/widgets/asmita_bottom_nav_bar.dart';

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
          Expanded(
            child: BlocBuilder<CommunityPostBloc, CommunityPostState>(
              builder: (context, state) {
                if (state.status == CommunityPostStatus.loading) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (state.status == CommunityPostStatus.loaded) {
                  final now = DateTime.now();
                  final activePosts = state.posts.where((p) {
                    if (p.status != 'approved') return false;
                    final today = DateTime(now.year, now.month, now.day);
                    if (p.startDate != null) {
                      final start = DateTime(p.startDate!.year, p.startDate!.month, p.startDate!.day);
                      if (start.isAfter(today)) return false;
                    }
                    if (p.endDate != null) {
                      final end = DateTime(p.endDate!.year, p.endDate!.month, p.endDate!.day);
                      if (end.isBefore(today)) return false;
                    }
                    return true;
                  }).toList();

                  activePosts.sort((a, b) => b.createdAt.compareTo(a.createdAt));

                  if (activePosts.isEmpty) {
                    return const Center(child: Text("No active notices right now."));
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    itemCount: activePosts.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: CommunityPostItem(post: activePosts[index]),
                      );
                    },
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
