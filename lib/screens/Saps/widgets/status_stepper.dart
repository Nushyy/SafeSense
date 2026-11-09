import 'package:flutter/material.dart';

import '../../../services/saps/saps_case.dart';
import '../saps_colors.dart';

/// Shows where a case is on its path and what comes next.
class StatusStepper extends StatelessWidget {
  const StatusStepper({super.key, required this.c});
  final SapsCase c;

  @override
  Widget build(BuildContext context) {
    final steps = c.steps;
    final current = steps.indexOf(c.status);

    if (current < 0) {
      // Closed some other way: false alarm, rejected, cancelled by user.
      return Row(
        children: [
          const Icon(Icons.check_circle_outline,
              size: 20, color: SapsColors.textSecondary),
          const SizedBox(width: 8),
          Text('Closed as ${statusLabel(c.status).toLowerCase()}',
              style: const TextStyle(
                  fontSize: 14, color: SapsColors.textSecondary)),
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (int i = 0; i < steps.length; i++)
          Expanded(
            child: Column(
              children: [
                SizedBox(
                  height: 26,
                  child: Row(
                    children: [
                      Expanded(
                        child: i == 0
                            ? const SizedBox()
                            : _Line(done: i <= current),
                      ),
                      _Dot(
                        label: i < current ? '✓' : '${i + 1}',
                        state: i < current
                            ? _S.done
                            : i == current
                                ? _S.now
                                : _S.todo,
                      ),
                      Expanded(
                        child: i == steps.length - 1
                            ? const SizedBox()
                            : _Line(done: i < current),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  statusLabel(steps[i]),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight:
                        i == current ? FontWeight.w600 : FontWeight.w400,
                    color: i == current
                        ? SapsColors.navy
                        : SapsColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

enum _S { done, now, todo }

class _Dot extends StatelessWidget {
  const _Dot({required this.label, required this.state});
  final String label;
  final _S state;

  @override
  Widget build(BuildContext context) {
    final bg = state == _S.done
        ? SapsColors.green
        : state == _S.now
            ? SapsColors.gold
            : SapsColors.surface;
    final fg = state == _S.done
        ? Colors.white
        : state == _S.now
            ? SapsColors.navy
            : SapsColors.textSecondary;
    return Container(
      width: 26,
      height: 26,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: bg,
        shape: BoxShape.circle,
        border: Border.all(
          color: state == _S.todo ? SapsColors.fieldBorder : bg,
          width: 1.5,
        ),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 13, fontWeight: FontWeight.w600, color: fg)),
    );
  }
}

class _Line extends StatelessWidget {
  const _Line({required this.done});
  final bool done;

  @override
  Widget build(BuildContext context) => Container(
        height: 2,
        color: done ? SapsColors.green : SapsColors.border,
      );
}
