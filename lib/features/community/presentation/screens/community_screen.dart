import 'package:flutter/material.dart';
import 'package:asmita_society/core/constants/design_system.dart';

class CommunityScreen extends StatelessWidget {
  const CommunityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AsmitaPalette.systemBG,
        appBar: AppBar(
          backgroundColor: AsmitaPalette.systemBG,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AsmitaPalette.deepNavy),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            'Community Hub',
            style: textTheme.titleLarge?.copyWith(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          centerTitle: true,
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(48),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(12),
              ),
              child: TabBar(
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                indicator: BoxDecoration(
                  color: AsmitaPalette.deepNavy,
                  borderRadius: BorderRadius.circular(12),
                ),
                labelColor: Colors.white,
                unselectedLabelColor: AsmitaPalette.textLight,
                labelStyle: textTheme.titleLarge?.copyWith(fontSize: 13, fontWeight: FontWeight.w700),
                tabs: const [
                  Tab(text: 'Notices & Board'),
                  Tab(text: 'Discussions'),
                ],
              ),
            ),
          ),
        ),
        body: TabBarView(
          children: [
            _buildNoticeTab(context),
            _buildDiscussionTab(context),
          ],
        ),
      ),
    );
  }

  Widget _buildNoticeTab(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: 3,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AsmitaPalette.borderGrey, width: 1.5),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: AsmitaPalette.actionRed.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                    child: Text('MANAGEMENT', style: textTheme.bodyMedium?.copyWith(color: AsmitaPalette.actionRed, fontSize: 9, fontWeight: FontWeight.w700)),
                  ),
                  Text('2 hrs ago', style: textTheme.bodyMedium?.copyWith(fontSize: 11)),
                ],
              ),
              const SizedBox(height: 12),
              Text('Annual General Body Meeting', style: textTheme.titleLarge?.copyWith(fontSize: 14, fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              Text('The AGM is scheduled for this coming Sunday at 10:00 AM in the clubhouse. Attendance is mandatory.', style: textTheme.bodyMedium?.copyWith(fontSize: 12, height: 1.4)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDiscussionTab(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: 2,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AsmitaPalette.borderGrey, width: 1.5),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(radius: 14, backgroundColor: AsmitaPalette.deepNavy, child: Text('AK', style: textTheme.titleLarge?.copyWith(fontSize: 10, color: Colors.white))),
                  const SizedBox(width: 10),
                  Text('Amit Khan (B-202)', style: textTheme.titleLarge?.copyWith(fontSize: 13, fontWeight: FontWeight.w700)),
                ],
              ),
              const SizedBox(height: 12),
              Text('Stray dog management protocols inside the main gate premises require optimization.', style: textTheme.bodyMedium?.copyWith(fontSize: 12, height: 1.4, color: AsmitaPalette.textDark)),
              const SizedBox(height: 12),
              Divider(color: AsmitaPalette.borderGrey, height: 1),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.chat_bubble_outline_rounded, size: 16, color: AsmitaPalette.textLight),
                  const SizedBox(width: 6),
                  Text('14 Comments', style: textTheme.bodyMedium?.copyWith(fontSize: 12, fontWeight: FontWeight.w600)),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}