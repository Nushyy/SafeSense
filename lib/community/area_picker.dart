import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'community_data.dart';

/// What the user picked in the area picker.
class AreaChoice {
  final Suburb? area; // a real area from the list
  final bool isOther; // "Other" (create-post screen only)
  const AreaChoice.area(Suburb a)
      : area = a,
        isOther = false;
  const AreaChoice.other()
      : area = null,
        isOther = true;
  const AreaChoice.all() // "All areas" (bulletin board filter only)
      : area = null,
        isOther = false;
}

/// Searchable list: Province -> towns / suburbs.
/// Returns null if the user closes the sheet without choosing.
Future<AreaChoice?> showAreaPicker(
  BuildContext context, {
  Suburb? selected,
  bool allowAll = false,
  bool allowOther = false,
  bool otherSelected = false,
}) {
  return showModalBottomSheet<AreaChoice>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => _AreaPickerSheet(
      selected: selected,
      allowAll: allowAll,
      allowOther: allowOther,
      otherSelected: otherSelected,
    ),
  );
}

class _AreaPickerSheet extends StatefulWidget {
  final Suburb? selected;
  final bool allowAll;
  final bool allowOther;
  final bool otherSelected;
  const _AreaPickerSheet({
    required this.selected,
    required this.allowAll,
    required this.allowOther,
    required this.otherSelected,
  });

  @override
  State<_AreaPickerSheet> createState() => _AreaPickerSheetState();
}

class _AreaPickerSheetState extends State<_AreaPickerSheet> {
  String _query = '';
  static const _check = Icon(Icons.check, color: AppColors.primaryBlue);

  @override
  Widget build(BuildContext context) {
    final q = _query.trim().toLowerCase();
    final provinces = communityRepo.cities;

    // Search results (flat list across all provinces).
    final results = <Suburb>[];
    if (q.isNotEmpty) {
      for (final p in provinces) {
        for (final s in p.suburbs) {
          if (s.name.toLowerCase().contains(q) ||
              s.city.toLowerCase().contains(q)) {
            results.add(s);
            if (results.length >= 100) break;
          }
        }
        if (results.length >= 100) break;
      }
    }

    final otherTile = ListTile(
      leading: const Icon(Icons.edit_location_alt_outlined),
      title: const Text('Other'),
      subtitle: const Text("My town or village isn't listed"),
      trailing: widget.otherSelected ? _check : null,
      onTap: () => Navigator.pop(context, const AreaChoice.other()),
    );

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.8,
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 20, 20, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('Choose your area',
                    style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w700)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: TextField(
                onChanged: (v) => setState(() => _query = v),
                decoration: InputDecoration(
                  hintText: 'Search town, village or suburb',
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: AppColors.softSurface,
                  contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(28),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            Expanded(
              child: ListView(
                children: [
                  if (widget.allowAll && q.isEmpty)
                    ListTile(
                      leading: const Icon(Icons.public),
                      title: const Text('All areas'),
                      trailing: widget.selected == null ? _check : null,
                      onTap: () =>
                          Navigator.pop(context, const AreaChoice.all()),
                    ),
                  if (widget.allowOther) otherTile,
                  if (q.isNotEmpty) ...[
                    if (results.isEmpty)
                      Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          widget.allowOther
                              ? 'No match for "$_query". Choose "Other" above to type your own.'
                              : 'No match for "$_query".',
                          style:
                              const TextStyle(color: AppColors.textSecondary),
                        ),
                      ),
                    for (final s in results)
                      ListTile(
                        leading: const Icon(Icons.place_outlined),
                        title: Text(s.name),
                        subtitle: Text(s.city),
                        trailing: widget.selected?.id == s.id ? _check : null,
                        onTap: () => Navigator.pop(context, AreaChoice.area(s)),
                      ),
                  ] else
                    for (final province in provinces)
                      ExpansionTile(
                        initiallyExpanded: widget.selected != null &&
                            province.suburbs
                                .any((s) => s.id == widget.selected!.id),
                        leading: const Icon(Icons.map_outlined),
                        title: Text(province.name),
                        subtitle: Text('${province.suburbs.length} areas'),
                        children: [
                          for (final s in province.suburbs)
                            ListTile(
                              contentPadding:
                                  const EdgeInsets.only(left: 72, right: 16),
                              title: Text(s.name),
                              subtitle: s.city == province.name
                                  ? null
                                  : Text(s.city),
                              trailing:
                                  widget.selected?.id == s.id ? _check : null,
                              onTap: () =>
                                  Navigator.pop(context, AreaChoice.area(s)),
                            ),
                        ],
                      ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}