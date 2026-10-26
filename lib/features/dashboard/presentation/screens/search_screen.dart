import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/widgets/asmita_loading_indicator.dart';
import '../../../../features/auth/bloc/auth_bloc.dart';
import '../../../../features/auth/bloc/auth_state.dart';
import '../../bloc/search/search_bloc.dart';
import '../../bloc/search/search_event.dart';
import '../../bloc/search/search_state.dart';
import '../../../visitor_management/utils/visitor_utils.dart';
import '../../../visitor_management/presentation/widgets/visitor_card.dart';

class AsmitaSearchScreen extends StatefulWidget {
  final VoidCallback? onBack;
  final Function(int)? onQuickRedirect;

  const AsmitaSearchScreen({
    super.key,
    this.onBack,
    this.onQuickRedirect,
  });

  @override
  State<AsmitaSearchScreen> createState() => _AsmitaSearchScreenState();
}

class _AsmitaSearchScreenState extends State<AsmitaSearchScreen> {
  final TextEditingController _searchController = TextEditingController();

  final List<String> _recentSearches = ['Amazon', 'Plumber', 'A-204'];
  final List<String> _searchModules = ['Gate Records', 'Community', 'Services', 'Users'];
  
  String _selectedModule = 'Gate Records';
  bool _hasSearched = false;
  String _currentSearchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _executeSearch(String query) {
    if (query.trim().isEmpty) return;
    setState(() {
      _currentSearchQuery = query.trim();
      _hasSearched = true;
      if (!_recentSearches.contains(_currentSearchQuery)) {
        _recentSearches.insert(0, _currentSearchQuery);
        if (_recentSearches.length > 3) _recentSearches.removeLast();
      }
    });

    context.read<SearchBloc>().add(SearchInitiated(
      query: _currentSearchQuery,
      module: _selectedModule,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search Input Row Container Block
            Padding(
              padding: const EdgeInsets.only(left: 12, right: 16, top: 12, bottom: 16),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back_ios_new_rounded, color: Theme.of(context).colorScheme.primary, size: 20),
                    onPressed: () {
                      if (widget.onBack != null) {
                        widget.onBack!();
                      } else {
                        Navigator.of(context).maybePop();
                      }
                    },
                  ),
                  Expanded(
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceContainer,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Theme.of(context).dividerColor, width: 1.2),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Row(
                        children: [
                          Icon(Icons.search_rounded, color: Theme.of(context).iconTheme.color, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              controller: _searchController,
                              autofocus: true,
                              textInputAction: TextInputAction.search,
                              onSubmitted: _executeSearch,
                              style: TextStyle(fontFamily: 'Poppins', fontSize: 14, color: Theme.of(context).textTheme.bodyLarge?.color),
                              decoration: InputDecoration(
                                hintText: 'Search services, utilities or logs...',
                                hintStyle: TextStyle(color: Theme.of(context).hintColor, fontSize: 13, fontWeight: FontWeight.w400),
                                border: InputBorder.none,
                                isDense: true,
                              ),
                            ),
                          ),
                          if (_searchController.text.isNotEmpty)
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  _searchController.clear();
                                  _hasSearched = false;
                                });
                                context.read<SearchBloc>().add(SearchCleared());
                              },
                              child: Icon(Icons.cancel_rounded, color: Theme.of(context).iconTheme.color, size: 18),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            Divider(color: Theme.of(context).dividerColor, height: 1),

            Expanded(
              child: _hasSearched ? _buildSearchResults() : _buildSearchInitialState(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchInitialState() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          'Recent Searches',
          style: TextStyle(
            fontFamily: 'Montserrat',
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 10,
          runSpacing: 12,
          children: _recentSearches.map((item) {
            return InkWell(
              onTap: () {
                _searchController.text = item;
                _executeSearch(item);
              },
              borderRadius: BorderRadius.circular(30),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: Theme.of(context).dividerColor, width: 1.2),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.history_rounded, color: Theme.of(context).iconTheme.color, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      item,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 32),
        Text(
          'Search in?',
          style: TextStyle(
            fontFamily: 'Montserrat',
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 10,
          runSpacing: 12,
          children: _searchModules.map((item) {
            final isSelected = _selectedModule == item;
            return InkWell(
              onTap: () {
                setState(() {
                  _selectedModule = item;
                });
              },
              borderRadius: BorderRadius.circular(30),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color: isSelected ? Theme.of(context).colorScheme.primary : Theme.of(context).dividerColor, 
                    width: 1.2,
                  ),
                ),
                child: Text(
                  item,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected ? Colors.white : Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildSearchResults() {
    return BlocBuilder<SearchBloc, SearchState>(
      builder: (context, state) {
        if (state is SearchLoading) {
          return Center(
            child: AsmitaLoadingIndicator(color: Theme.of(context).colorScheme.secondary, size: 28),
          );
        }

        if (state is SearchError) {
          return Center(
            child: Text(
              state.message,
              style: TextStyle(
                fontFamily: 'Montserrat',
                color: Theme.of(context).colorScheme.secondary,
              ),
            ),
          );
        }

        if (state is SearchLoaded) {
          final results = state.results;

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.info_outline_rounded, color: Theme.of(context).colorScheme.primary, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Searched for "$_currentSearchQuery" in $_selectedModule',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              if (results.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 40),
                    child: Text(
                      'No results found',
                      style: TextStyle(
                        fontFamily: 'Montserrat',
                        color: Theme.of(context).textTheme.bodySmall?.color,
                      ),
                    ),
                  ),
                )
              else
                ...results.map((rawItem) {
                  if (_selectedModule == 'Gate Records') {
                    final authState = context.read<AuthBloc>().state;
                    String currentUserName = 'Resident';
                    if (authState is AuthAuthenticated) {
                      currentUserName = authState.user.fullName;
                    }
                    final item = VisitorUtils.normalizeItem(rawItem, currentUserName);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: VisitorHistoryCard(item: item),
                    );
                  } else if (_selectedModule == 'Users') {
                    final name = rawItem['full_name'] ?? rawItem['name'] ?? 'Staff Member';
                    final phone = (rawItem['mobile_number'] ?? rawItem['phone'] ?? '').toString();
                    
                    // Parse extension and role from role_details JSON or direct fields
                    dynamic roleDetails = rawItem['role_details'];
                    String ext = '';
                    String designation = rawItem['primary_role'] ?? rawItem['role'] ?? 'Staff';
                    String department = rawItem['department_name'] ?? rawItem['department'] ?? '';
                    
                    if (roleDetails is Map) {
                      ext = (roleDetails['extension'] ?? roleDetails['ext'] ?? '').toString();
                      if (roleDetails['designation'] != null) {
                        designation = roleDetails['designation'].toString();
                      }
                      if (roleDetails['department'] != null && department.isEmpty) {
                        department = roleDetails['department'].toString();
                      }
                    }
                    if (ext.isEmpty) {
                      ext = (rawItem['extension'] ?? rawItem['ext'] ?? '').toString();
                    }

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Theme.of(context).dividerColor),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.02),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 20,
                            backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                            child: Text(
                              name.isNotEmpty ? name[0].toUpperCase() : 'U',
                              style: TextStyle(
                                fontFamily: 'Montserrat',
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  name.toString(),
                                  style: const TextStyle(
                                    fontFamily: 'Montserrat',
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13.5,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  department.isNotEmpty ? '$designation • $department' : designation,
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 11,
                                    color: Theme.of(context).textTheme.bodySmall?.color,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 6),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 4,
                                  children: [
                                    if (ext.isNotEmpty)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.08),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.dialer_sip_rounded,
                                              size: 10,
                                              color: Theme.of(context).colorScheme.primary,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              'Ext: $ext',
                                              style: TextStyle(
                                                fontFamily: 'Montserrat',
                                                fontSize: 10,
                                                fontWeight: FontWeight.w700,
                                                color: Theme.of(context).colorScheme.primary,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    if (phone.isNotEmpty)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Theme.of(context).dividerColor.withValues(alpha: 0.2),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.phone_iphone_rounded,
                                              size: 10,
                                              color: Theme.of(context).textTheme.bodySmall?.color,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              phone,
                                              style: TextStyle(
                                                fontFamily: 'Montserrat',
                                                fontSize: 10,
                                                fontWeight: FontWeight.w600,
                                                color: Theme.of(context).textTheme.bodySmall?.color,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          if (phone.isNotEmpty)
                            IconButton(
                              onPressed: () async {
                                final uri = Uri.parse('tel:$phone');
                                if (await canLaunchUrl(uri)) {
                                  await launchUrl(uri);
                                }
                              },
                              icon: const Icon(
                                Icons.phone_in_talk_rounded,
                                size: 18,
                                color: Color(0xFF10B981),
                              ),
                              style: IconButton.styleFrom(
                                backgroundColor: const Color(0xFF10B981).withValues(alpha: 0.12),
                                padding: const EdgeInsets.all(8),
                              ),
                            ),
                        ],
                      ),
                    );
                  } else {
                    // Fallback card for Services & Community
                    final title = rawItem['name'] ?? rawItem['title'] ?? rawItem['visitor_name'] ?? rawItem['sender_name'] ?? 'Result';
                    final subtitle = rawItem['description'] ?? rawItem['message'] ?? rawItem['subtitle'] ?? '';
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Theme.of(context).dividerColor),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title.toString(),
                            style: const TextStyle(fontFamily: 'Montserrat', fontWeight: FontWeight.w600, fontSize: 13.5),
                          ),
                          if (subtitle.toString().isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              subtitle.toString(),
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 11.5,
                                color: Theme.of(context).textTheme.bodySmall?.color,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    );
                  }
                }),
            ],
          );
        }

        return const SizedBox.shrink();
      },
    );
  }
}