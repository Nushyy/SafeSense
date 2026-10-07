import 'package:flutter/material.dart';

import '../../models/trusted_user.dart';
import '../../services/app_session.dart';
import '../../theme/app_colors.dart';

class AddTrustedUserScreen extends StatefulWidget {
  const AddTrustedUserScreen({super.key});

  @override
  State<AddTrustedUserScreen> createState() =>
      _AddTrustedUserScreenState();
}

class _AddTrustedUserScreenState
    extends State<AddTrustedUserScreen> {
  final nameController = TextEditingController();
  final usernameController = TextEditingController();

  String relationship = 'Friend';
  bool locationSharing = true;

  final relationships = [
    'Family',
    'Friend',
    'Partner',
    'Neighbour',
    'Other',
  ];

  @override
  void dispose() {
    nameController.dispose();
    usernameController.dispose();

    super.dispose();
  }

  void addUser() {
    final name = nameController.text.trim();
    final username = usernameController.text.trim();

    if (name.isEmpty || username.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please enter a name and username.',
          ),
        ),
      );

      return;
    }

    AppSession.addTrustedUser(
      TrustedUser(
        name: name,
        username: username.startsWith('@')
            ? username
            : '@$username',
        relationship: relationship,
        locationSharing: locationSharing,
      ),
    );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Add Trusted User',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            const Text(
              'Add someone you trust',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              'This person will become part of your Trusted Circle.',
              style: TextStyle(
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withOpacity(0.65),
              ),
            ),

            const SizedBox(height: 28),

            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Full Name',
                prefixIcon:
                    Icon(Icons.person_outline),
              ),
            ),

            const SizedBox(height: 14),

            TextField(
              controller: usernameController,
              decoration: const InputDecoration(
                labelText: 'Username',
                prefixIcon:
                    Icon(Icons.alternate_email),
              ),
            ),

            const SizedBox(height: 14),

            DropdownButtonFormField<String>(
              value: relationship,
              decoration: const InputDecoration(
                labelText: 'Relationship',
                prefixIcon:
                    Icon(Icons.people_outline),
              ),
              items: relationships.map((item) {
                return DropdownMenuItem(
                  value: item,
                  child: Text(item),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    relationship = value;
                  });
                }
              },
            ),

            const SizedBox(height: 20),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius:
                    BorderRadius.circular(18),
                border: Border.all(
                  color:
                      Theme.of(context).dividerColor,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.success
                          .withOpacity(0.10),
                      borderRadius:
                          BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.location_on_outlined,
                      color: AppColors.success,
                    ),
                  ),

                  const SizedBox(width: 12),

                  const Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Share my location',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 3),
                        Text(
                          'Allow this trusted user to see your location.',
                          style: TextStyle(
                            color:
                                AppColors.textSecondary,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),

                  Switch(
                    value: locationSharing,
                    onChanged: (value) {
                      setState(() {
                        locationSharing = value;
                      });
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: addUser,
                icon: const Icon(Icons.person_add_alt_1),
                label: const Text(
                  'Add to Trusted Circle',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      AppColors.primaryBlue,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}