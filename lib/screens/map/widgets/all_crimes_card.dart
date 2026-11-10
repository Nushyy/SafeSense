import 'package:flutter/material.dart';

class AllCrimesCard extends StatelessWidget {
  final Map<String, int> crimes;

  const AllCrimesCard({
    super.key,
    required this.crimes,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),

      padding: const EdgeInsets.all(20),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),

        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.05),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [

          const Text(
            "All Crime Categories",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),

          const SizedBox(height: 18),

          ...crimes.entries.map((crime) {

            final color = getCrimeColor(crime.key);

            return Padding(
              padding: const EdgeInsets.only(bottom: 14),

              child: Row(
                children: [

                  Container(
                    width: 42,
                    height: 42,

                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: color.withOpacity(.14),
                    ),

                    child: Icon(
                      getCrimeIcon(crime.key),
                      color: color,
                      size: 22,
                    ),
                  ),

                  const SizedBox(width: 14),

                  Expanded(
                    child: Text(
                      crime.key,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),

                  Text(
                    crime.value.toString(),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
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

  //=================== ICONS ===================

  IconData getCrimeIcon(String crime) {
    switch (crime) {
      case 'All Crime':
        return Icons.apps_rounded;

      case 'Antisocial Behavior':
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
        return Icons.local_police;
    }
  }

  //=================== COLOURS ===================

  Color getCrimeColor(String crime) {
    switch (crime) {
      case 'All Crime':
        return const Color(0xFF4F46E5);

      case 'Antisocial Behavior':
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
}