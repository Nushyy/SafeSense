import 'package:flutter/material.dart';

class StatsHeader extends StatelessWidget {
  final int totalIncidents;
  final String forceInCharge;
  final String neighbourhood;
  final String municipality;
  final String period;

  const StatsHeader({
    super.key,
    required this.totalIncidents,
    this.forceInCharge = "SAPS Park Rd Police Station",
    this.neighbourhood = "Park West",
    this.municipality = "Manguang",
    this.period = "Last 12 Months",
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
      ),
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          children: [
            _StatRow(label: "Force in Charge", value: forceInCharge),
            const SizedBox(height: 16),
            _StatRow(label: "Neighbourhood", value: neighbourhood),
            const SizedBox(height: 16),
            _StatRow(label: "Municipality", value: municipality),
            const SizedBox(height: 16),
            _StatRow(label: "Period", value: period),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
            _StatRow(
              label: "Total Incidents",
              value: totalIncidents.toString(),
              isBold: true,
            ),
          ],
        ),
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isBold;

  const _StatRow({
    required this.label,
    required this.value,
    this.isBold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          flex: 5,
          child: Text(
            label,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 16,
            ),
          ),
        ),
        Expanded(
          flex: 6,
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: TextStyle(
              fontSize: 16,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}