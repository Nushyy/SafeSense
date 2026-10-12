import 'package:flutter/material.dart';

class CrimeFilterSheet extends StatelessWidget {
  final String selectedCrime;

  const CrimeFilterSheet({
    super.key,
    required this.selectedCrime,
  });

  static const List<String> crimes = [
    'All Crime',
    'Antisocial Behaviour',
    'Bicycle Theft',
    'Burglary',
    'Criminal Damage & Arson',
    'Drugs',
    'Other Crime',
    'Other Theft',
    'Possession of Weapons',
    'Public Order',
    'Robbery',
    'Shoplifting',
    'Theft from Person',
    'Vehicle Crime',
    'Violence & Sexual Offences',
  ];

  // Returns an icon for each crime type
  IconData getCrimeIcon(String crime) {
    switch (crime) {
      case 'All Crime':
        return Icons.apps_rounded;

      case 'Antisocial Behaviour':
        return Icons.groups_rounded;

      case 'Bicycle Theft':
        return Icons.pedal_bike_rounded;

      case 'Burglary':
        return Icons.home_work_rounded;

      case 'Criminal Damage & Arson':
        return Icons.local_fire_department_rounded;

      case 'Drugs':
        return Icons.medication_rounded;

      case 'Other Crime':
        return Icons.warning_amber_rounded;

      case 'Other Theft':
        return Icons.inventory_2_rounded;

      case 'Possession of Weapons':
        return Icons.security_rounded;

      case 'Public Order':
        return Icons.campaign_rounded;

      case 'Robbery':
        return Icons.person_off_rounded;

      case 'Shoplifting':
        return Icons.shopping_bag_rounded;

      case 'Theft from Person':
        return Icons.wallet_rounded;

      case 'Vehicle Crime':
        return Icons.directions_car_rounded;

      case 'Violence & Sexual Offences':
        return Icons.report_rounded;

      default:
        return Icons.local_police_outlined;
    }
  }

  // Gives every crime category its own colour
  Color getCrimeColor(String crime) {
    switch (crime) {
      case 'All Crime':
        return const Color(0xFF4F46E5);

      case 'Antisocial Behaviour':
        return const Color(0xFF7C3AED);

      case 'Bicycle Theft':
        return const Color(0xFF0891B2);

      case 'Burglary':
        return const Color(0xFFF59E0B);

      case 'Criminal Damage & Arson':
        return const Color(0xFFEF4444);

      case 'Drugs':
        return const Color(0xFF10B981);

      case 'Other Crime':
        return const Color(0xFF64748B);

      case 'Other Theft':
        return const Color(0xFF0EA5E9);

      case 'Possession of Weapons':
        return const Color(0xFFDC2626);

      case 'Public Order':
        return const Color(0xFF8B5CF6);

      case 'Robbery':
        return const Color(0xFFE11D48);

      case 'Shoplifting':
        return const Color(0xFF14B8A6);

      case 'Theft from Person':
        return const Color(0xFFF97316);

      case 'Vehicle Crime':
        return const Color(0xFF2563EB);

      case 'Violence & Sexual Offences':
        return const Color(0xFFBE123C);

      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.72,

        child: Column(
          children: [
            const SizedBox(height: 10),

            // Drag indicator
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
              'Filter by Crime',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),

            const SizedBox(height: 10),

            Expanded(
              child: ListView.separated(
                itemCount: crimes.length,

                separatorBuilder: (_, __) => const Divider(
                  height: 1,
                  indent: 76,
                  endIndent: 20,
                ),

                itemBuilder: (context, index) {
                  final crime = crimes[index];
                  final isSelected = crime == selectedCrime;

                  final crimeColor = getCrimeColor(crime);
                  final crimeIcon = getCrimeIcon(crime);

                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 5,
                    ),

                    // Coloured circle + crime icon
                    leading: Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,

                        // Soft transparent version of the category colour
                        color: crimeColor.withOpacity(0.14),
                      ),

                      child: Icon(
                        crimeIcon,
                        color: crimeColor,
                        size: 22,
                      ),
                    ),

                    title: Text(
                      crime,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: isSelected
                            ? FontWeight.w700
                            : FontWeight.w500,
                      ),
                    ),

                    // Check mark for active filter
                    trailing: isSelected
                        ? Container(
                            width: 26,
                            height: 26,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: crimeColor.withOpacity(0.14),
                            ),
                            child: Icon(
                              Icons.check_rounded,
                              color: crimeColor,
                              size: 18,
                            ),
                          )
                        : null,

                    onTap: () {
                      Navigator.pop(
                        context,
                        crime,
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