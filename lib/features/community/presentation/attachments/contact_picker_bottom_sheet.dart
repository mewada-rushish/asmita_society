import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:asmita_society/core/widgets/asmita_loading_indicator.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../bloc/community_bloc.dart';
import '../../bloc/community_event.dart';

class ContactPickerBottomSheet extends StatefulWidget {
  const ContactPickerBottomSheet({super.key});

  @override
  State<ContactPickerBottomSheet> createState() => _ContactPickerBottomSheetState();
}

class _ContactPickerBottomSheetState extends State<ContactPickerBottomSheet> {
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

    context.read<CommunityBloc>().add(SendContactMessage(name, phone));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return SizedBox(
        height: 200,
        child: Center(
          child: AsmitaLoadingIndicator(color: Theme.of(context).colorScheme.primary, size: 28),
        ),
      );
    }

    if (_permissionDenied) {
      return SizedBox(
        height: 200,
        child: Center(
          child: Text(
            'Contact permissions are required.',
            style: TextStyle(fontFamily: 'Poppins', color: Theme.of(context).textTheme.bodyLarge?.color),
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
            style: TextStyle(fontFamily: 'Poppins', fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Search contacts...',
              prefixIcon: Icon(Icons.search_rounded, color: Theme.of(context).colorScheme.primary),
              contentPadding: EdgeInsets.symmetric(vertical: 12),
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
                borderSide: BorderSide(color: Theme.of(context).colorScheme.primary),
              ),
            ),
          ),
          SizedBox(height: 16),
          if (_filteredContacts.isEmpty)
            Expanded(
              child: Center(
                child: Text(
                  'No contacts found.',
                  style: TextStyle(fontFamily: 'Poppins', color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.38)),
                ),
              ),
            )
          else
            Expanded(
              child: ListView.separated(
                physics: const BouncingScrollPhysics(),
                itemCount: _filteredContacts.length,
                separatorBuilder: (context, index) => Divider(color: Theme.of(context).dividerColor, height: 1),
                itemBuilder: (context, index) {
                  final contact = _filteredContacts[index];
                  final initial = (contact.displayName?.isNotEmpty ?? false) ? contact.displayName![0].toUpperCase() : '?';
                  final phone = contact.phones.isNotEmpty ? contact.phones.first.number : '';

                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                      child: Text(
                        initial,
                        style: TextStyle(
                          fontFamily: 'Montserrat',
                          fontWeight: FontWeight.w700,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                    title: Text(
                      contact.displayName ?? "",
                      style: TextStyle(
                        fontFamily: 'Montserrat',
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      phone,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12,
                        color: Theme.of(context).textTheme.bodyMedium?.color,
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
