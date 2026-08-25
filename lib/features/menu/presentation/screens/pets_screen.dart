import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:asmita_society/core/constants/design_system.dart';
import 'package:asmita_society/core/widgets/asmita_sub_header.dart';
import 'package:asmita_society/features/menu/presentation/providers/pets_provider.dart';
import 'package:asmita_society/features/menu/data/models/pet_model.dart';

class PetsScreen extends ConsumerWidget {
  const PetsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final petsState = ref.watch(petsProvider);

    return Scaffold(
      backgroundColor: AsmitaPalette.systemBG,
      body: SafeArea(
        child: Column(
          children: [
            const AsmitaSubHeader(title: 'Pets'),
            Expanded(
              child: petsState.when(
                data: (pets) {
                  return ListView(
                    physics: const ClampingScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    children: [
                      _buildAddButton(context, ref, textTheme),
                      const SizedBox(height: 24),
                      if (pets.isEmpty)
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.all(32.0),
                            child: Text(
                              'No pets added yet.',
                              style: textTheme.bodyLarge?.copyWith(color: AsmitaPalette.textLight),
                            ),
                          ),
                        )
                      else
                        ...pets.map((p) => Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: _buildPetCard(context, ref, textTheme, p),
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
            Text('Add Pet', style: textTheme.titleMedium?.copyWith(color: AsmitaPalette.deepNavy, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _buildPetCard(BuildContext context, WidgetRef ref, TextTheme textTheme, PetModel pet) {
    return Dismissible(
      key: ValueKey(pet.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (direction) async {
        return await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete Pet'),
            content: Text('Are you sure you want to remove ${pet.name}?'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
              TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
            ],
          ),
        );
      },
      onDismissed: (direction) {
        ref.read(petsProvider.notifier).deletePet(pet.id);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${pet.name} deleted')));
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
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.pets_rounded, color: Colors.orange, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(pet.name, style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text(pet.breed, style: textTheme.bodyMedium?.copyWith(color: AsmitaPalette.textLight)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: pet.isVaccinated ? AsmitaPalette.successGreen.withValues(alpha: 0.1) : AsmitaPalette.actionRed.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(pet.isVaccinated ? Icons.check_circle_rounded : Icons.error_outline_rounded, 
                              size: 12, 
                              color: pet.isVaccinated ? AsmitaPalette.successGreen : AsmitaPalette.actionRed
                            ),
                            const SizedBox(width: 4),
                            Text(pet.isVaccinated ? 'Vaccinated' : 'Pending', 
                              style: textTheme.bodySmall?.copyWith(
                                color: pet.isVaccinated ? AsmitaPalette.successGreen : AsmitaPalette.actionRed, 
                                fontSize: 10, 
                                fontWeight: FontWeight.w700
                              )
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert_rounded, color: AsmitaPalette.textLight),
              onSelected: (val) {
                if (val == 'edit') {
                  _showAddEditSheet(context, ref, pet: pet);
                } else if (val == 'delete') {
                  ref.read(petsProvider.notifier).deletePet(pet.id);
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

  void _showAddEditSheet(BuildContext context, WidgetRef ref, {PetModel? pet}) {
    final nameCtrl = TextEditingController(text: pet?.name ?? '');
    final breedCtrl = TextEditingController(text: pet?.breed ?? '');
    bool isVaccinated = pet?.isVaccinated ?? false;

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
                  Text(pet == null ? 'Add Pet' : 'Edit Pet', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 16),
                  TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(labelText: 'Pet Name', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: breedCtrl,
                    decoration: const InputDecoration(labelText: 'Breed (e.g. Golden Retriever)', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    title: const Text('Vaccinated'),
                    value: isVaccinated,
                    onChanged: (val) => setState(() => isVaccinated = val),
                    contentPadding: EdgeInsets.zero,
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        if (nameCtrl.text.isEmpty || breedCtrl.text.isEmpty) return;
                        final notifier = ref.read(petsProvider.notifier);
                        bool success;
                        if (pet == null) {
                          success = await notifier.addPet(
                            name: nameCtrl.text,
                            breed: breedCtrl.text,
                            isVaccinated: isVaccinated,
                          );
                        } else {
                          success = await notifier.updatePet(
                            pet.id,
                            name: nameCtrl.text,
                            breed: breedCtrl.text,
                            isVaccinated: isVaccinated,
                          );
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
                      child: Text(pet == null ? 'Save Pet' : 'Update Pet', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
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
