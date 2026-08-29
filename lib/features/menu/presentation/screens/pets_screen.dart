import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:asmita_society/core/constants/design_system.dart';
import 'package:asmita_society/core/widgets/asmita_sub_header.dart';
import 'package:asmita_society/core/widgets/asmita_primary_header.dart';
import 'package:asmita_society/core/widgets/asmita_animated_refresh.dart';
import 'package:asmita_society/core/widgets/asmita_toast.dart';
import 'package:asmita_society/core/widgets/asmita_bottom_nav_bar.dart';
import 'package:asmita_society/features/menu/presentation/providers/pets_provider.dart';
import 'package:asmita_society/features/menu/data/models/pet_model.dart';
import 'package:image_picker/image_picker.dart';

class PetsScreen extends ConsumerWidget {
  final ValueChanged<int>? onNavigateToTab;

  const PetsScreen({super.key, this.onNavigateToTab});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final petsState = ref.watch(petsProvider);

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
              onSearchPressed: () {},
              onChatPressed: () {},
            ),
            const AsmitaSubHeader(title: 'Pets'),
            Expanded(
              child: petsState.when(
                data: (pets) {
                  return CustomScrollView(
                    physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                    slivers: [
                      AsmitaAnimatedRefresh(
                        onRefresh: () async {
                          ref.invalidate(petsProvider);
                          await Future.delayed(const Duration(milliseconds: 1000));
                        },
                      ),
                      if (pets.isEmpty)
                        SliverFillRemaining(
                          child: Center(
                            child: Text(
                              'No pets added yet.',
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
                              childAspectRatio: 0.85,
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                            ),
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                return _buildPetGridCard(context, ref, textTheme, pets[index]);
                              },
                              childCount: pets.length,
                            ),
                          ),
                        ),
                    ],
                  );
                },
                loading: () => const Center(child: CupertinoActivityIndicator()),
                error: (error, _) => Center(
                  child: Text('Error: ', style: textTheme.bodyLarge?.copyWith(color: Colors.red)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPetGridCard(BuildContext context, WidgetRef ref, TextTheme textTheme, PetModel pet) {
    return GestureDetector(
      onTap: () => _showPetOptions(context, ref, pet),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AsmitaPalette.borderGrey, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(),
            CircleAvatar(
              radius: 38,
              backgroundColor: AsmitaPalette.deepNavy.withValues(alpha: 0.08),
              backgroundImage: pet.avatarUrl != null && pet.avatarUrl!.isNotEmpty 
                  ? NetworkImage(pet.avatarUrl!) 
                  : null,
              child: pet.avatarUrl == null || pet.avatarUrl!.isEmpty
                ? Text(
                    pet.name.isNotEmpty ? pet.name.substring(0, 1).toUpperCase() : '?', 
                    style: textTheme.headlineSmall?.copyWith(
                      color: AsmitaPalette.deepNavy, 
                      fontWeight: FontWeight.bold
                    )
                  )
                : null,
            ),
            const SizedBox(height: 12),
            Text(
              pet.name, 
              style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              pet.breed, 
              style: textTheme.bodyMedium?.copyWith(
                color: AsmitaPalette.textLight,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                color: pet.isVaccinated ? AsmitaPalette.successGreen.withValues(alpha: 0.1) : AsmitaPalette.actionRed.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
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
      ),
    );
  }

  void _showPetOptions(BuildContext context, WidgetRef ref, PetModel pet) {
    showCupertinoModalPopup(
      context: context,
      builder: (BuildContext context) => CupertinoActionSheet(
        title: Text(pet.name),
        message: const Text('Select an action'),
        actions: <CupertinoActionSheetAction>[
          CupertinoActionSheetAction(
            child: const Text('Edit Pet'),
            onPressed: () {
              Navigator.pop(context);
              _showAddEditSheet(context, ref, pet: pet);
            },
          ),
          CupertinoActionSheetAction(
            isDestructiveAction: true,
            onPressed: () {
              Navigator.pop(context);
              _confirmDelete(context, ref, pet);
            },
            child: const Text('Delete Pet'),
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

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref, PetModel pet) async {
    final confirm = await showCupertinoDialog<bool>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('Delete Pet'),
        content: Text('Are you sure you want to remove ?'),
        actions: [
          CupertinoDialogAction(
            child: const Text('Cancel'),
            onPressed: () => Navigator.pop(ctx, false),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            child: const Text('Delete'),
            onPressed: () => Navigator.pop(ctx, true),
          ),
        ],
      ),
    );
    
    if (confirm == true) {
      final success = await ref.read(petsProvider.notifier).deletePet(pet.id);
      if (success && context.mounted) {
        AsmitaToast.show(context, message: ' deleted', type: AsmitaToastType.success);
      }
    }
  }

  void _showAddEditSheet(BuildContext context, WidgetRef ref, {PetModel? pet}) {
    final nameCtrl = TextEditingController(text: pet?.name ?? '');
    final breedCtrl = TextEditingController(text: pet?.breed ?? '');
    bool isVaccinated = pet?.isVaccinated ?? false;
    bool isLoading = false;
    File? imageFile;

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
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(pet == null ? 'Add Pet' : 'Edit Pet', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(CupertinoIcons.xmark_circle_fill, color: AsmitaPalette.textLight, size: 28),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  // Photo picker
                  GestureDetector(
                    onTap: () async {
                      final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
                      if (picked != null) {
                        setState(() => imageFile = File(picked.path));
                      }
                    },
                    child: CircleAvatar(
                      radius: 40,
                      backgroundColor: AsmitaPalette.deepNavy.withValues(alpha: 0.1),
                      backgroundImage: imageFile != null 
                        ? FileImage(imageFile!) as ImageProvider
                        : (pet?.avatarUrl != null && pet!.avatarUrl!.isNotEmpty) 
                          ? NetworkImage(pet.avatarUrl!) 
                          : null,
                      child: (imageFile == null && (pet?.avatarUrl == null || pet!.avatarUrl!.isEmpty))
                        ? const Icon(CupertinoIcons.camera_fill, color: AsmitaPalette.deepNavy, size: 30)
                        : null,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text('Tap to select photo', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AsmitaPalette.textLight)),
                  const SizedBox(height: 24),

                  Text('PET NAME', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AsmitaPalette.textLight, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
                  const SizedBox(height: 8),
                  CupertinoTextField(
                    controller: nameCtrl,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AsmitaPalette.borderGrey),
                    ),
                    placeholder: 'Enter pet name',
                    placeholderStyle: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AsmitaPalette.borderGrey),
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 20),
                  Text('BREED', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AsmitaPalette.textLight, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
                  const SizedBox(height: 8),
                  CupertinoTextField(
                    controller: breedCtrl,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AsmitaPalette.borderGrey),
                    ),
                    placeholder: 'Enter breed',
                    placeholderStyle: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AsmitaPalette.borderGrey),
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 20),
                  
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AsmitaPalette.borderGrey),
                    ),
                    child: CupertinoListTile(
                      title: Text('Vaccinated', style: Theme.of(context).textTheme.bodyLarge),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      trailing: CupertinoSwitch(
                        value: isVaccinated,
                        activeTrackColor: AsmitaPalette.deepNavy,
                        onChanged: (val) => setState(() => isVaccinated = val),
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: CupertinoButton(
                      color: AsmitaPalette.deepNavy,
                      borderRadius: BorderRadius.circular(12),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      onPressed: () async {
                        if (isLoading) return;
                        
                        final name = nameCtrl.text.trim();
                        final breed = breedCtrl.text.trim();
                        
                        if (name.isEmpty || breed.isEmpty) {
                           AsmitaToast.show(context, message: 'Please enter all details', type: AsmitaToastType.error);
                           return;
                        }

                        if (pet == null && imageFile == null) {
                           AsmitaToast.show(context, message: 'Photo is mandatory for pets', type: AsmitaToastType.error);
                           return;
                        }

                        final notifier = ref.read(petsProvider.notifier);
                        setState(() => isLoading = true);
                        
                        bool success;
                        if (pet == null) {
                          success = await notifier.addPet(
                            name: name, 
                            breed: breed, 
                            isVaccinated: isVaccinated,
                            imageFile: imageFile!,
                          );
                        } else {
                          success = await notifier.updatePet(
                            pet.id, 
                            name: name, 
                            breed: breed, 
                            isVaccinated: isVaccinated,
                            imageFile: imageFile,
                          );
                        }
                        
                        if (context.mounted) {
                          setState(() => isLoading = false);
                          if (success) {
                            AsmitaToast.show(
                              context,
                              message: pet == null ? 'Pet saved successfully!' : 'Pet updated successfully!',
                              type: AsmitaToastType.success,
                            );
                            Navigator.pop(context);
                          }
                        }
                      },
                      child: isLoading 
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.5,
                              ),
                            )
                          : Text(pet == null ? 'Save Pet' : 'Update Pet', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
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
