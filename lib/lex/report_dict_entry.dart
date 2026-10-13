import 'package:arabic_lexicons/conf.dart';
import 'package:arabic_lexicons/data.dart';
import 'package:arabic_lexicons/lex/dicts/db.dart';
import 'package:arabic_lexicons/utils/toast_snack.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

Future<bool> reportDefinition(DbRow row, Dict dict) async {
  final body =
      '''DICTIONARY
Name: ${dict.enLong}
Arabic name: ${dict.ar}
Short name: ${dict.en}
Table: ${dict.table}

ENTRY
ID: ${row.id}
Word: ${row.word}

Current definition:
${row.meanings}

Reported mistake:
[Describe the mistake here]

Suggested correction:
[Enter the corrected definition, if known]
''';

  final uri = Uri.parse(
    'mailto:$emailAddr'
    '?subject=${Uri.encodeComponent('Dictionary Report: ${dict.table} ${row.word}')}'
    '&body=${Uri.encodeComponent(body)}',
  );

  if (!await canLaunchUrl(uri)) return false;

  return launchUrl(uri);
}

Future<void> showEmailFallbackDialog(
  BuildContext context, {
  required DbRow row,
  required Dict dict,
  required String email,
}) async {
  final controller = TextEditingController(
    text:
        '''
To: $email
Subject: Dictionary Error Report: ${row.word}

DICTIONARY
Name: ${dict.enLong}
Arabic name: ${dict.ar}
Short name: ${dict.en}
Table: ${dict.table}

Current definition:
${row.meanings}

Reported mistake:
[Describe the mistake here.]

Suggested correction:
[Enter the corrected definition, if known.]''',
  );

  await showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      constraints: maxUiWidth,
      icon: const Icon(Icons.email_outlined),
      title: const Text('Report a dictionary error'),
      content: SizedBox(
        width: double.maxFinite,
        child: TextField(
          style: L.arStyleSized,
          controller: controller,
          autofocus: true,
          minLines: 10,
          maxLines: 16,
          decoration: const InputDecoration(hintText: 'Email report'),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: const Text('Cancel'),
        ),
        FilledButton.icon(
          onPressed: () async {
            await Clipboard.setData(ClipboardData(text: controller.text));

            if (dialogContext.mounted) {
              Navigator.pop(dialogContext);
              MsgSv.showSnackbarMsg('Email report copied');
            }
          },
          icon: const Icon(Icons.copy),
          label: const Text('Copy'),
        ),
      ],
    ),
  );

  controller.dispose();
}
