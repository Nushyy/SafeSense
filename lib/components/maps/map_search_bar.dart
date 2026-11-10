import 'package:flutter/material.dart';

class MapSearchBar extends StatelessWidget {
  final VoidCallback? onTap;

  const MapSearchBar({
    super.key,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 54,
        padding: const EdgeInsets.symmetric(horizontal: 18),
        decoration: BoxDecoration(
          color: const Color.fromARGB(255, 20, 18, 48),
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.black,
              blurRadius: 11,
              offset: const Offset(0, 5),
            )
          ],
        ),

        child: const Row(
          children: [

            Icon(
              Icons.search,
              color: Colors.grey,
            ),

            SizedBox(width: 12),

            Expanded(
              child: Text(
                "Search area or address",
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 15,
                ),
              ),
            ),

          ],
        ),
      ),
    );
  }
}