import 'package:flutter/material.dart';

class FilterChipButton extends StatelessWidget {

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const FilterChipButton({

    super.key,

    required this.label,
    required this.icon,
    required this.onTap,

  });

  @override
  Widget build(BuildContext context) {

    return GestureDetector(

      onTap: onTap,

      child: Container(

        padding: const EdgeInsets.symmetric(
          horizontal: 10,
          vertical: 8,
        ),

        decoration: BoxDecoration(

          color: Colors.white,

          borderRadius: BorderRadius.circular(24),

          boxShadow: [

            BoxShadow(

              color: Colors.black,

              blurRadius: 10,

            )

          ],

        ),

        child: Row(

          mainAxisSize: MainAxisSize.min,

          children: [

            Icon(
              icon,
              size: 14,
              color: Colors.black,
            ),

            const SizedBox(width: 4),

            Text(
              style: const TextStyle(
                fontSize: 12,
                color: Colors.black,
              ),
              label,
            ),

            const SizedBox(width: 4),

            const Icon(
              Icons.keyboard_arrow_down,
              size: 14,
              color: Colors.black,
            ),

          ],
        ),
      ),
    );
  }
}