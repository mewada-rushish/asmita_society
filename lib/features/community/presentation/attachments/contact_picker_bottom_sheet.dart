import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:asmita_society/core/constants/design_system.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/community_provider.dart';

class ContactPickerBottomSheet extends ConsumerStatefulWidget {
  const ContactPickerBottomSheet({super.key});

  @override
  ConsumerState<ContactPickerBottomSheet> createState() => _ContactPickerBottomSheetState();
}

class _ContactPickerBottomSheetState extends ConsumerState<ContactPickerBottomSheet> {
  List<Contact> _contacts = [];
  List<Contact> _filteredContacts = [];
  bool _isLoading = true;
  bool _permissionDenied = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchContacts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchContacts() async {
    final status = await Permission.contacts.request();
    if (status.isGranted) {
      final contacts = await FlutterContacts.getAll(properties: {ContactProperty.phone});
      
      // Filter out contacts without a phone number
      final validContacts = contacts.where((c) => c.phones.isNotEmpty).toList();
      
      // Sort alphabetically
      validContacts.sort((a, b) => (a.displayName ?? "").compareTo(b.displayName ?? ""));

      if (mounted) {
        setState(() {
          _contacts = validContacts;
          _filteredContacts = validContacts;
          _isLoading = false;
        });
      }
    } else {
      if (mounted) {
        setState(() {
          _permissionDenied = true;
          _isLoading = false;
        });
      }
    }
  }

  void _filterContacts(String query) {
    if (query.isEmpty) {
      setState(() {
        _filteredContacts = _contacts;
      });
      return;
    }

    final lowerQuery = query.toLowerCase();
    setState(() {
      _filteredContacts = _contacts.where((contact) {
        final nameMatch = (contact.displayName ?? "").toLowerCase().contains(lowerQuery);
        final phoneMatch = contact.phones.any((p) => p.number.replaceAll(RegExp(r'\D'), '').contains(lowerQuery));
        return nameMatch || phoneMatch;
      }).toList();
    });
  }

  void _onContactSelected(Contact contact) {
    if (contact.phones.isEmpty) return;

    // We take the first phone number for simplicity, formatted cleanly.
    final name = contact.displayName ?? "";
    final phone = contact.phones.first.number;

    ref.read(communityProvider.notifier).sendContactMessage(name, phone);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SizedBox(
        height: 200,
        child: Center(
          child: CircularProgressIndicator(color: AsmitaPalette.deepNavy),
        ),
      );
    }

    if (_permissionDenied) {
      return const SizedBox(
        height: 200,
        child: Center(
          child: Text(
            'Contact permissions are required.',
            style: TextStyle(fontFamily: 'Poppins', color: AsmitaPalette.textDark),
          ),
        ),
      );
    }

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.7),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _searchController,
            onChanged: _filterContacts,
            style: const TextStyle(fontFamily: 'Poppins', fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Search contacts...',
              prefixIcon: const Icon(Icons.search_rounded, color: AsmitaPalette.deepNavy),
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AsmitaPalette.deepNavy),
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (_filteredContacts.isEmpty)
            const Expanded(
              child: Center(
                child: Text(
                  'No contacts found.',
                  style: TextStyle(fontFamily: 'Poppins', color: Colors.black38),
                ),
              ),
            )
          else
            Expanded(
              child: ListView.separated(
                physics: const BouncingScrollPhysics(),
                itemCount: _filteredContacts.length,
                separatorBuilder: (context, index) => const Divider(color: AsmitaPalette.borderGrey, height: 1),
                itemBuilder: (context, index) {
                  final contact = _filteredContacts[index];
                  final initial = (contact.displayName?.isNotEmpty ?? false) ? contact.displayName![0].toUpperCase() : '?';
                  final phone = contact.phones.isNotEmpty ? contact.phones.first.number : '';

                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      backgroundColor: AsmitaPalette.deepNavy.withValues(alpha: 0.1),
                      child: Text(
                        initial,
                        style: const TextStyle(
                          fontFamily: 'Montserrat',
                          fontWeight: FontWeight.w700,
                          color: AsmitaPalette.deepNavy,
                        ),
                      ),
                    ),
                    title: Text(
                      contact.displayName ?? "",
                      style: const TextStyle(
                        fontFamily: 'Montserrat',
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: AsmitaPalette.textDark,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      phone,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12,
                        color: AsmitaPalette.textLight,
                      ),
                    ),
                    onTap: () => _onContactSelected(contact),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
