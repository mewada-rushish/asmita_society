import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/community_provider.dart';

class CreatePollDialog extends ConsumerStatefulWidget {
  const CreatePollDialog({super.key});

  @override
  ConsumerState<CreatePollDialog> createState() => _CreatePollDialogState();
}

class _CreatePollDialogState extends ConsumerState<CreatePollDialog> {
  final TextEditingController _questionController = TextEditingController();
  final List<TextEditingController> _optionControllers = [
    TextEditingController(),
    TextEditingController(),
  ];
  bool _allowMultipleAnswers = false;

  void _addOption() {
    if (_optionControllers.length < 6) {
      setState(() {
        _optionControllers.add(TextEditingController());
      });
    }
  }

  void _removeOption(int index) {
    if (_optionControllers.length > 2) {
      setState(() {
        _optionControllers[index].dispose();
        _optionControllers.removeAt(index);
      });
    }
  }

  void _createPoll() {
    final question = _questionController.text.trim();
    if (question.isEmpty) return;

    final options = <String, int>{};
    for (var controller in _optionControllers) {
      final opt = controller.text.trim();
      if (opt.isNotEmpty && !options.containsKey(opt)) {
        options[opt] = 0;
      }
    }

    if (options.length >= 2) {
      ref.read(communityProvider.notifier).sendPollMessage(
            question,
            options,
            _allowMultipleAnswers,
          );
      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please provide at least 2 options.')),
      );
    }
  }

  @override
  void dispose() {
    _questionController.dispose();
    for (var controller in _optionControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  InputDecoration _iosInputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color),
      filled: true,
      fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 1.5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 8,
        bottom: MediaQuery.of(context).viewInsets.bottom + MediaQuery.of(context).padding.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // iOS style drag handle
            Center(
              child: Container(
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            SizedBox(height: 16),
            
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    foregroundColor: Theme.of(context).colorScheme.primary,
                    minimumSize: const Size(50, 30),
                    alignment: Alignment.centerLeft,
                  ),
                  child: Text('Cancel', style: TextStyle(fontSize: 16)),
                ),
                Text(
                  'New Poll',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 17,
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                      ),
                ),
                TextButton(
                  onPressed: _createPoll,
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    foregroundColor: Theme.of(context).colorScheme.primary,
                    minimumSize: const Size(50, 30),
                    alignment: Alignment.centerRight,
                  ),
                  child: Text('Post', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            SizedBox(height: 20),
            
            TextField(
              controller: _questionController,
              decoration: InputDecoration(
                hintText: 'Ask a question...',
                hintStyle: TextStyle(
                  color: Theme.of(context).textTheme.bodyMedium?.color,
                  fontSize: 18,
                  fontWeight: FontWeight.w400,
                ),
                filled: false,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 12),
              ),
              maxLines: 3,
              minLines: 1,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),
            Padding(
              padding: EdgeInsets.only(bottom: 20, top: 4),
              child: Divider(height: 1, color: Theme.of(context).dividerColor),
            ),
            
            ...List.generate(_optionControllers.length, (index) {
              return Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _optionControllers[index],
                        decoration: _iosInputDecoration('Option ${index + 1}'),
                        style: TextStyle(fontSize: 16, color: Theme.of(context).textTheme.bodyLarge?.color),
                      ),
                    ),
                    if (_optionControllers.length > 2)
                      IconButton(
                        icon: Icon(CupertinoIcons.minus_circle_fill, color: Theme.of(context).colorScheme.primary, size: 24),
                        onPressed: () => _removeOption(index),
                      ),
                  ],
                ),
              );
            }),
            
            if (_optionControllers.length < 6)
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: _addOption,
                  icon: Icon(CupertinoIcons.add_circled_solid, size: 20, color: Theme.of(context).colorScheme.primary),
                  label: Text(
                    'Add Option',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.primary),
                  ),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ),
            
            SizedBox(height: 8),
            Material(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
              clipBehavior: Clip.antiAlias,
              child: SwitchListTile.adaptive(
                title: Text(
                  'Allow multiple answers',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Theme.of(context).textTheme.bodyLarge?.color),
                ),
                activeTrackColor: Theme.of(context).colorScheme.primary,
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                value: _allowMultipleAnswers,
                onChanged: (val) {
                  setState(() {
                    _allowMultipleAnswers = val;
                  });
                },
              ),
            ),
            SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}
