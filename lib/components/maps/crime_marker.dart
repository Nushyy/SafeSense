import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class CrimeMarker {
  final String crime;
  final LatLng location;

  CrimeMarker({
    required this.crime,
    required this.location,
  });

  static IconData getIcon(String crime) {
    switch (crime) {
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

  static Color getColor(String crime) {
    switch (crime) {
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
        return Colors.indigo;
    }
  }

  static Marker build(CrimeMarker crime) {
    return Marker(
      point: crime.location,
      width: 55,
      height: 55,

      child: Container(
        decoration: BoxDecoration(
          color: getColor(crime.crime),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: getColor(crime.crime).withOpacity(0.5),
              blurRadius: 12,
              spreadRadius: 3,
            )
          ],
        ),

        child: Icon(
          getIcon(crime.crime),
          color: Colors.white,
          size: 30,
        ),
      ),
    );
  }
}