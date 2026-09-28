import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import '../../../core/constants/design_system.dart';

class UnsafeDeviceScreen extends StatefulWidget {
  const UnsafeDeviceScreen({super.key});

  @override
  State<UnsafeDeviceScreen> createState() => _UnsafeDeviceScreenState();
}

class _UnsafeDeviceScreenState extends State<UnsafeDeviceScreen> {
  @override
  void initState() {
    super.initState();
    // Remove splash screen when showing this error
    FlutterNativeSplash.remove();
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.paddingOf(context).top;
    final bottomPadding = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      backgroundColor: AsmitaPalette.deepNavy,
      body: CustomScrollView(
        physics: const ClampingScrollPhysics(),
        slivers: [
          SliverFillRemaining(
            hasScrollBody: false,
            child: Column(
              children: [
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(top: topPadding + 30.0, bottom: 30.0),
                    child: Center(
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            height: 180,
                            width: 180,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AsmitaPalette.actionRed.withValues(alpha: 0.1),
                            ),
                          ),
                          const Icon(
                            Icons.gpp_bad_rounded,
                            color: AsmitaPalette.actionRed,
                            size: 100,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Stack(
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
                    Container(
                      margin: const EdgeInsets.only(top: 12),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                      ),
                      padding: EdgeInsets.only(
                        left: 24.0,
                        right: 24.0,
                        top: 48.0,
                        bottom: bottomPadding > 0 ? bottomPadding + 16.0 : 32.0,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Security Risk Detected',
                            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                  color: Colors.black,
                                  fontWeight: FontWeight.w800,
                                ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'This app cannot run on rooted or jailbroken devices to protect your secure smart home and society operations data.',
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                  color: Colors.grey.shade600,
                                  height: 1.5,
                                ),
                          ),
                          const SizedBox(height: 48),
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AsmitaPalette.actionRed,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              onPressed: () {
                                SystemNavigator.pop();
                              },
                              child: const Text(
                                'Exit App',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
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
        ],
      ),
    );
  }
}
