import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:asmita_society/features/menu/bloc/pets_bloc.dart';
import 'package:asmita_society/features/menu/bloc/pets_event.dart';
import 'package:asmita_society/features/menu/bloc/pets_state.dart';
import 'package:asmita_society/core/widgets/asmita_loading_indicator.dart';
import 'package:asmita_society/core/widgets/asmita_sub_header.dart';
import 'package:asmita_society/core/widgets/asmita_primary_header.dart';
import 'package:asmita_society/core/widgets/asmita_animated_refresh.dart';
import 'package:asmita_society/core/widgets/asmita_toast.dart';
import 'package:asmita_society/core/widgets/asmita_bottom_nav_bar.dart';

import 'package:asmita_society/features/menu/data/models/pet_model.dart';
import 'package:image_picker/image_picker.dart';

class PetsScreen extends StatelessWidget {
  final ValueChanged<int>? onNavigateToTab;

  const PetsScreen({super.key, this.onNavigateToTab});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
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
        onPressed: () => _showAddEditSheet(context),
        backgroundColor: Theme.of(context).colorScheme.primary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Icon(CupertinoIcons.add, color: Theme.of(context).colorScheme.surface),
      ),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            AsmitaPrimaryHeader(
              showBackButton: false,
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              bottomPadding: 0.0,
              onSearchPressed: () {},
              onChatPressed: () {},
            ),
            const AsmitaSubHeader(title: 'Pets'),
            Expanded(
              child: BlocBuilder<PetsBloc, PetsState>(
                builder: (context, state) {
                  if (state is PetsLoading) {
                    return Center(child: AsmitaLoadingIndicator(color: Theme.of(context).colorScheme.primary, size: 28));
                  } else if (state is PetsError) {
                    return Center(child: Text('Error: ${state.message}', style: textTheme.bodyLarge?.copyWith(color: Colors.red)));
                  } else if (state is PetsLoaded) {
                    final pets = state.items;
                    return CustomScrollView(
                    physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                    slivers: [
                      AsmitaAnimatedRefresh(
                        onRefresh: () async {
                          context.read<PetsBloc>().add(const LoadPets());
                          await Future.delayed(const Duration(milliseconds: 1000));
                        },
                      ),
                      if (pets.isEmpty)
                        SliverFillRemaining(
                          child: Center(
                            child: Text(
                              'No pets added yet.',
                              style: textTheme.bodyLarge?.copyWith(color: Theme.of(context).textTheme.bodyMedium?.color),
                            ),
                          ),
                        )
                      else
                        SliverPadding(
                          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                          sliver: SliverGrid(
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              childAspectRatio: 0.85,
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                            ),
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                return _buildPetGridCard(context, textTheme, pets[index]);
                              },
                              childCount: pets.length,
                            ),
                          ),
                        ),
                    ],
                  );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPetGridCard(BuildContext context, TextTheme textTheme, PetModel pet) {
    return GestureDetector(
      onTap: () => _showPetOptions(context, pet),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Theme.of(context).dividerColor, width: 1),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.02),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(),
            CircleAvatar(
              radius: 38,
              backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.08),
              backgroundImage: pet.avatarUrl != null && pet.avatarUrl!.isNotEmpty 
                  ? NetworkImage(pet.avatarUrl!) 
                  : null,
              child: pet.avatarUrl == null || pet.avatarUrl!.isEmpty
                ? Text(
                    pet.name.isNotEmpty ? pet.name.substring(0, 1).toUpperCase() : '?', 
                    style: textTheme.headlineSmall?.copyWith(
                      color: Theme.of(context).colorScheme.primary, 
                      fontWeight: FontWeight.bold
                    )
                  )
                : null,
            ),
            SizedBox(height: 12),
            Text(
              pet.name, 
              style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: 2),
            Text(
              pet.breed, 
              style: textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).textTheme.bodyMedium?.color,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const Spacer(),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                color: pet.isVaccinated ? Colors.green.withValues(alpha: 0.1) : Theme.of(context).colorScheme.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(pet.isVaccinated ? Icons.check_circle_rounded : Icons.error_outline_rounded, 
                    size: 12, 
                    color: pet.isVaccinated ? Colors.green : Theme.of(context).colorScheme.primary
                  ),
                  SizedBox(width: 4),
                  Text(pet.isVaccinated ? 'Vaccinated' : 'Pending', 
                    style: textTheme.bodySmall?.copyWith(
                      color: pet.isVaccinated ? Colors.green : Theme.of(context).colorScheme.primary, 
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

  void _showPetOptions(BuildContext context, PetModel pet) {
    showCupertinoModalPopup(
      context: context,
      builder: (BuildContext context) => SafeArea(
        child: CupertinoActionSheet(
          title: Text(pet.name),
        message: Text('Select an action'),
        actions: <CupertinoActionSheetAction>[
          CupertinoActionSheetAction(
            child: Text('Edit Pet'),
            onPressed: () {
              Navigator.pop(context);
              _showAddEditSheet(context, pet: pet);
            },
          ),
          CupertinoActionSheetAction(
            isDestructiveAction: true,
            onPressed: () {
              Navigator.pop(context);
              _confirmDelete(context, pet);
            },
            child: Text('Delete Pet'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          child: Text('Cancel'),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, PetModel pet) async {
    final confirm = await showCupertinoDialog<bool>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: Text('Delete Pet'),
        content: Text('Are you sure you want to remove ?'),
        actions: [
          CupertinoDialogAction(
            child: Text('Cancel'),
            onPressed: () => Navigator.pop(ctx, false),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            child: Text('Delete'),
            onPressed: () => Navigator.pop(ctx, true),
          ),
        ],
      ),
    );
    
    if (confirm == true && context.mounted) {
      context.read<PetsBloc>().add(DeletePet(pet.id));
      AsmitaToast.show(context, message: 'Pet deleted', type: AsmitaToastType.success);
    }
  }

  void _showAddEditSheet(BuildContext context, {PetModel? pet}) {
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
                bottom: MediaQuery.of(context).viewInsets.bottom + MediaQuery.of(context).padding.bottom + 24,
                left: 16,
                right: 16,
                top: 24,
              ),
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
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
                        icon: Icon(CupertinoIcons.xmark_circle_fill, color: Theme.of(context).textTheme.bodyMedium?.color, size: 28),
                      ),
                    ],
                  ),
                  SizedBox(height: 24),
                  
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
                      backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                      backgroundImage: imageFile != null 
                        ? FileImage(imageFile!) as ImageProvider
                        : (pet?.avatarUrl != null && pet!.avatarUrl!.isNotEmpty) 
                          ? NetworkImage(pet.avatarUrl!) 
                          : null,
                      child: (imageFile == null && (pet?.avatarUrl == null || pet!.avatarUrl!.isEmpty))
                        ? Icon(CupertinoIcons.camera_fill, color: Theme.of(context).colorScheme.primary, size: 30)
                        : null,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text('Tap to select photo', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).textTheme.bodyMedium?.color)),
                  SizedBox(height: 24),

                  Text('PET NAME', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: Theme.of(context).textTheme.bodyMedium?.color, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
                  SizedBox(height: 8),
                  CupertinoTextField(
                    controller: nameCtrl,
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Theme.of(context).dividerColor),
                    ),
                    placeholder: 'Enter pet name',
                    placeholderStyle: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Theme.of(context).dividerColor),
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  SizedBox(height: 20),
                  Text('BREED', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: Theme.of(context).textTheme.bodyMedium?.color, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
                  SizedBox(height: 8),
                  CupertinoTextField(
                    controller: breedCtrl,
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Theme.of(context).dividerColor),
                    ),
                    placeholder: 'Enter breed',
                    placeholderStyle: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Theme.of(context).dividerColor),
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  SizedBox(height: 20),
                  
                  Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Theme.of(context).dividerColor),
                    ),
                    child: CupertinoListTile(
                      title: Text('Vaccinated', style: Theme.of(context).textTheme.bodyLarge),
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      trailing: CupertinoSwitch(
                        value: isVaccinated,
                        activeTrackColor: Theme.of(context).colorScheme.primary,
                        onChanged: (val) => setState(() => isVaccinated = val),
                      ),
                    ),
                  ),

                  SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: CupertinoButton(
                      color: Theme.of(context).colorScheme.primary,
                      borderRadius: BorderRadius.circular(12),
                      padding: EdgeInsets.symmetric(vertical: 16),
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

                        final bloc = context.read<PetsBloc>();
                        setState(() => isLoading = true);
                        
                        if (pet == null) {
                          bloc.add(AddPet(
                            name: name, 
                            breed: breed, 
                            isVaccinated: isVaccinated,
                            imageFile: imageFile!,
                          ));
                        } else {
                          bloc.add(UpdatePet(
                            id: pet.id, 
                            name: name, 
                            breed: breed, 
                            isVaccinated: isVaccinated,
                            imageFile: imageFile,
                          ));
                        }
                        
                        await Future.delayed(const Duration(milliseconds: 500));
                        if (context.mounted) {
                          setState(() => isLoading = false);
                          AsmitaToast.show(
                            context,
                            message: pet == null ? 'Pet saved successfully!' : 'Pet updated successfully!',
                            type: AsmitaToastType.success,
                          );
                          Navigator.pop(context);
                        }
                      },
                      child: isLoading 
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: AsmitaLoadingIndicator(
                                  color: Theme.of(context).colorScheme.surface,
                                  size: 20,
                                ),
                            )
                          : Text(pet == null ? 'Save Pet' : 'Update Pet', style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.surface)),
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
