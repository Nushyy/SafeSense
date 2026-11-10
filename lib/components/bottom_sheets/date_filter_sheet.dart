import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DateFilterSheet extends StatefulWidget {
  final String selectedDate;

  const DateFilterSheet({
    super.key,
    required this.selectedDate,
  });

  @override
  State<DateFilterSheet> createState() => _DateFilterSheetState();
}

class _DateFilterSheetState extends State<DateFilterSheet> {
  late String selected;

  final List<String> dates = [
    "Current Month",
    "Previous Month",
    "Last 12 Months",
    "Custom Range",
  ];

  @override
  void initState() {
    super.initState();
    selected = widget.selectedDate;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.55,

        child: Column(
          children: [
            const SizedBox(height: 10),

            // Drag Handle
            Container(
              width: 42,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(20),
              ),
            ),

            const SizedBox(height: 18),

            const Text(
              "Filter by Date",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),

            const SizedBox(height: 10),

            Expanded(
              child: ListView.separated(
                itemCount: dates.length,

                separatorBuilder: (_, __) => const Divider(
                  height: 1,
                  indent: 20,
                ),

                itemBuilder: (context, index) {
                  final date = dates[index];

                  final isSelected = selected == date;

                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 4,
                    ),

                    title: Text(
                      date,
                      style: TextStyle(
                        fontWeight: isSelected
                            ? FontWeight.w700
                            : FontWeight.w400,
                      ),
                    ),

                    trailing: isSelected
                        ? const Icon(
                            Icons.check_circle,
                            color: Color(0xFF172554),
                          )
                        : null,

                    onTap: () async {
                      if (date == "Custom Range") {
                        final range = await showDateRangePicker(
                          context: context,
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now(),
                        );

                        if (range == null) return;

                        final formatter =
                            DateFormat("dd MMM yyyy");

                        Navigator.pop(
                          context,
                          "${formatter.format(range.start)} - ${formatter.format(range.end)}",
                        );
                      } else {
                        Navigator.pop(context, date);
                      }
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}