import 'package:flutter/material.dart';
import '../screens/employee_registry_screen.dart';

export '../screens/employee_registry_screen.dart';

class EmployeeRegistrySheet extends StatelessWidget {
  final int? societyId;

  const EmployeeRegistrySheet({
    super.key,
    this.societyId,
  });

  /// Opens the dedicated full page Employee Registry Screen
  static Future<void> show(BuildContext context, {int? societyId}) async {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EmployeeRegistryScreen(societyId: societyId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return EmployeeRegistryScreen(societyId: societyId);
  }
}
