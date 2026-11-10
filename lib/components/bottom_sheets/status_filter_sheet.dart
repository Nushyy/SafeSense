import 'package:flutter/material.dart';

class StatusFilterSheet extends StatelessWidget {
  final String selectedStatus;

  const StatusFilterSheet({
    super.key,
    required this.selectedStatus,
  });

  static const List<String> statuses = [
    'All Status',
    'Still In Progress',
    'Offender Dealt With',
    'No Further Action',
    'Under Investigation',
  ];

  // Status colours
  Color statusColor(String status) {
    switch (status) {
      case 'Still In Progress':
        return Colors.green;

      case 'Offender Dealt With':
        return Colors.orange;

      case 'No Further Action':
        return Colors.blue;

      case 'Under Investigation':
        return Colors.purple;

      default:
        return Colors.grey;
    }
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
              'Filter by Status',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),

            const SizedBox(height: 10),

            Expanded(
              child: ListView.separated(
                itemCount: statuses.length,

                separatorBuilder: (_, __) => const Divider(
                  height: 1,
                  indent: 70,
                ),

                itemBuilder: (context, index) {
                  final status = statuses[index];
                  final isSelected = status == selectedStatus;

                  final colour = statusColor(status);

                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 4,
                    ),

                    leading: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: colour,
                        shape: BoxShape.circle,
                      ),
                    ),

                    title: Text(
                      status,
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

                    onTap: () {
                      Navigator.pop(
                        context,
                        status,
                      );
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