import 'package:ara_dict/main_widgets.dart';
import 'package:ara_dict/widgets/selectable_text_screen.dart';
import 'package:flutter/material.dart';

enum LlmModels {
  chatGpt(name: 'ChatGPT', ar: 'شات جي بي تي'),
  gemini(name: 'Gemini', ar: 'جيميني');

  final String name;
  final String ar;

  const LlmModels({required this.name, required this.ar});
}

class LlmModel {
  final LlmModels model;
  final List<String> models;
  final List<String> apiKeys;

  const LlmModel({
    required this.model,
    required this.models,
    required this.apiKeys,
  });
}

class LlmModelsEditPage extends StatefulWidget {
  const LlmModelsEditPage({super.key});

  @override
  State<LlmModelsEditPage> createState() => _LlmModelsEditPageState();
}

class _LlmModelsEditPageState extends State<LlmModelsEditPage> {
  final _models = [
    LlmModel(
      model: LlmModels.gemini,
      models: Chats.geminiModels.toList(),
      apiKeys: Chats.geminiApiKeys.toList(),
    ),
  ];

  Future<void> _addValue({
    required String title,
    required void Function(String value) onAdd,
  }) async {
    final controller = TextEditingController();

    final value = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(border: OutlineInputBorder()),
            onSubmitted: (v) => Navigator.pop(context, v),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(context, controller.text.trim());
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );

    if (value == null || value.isEmpty) return;

    onAdd(value);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final th = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('LLM Models')),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _models.length,
        separatorBuilder: (_, _) => const SizedBox(height: 16),
        itemBuilder: (context, index) {
          final m = _models[index];

          return Card(
            clipBehavior: Clip.antiAlias,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(m.model.name, style: th.titleLarge),

                  const SizedBox(height: 20),

                  Row(
                    children: [
                      Expanded(child: Text('Models', style: th.titleMedium)),
                      FilledButton.icon(
                        onPressed: () {
                          _addValue(
                            title: 'Add Model',
                            onAdd: (v) => m.models.add(v),
                          );
                        },
                        icon: const Icon(Icons.add),
                        label: const Text('Add'),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final model in m.models)
                        InputChip(
                          label: Text(model),
                          onDeleted: () async {
                            final confirm = await showConfirmDialog(
                              context,
                              'Delete Model?',
                              message: 'Delete: $model',
                              confirmText: 'Delete',
                              destructive: true,
                            );

                            if (confirm != true || !context.mounted) return;

                            setState(() {
                              m.models.remove(model);
                            });
                          },
                        ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  Row(
                    children: [
                      Expanded(child: Text('API Keys', style: th.titleMedium)),
                      FilledButton.icon(
                        onPressed: () {
                          _addValue(
                            title: 'Add API Key',
                            onAdd: (v) => m.apiKeys.add(v),
                          );
                        },
                        icon: const Icon(Icons.add),
                        label: const Text('Add'),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final key in m.apiKeys)
                        InputChip(
                          label: SizedBox(
                            width: 80,
                            child: Text(key, overflow: TextOverflow.ellipsis),
                          ),
                          tooltip: key,
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (_) => AlertDialog(
                                title: const Text('API Key'),
                                content: SelectableText(key),
                              ),
                            );
                          },
                          onDeleted: () async {
                            final confirm = await showConfirmDialog(
                              context,
                              'Delete Api key?',
                              message: 'Delete: $key',
                              constraints: true,
                              confirmText: 'Delete',
                              destructive: true,
                            );

                            if (confirm != true || !context.mounted) return;

                            setState(() {
                              m.apiKeys.remove(key);
                            });
                          },
                        ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
