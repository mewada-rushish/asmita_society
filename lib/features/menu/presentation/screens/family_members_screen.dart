import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:asmita_society/core/constants/design_system.dart';
import 'package:asmita_society/core/widgets/asmita_sub_header.dart';
import 'package:asmita_society/features/menu/presentation/providers/family_provider.dart';
import 'package:asmita_society/features/menu/data/models/family_member_model.dart';

class FamilyMembersScreen extends ConsumerWidget {
  const FamilyMembersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final familyState = ref.watch(familyProvider);

    return Scaffold(
      backgroundColor: AsmitaPalette.systemBG,
      body: SafeArea(
        child: Column(
          children: [
            const AsmitaSubHeader(title: 'Family Members'),
            Expanded(
              child: familyState.when(
                data: (members) {
                  return ListView(
                    physics: const ClampingScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    children: [
                      _buildAddButton(context, ref, textTheme),
                      const SizedBox(height: 24),
                      if (members.isEmpty)
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.all(32.0),
                            child: Text(
                              'No family members added yet.',
                              style: textTheme.bodyLarge?.copyWith(color: AsmitaPalette.textLight),
                            ),
                          ),
                        )
                      else
                        ...members.map((member) => Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: _buildFamilyCard(context, ref, textTheme, member),
                        )),
                    ],
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
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

  Widget _buildAddButton(BuildContext context, WidgetRef ref, TextTheme textTheme) {
    return InkWell(
      onTap: () => _showAddEditSheet(context, ref),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AsmitaPalette.deepNavy.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AsmitaPalette.deepNavy, width: 1.5, style: BorderStyle.solid),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.add_circle_outline_rounded, color: AsmitaPalette.deepNavy),
            const SizedBox(width: 8),
            Text('Add Family Member', style: textTheme.titleMedium?.copyWith(color: AsmitaPalette.deepNavy, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _buildFamilyCard(BuildContext context, WidgetRef ref, TextTheme textTheme, FamilyMemberModel member) {
    return Dismissible(
      key: ValueKey(member.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (direction) async {
        return await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete Member'),
            content: Text('Are you sure you want to remove ${member.name}?'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
              TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
            ],
          ),
        );
      },
      onDismissed: (direction) {
        ref.read(familyProvider.notifier).deleteMember(member.id);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${member.name} deleted')));
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AsmitaPalette.borderGrey, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: AsmitaPalette.deepNavy.withValues(alpha: 0.1),
              child: Text(
                member.name.isNotEmpty ? member.name.substring(0, 1).toUpperCase() : '?', 
                style: textTheme.titleLarge?.copyWith(color: AsmitaPalette.deepNavy)
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(member.name, style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(member.relationship, style: textTheme.bodyMedium?.copyWith(color: AsmitaPalette.textLight)),
                      if (member.isEmergencyContact) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AsmitaPalette.actionRed.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text('Emergency', style: textTheme.bodySmall?.copyWith(color: AsmitaPalette.actionRed, fontSize: 10, fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert_rounded, color: AsmitaPalette.textLight),
              onSelected: (val) {
                if (val == 'edit') {
                  _showAddEditSheet(context, ref, member: member);
                } else if (val == 'delete') {
                  ref.read(familyProvider.notifier).deleteMember(member.id);
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'edit', child: Text('Edit')),
                const PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: Colors.red))),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showAddEditSheet(BuildContext context, WidgetRef ref, {FamilyMemberModel? member}) {
    final nameCtrl = TextEditingController(text: member?.name ?? '');
    final relCtrl = TextEditingController(text: member?.relationship ?? '');
    bool isEmergency = member?.isEmergencyContact ?? false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 20,
                right: 20,
                top: 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(member == null ? 'Add Family Member' : 'Edit Family Member', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 16),
                  TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(labelText: 'Full Name', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: relCtrl,
                    decoration: const InputDecoration(labelText: 'Relationship (e.g., Spouse, Son)', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    title: const Text('Emergency Contact'),
                    value: isEmergency,
                    onChanged: (val) => setState(() => isEmergency = val),
                    contentPadding: EdgeInsets.zero,
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        if (nameCtrl.text.isEmpty || relCtrl.text.isEmpty) return;
                        final notifier = ref.read(familyProvider.notifier);
                        bool success;
                        if (member == null) {
                          success = await notifier.addMember(name: nameCtrl.text, relationship: relCtrl.text, isEmergencyContact: isEmergency);
                        } else {
                          success = await notifier.updateMember(member.id, name: nameCtrl.text, relationship: relCtrl.text, isEmergencyContact: isEmergency);
                        }
                        if (success && context.mounted) {
                          Navigator.pop(context);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AsmitaPalette.deepNavy,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(member == null ? 'Save Member' : 'Update Member', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            );
          }
        );
      }
    );
  }
}
