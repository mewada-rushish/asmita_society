import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/design_system.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';
import 'otp_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _phoneController = TextEditingController();
  bool _isValid = false;
  bool _isDirty = false;

  @override
  void initState() {
    super.initState();
    _phoneController.addListener(() {
      setState(() {
        _isDirty = _phoneController.text.isNotEmpty;
        _isValid = _phoneController.text.length == 10;
      });
    });
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  void _submitPhone() {
    if (_isValid) {
      FocusScope.of(context).unfocus();
      context.read<AuthBloc>().add(SendOtpRequested(_phoneController.text));
    }
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.paddingOf(context).top;
    final bottomPadding = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      backgroundColor: AsmitaPalette.deepNavy, 
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthOtpSent) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => BlocProvider.value(
                  value: context.read<AuthBloc>(),
                  child: OtpScreen(phoneNumber: state.phoneNumber),
                ),
              ),
            );
          } else if (state is AuthError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AsmitaPalette.actionRed,
              ),
            );
          }
        },
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.only(top: topPadding + 30.0, bottom: 30.0),
              child: Center(
                child: Image.asset(
                  'assets/images/lock_icon.png', 
                  height: 225, 
                  width: 225,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(Icons.lock_rounded, color: Colors.white, size: 180);
                  },
                ),
              ),
            ),
            Expanded(
              child: Stack(
                children: [
                  Positioned(
                    top: 0,
                    left: 24,
                    right: 24,
                    bottom: 0,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.4), 
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 12, 
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: Container(
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 48),
                            Text(
                              'Welcome Back!',
                              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                color: Colors.black,
                                fontWeight: FontWeight.w800, 
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Please enter your phone number or email address\nand continue my asmita app.',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Colors.grey.shade500,
                                height: 1.5,
                              ),
                            ),
                            const SizedBox(height: 40),
                            Text(
                              'Phone Number',
                              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                color: AsmitaPalette.deepNavy,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: _isDirty && !_isValid ? AsmitaPalette.actionRed : Colors.grey.shade300,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Text('🇮🇳', style: TextStyle(fontSize: 20)),
                                        const SizedBox(width: 8),
                                        Text(
                                          '+91',
                                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                            color: Colors.black87,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.black87, size: 20),
                                        const SizedBox(width: 16),
                                        Container(height: 24, width: 1, color: Colors.grey.shade300),
                                      ],
                                    ),
                                  ),
                                  Expanded(
                                    child: TextField(
                                      controller: _phoneController,
                                      keyboardType: TextInputType.phone,
                                      inputFormatters: [
                                        FilteringTextInputFormatter.digitsOnly,
                                        LengthLimitingTextInputFormatter(10),
                                      ],
                                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                        color: Colors.black87,
                                      ),
                                      decoration: const InputDecoration(
                                        border: InputBorder.none,
                                        contentPadding: EdgeInsets.symmetric(vertical: 16),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (_isDirty && !_isValid)
                              Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Text(
                                  'Incorrect mobile number*',
                                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: AsmitaPalette.actionRed,
                                  ),
                                ),
                              ),
                            const Spacer(),
                            BlocBuilder<AuthBloc, AuthState>(
                              builder: (context, state) {
                                final isLoading = state is AuthLoading;
                                return Padding(
                                  padding: EdgeInsets.only(
                                    bottom: bottomPadding > 0 ? bottomPadding + 16.0 : 32.0,
                                  ),
                                  child: SizedBox(
                                    width: double.infinity,
                                    height: 56,
                                    child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: _isValid ? AsmitaPalette.actionRed : Colors.grey.shade300,
                                        elevation: 0,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(16),
                                        ),
                                      ),
                                      onPressed: isLoading || !_isValid ? null : _submitPhone,
                                      child: isLoading 
                                        ? const SizedBox(
                                            height: 24, 
                                            width: 24, 
                                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5)
                                          )
                                        : Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Text(
                                                'Login',
                                                style: TextStyle(
                                                  color: _isValid ? Colors.white : Colors.grey.shade500,
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Icon(Icons.arrow_forward_rounded, color: _isValid ? Colors.white : Colors.grey.shade500, size: 20),
                                            ],
                                          ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
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
}