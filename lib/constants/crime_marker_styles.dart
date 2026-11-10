import 'package:flutter/material.dart';

class CrimeMarkerStyles {

  static IconData icon(String crime){

    switch(crime){

      case "Burglary":
        return Icons.home;

      case "Robbery":
        return Icons.money;

      case "Vehicle Crime":
        return Icons.directions_car;

      case "Violence & Sexual Offences":
        return Icons.warning_rounded;

      case "Drugs":
        return Icons.medication;

      case "Bicycle Theft":
        return Icons.pedal_bike;

      case "Shoplifting":
        return Icons.shopping_bag;

      case "Other Theft":
        return Icons.inventory;

      case "Other Crime":
        return Icons.report;

      case "Theft from Person":
        return Icons.person;

      case "Public Order":
        return Icons.groups;

      case "Possession of Weapons":
        return Icons.gpp_bad;

      case "Criminal Damage & Arson":
        return Icons.local_fire_department;

      case "Antisocial Behaviour":
        return Icons.record_voice_over;

      default:
        return Icons.location_on;
    }
  }

  static Color color(String crime){

    switch(crime){

      case "Burglary":
        return Colors.brown;

      case "Robbery":
        return Colors.red;

      case "Vehicle Crime":
        return Colors.blue;

      case "Violence & Sexual Offences":
        return Colors.deepPurple;

      case "Drugs":
        return Colors.green;

      case "Bicycle Theft":
        return Colors.orange;

      case "Shoplifting":
        return Colors.pink;

      case "Other Theft":
        return Colors.amber;

      case "Other Crime":
        return Colors.grey;

      case "Theft from Person":
        return Colors.teal;

      case "Public Order":
        return Colors.indigo;

      case "Possession of Weapons":
        return Colors.black87;

      case "Criminal Damage & Arson":
        return Colors.deepOrange;

      case "Antisocial Behaviour":
        return Colors.cyan;

      default:
        return Colors.grey;
    }
  }

}