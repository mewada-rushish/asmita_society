import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/design_system.dart';
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
      backgroundColor: Colors.white,
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
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AsmitaPalette.deepNavy, size: 20),
                    onPressed: widget.onBack,
                  ),
                  Expanded(
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: AsmitaPalette.systemBG,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AsmitaPalette.borderGrey, width: 1.2),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Row(
                        children: [
                          const Icon(Icons.search_rounded, color: AsmitaPalette.textLight, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              controller: _searchController,
                              autofocus: true,
                              textInputAction: TextInputAction.search,
                              onSubmitted: _executeSearch,
                              style: const TextStyle(fontFamily: 'Poppins', fontSize: 14, color: AsmitaPalette.textDark),
                              decoration: const InputDecoration(
                                hintText: 'Search services, utilities or logs...',
                                hintStyle: TextStyle(color: AsmitaPalette.textLight, fontSize: 13, fontWeight: FontWeight.w400),
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
                              child: const Icon(Icons.cancel_rounded, color: AsmitaPalette.textLight, size: 18),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            const Divider(color: AsmitaPalette.borderGrey, height: 1),

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
        const Text(
          'Recent Searches',
          style: TextStyle(
            fontFamily: 'Montserrat',
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AsmitaPalette.deepNavy,
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
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: AsmitaPalette.borderGrey, width: 1.2),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.history_rounded, color: AsmitaPalette.textLight, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      item,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AsmitaPalette.textDark,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 32),
        const Text(
          'Search in?',
          style: TextStyle(
            fontFamily: 'Montserrat',
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AsmitaPalette.deepNavy,
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
                  color: isSelected ? AsmitaPalette.deepNavy : Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color: isSelected ? AsmitaPalette.deepNavy : AsmitaPalette.borderGrey, 
                    width: 1.2,
                  ),
                ),
                child: Text(
                  item,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected ? Colors.white : AsmitaPalette.textDark,
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
          return const Center(
            child: CircularProgressIndicator(color: AsmitaPalette.actionRed),
          );
        }

        if (state is SearchError) {
          return Center(
            child: Text(
              state.message,
              style: const TextStyle(
                fontFamily: 'Montserrat',
                color: AsmitaPalette.actionRed,
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
                  color: const Color(0xFFF0EDFF),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AsmitaPalette.deepNavy.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.info_outline_rounded, color: AsmitaPalette.deepNavy, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Searched for "$_currentSearchQuery" in $_selectedModule',
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: AsmitaPalette.deepNavy,
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
                const Center(
                  child: Padding(
                    padding: EdgeInsets.only(top: 40),
                    child: Text(
                      'No results found',
                      style: TextStyle(
                        fontFamily: 'Montserrat',
                        color: AsmitaPalette.textLight,
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
                  } else {
                    // Fallback generic card for other modules
                    final title = rawItem['title'] ?? rawItem['visitor_name'] ?? rawItem['sender_name'] ?? 'Result';
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AsmitaPalette.borderGrey),
                      ),
                      child: Text(
                        title.toString(),
                        style: const TextStyle(fontFamily: 'Montserrat', fontWeight: FontWeight.w600),
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