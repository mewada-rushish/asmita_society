import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:asmita_society/core/widgets/asmita_toast.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:asmita_society/features/menu/bloc/tenant_bloc.dart';
import 'package:asmita_society/features/menu/bloc/tenant_event.dart';
import 'package:asmita_society/features/menu/bloc/tenant_state.dart';
import 'package:asmita_society/core/widgets/asmita_loading_indicator.dart';
import 'package:asmita_society/core/widgets/asmita_sub_header.dart';
import 'package:asmita_society/core/widgets/asmita_primary_header.dart';
import 'package:asmita_society/core/widgets/asmita_bottom_nav_bar.dart';
import 'package:asmita_society/core/widgets/asmita_animated_refresh.dart';
import 'package:asmita_society/features/menu/data/models/tenant_model.dart';

class TenantsScreen extends StatelessWidget {
  final ValueChanged<int>? onNavigateToTab;
  final VoidCallback? onNavigateToCommunity;
  final VoidCallback? onNavigateToSearch;

  const TenantsScreen({
    super.key,
    this.onNavigateToTab,
    this.onNavigateToCommunity,
    this.onNavigateToSearch,
  });

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
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton(
            heroTag: 'request_history_fab',
            onPressed: () => _onHistoryRequestFabTapped(context),
            backgroundColor: Theme.of(context).colorScheme.primary,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Icon(Icons.history, color: Theme.of(context).colorScheme.surface),
          ),
          SizedBox(height: 16),
          FloatingActionButton(
            heroTag: 'add_tenant_fab',
            onPressed: () => _showAddEditSheet(context),
            backgroundColor: Theme.of(context).colorScheme.primary,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Icon(CupertinoIcons.add, color: Theme.of(context).colorScheme.surface),
          ),
        ],
      ),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            AsmitaPrimaryHeader(
              showBackButton: false,
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              bottomPadding: 0.0,
              onSearchPressed: onNavigateToSearch,
              onChatPressed: onNavigateToCommunity,
            ),
            const AsmitaSubHeader(title: 'Tenants'),
            Expanded(
              child: BlocBuilder<TenantBloc, TenantState>(
                builder: (context, state) {
                  if (state is TenantLoading) {
                    return Center(child: AsmitaLoadingIndicator(color: Theme.of(context).colorScheme.primary, size: 28));
                  } else if (state is TenantError) {
                    return Center(
                      child: Text('Error: ${state.message}', style: textTheme.bodyLarge?.copyWith(color: Colors.red)),
                    );
                  } else if (state is TenantLoaded) {
                    final members = state.items;
                    return CustomScrollView(
                      physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                      slivers: [
                        AsmitaAnimatedRefresh(
                          onRefresh: () async {
                            context.read<TenantBloc>().add(const LoadTenant());
                            await Future.delayed(const Duration(milliseconds: 1000));
                          },
                        ),
                        if (members.isEmpty)
                          SliverFillRemaining(
                            child: Center(
                              child: Text(
                                'No Tenants added yet.',
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
                                  return _buildTenantGridCard(context, textTheme, members[index]);
                                },
                                childCount: members.length,
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

  Widget _buildTenantGridCard(BuildContext context, TextTheme textTheme, TenantModel member) {
    return Stack(
      children: [
        GestureDetector(
          onTap: () {
            _showMemberOptions(context, member);
          },
          child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Theme.of(context).dividerColor, 
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.02),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 32,
              backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.08),
              backgroundImage: member.avatarUrl != null && member.avatarUrl!.isNotEmpty 
                  ? NetworkImage(member.avatarUrl!) 
                  : null,
              child: member.avatarUrl == null || member.avatarUrl!.isEmpty
                ? Text(
                    member.name.isNotEmpty ? member.name.substring(0, 1).toUpperCase() : '?', 
                    style: textTheme.headlineSmall?.copyWith(
                      color: Theme.of(context).colorScheme.primary, 
                      fontWeight: FontWeight.bold
                    )
                  )
                : null,
            ),
            SizedBox(height: 12),
            Text(
              member.name, 
              style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: 4),
            Text(
              member.relationship, 
              style: textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).textTheme.bodyMedium?.color,
                fontWeight: FontWeight.normal,
              ),
              textAlign: TextAlign.center,
            ),
            if (member.isEmergencyContact) ...[
              SizedBox(height: 8),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text('Emergency', style: textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.primary, fontSize: 10, fontWeight: FontWeight.w700)),
              ),
            ],
          ],
        ),
      ),
    ),
    ],
    );
  }

  void _onHistoryRequestFabTapped(BuildContext context) {
    final tenantState = context.read<TenantBloc>().state;
    if (tenantState is TenantLoaded) {
      final tenants = tenantState.items;
      final actualTenants = tenants.where((t) => t.id != -1).toList();
      
      if (actualTenants.isEmpty) {
        AsmitaToast.show(context, message: 'No tenants found', type: AsmitaToastType.info);
        return;
      }
      
      if (actualTenants.length == 1) {
        _handleHistoryRequest(context, actualTenants.first);
      } else {
        // Show bottom sheet to select tenant
        showModalBottomSheet(
          context: context,
          backgroundColor: Colors.transparent,
          builder: (context) => Container(
            padding: EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Select Tenant', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
                SizedBox(height: 16),
                ...actualTenants.map((tenant) => CupertinoListTile(
                  title: Text(tenant.name),
                  subtitle: Text(tenant.relationship.isEmpty ? 'Tenant' : tenant.relationship),
                  onTap: () {
                    Navigator.pop(context);
                    _handleHistoryRequest(context, tenant);
                  },
                )),
              ],
            ),
          )
        );
      }
    }
  }

  void _handleHistoryRequest(BuildContext context, TenantModel member) {
    if (member.historyRequestStatus == null) {
      context.read<TenantBloc>().add(RequestTenantHistoryAccess(member.id));
      AsmitaToast.show(context, message: 'Request sent to tenant', type: AsmitaToastType.success);
    } else if (member.historyRequestStatus == 'PENDING') {
      AsmitaToast.show(context, message: 'Request is already pending', type: AsmitaToastType.info);
    } else {
      showCupertinoDialog(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: Text('History Access'),
          content: Text('Access to visitor history is currently approved. Request a new time range?'),
          actions: [
            CupertinoDialogAction(child: Text('Cancel'), onPressed: () => Navigator.pop(context)),
            CupertinoDialogAction(
              child: Text('Request Again'), 
              onPressed: () {
                Navigator.pop(context);
                context.read<TenantBloc>().add(RequestTenantHistoryAccess(member.id));
                AsmitaToast.show(context, message: 'New request sent', type: AsmitaToastType.success);
              }
            ),
          ]
        )
      );
    }
  }

  void _showMemberOptions(BuildContext context, TenantModel member) {
    showCupertinoModalPopup(
      context: context,
      builder: (BuildContext context) => SafeArea(
        child: CupertinoActionSheet(
          title: Text(member.name),
        message: Text('Select an action'),
        actions: <CupertinoActionSheetAction>[
          CupertinoActionSheetAction(
            child: Text('Edit Member'),
            onPressed: () {
              Navigator.pop(context);
              _showAddEditSheet(context, member: member);
            },
          ),
          CupertinoActionSheetAction(
            isDestructiveAction: true,
            onPressed: () {
              Navigator.pop(context);
              _confirmDelete(context, member);
            },
            child: Text('Delete Member'),
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

  void _confirmDelete(BuildContext context, TenantModel member) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text('Delete Member'),
        content: Text('Are you sure you want to remove ${member.name}?'),
        actions: [
          CupertinoDialogAction(
            child: Text('Cancel'),
            onPressed: () => Navigator.pop(context),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            child: Text('Delete'),
            onPressed: () {
              Navigator.pop(context);
              context.read<TenantBloc>().add(DeleteTenant(member.id));
              AsmitaToast.show(context, message: 'Tenant deleted', type: AsmitaToastType.success);
            },
          ),
        ],
      ),
    );
  }

  void _showAddEditSheet(BuildContext context, {TenantModel? member}) {
    final nameCtrl = TextEditingController(text: member?.name ?? '');
    final contactCtrl = TextEditingController(text: member?.contactNumber ?? '');
    String selectedRel = member?.relationship ?? 'Primary Tenant';
    bool isEmergency = member?.isEmergencyContact ?? false;
    bool isLoading = false;
    
    final relationships = ['Primary Tenant', 'Co-Tenant', 'Roommate', 'Family of Tenant', 'Other'];
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
                bottom: MediaQuery.of(context).viewInsets.bottom + MediaQuery.of(context).padding.bottom + 24,
                left: 16,
                right: 16,
                top: 24,
              ),
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(member == null ? 'Add Tenant' : 'Edit Tenant', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(color: Theme.of(context).dividerColor.withValues(alpha: 0.5), shape: BoxShape.circle),
                          child: Icon(CupertinoIcons.xmark, size: 16, color: Theme.of(context).textTheme.bodyLarge?.color),
                        ),
                      )
                    ],
                  ),
                  SizedBox(height: 24),
                  
                  // Name Field
                  Text('FULL NAME', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: Theme.of(context).textTheme.bodyMedium?.color, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
                  SizedBox(height: 8),
                  CupertinoTextField(
                    controller: nameCtrl,
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Theme.of(context).dividerColor),
                    ),
                    placeholder: 'Enter full name',
                    placeholderStyle: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Theme.of(context).dividerColor),
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  
                  SizedBox(height: 20),
                  
                  // Relationship Field
                  Text('RELATIONSHIP', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: Theme.of(context).textTheme.bodyMedium?.color, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
                  SizedBox(height: 8),
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
                                  decoration: BoxDecoration(
                                    color: CupertinoColors.systemGroupedBackground,
                                    border: Border(bottom: BorderSide(color: Theme.of(context).dividerColor, width: 0.5)),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      CupertinoButton(
                                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                        onPressed: () => Navigator.of(context).pop(),
                                        child: Text('Done', style: TextStyle(fontWeight: FontWeight.bold)),
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
                                            color: Theme.of(context).textTheme.bodyLarge?.color,
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
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Theme.of(context).dividerColor),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(selectedRel, style: Theme.of(context).textTheme.bodyLarge),
                          Icon(CupertinoIcons.chevron_down, size: 18, color: Theme.of(context).textTheme.bodyMedium?.color),
                        ],
                      ),
                    ),
                  ),
                  
                  SizedBox(height: 20),

                  // Contact Number Field
                  Text('CONTACT NUMBER', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: Theme.of(context).textTheme.bodyMedium?.color, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
                  SizedBox(height: 8),
                  CupertinoTextField(
                    controller: contactCtrl,
                    keyboardType: TextInputType.phone,
                    maxLength: 10,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Theme.of(context).dividerColor),
                    ),
                    placeholder: 'Enter contact number',
                    placeholderStyle: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Theme.of(context).dividerColor),
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  
                  SizedBox(height: 20),
                  
                  // Emergency Contact Switch
                  Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Theme.of(context).dividerColor),
                    ),
                    child: CupertinoListTile(
                      title: Text('Set as Emergency Contact', style: Theme.of(context).textTheme.bodyLarge),
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      trailing: CupertinoSwitch(
                        value: isEmergency,
                        activeTrackColor: Theme.of(context).colorScheme.primary,
                        onChanged: (val) => setState(() => isEmergency = val),
                      ),
                    ),
                  ),

                  SizedBox(height: 32),
                  
                  // Save Button
                  SizedBox(
                    width: double.infinity,
                    child: CupertinoButton(
                      color: Theme.of(context).colorScheme.primary,
                      borderRadius: BorderRadius.circular(12),
                      padding: EdgeInsets.symmetric(vertical: 16),
                      onPressed: () async {
                        if (isLoading) return;
                        final name = nameCtrl.text.trim();
                        final contact = contactCtrl.text.trim();
                        
                        if (name.isEmpty || contact.isEmpty) return;
                        
                        if (!RegExp(r'^[0-9]{10}$').hasMatch(contact)) {
                          showCupertinoDialog(
                            context: context,
                            builder: (ctx) => CupertinoAlertDialog(
                              title: Text('Invalid Number'),
                              content: Text('Please enter a valid 10-digit contact number.'),
                              actions: [
                                CupertinoDialogAction(
                                  child: Text('OK'),
                                  onPressed: () => Navigator.pop(ctx),
                                ),
                              ],
                            ),
                          );
                          return;
                        }

                        final bloc = context.read<TenantBloc>();
                        
                        setState(() => isLoading = true);
                        
                        if (member == null) {
                          bloc.add(AddTenant(
                            name: name, 
                            relationship: selectedRel, 
                            contactNumber: contact,
                            isEmergencyContact: isEmergency
                          ));
                        } else {
                          bloc.add(UpdateTenant(
                            id: member.id, 
                            name: name, 
                            relationship: selectedRel, 
                            contactNumber: contact,
                            isEmergencyContact: isEmergency
                          ));
                        }
                        
                        await Future.delayed(const Duration(milliseconds: 500));
                        if (context.mounted) {
                          setState(() => isLoading = false);
                          AsmitaToast.show(
                            context,
                            message: member == null ? 'Tenant saved successfully!' : 'Tenant updated successfully!',
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
                          : Text(member == null ? 'Save Tenant' : 'Update Tenant', style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.surface)),
                    ),
                  ),
                ],
              ),
              ),
            );
          }
        );
      }
    );
  }
}
