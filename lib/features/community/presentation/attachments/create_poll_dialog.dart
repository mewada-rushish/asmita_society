import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:asmita_society/core/constants/design_system.dart';
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

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Create Poll',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AsmitaPalette.deepNavy,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _questionController,
                decoration: const InputDecoration(
                  labelText: 'Ask a question',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
                minLines: 1,
              ),
              const SizedBox(height: 16),
              ...List.generate(_optionControllers.length, (index) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _optionControllers[index],
                          decoration: InputDecoration(
                            labelText: 'Option ${index + 1}',
                            border: const OutlineInputBorder(),
                          ),
                        ),
                      ),
                      if (_optionControllers.length > 2)
                        IconButton(
                          icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                          onPressed: () => _removeOption(index),
                        ),
                    ],
                  ),
                );
              }),
              if (_optionControllers.length < 6)
                TextButton.icon(
                  onPressed: _addOption,
                  icon: const Icon(Icons.add),
                  label: const Text('Add Option'),
                ),
              const SizedBox(height: 8),
              SwitchListTile(
                title: const Text('Allow multiple answers'),
                value: _allowMultipleAnswers,
                onChanged: (val) {
                  setState(() {
                    _allowMultipleAnswers = val;
                  });
                },
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _createPoll,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AsmitaPalette.deepNavy,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text('Create'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
