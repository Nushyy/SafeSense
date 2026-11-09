import 'package:flutter/material.dart';

import '../../../services/saps/saps_case.dart';
import '../../../services/saps/saps_case_service.dart';
import '../saps_colors.dart';
import 'case_list.dart' show KindTag;
import 'case_map.dart';
import 'status_stepper.dart';

class CaseDetail extends StatelessWidget {
  const CaseDetail({
    super.key,
    required this.c,
    required this.onAdvance,
    required this.onCloseNegative,
    required this.onCall,
    required this.onMaps,
  });

  final SapsCase c;
  final VoidCallback onAdvance;
  final VoidCallback onCloseNegative;
  final VoidCallback onCall;
  final VoidCallback onMaps;

  @override
  Widget build(BuildContext context) {
    final next = c.nextStatus;
    final reporter = c.reporterName == null
        ? 'Reporter: anonymous'
        : 'Reporter: ${c.reporterName}';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            KindTag(isSos: c.isSos),
            const SizedBox(width: 8),
            _StatusChip(statusLabel(c.status)),
          ]),
          const SizedBox(height: 8),
          Text(c.displayTitle,
              style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: SapsColors.navy)),
          Text(
            '${c.area ?? 'Location unknown'}'
            '${c.isOpen ? ' · waiting ${formatWait(c.waiting)}' : ''}',
            style: const TextStyle(
                fontSize: 14, color: SapsColors.textSecondary),
          ),
          const SizedBox(height: 14),
          StatusStepper(c: c),
          const SizedBox(height: 14),
          CaseMap(c: c),
          const SizedBox(height: 14),
          if (c.description != null && c.description!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(c.description!, style: const TextStyle(fontSize: 15)),
            ),
          Text(
            [reporter, if (c.battery != null) 'Battery ${c.battery}%']
                .join(' · '),
            style: const TextStyle(
                fontSize: 14, color: SapsColors.textSecondary),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: onCall,
                icon: const Icon(Icons.phone_outlined, size: 18),
                label: const Text('Call reporter'),
              ),
              OutlinedButton.icon(
                onPressed: onMaps,
                icon: const Icon(Icons.place_outlined, size: 18),
                label: const Text('Open in Maps'),
              ),
            ],
          ),
          if (next != null) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: SapsColors.gold,
                    foregroundColor: SapsColors.navy,
                    minimumSize: const Size(160, 48),
                    textStyle: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                  onPressed: onAdvance,
                  child: Text('Mark ${statusLabel(next).toLowerCase()}'),
                ),
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: SapsColors.redText,
                    side: const BorderSide(color: SapsColors.red),
                    minimumSize: const Size(0, 48),
                  ),
                  onPressed: onCloseNegative,
                  child: Text('${statusLabel(c.rejectStatus)}…'),
                ),
              ],
            ),
          ],
          const SizedBox(height: 16),
          AuditLog(c: c),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: SapsColors.goldLight,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(text,
            style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: SapsColors.goldText)),
      );
}

/// Who did what and when. Read-only: officers cannot edit this.
class AuditLog extends StatefulWidget {
  const AuditLog({super.key, required this.c});
  final SapsCase c;

  @override
  State<AuditLog> createState() => _AuditLogState();
}

class _AuditLogState extends State<AuditLog> {
  late Future<List<AuditEntry>> _f;

  @override
  void initState() {
    super.initState();
    _f = SapsCaseService.instance.audit(widget.c);
  }

  @override
  void didUpdateWidget(covariant AuditLog old) {
    super.didUpdateWidget(old);
    if (old.c.id != widget.c.id || old.c.status != widget.c.status) {
      _f = SapsCaseService.instance.audit(widget.c);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: SapsColors.background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Audit log',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
          const SizedBox(height: 6),
          FutureBuilder<List<AuditEntry>>(
            future: _f,
            builder: (context, snap) {
              final lines = <String>[];
              if (snap.hasData) {
                for (final e in snap.data!) {
                  lines.add('${formatTime(e.at)} · ${e.officer} · ${e.text}'
                      '${e.reason != null ? ' (${e.reason})' : ''}');
                }
              }
              lines.add('${formatTime(widget.c.createdAt)} · Case created');
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final l in lines)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 2),
                      child: Text(l,
                          style: const TextStyle(
                              fontSize: 13, color: SapsColors.textSecondary)),
                    ),
                  if (snap.hasError)
                    const Text("Couldn't load the log.",
                        style: TextStyle(
                            fontSize: 13, color: SapsColors.redText)),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
