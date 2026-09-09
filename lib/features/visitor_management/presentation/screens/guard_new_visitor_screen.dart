import 'package:flutter/material.dart';
import '../../../../core/constants/design_system.dart';
import '../../../dashboard/widgets/asmita_pre_approve_wizard.dart';

class GuardNewVisitorScreen extends StatelessWidget {
  const GuardNewVisitorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AsmitaPalette.systemBG,
      appBar: AppBar(
        title: Text('New Walk-in Visitor', style: Theme.of(context).textTheme.titleLarge),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AsmitaPalette.textDark),
      ),
      body: const AsmitaPreApproveWizard(isGuardMode: true),
    );
  }
}
