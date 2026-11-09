import 'package:flutter/material.dart';

import '../../../services/saps/saps_case.dart';
import '../saps_colors.dart';

/// Closing a case as false alarm / rejected ends it, so it needs a reason.
/// Moving a case FORWARD does not ask (it has Undo instead).
/// Returns the chosen reason, or null if the officer went back.
Future<String?> askCloseReason(BuildContext context, SapsCase c) {
  return showDialog<String>(
    context: context,
    builder: (_) => _CloseReasonDialog(c: c),
  );
}

class _CloseReasonDialog extends StatefulWidget {
  const _CloseReasonDialog({required this.c});
  final SapsCase c;

  @override
  State<_CloseReasonDialog> createState() => _CloseReasonDialogState();
}

class _CloseReasonDialogState extends State<_CloseReasonDialog> {
  static const _reasons = [
    'Duplicate of another case',
    'Reporter confirmed all is well',
    'Not a police matter',
    'Could not verify',
  ];
  String? _reason;
  bool _error = false;

  @override
  Widget build(BuildContext context) {
    final label = statusLabel(widget.c.rejectStatus).toLowerCase();
    return AlertDialog(
      backgroundColor: SapsColors.surface,
      title: Text('Why is this a $label?'),
      content: SizedBox(
        width: 360,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DropdownButtonFormField<String>(
              initialValue: _reason,
              isExpanded: true,
              decoration: const InputDecoration(
                hintText: 'Choose a reason',
                border: OutlineInputBorder(),
              ),
              items: [
                for (final r in _reasons)
                  DropdownMenuItem(value: r, child: Text(r)),
              ],
              onChanged: (v) => setState(() {
                _reason = v;
                _error = false;
              }),
            ),
            if (_error)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text('Choose a reason to close this case.',
                    style: TextStyle(color: SapsColors.redText, fontSize: 13)),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Go back'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: SapsColors.red,
            foregroundColor: Colors.white,
            minimumSize: const Size(0, 44),
          ),
          onPressed: () {
            if (_reason == null) {
              setState(() => _error = true);
              return;
            }
            Navigator.of(context).pop(_reason);
          },
          child: const Text('Close case'),
        ),
      ],
    );
  }
}
