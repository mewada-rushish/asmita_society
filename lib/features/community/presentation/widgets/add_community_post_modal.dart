import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:asmita_society/core/constants/design_system.dart';
import 'package:asmita_society/features/community/bloc/community_post_bloc.dart';
import 'package:asmita_society/features/community/bloc/community_post_event.dart';
import 'package:asmita_society/features/community/bloc/community_post_state.dart';
import 'package:asmita_society/features/community/data/models/community_post_model.dart';
import 'package:asmita_society/features/auth/bloc/auth_bloc.dart';
import 'package:asmita_society/features/auth/bloc/auth_state.dart';
import 'package:asmita_society/core/widgets/asmita_toast.dart';

class AddCommunityPostModal extends StatefulWidget {
  const AddCommunityPostModal({super.key});

  @override
  State<AddCommunityPostModal> createState() => _AddCommunityPostModalState();
}

class _AddCommunityPostModalState extends State<AddCommunityPostModal> {
  final _titleController = TextEditingController();
  final QuillController _quillController = QuillController.basic();
  final FocusNode _titleFocus = FocusNode();
  final FocusNode _editorFocus = FocusNode();
  DateTimeRange? _selectedDateRange;

  @override
  void initState() {
    super.initState();
    _selectedDateRange = DateTimeRange(
      start: DateTime.now(),
      end: DateTime.now().add(const Duration(days: 1)),
    );
    _titleFocus.addListener(() => setState(() {}));
    _editorFocus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _titleController.dispose();
    _quillController.dispose();
    _titleFocus.dispose();
    _editorFocus.dispose();
    super.dispose();
  }

  Future<void> _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: _selectedDateRange,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.fromSeed(
              seedColor: AsmitaPalette.deepNavy,
              primary: AsmitaPalette.deepNavy,
              surface: Colors.white,
            ),
            datePickerTheme: DatePickerThemeData(
              backgroundColor: Colors.white,
              rangeSelectionOverlayColor: WidgetStateProperty.all(AsmitaPalette.deepNavy.withValues(alpha: 0.15)),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _selectedDateRange = picked;
      });
    }
  }

  Future<void> _showColorPicker(QuillController controller, bool isBackground) async {
    final colors = [
      Colors.black, Colors.white, Colors.red, Colors.green, Colors.blue,
      Colors.yellow, Colors.orange, Colors.purple, Colors.cyan, Colors.brown,
      Colors.grey, Colors.pink, Colors.teal, Colors.indigo,
    ];

    final Color? selectedColor = await showDialog<Color>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text('Select ${isBackground ? 'Background' : 'Text'} Color'),
          content: Wrap(
            spacing: 12,
            runSpacing: 12,
            children: colors.map((c) => GestureDetector(
              onTap: () => Navigator.pop(ctx, c),
              child: Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color: c,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.grey.shade300),
                ),
              ),
            )).toList(),
          ),
        );
      }
    );

    if (selectedColor != null) {
      final hexColor = '#${selectedColor.toARGB32().toRadixString(16).padLeft(8, '0').substring(2)}';
      if (isBackground) {
        controller.formatSelection(BackgroundAttribute(hexColor));
      } else {
        controller.formatSelection(ColorAttribute(hexColor));
      }
    }
  }

  bool _wasSubmitting = false;
  String _pendingStatus = '';

  void _submitPost() {
    if (_titleController.text.trim().isEmpty) {
      AsmitaToast.show(context, message: 'Please enter a title', type: AsmitaToastType.error);
      return;
    }
    
    final authState = context.read<AuthBloc>().state;
    String userRole = 'resident';
    String authorName = 'User';
    if (authState is AuthAuthenticated) {
      userRole = authState.user.userType;
      authorName = authState.user.fullName;
    }

    final String status = (userRole == 'admin' || userRole == 'guard') ? 'approved' : 'pending';
    _pendingStatus = status;
    
    final contentJson = jsonEncode(_quillController.document.toDelta().toJson());
    
    final newPost = CommunityPostModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: _titleController.text.trim(),
      contentJson: contentJson,
      authorName: authorName,
      status: status,
      createdAt: DateTime.now(),
      startDate: _selectedDateRange?.start,
      endDate: _selectedDateRange?.end,
    );

    context.read<CommunityPostBloc>().add(AddCommunityPost(newPost));
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 8,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _titleController,
              focusNode: _titleFocus,
              style: const TextStyle(color: Colors.black),
              decoration: InputDecoration(
                hintText: 'Post Title',
                hintStyle: const TextStyle(color: Colors.grey),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AsmitaPalette.deepNavy, width: 2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              height: 200,
              decoration: BoxDecoration(
                border: Border.all(
                  color: _editorFocus.hasFocus ? AsmitaPalette.deepNavy : Colors.grey.shade300,
                  width: _editorFocus.hasFocus ? 2 : 1,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: QuillEditor.basic(
                controller: _quillController,
                focusNode: _editorFocus,
                config: const QuillEditorConfig(
                  padding: EdgeInsets.all(16),
                  placeholder: 'Write your post here...',
                ),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: QuillSimpleToolbar(
                  controller: _quillController,
                  config: QuillSimpleToolbarConfig(
                    showFontFamily: false,
                    showFontSize: false,
                    showSearchButton: false,
                    showInlineCode: false,
                    showCodeBlock: false,
                    color: Colors.transparent,
                    buttonOptions: QuillSimpleToolbarButtonOptions(
                      color: QuillToolbarColorButtonOptions(
                        customOnPressedCallback: _showColorPicker,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _selectDateRange,
              icon: const Icon(Icons.date_range, size: 18),
              label: Text('Duration: ${_selectedDateRange!.start.day}/${_selectedDateRange!.start.month}/${_selectedDateRange!.start.year} - ${_selectedDateRange!.end.day}/${_selectedDateRange!.end.month}/${_selectedDateRange!.end.year}'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AsmitaPalette.deepNavy,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                side: BorderSide(color: Colors.grey.shade300),
              ),
            ),
            const SizedBox(height: 16),
            BlocConsumer<CommunityPostBloc, CommunityPostState>(
              listener: (context, state) {
                if (_wasSubmitting && !state.isSubmitting) {
                  if (_pendingStatus == 'pending') {
                    AsmitaToast.show(context, message: 'Post submitted for admin approval', type: AsmitaToastType.success);
                  } else {
                    AsmitaToast.show(context, message: 'Post published successfully', type: AsmitaToastType.success);
                  }
                  Navigator.pop(context);
                }
                _wasSubmitting = state.isSubmitting;
              },
              builder: (context, state) {
                return ElevatedButton(
                  onPressed: state.isSubmitting ? null : _submitPost,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AsmitaPalette.deepNavy,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: state.isSubmitting 
                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Post', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                );
              },
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
