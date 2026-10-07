import 'package:flutter/material.dart';

import '../../models/profile_data.dart';
import '../../theme/app_colors.dart';
import 'edit_profile_screen.dart';

class PersonalDetailsScreen extends StatefulWidget {
  const PersonalDetailsScreen({super.key});

  @override
  State<PersonalDetailsScreen> createState() =>
      _PersonalDetailsScreenState();
}

class _PersonalDetailsScreenState extends State<PersonalDetailsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Personal Details',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Center(
            child: Text(
              'ACCOUNT INFORMATION',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.4,
                color: AppColors.textSecondary,
              ),
            ),
          ),

          const SizedBox(height: 12),

          _infoCard(
            children: [
              _infoRow('Full Name', ProfileData.fullName),
              _divider(),
              _infoRow('Phone Number', ProfileData.phoneNumber),
              _divider(),
              _infoRow('Email Address', ProfileData.email),
              _divider(),
              _infoRow('Username', ProfileData.username),
              _divider(),
              _infoRow('Town / Location', ProfileData.town),
            ],
          ),

          const SizedBox(height: 22),

          const Text(
            'Your name, phone number and email are linked to your account registration. You can manage your profile preferences separately.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
              height: 1.5,
            ),
          ),

          const SizedBox(height: 22),

          SizedBox(
            height: 50,
            child: OutlinedButton.icon(
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const EditProfileScreen(),
                  ),
                );

                setState(() {});
              },
              icon: const Icon(Icons.edit_outlined),
              label: const Text('Edit Profile Preferences'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoCard({required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(children: children),
    );
  }

  Widget _infoRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 18,
        vertical: 17,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 15,
              ),
            ),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider() {
    return const Divider(
      height: 1,
      indent: 18,
      endIndent: 18,
      color: AppColors.divider,
    );
  }
}