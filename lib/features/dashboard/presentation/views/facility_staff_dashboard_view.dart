import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/design_system.dart';
import '../../../../core/widgets/asmita_loading_indicator.dart';
import '../../../../core/widgets/asmita_primary_header.dart';
import '../../../../core/widgets/asmita_toast.dart';
import '../../../visitor_management/bloc/industrial_visit_bloc.dart';
import '../../../visitor_management/bloc/industrial_visit_event.dart';
import '../../../visitor_management/bloc/industrial_visit_state.dart';
import '../../../visitor_management/data/models/industrial_visit_model.dart';

/// Representation of an operations/facility task item
class FacilityTaskItem {
  final String id;
  final String title;
  final String category;
  final String priority;
  final Color priorityColor;
  bool isCompleted;

  FacilityTaskItem({
    required this.id,
    required this.title,
    required this.category,
    required this.priority,
    required this.priorityColor,
    this.isCompleted = false,
  });
}

/// Facility Staff Role Dashboard:
/// - Operations work queue with interactive task toggling and creation
/// - Real-time building occupancy and active checked-in visitor tracking
/// - Facility inspections and emergency muster tracking
class FacilityStaffDashboardView extends StatefulWidget {
  final List<IndustrialVisitModel>? visits;
  final VoidCallback? onRefresh;
  final ValueChanged<FacilityTaskItem>? onTaskToggled;

  const FacilityStaffDashboardView({
    super.key,
    this.visits,
    this.onRefresh,
    this.onTaskToggled,
  });

  @override
  State<FacilityStaffDashboardView> createState() => _FacilityStaffDashboardViewState();
}

class _FacilityStaffDashboardViewState extends State<FacilityStaffDashboardView> {
  late List<FacilityTaskItem> _tasks;
  bool _showVisitorsList = false;

  @override
  void initState() {
    super.initState();
    _tasks = [
      FacilityTaskItem(
        id: 'TASK-1',
        title: 'HVAC Airflow Check - Floor 2 Executive Cabins',
        category: 'Climate & Power',
        priority: 'High Priority',
        priorityColor: AsmitaPalette.actionRed,
        isCompleted: false,
      ),
      FacilityTaskItem(
        id: 'TASK-2',
        title: 'Lobby Visitor Badge Dispenser Maintenance',
        category: 'Security Systems',
        priority: 'Normal',
        priorityColor: AsmitaPalette.deepNavy,
        isCompleted: true,
      ),
      FacilityTaskItem(
        id: 'TASK-3',
        title: 'Conference Room 101 Projector Calibration',
        category: 'AV & IT Facilities',
        priority: 'Scheduled',
        priorityColor: AsmitaPalette.successGreen,
        isCompleted: false,
      ),
      FacilityTaskItem(
        id: 'TASK-4',
        title: 'Backup Generator Fuel & Battery Test',
        category: 'Power Backup',
        priority: 'Scheduled',
        priorityColor: AsmitaPalette.deepNavy,
        isCompleted: false,
      ),
    ];

    if (widget.visits == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        try {
          context.read<IndustrialVisitBloc>().add(const LoadIndustrialVisits());
        } catch (_) {}
      });
    }
  }

  void _handleRefresh(BuildContext context) {
    if (widget.onRefresh != null) {
      widget.onRefresh!();
    } else {
      context.read<IndustrialVisitBloc>().add(const LoadIndustrialVisits());
    }
  }

  void _toggleTask(FacilityTaskItem task) {
    setState(() {
      task.isCompleted = !task.isCompleted;
    });
    if (widget.onTaskToggled != null) {
      widget.onTaskToggled!(task);
    } else {
      AsmitaToast.show(
        context,
        message: task.isCompleted
            ? 'Task completed: ${task.title}'
            : 'Task marked incomplete: ${task.title}',
        type: AsmitaToastType.info,
      );
    }
  }

  void _showAddTaskDialog(BuildContext context) {
    final titleController = TextEditingController();
    String selectedCategory = 'Climate & Power';
    String selectedPriority = 'High Priority';
    Color selectedColor = AsmitaPalette.actionRed;

    showDialog<void>(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text(
            'New Facility Work Order',
            style: TextStyle(fontFamily: 'Montserrat', fontSize: 16, fontWeight: FontWeight.bold),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Task Description',
                    hintText: 'e.g. Clean air filters in Wing B',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  initialValue: selectedCategory,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Category',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'Climate & Power', child: Text('Climate & Power')),
                    DropdownMenuItem(value: 'Security Systems', child: Text('Security Systems')),
                    DropdownMenuItem(value: 'AV & IT Facilities', child: Text('AV & IT Facilities')),
                    DropdownMenuItem(value: 'Sanitation & Hygiene', child: Text('Sanitation & Hygiene')),
                    DropdownMenuItem(value: 'Power Backup', child: Text('Power Backup')),
                  ],
                  onChanged: (val) {
                    if (val != null) {
                      setDialogState(() => selectedCategory = val);
                    }
                  },
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  initialValue: selectedPriority,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Priority',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'High Priority', child: Text('High Priority')),
                    DropdownMenuItem(value: 'Normal', child: Text('Normal')),
                    DropdownMenuItem(value: 'Scheduled', child: Text('Scheduled')),
                  ],
                  onChanged: (val) {
                    if (val != null) {
                      setDialogState(() {
                        selectedPriority = val;
                        if (val == 'High Priority') {
                          selectedColor = AsmitaPalette.actionRed;
                        } else if (val == 'Scheduled') {
                          selectedColor = AsmitaPalette.successGreen;
                        } else {
                          selectedColor = AsmitaPalette.deepNavy;
                        }
                      });
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final text = titleController.text.trim();
                if (text.isEmpty) return;
                Navigator.pop(dialogCtx);
                setState(() {
                  _tasks.insert(
                    0,
                    FacilityTaskItem(
                      id: 'TASK-${DateTime.now().millisecondsSinceEpoch}',
                      title: text,
                      category: selectedCategory,
                      priority: selectedPriority,
                      priorityColor: selectedColor,
                    ),
                  );
                });
                AsmitaToast.show(
                  context,
                  message: 'Work order added to queue',
                  type: AsmitaToastType.success,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AsmitaPalette.deepNavy,
                foregroundColor: Colors.white,
              ),
              child: const Text('Add Task'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.visits != null) {
      return _buildScaffold(context, widget.visits!, isLoading: false);
    }

    return BlocConsumer<IndustrialVisitBloc, IndustrialVisitState>(
      listener: (context, state) {
        if (state.status == IndustrialVisitBlocStatus.actionSuccess &&
            state.successMessage != null) {
          AsmitaToast.show(
            context,
            message: state.successMessage!,
            type: AsmitaToastType.success,
          );
        } else if (state.status == IndustrialVisitBlocStatus.error &&
            state.errorMessage != null) {
          AsmitaToast.show(
            context,
            message: state.errorMessage!,
            type: AsmitaToastType.error,
          );
        }
      },
      builder: (context, state) {
        final isLoading = state.status == IndustrialVisitBlocStatus.loading &&
            state.visits.isEmpty;

        return _buildScaffold(context, state.visits, isLoading: isLoading);
      },
    );
  }

  Widget _buildScaffold(
    BuildContext context,
    List<IndustrialVisitModel> visits, {
    required bool isLoading,
  }) {
    final checkedInVisitors = visits
        .where((v) => v.status == IndustrialVisitStatus.checkedIn)
        .toList();
    final insideBuildingCount = checkedInVisitors.length;
    final pendingTasksCount = _tasks.where((t) => !t.isCompleted).length;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddTaskDialog(context),
        backgroundColor: AsmitaPalette.deepNavy,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_task),
        label: const Text('New Task', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: Column(
        children: [
          const AsmitaPrimaryHeader(
            subtitleOverride: 'Facility & Operations HQ',
            allowPropertySwitching: false,
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                _handleRefresh(context);
              },
              child: isLoading
                  ? const Center(
                      child: AsmitaLoadingIndicator(
                        color: AsmitaPalette.deepNavy,
                        size: 32,
                      ),
                    )
                  : SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Building Occupancy Tracker Banner
                      InkWell(
                        onTap: () {
                          setState(() {
                            _showVisitorsList = !_showVisitorsList;
                          });
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AsmitaPalette.deepNavy.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AsmitaPalette.deepNavy.withValues(alpha: 0.2)),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: const BoxDecoration(
                                  color: AsmitaPalette.deepNavy,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.apartment, color: Colors.white, size: 24),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Building Occupancy Tracker',
                                      style: TextStyle(fontFamily: 'Montserrat', fontSize: 14, fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '$insideBuildingCount Visitors Currently Checked-In',
                                      style: const TextStyle(fontSize: 12, color: AsmitaPalette.textLight),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(
                                _showVisitorsList
                                    ? Icons.keyboard_arrow_up
                                    : Icons.keyboard_arrow_down,
                                color: AsmitaPalette.deepNavy,
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Optional Expanded Checked-In Visitors Roster
                      if (_showVisitorsList) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Theme.of(context).dividerColor),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'On-Premises Visitor Roster',
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                  ),
                                  Text(
                                    '$insideBuildingCount inside',
                                    style: const TextStyle(fontSize: 11, color: AsmitaPalette.textLight),
                                  ),
                                ],
                              ),
                              const Divider(height: 16),
                              if (checkedInVisitors.isEmpty)
                                const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 8),
                                  child: Center(
                                    child: Text(
                                      'No visitors currently checked-in on premises.',
                                      style: TextStyle(fontSize: 12, color: AsmitaPalette.textLight),
                                    ),
                                  ),
                                )
                              else
                                ...checkedInVisitors.map(
                                  (visitor) => Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 6),
                                    child: Row(
                                      children: [
                                        CircleAvatar(
                                          radius: 14,
                                          backgroundColor: AsmitaPalette.deepNavy.withValues(alpha: 0.1),
                                          child: Text(
                                            visitor.visitorName.isNotEmpty ? visitor.visitorName[0] : 'V',
                                            style: const TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                              color: AsmitaPalette.deepNavy,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                visitor.visitorName,
                                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                                              ),
                                              Text(
                                                '${visitor.cabinNumber != null ? "Cabin ${visitor.cabinNumber}" : (visitor.departmentName ?? "General Facility")} • ${visitor.arrivalMode}',
                                                style: const TextStyle(fontSize: 11, color: AsmitaPalette.textLight),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: AsmitaPalette.successGreen.withValues(alpha: 0.12),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: const Text(
                                            'Inside',
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                              color: AsmitaPalette.successGreen,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],

                      const SizedBox(height: 24),

                      // Operations Work Queue Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Operations Work Queue',
                            style: TextStyle(fontFamily: 'Montserrat', fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            '$pendingTasksCount Pending',
                            style: const TextStyle(fontSize: 12, color: AsmitaPalette.textLight, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      if (_tasks.isEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 30),
                          alignment: Alignment.center,
                          child: const Text(
                            'No facility tasks in queue. All systems operating normally.',
                            style: TextStyle(fontSize: 12, color: AsmitaPalette.textLight),
                          ),
                        )
                      else
                        ..._tasks.map((task) => _taskTile(context, task)),

                      const SizedBox(height: 60), // Spacing for extended FAB
                    ],
                  ),
                ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _taskTile(BuildContext context, FacilityTaskItem task) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: Theme.of(context).dividerColor),
      ),
      child: ListTile(
        onTap: () => _toggleTask(task),
        leading: Icon(
          task.isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
          color: task.isCompleted ? AsmitaPalette.successGreen : AsmitaPalette.textLight,
        ),
        title: Text(
          task.title,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            decoration: task.isCompleted ? TextDecoration.lineThrough : null,
          ),
        ),
        subtitle: Text(task.category, style: const TextStyle(fontSize: 11, color: AsmitaPalette.textLight)),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: task.priorityColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            task.priority,
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: task.priorityColor),
          ),
        ),
      ),
    );
  }
}
