import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:asmita_society/core/constants/design_system.dart';
import 'package:asmita_society/features/community/bloc/community_post_bloc.dart';
import 'package:asmita_society/features/community/bloc/community_post_state.dart';
import 'package:asmita_society/features/community/presentation/widgets/community_post_item.dart';

class AllNoticesScreen extends StatefulWidget {
  const AllNoticesScreen({super.key});

  @override
  State<AllNoticesScreen> createState() => _AllNoticesScreenState();
}

class _AllNoticesScreenState extends State<AllNoticesScreen> {
  int _currentSliderIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('All Notices', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: true,
      ),
      body: BlocBuilder<CommunityPostBloc, CommunityPostState>(
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

            final top3 = activePosts.take(3).toList();
            final rest = activePosts.skip(3).toList();

            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (top3.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text('Latest Notices', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 130,
                      child: PageView.builder(
                        itemCount: top3.length,
                        onPageChanged: (index) {
                          setState(() {
                            _currentSliderIndex = index;
                          });
                        },
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: CommunityPostItem(post: top3[index]),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        top3.length,
                        (index) => Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _currentSliderIndex == index ? AsmitaPalette.deepNavy : Colors.grey.shade300,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                  if (rest.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text('${rest.length} more active notice${rest.length == 1 ? '' : 's'}', style: Theme.of(context).textTheme.titleSmall?.copyWith(color: AsmitaPalette.textLight)),
                    ),
                    const SizedBox(height: 12),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: rest.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: CommunityPostItem(post: rest[index]),
                        );
                      },
                    ),
                  ],
                ],
              ),
            );
          }
          return const Center(child: Text('Failed to load notices.'));
        },
      ),
    );
  }
}
