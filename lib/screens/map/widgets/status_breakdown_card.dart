import 'package:flutter/material.dart';

class StatusBreakdownCard extends StatelessWidget {
  final Map<String, int> statuses;

  const StatusBreakdownCard({
    super.key,
    required this.statuses,
  });

  Color statusColor(String status) {
    switch (status) {

      case "Still In Progress":
        return Colors.green;

      case "Under Investigation":
        return Colors.purple;

      case "Offender Dealt With":
        return Colors.orange;

      case "No Further Action":
        return Colors.blue;

      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(18),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.05),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          const Text(
            "Status Breakdown",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 18),

          ...statuses.entries.map((status) {

            return Padding(
              padding: const EdgeInsets.only(bottom: 16),

              child: Row(
                children: [

                  Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: statusColor(status.key),
                      shape: BoxShape.circle,
                    ),
                  ),

                  const SizedBox(width: 14),

                  Expanded(
                    child: Text(
                      status.key,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),

                  Text(
                    status.value.toString(),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}