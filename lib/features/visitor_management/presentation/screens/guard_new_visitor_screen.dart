import 'package:flutter/material.dart';
import '../../../../core/constants/design_system.dart';
import '../../../dashboard/widgets/asmita_pre_approve_wizard.dart';

<<<<<<< HEAD
=======
import '../../../../core/widgets/asmita_sub_header.dart';

>>>>>>> 8e14b7ab5ec9ba6ee223925910b776c044e433df
class GuardNewVisitorScreen extends StatelessWidget {
  const GuardNewVisitorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AsmitaPalette.systemBG,
<<<<<<< HEAD
      appBar: AppBar(
        title: Text('New Walk-in Visitor', style: Theme.of(context).textTheme.titleLarge),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AsmitaPalette.textDark),
      ),
      body: const AsmitaPreApproveWizard(isGuardMode: true),
=======
      body: SafeArea(
        child: Column(
          children: [
            const AsmitaSubHeader(title: 'New Walk-in Visitor'),
            Expanded(
              child: Container(
                margin: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AsmitaPalette.borderGrey, width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const AsmitaPreApproveWizard(isGuardMode: true),
              ),
            ),
          ],
        ),
      ),
>>>>>>> 8e14b7ab5ec9ba6ee223925910b776c044e433df
    );
  }
}
