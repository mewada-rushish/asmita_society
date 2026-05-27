import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/design_system.dart';
import '../../../core/security/secure_storage_service.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../auth/presentation/login_screen.dart';
import '../../auth/data/repositories/auth_repository.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  int _currentPage = 0;

  final List<Map<String, dynamic>> _slides = [
    {
      'title': 'Smart IoT Access',
      'description': 'Control your home lighting, secure digital locks, and manage hardware directly from your device.',
      'icon': Icons.home_repair_service_rounded,
    },
    {
      'title': 'High-Assurance Security',
      'description': 'Approve live visitor entries and pre-authorize guests with secure, time-bound QR codes.',
      'icon': Icons.security_rounded,
    },
    {
      'title': 'Seamless ERP & BBPS',
      'description': 'View maintenance ledgers and clear utility bills instantly through the integrated payment system.',
      'icon': Icons.account_balance_wallet_rounded,
    },
  ];

  /// Persists onboarding completion flag and transitions to the authenticated routing tree
  Future<void> _completeOnboarding() async {
    await _secureStorage.write(key: 'has_seen_onboarding', value: 'true');
    if (!mounted) return;
    
    // Initialize dependency singletons for the authentication flow
    final authRepository = AuthRepository();
    final secureStorageService = SecureStorageService();

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => BlocProvider(
          create: (context) => AuthBloc(
            authRepository: authRepository,
            secureStorage: secureStorageService,
          ),
          child: const LoginScreen(),
        ),
      ),
    );
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
      backgroundColor: AsmitaPalette.systemBG,
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.only(
              top: topPadding > 0 ? topPadding + 8.0 : 24.0, 
              right: 16.0, 
              bottom: 8.0
            ),
            child: Align(
              alignment: Alignment.topRight,
              child: TextButton(
                onPressed: _completeOnboarding,
                child: Text(
                  'Skip',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: AsmitaPalette.deepNavy,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
          
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              physics: const BouncingScrollPhysics(),
              onPageChanged: (index) {
                setState(() => _currentPage = index);
              },
              itemCount: _slides.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _slides[index]['icon'],
                        size: 140,
                        color: AsmitaPalette.actionRed,
                      ),
                      const SizedBox(height: 64),
                      Text(
                        _slides[index]['title'],
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: AsmitaPalette.deepNavy,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _slides[index]['description'],
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Colors.grey.shade600,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          
          Padding(
            padding: EdgeInsets.only(
              left: 24.0, 
              right: 24.0, 
              bottom: bottomPadding > 0 ? bottomPadding + 16.0 : 32.0, 
              top: 16.0
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                AnimatedOpacity(
                  opacity: _currentPage == 0 ? 0.0 : 1.0,
                  duration: const Duration(milliseconds: 300),
                  child: IconButton(
                    onPressed: _currentPage == 0 ? null : _previousPage,
                    icon: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: AsmitaPalette.deepNavy,
                    ),
                    splashRadius: 24,
                  ),
                ),
                Row(
                  children: List.generate(
                    _slides.length,
                    (index) => _buildAnimatedDot(index),
                  ),
                ),
                GestureDetector(
                  onTap: _nextPage,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    height: 56,
                    width: 56,
                    decoration: const BoxDecoration(
                      color: AsmitaPalette.deepNavy,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _currentPage == _slides.length - 1 
                          ? Icons.check_rounded 
                          : Icons.arrow_forward_ios_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedDot(int index) {
    final isActive = _currentPage == index;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 4.0),
      height: 8,
      width: isActive ? 24 : 8,
      decoration: BoxDecoration(
        color: isActive ? AsmitaPalette.actionRed : Colors.grey.shade300,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}