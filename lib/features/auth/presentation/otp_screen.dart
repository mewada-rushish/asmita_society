import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// Adjusted relative paths based on your folder structure
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';

class OtpScreen extends StatefulWidget {
  final String phoneNumber;

  const OtpScreen({super.key, required this.phoneNumber});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final TextEditingController _otpController = TextEditingController();

  void _verifyOtp() {
    final otp = _otpController.text.trim();
    if (otp.length == 6) {
      // Dispatch the updated production verification event
      context.read<AuthBloc>().add(
        AuthVerifyRequested(mobile: widget.phoneNumber, otp: otp)
      );
    }
  }

  void _resendOtp() {
    // Re-dispatch the initialization event to resend the SMS
    context.read<AuthBloc>().add(
      AuthInitiateRequested(mobile: widget.phoneNumber)
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Verify Identity')),
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          // Listen for the new AuthAuthenticated state
          if (state is AuthAuthenticated) {
            
            // Extract the role from the secure backend payload
            final role = state.user.userType.toLowerCase();
            
            if (role == 'owner') {
              // Navigator.pushReplacementNamed(context, '/ownerDashboard');
              print("Routing to Owner Dashboard");
            } else {
              // Navigator.pushReplacementNamed(context, '/residentDashboard');
              print("Routing to Standard Dashboard");
            }
          } else if (state is AuthError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          }
        },
        builder: (context, state) {
          if (state is AuthLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Enter OTP sent to ${widget.phoneNumber}'),
                const SizedBox(height: 20),
                TextField(
                  controller: _otpController,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  decoration: const InputDecoration(labelText: '6-Digit OTP'),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _verifyOtp,
                  child: const Text('Verify & Login'),
                ),
                TextButton(
                  onPressed: _resendOtp,
                  child: const Text('Resend OTP'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}