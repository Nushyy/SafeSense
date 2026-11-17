import 'package:flutter/material.dart';

import '../../../services/saps/saps_case.dart';
import '../saps_colors.dart';

/// Small coloured label. Icon + word, so it never relies on colour alone.
class KindTag extends StatelessWidget {
  const KindTag({super.key, required this.isSos});
  final bool isSos;

  @override
  Widget build(BuildContext context) {
    final bg = isSos ? SapsColors.red : SapsColors.blueTint;
    final fg = isSos ? Colors.white : SapsColors.blueTintText;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(isSos ? Icons.crisis_alert : Icons.description_outlined,
              size: 14, color: fg),
          const SizedBox(width: 4),
          Text(isSos ? 'SOS' : 'Report',
              style: TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w600, color: fg)),
        ],
      ),
    );
  }
}

class CaseList extends StatelessWidget {
  const CaseList({
    super.key,
    required this.cases,
    required this.counts,
    required this.bucket,
    required this.onBucket,
    required this.selectedId,
    required this.flashId,
    required this.onSelect,
    this.showSelection = true,
  });

  final List<SapsCase> cases;
  final Map<CaseBucket, int> counts;
  final CaseBucket bucket;
  final ValueChanged<CaseBucket> onBucket;
  final String? selectedId;
  final String? flashId;
  final ValueChanged<SapsCase> onSelect;
  final bool showSelection;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(10),
          child: Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _Filter('Needs action', counts[CaseBucket.needsAction] ?? 0,
                  bucket == CaseBucket.needsAction,
                  () => onBucket(CaseBucket.needsAction)),
              _Filter('In progress', counts[CaseBucket.inProgress] ?? 0,
                  bucket == CaseBucket.inProgress,
                  () => onBucket(CaseBucket.inProgress)),
              _Filter('Closed', counts[CaseBucket.closed] ?? 0,
                  bucket == CaseBucket.closed,
                  () => onBucket(CaseBucket.closed)),
            ],
          ),
        ),
        const Divider(height: 1, color: SapsColors.border),
        Expanded(
          child: cases.isEmpty
              ? const Padding(
                  padding: EdgeInsets.all(16),
                  child: Align(
                    alignment: Alignment.topLeft,
                    child: Text(
                      'Nothing here. New cases appear automatically.',
                      style: TextStyle(color: SapsColors.textSecondary),
                    ),
                  ),
                )
              : ListView.separated(
                  itemCount: cases.length,
                  separatorBuilder: (_, _) =>
                      const Divider(height: 1, color: SapsColors.border),
                  itemBuilder: (_, i) {
                    final c = cases[i];
                    return _Row(
                      c: c,
                      selected: showSelection && c.id == selectedId,
                      flash: c.id == flashId,
                      onTap: () => onSelect(c),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _Filter extends StatelessWidget {
  const _Filter(this.label, this.count, this.on, this.onTap);
  final String label;
  final int count;
  final bool on;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: on ? SapsColors.navy : SapsColors.surface,
      shape: StadiumBorder(
        side: BorderSide(color: on ? SapsColors.navy : SapsColors.fieldBorder),
      ),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: Container(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          alignment: Alignment.center,
          child: Text('$label ($count)',
              style: TextStyle(
                  fontSize: 14,
                  color: on ? Colors.white : SapsColors.navy,
                  fontWeight: FontWeight.w500)),
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.c,
    required this.selected,
    required this.flash,
    required this.onTap,
  });

  final SapsCase c;
  final bool selected;
  final bool flash;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final overdue = c.overdue;
    final subtitle = [
      if (c.area != null && c.area!.isNotEmpty) c.area!,
      if (!c.isOpen) statusLabel(c.status),
    ].join(' · ');

    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      decoration: BoxDecoration(
        color: flash
            ? SapsColors.redTint
            : selected
                ? const Color(0xFFEEF2F8)
                : SapsColors.surface,
        border: Border(
          left: BorderSide(
            color: selected ? SapsColors.gold : Colors.transparent,
            width: 4,
          ),
        ),
      ),
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 56),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    KindTag(isSos: c.isSos),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(c.displayTitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: SapsColors.navy)),
                    ),
                    if (c.isOpen) _Wait(c: c, overdue: overdue),
                  ],
                ),
                if (subtitle.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(subtitle,
                        style: const TextStyle(
                            fontSize: 13, color: SapsColors.textSecondary)),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Wait extends StatelessWidget {
  const _Wait({required this.c, required this.overdue});
  final SapsCase c;
  final bool overdue;

  @override
  Widget build(BuildContext context) {
    final text = formatWait(c.waiting);
    if (!overdue) {
      return Text(text,
          style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: SapsColors.textSecondary));
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: SapsColors.red,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.timer_outlined, size: 14, color: Colors.white),
          const SizedBox(width: 4),
          Text('Overdue · $text',
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.white)),
        ],
      ),
    );
  }
}
