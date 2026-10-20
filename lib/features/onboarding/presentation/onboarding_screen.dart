import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/design_system.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../auth/bloc/auth_event.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, dynamic>> _slides = const [
    {
      'title': 'Smart IoT Access',
      'subtitle': 'Enterprise & Society Automation',
      'description':
          'Control your premises lighting, secure digital smart locks, and monitor hardware directly from your device.',
      'icon': Icons.home_repair_service_rounded,
    },
    {
      'title': 'High-Assurance Security',
      'subtitle': 'Gate-Sync & Visitor Logs',
      'description':
          'Approve live visitor entries, track vehicle movement, and pre-authorize guests with secure, time-bound QR codes.',
      'icon': Icons.security_rounded,
    },
    {
      'title': 'Seamless ERP & BBPS',
      'subtitle': 'Operations & Ledgers',
      'description':
          'View maintenance ledgers, track service requests, and clear utility bills instantly through the integrated payment system.',
      'icon': Icons.account_balance_wallet_rounded,
    },
  ];

  /// Persists onboarding completion flag and transitions to the authenticated routing tree
  Future<void> _completeOnboarding() async {
    final authBloc = context.read<AuthBloc>();
    try {
      await authBloc.secureStorage.write(
            key: 'has_seen_onboarding',
            value: 'true',
          );
    } catch (_) {}

    if (mounted) {
      authBloc.add(AuthCheckRequested());
    }
  }

  void _nextPage() {
    if (_currentPage == _slides.length - 1) {
      _completeOnboarding();
    } else {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
      );
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.paddingOf(context).bottom;
    final topPadding = MediaQuery.paddingOf(context).top;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        top: false,
        bottom: false,
        child: Column(
          children: [
            // Top Bar with Skip capsule
            Padding(
              padding: EdgeInsets.only(
                top: topPadding > 0 ? topPadding + 8.0 : 24.0,
                right: 20.0,
                left: 20.0,
                bottom: 8.0,
              ),
              child: Align(
                alignment: Alignment.topRight,
                child: InkWell(
                  onTap: _completeOnboarding,
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                    decoration: BoxDecoration(
                      color: AsmitaPalette.deepNavy.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AsmitaPalette.deepNavy.withValues(alpha: 0.12),
                        width: 1,
                      ),
                    ),
                    child: const Text(
                      'Skip',
                      style: TextStyle(
                        fontFamily: 'Montserrat',
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AsmitaPalette.deepNavy,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Middle Carousel Slides
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                physics: const BouncingScrollPhysics(),
                onPageChanged: (index) {
                  setState(() => _currentPage = index);
                },
                itemCount: _slides.length,
                itemBuilder: (context, index) {
                  final slide = _slides[index];
                  return LayoutBuilder(
                    builder: (context, constraints) {
                      return SingleChildScrollView(
                        physics: const ClampingScrollPhysics(),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minHeight: constraints.maxHeight,
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 32.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const SizedBox(height: 16),
                                // Hero Icon Container
                                Container(
                                  width: 130,
                                  height: 130,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        AsmitaPalette.deepNavy.withValues(alpha: 0.06),
                                        AsmitaPalette.deepNavy.withValues(alpha: 0.14),
                                      ],
                                    ),
                                    border: Border.all(
                                      color: AsmitaPalette.deepNavy.withValues(alpha: 0.2),
                                      width: 2,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AsmitaPalette.deepNavy.withValues(alpha: 0.04),
                                        blurRadius: 16,
                                        offset: const Offset(0, 8),
                                      ),
                                    ],
                                  ),
                                  child: Center(
                                    child: Icon(
                                      slide['icon'] as IconData,
                                      size: 58,
                                      color: AsmitaPalette.deepNavy,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 36),
                                // Subtitle badge
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AsmitaPalette.deepNavy.withValues(alpha: 0.06),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    (slide['subtitle'] as String).toUpperCase(),
                                    style: const TextStyle(
                                      fontFamily: 'Montserrat',
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: AsmitaPalette.deepNavy,
                                      letterSpacing: 0.8,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                // Main Title
                                Text(
                                  slide['title'] as String,
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                        fontFamily: 'Montserrat',
                                        fontWeight: FontWeight.w800,
                                        color: AsmitaPalette.deepNavy,
                                        letterSpacing: -0.5,
                                      ),
                                ),
                                const SizedBox(height: 16),
                                // Description
                                Text(
                                  slide['description'] as String,
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                        fontFamily: 'Poppins',
                                        color: const Color(0xFF64748B),
                                        height: 1.6,
                                        fontSize: 14,
                                      ),
                                ),
                                const SizedBox(height: 24),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),

            // Bottom Navigation Bar with Dots & Next / Get Started Action
            Padding(
              padding: EdgeInsets.only(
                left: 24.0,
                right: 24.0,
                bottom: bottomPadding > 0 ? bottomPadding + 16.0 : 32.0,
                top: 16.0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Back Button (hidden on first page)
                  AnimatedOpacity(
                    opacity: _currentPage == 0 ? 0.0 : 1.0,
                    duration: const Duration(milliseconds: 300),
                    child: InkWell(
                      onTap: _currentPage == 0 ? null : _previousPage,
                      borderRadius: BorderRadius.circular(24),
                      child: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AsmitaPalette.deepNavy.withValues(alpha: 0.15),
                            width: 1.5,
                          ),
                        ),
                        child: const Icon(
                          Icons.arrow_back_ios_new_rounded,
                          size: 18,
                          color: AsmitaPalette.deepNavy,
                        ),
                      ),
                    ),
                  ),

                  // Animated Page Indicator Dots
                  Row(
                    children: List.generate(
                      _slides.length,
                      (index) => _buildAnimatedDot(index),
                    ),
                  ),

                  // Next / Get Started Dynamic Pill Button
                  InkWell(
                    onTap: _nextPage,
                    borderRadius: BorderRadius.circular(28),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOutCubic,
                      height: 54,
                      width: _currentPage == _slides.length - 1 ? 144 : 54,
                      clipBehavior: Clip.antiAlias,
                      decoration: BoxDecoration(
                        color: AsmitaPalette.deepNavy,
                        borderRadius: BorderRadius.circular(27),
                        boxShadow: [
                          BoxShadow(
                            color: AsmitaPalette.deepNavy.withValues(alpha: 0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Center(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 14.0),
                            child: _currentPage == _slides.length - 1
                                ? const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        'Get Started',
                                        style: TextStyle(
                                          fontFamily: 'Montserrat',
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white,
                                          fontSize: 13,
                                          letterSpacing: 0.3,
                                        ),
                                      ),
                                      SizedBox(width: 6),
                                      Icon(
                                        Icons.arrow_forward_rounded,
                                        color: Colors.white,
                                        size: 18,
                                      ),
                                    ],
                                  )
                                : const Icon(
                                    Icons.arrow_forward_ios_rounded,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedDot(int index) {
    final isActive = _currentPage == index;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 4.0),
      height: 8,
      width: isActive ? 28 : 8,
      decoration: BoxDecoration(
        color: isActive ? AsmitaPalette.deepNavy : const Color(0xFFCBD5E1),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}