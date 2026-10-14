import 'package:flutter/material.dart';

class CrimeFilterChips extends StatelessWidget {
  const CrimeFilterChips({super.key});

  @override
  Widget build(BuildContext context) {
    final filters = [
      "All Crime",
      "Burglary",
      "Robbery",
      "Vehicle Crime",
      "Drugs",
    ];

    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(filters[index]),
              selected: index == 0,
              onSelected: (_) {},
            ),
          );
        },
      ),
    );
  }
}