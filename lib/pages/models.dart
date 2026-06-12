import 'dart:async';

import 'package:ara_dict/llm/llm_prover.dart';
import 'package:ara_dict/main_widgets.dart';
import 'package:flutter/material.dart';

class LlmModelsEditPage extends StatefulWidget {
  const LlmModelsEditPage({super.key});

  @override
  State<LlmModelsEditPage> createState() => _LlmModelsEditPageState();
}

class _LlmModelsEditPageState extends State<LlmModelsEditPage> {
  Future<void> _addValue({
    required String title,
    required FutureOr<void> Function(String value) onAdd,
    required bool commaSep,
  }) async {
    final controller = TextEditingController();

    final value = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          constraints: const BoxConstraints(maxWidth: 600),
          title: Text(title),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: InputDecoration(
              hintText: commaSep ? 'Comma seperated allowd' : null,
              border: OutlineInputBorder(),
            ),
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

    await onAdd(value);
    if (context.mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final th = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('LLM Models')),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: LlmModels.values.length,
        separatorBuilder: (_, _) => const SizedBox(height: 16),
        itemBuilder: (context, index) {
          final provider = LlmModels.values[index];

          final m = AppChatsDb.models[provider];

          if (m == null) return SizedBox.shrink();

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
                            commaSep: true,
                            onAdd: (v) async {
                              final values = v
                                  .trim()
                                  .split(',')
                                  .map((l) => l.trim())
                                  .takeWhile((l) => l.isNotEmpty)
                                  .toList();

                              for (final v in values) {
                                await AppChatsDb.addModel(provider, v);
                              }
                            },
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

                            await AppChatsDb.deleteModel(provider, model);
                            if (context.mounted) setState(() {});
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
                            commaSep: false,
                            title: 'Add API Key',
                            onAdd: (v) async =>
                                await AppChatsDb.addApiKey(provider, v),
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

                            await AppChatsDb.deleteApiKey(provider, key);
                            if (context.mounted) setState(() {});
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
