import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../saps_colors.dart';

/// Six big digit boxes backed by ONE invisible text field, so paste,
/// backspace and phone autofill all work without focus juggling.
class CodeBoxes extends StatelessWidget {
  const CodeBoxes({
    super.key,
    required this.controller,
    required this.focusNode,
    this.hasError = false,
    this.onCompleted,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool hasError;
  final VoidCallback? onCompleted;

  static const int length = 6;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ListenableBuilder(
          listenable: Listenable.merge([controller, focusNode]),
          builder: (context, _) {
            final text = controller.text;
            return Row(
              children: [
                for (int i = 0; i < length; i++) ...[
                  if (i > 0) const SizedBox(width: 8),
                  Expanded(
                    child: _Box(
                      char: i < text.length ? text[i] : '',
                      active: focusNode.hasFocus &&
                          (i == text.length ||
                              (i == length - 1 && text.length == length)),
                      error: hasError,
                    ),
                  ),
                ],
              ],
            );
          },
        ),
        Positioned.fill(
          child: TextField(
            controller: controller,
            focusNode: focusNode,
            keyboardType: TextInputType.number,
            autofillHints: const [AutofillHints.oneTimeCode],
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(length),
            ],
            showCursor: false,
            enableInteractiveSelection: false,
            style: const TextStyle(color: Colors.transparent),
            decoration: const InputDecoration(
              border: InputBorder.none,
              counterText: '',
              fillColor: Colors.transparent,
            ),
            onChanged: (v) {
              if (v.length == length) onCompleted?.call();
            },
          ),
        ),
      ],
    );
  }
}

class _Box extends StatelessWidget {
  const _Box({required this.char, required this.active, required this.error});
  final String char;
  final bool active;
  final bool error;

  @override
  Widget build(BuildContext context) {
    final color = error
        ? SapsColors.red
        : active
            ? SapsColors.blue
            : SapsColors.fieldBorder;
    return Container(
      height: 52,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color, width: active ? 2.5 : 1.5),
      ),
      child: Text(
        char,
        style: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w500,
          color: SapsColors.navy,
        ),
      ),
    );
  }
}
