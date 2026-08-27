import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:asmita_society/core/constants/design_system.dart';
import 'package:asmita_society/core/widgets/asmita_sub_header.dart';
import 'package:asmita_society/core/widgets/asmita_primary_header.dart';
import 'package:asmita_society/core/widgets/asmita_bottom_nav_bar.dart';
import 'package:asmita_society/core/widgets/asmita_animated_refresh.dart';
import 'package:asmita_society/features/menu/presentation/providers/family_provider.dart';
import 'package:asmita_society/features/menu/data/models/family_member_model.dart';

class FamilyMembersScreen extends ConsumerWidget {
  final ValueChanged<int>? onNavigateToTab;
  final VoidCallback? onNavigateToCommunity;
  final VoidCallback? onNavigateToSearch;

  const FamilyMembersScreen({
    super.key,
    this.onNavigateToTab,
    this.onNavigateToCommunity,
    this.onNavigateToSearch,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final familyState = ref.watch(familyProvider);

    return Scaffold(
      backgroundColor: AsmitaPalette.systemBG,
      bottomNavigationBar: AsmitaBottomNavBar(
        currentIndex: -1,
        onTap: (index) {
          Navigator.pop(context);
          if (onNavigateToTab != null) {
            onNavigateToTab!(index);
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEditSheet(context, ref),
        backgroundColor: AsmitaPalette.deepNavy,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const Icon(CupertinoIcons.add, color: Colors.white),
      ),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            AsmitaPrimaryHeader(
              showBackButton: false,
              backgroundColor: Colors.white,
              onSearchPressed: onNavigateToSearch,
              onChatPressed: onNavigateToCommunity,
            ),
            const AsmitaSubHeader(title: 'Family Members'),
            Expanded(
              child: familyState.when(
                data: (members) {
                  return CustomScrollView(
                    physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                    slivers: [
                      AsmitaAnimatedRefresh(
                        onRefresh: () async {
                          ref.invalidate(familyProvider);
                          await Future.delayed(const Duration(milliseconds: 1000));
                        },
                      ),
                      if (members.isEmpty)
                        SliverFillRemaining(
                          child: Center(
                            child: Text(
                              'No family members added yet.',
                              style: textTheme.bodyLarge?.copyWith(color: AsmitaPalette.textLight),
                            ),
                          ),
                        )
                      else
                        SliverPadding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                          sliver: SliverGrid(
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              childAspectRatio: 1.05,
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                            ),
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                return _buildFamilyGridCard(context, ref, textTheme, members[index]);
                              },
                              childCount: members.length,
                            ),
                          ),
                        ),
                    ],
                  );
                },
                loading: () => const Center(child: CupertinoActivityIndicator()),
                error: (error, _) => Center(
                  child: Text('Error: $error', style: textTheme.bodyLarge?.copyWith(color: Colors.red)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFamilyGridCard(BuildContext context, WidgetRef ref, TextTheme textTheme, FamilyMemberModel member) {
    final isPrimary = member.id == -1 || member.relationship == 'Primary';

    return GestureDetector(
      onTap: () {
        if (isPrimary) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Primary member profile can be edited from the Profile section')),
          );
        } else {
          _showMemberOptions(context, ref, member);
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: isPrimary ? AsmitaPalette.deepNavy.withValues(alpha: 0.03) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isPrimary ? AsmitaPalette.deepNavy : AsmitaPalette.borderGrey, 
            width: isPrimary ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 32,
              backgroundColor: isPrimary ? AsmitaPalette.deepNavy : AsmitaPalette.deepNavy.withValues(alpha: 0.08),
              backgroundImage: member.avatarUrl != null && member.avatarUrl!.isNotEmpty 
                  ? NetworkImage(member.avatarUrl!) 
                  : null,
              child: member.avatarUrl == null || member.avatarUrl!.isEmpty
                ? Text(
                    member.name.isNotEmpty ? member.name.substring(0, 1).toUpperCase() : '?', 
                    style: textTheme.headlineSmall?.copyWith(
                      color: isPrimary ? Colors.white : AsmitaPalette.deepNavy, 
                      fontWeight: FontWeight.bold
                    )
                  )
                : null,
            ),
            const SizedBox(height: 12),
            Text(
              member.name, 
              style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              member.relationship, 
              style: textTheme.bodyMedium?.copyWith(
                color: isPrimary ? AsmitaPalette.deepNavy : AsmitaPalette.textLight,
                fontWeight: isPrimary ? FontWeight.w600 : FontWeight.normal,
              ),
              textAlign: TextAlign.center,
            ),
            if (member.isEmergencyContact && !isPrimary) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AsmitaPalette.actionRed.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text('Emergency', style: textTheme.bodySmall?.copyWith(color: AsmitaPalette.actionRed, fontSize: 10, fontWeight: FontWeight.w700)),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showMemberOptions(BuildContext context, WidgetRef ref, FamilyMemberModel member) {
    showCupertinoModalPopup(
      context: context,
      builder: (BuildContext context) => CupertinoActionSheet(
        title: Text(member.name),
        message: const Text('Select an action'),
        actions: <CupertinoActionSheetAction>[
          CupertinoActionSheetAction(
            child: const Text('Edit Member'),
            onPressed: () {
              Navigator.pop(context);
              _showAddEditSheet(context, ref, member: member);
            },
          ),
          CupertinoActionSheetAction(
            isDestructiveAction: true,
            onPressed: () {
              Navigator.pop(context);
              _confirmDelete(context, ref, member);
            },
            child: const Text('Delete Member'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          child: const Text('Cancel'),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, FamilyMemberModel member) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Delete Member'),
        content: Text('Are you sure you want to remove ${member.name}?'),
        actions: [
          CupertinoDialogAction(
            child: const Text('Cancel'),
            onPressed: () => Navigator.pop(context),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            child: const Text('Delete'),
            onPressed: () {
              Navigator.pop(context);
              ref.read(familyProvider.notifier).deleteMember(member.id);
            },
          ),
        ],
      ),
    );
  }

  void _showAddEditSheet(BuildContext context, WidgetRef ref, {FamilyMemberModel? member}) {
    final nameCtrl = TextEditingController(text: member?.name ?? '');
    final contactCtrl = TextEditingController(text: member?.contactNumber ?? '');
    String selectedRel = member?.relationship ?? 'Spouse';
    bool isEmergency = member?.isEmergencyContact ?? false;
    
    final relationships = ['Spouse', 'Son', 'Daughter', 'Father', 'Mother', 'Brother', 'Sister', 'Other'];
    if (!relationships.contains(selectedRel)) {
      selectedRel = 'Other';
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
                left: 16,
                right: 16,
                top: 24,
              ),
              decoration: const BoxDecoration(
                color: AsmitaPalette.systemBG,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(member == null ? 'Add Family Member' : 'Edit Member', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: AsmitaPalette.borderGrey.withValues(alpha: 0.5), shape: BoxShape.circle),
                          child: const Icon(CupertinoIcons.xmark, size: 16, color: AsmitaPalette.textDark),
                        ),
                      )
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  // Name Field
                  Text('FULL NAME', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AsmitaPalette.textLight, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
                  const SizedBox(height: 8),
                  CupertinoTextField(
                    controller: nameCtrl,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AsmitaPalette.borderGrey),
                    ),
                    placeholder: 'Enter full name',
                    placeholderStyle: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AsmitaPalette.borderGrey),
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Relationship Field
                  Text('RELATIONSHIP', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AsmitaPalette.textLight, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () {
                      showCupertinoModalPopup(
                        context: context,
                        builder: (BuildContext context) => Container(
                          margin: EdgeInsets.only(
                            bottom: MediaQuery.of(context).viewInsets.bottom,
                          ),
                          color: CupertinoColors.systemBackground.resolveFrom(context),
                          child: SafeArea(
                            top: false,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  decoration: const BoxDecoration(
                                    color: CupertinoColors.systemGroupedBackground,
                                    border: Border(bottom: BorderSide(color: AsmitaPalette.borderGrey, width: 0.5)),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      CupertinoButton(
                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                        onPressed: () => Navigator.of(context).pop(),
                                        child: const Text('Done', style: TextStyle(fontWeight: FontWeight.bold)),
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(
                                  height: 160,
                                  child: CupertinoPicker(
                                    magnification: 1.22,
                                    squeeze: 1.2,
                                    useMagnifier: true,
                                    itemExtent: 40.0,
                                    scrollController: FixedExtentScrollController(
                                      initialItem: relationships.indexOf(selectedRel),
                                    ),
                                    onSelectedItemChanged: (int selectedItem) {
                                      setState(() {
                                        selectedRel = relationships[selectedItem];
                                      });
                                    },
                                    children: List<Widget>.generate(relationships.length, (int index) {
                                      return Center(
                                        child: Text(
                                          relationships[index],
                                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                            color: AsmitaPalette.textDark,
                                          ),
                                        ),
                                      );
                                    }),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AsmitaPalette.borderGrey),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(selectedRel, style: Theme.of(context).textTheme.bodyLarge),
                          const Icon(CupertinoIcons.chevron_down, size: 18, color: AsmitaPalette.textLight),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 20),

                  // Contact Number Field
                  Text('CONTACT NUMBER', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AsmitaPalette.textLight, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
                  const SizedBox(height: 8),
                  CupertinoTextField(
                    controller: contactCtrl,
                    keyboardType: TextInputType.phone,
                    maxLength: 10,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AsmitaPalette.borderGrey),
                    ),
                    placeholder: 'Enter contact number',
                    placeholderStyle: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AsmitaPalette.borderGrey),
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Emergency Contact Switch
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AsmitaPalette.borderGrey),
                    ),
                    child: CupertinoListTile(
                      title: Text('Set as Emergency Contact', style: Theme.of(context).textTheme.bodyLarge),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      trailing: CupertinoSwitch(
                        value: isEmergency,
                        activeTrackColor: AsmitaPalette.deepNavy,
                        onChanged: (val) => setState(() => isEmergency = val),
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),
                  
                  // Save Button
                  SizedBox(
                    width: double.infinity,
                    child: CupertinoButton(
                      color: AsmitaPalette.deepNavy,
                      borderRadius: BorderRadius.circular(12),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      onPressed: () async {
                        final name = nameCtrl.text.trim();
                        final contact = contactCtrl.text.trim();
                        
                        if (name.isEmpty || contact.isEmpty) return;
                        
                        if (!RegExp(r'^[0-9]{10}$').hasMatch(contact)) {
                          showCupertinoDialog(
                            context: context,
                            builder: (ctx) => CupertinoAlertDialog(
                              title: const Text('Invalid Number'),
                              content: const Text('Please enter a valid 10-digit contact number.'),
                              actions: [
                                CupertinoDialogAction(
                                  child: const Text('OK'),
                                  onPressed: () => Navigator.pop(ctx),
                                ),
                              ],
                            ),
                          );
                          return;
                        }

                        final notifier = ref.read(familyProvider.notifier);
                        bool success;
                        if (member == null) {
                          success = await notifier.addMember(
                            name: name, 
                            relationship: selectedRel, 
                            contactNumber: contact,
                            isEmergencyContact: isEmergency
                          );
                        } else {
                          success = await notifier.updateMember(
                            member.id, 
                            name: name, 
                            relationship: selectedRel, 
                            contactNumber: contact,
                            isEmergencyContact: isEmergency
                          );
                        }
                        if (success && context.mounted) {
                          Navigator.pop(context);
                        }
                      },
                      child: Text(member == null ? 'Save Member' : 'Update Member', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                    ),
                  ),
                ],
              ),
            );
          }
        );
      }
    );
  }
}
