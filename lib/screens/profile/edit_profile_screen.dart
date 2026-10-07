import 'package:flutter/material.dart';

import '../../models/profile_data.dart';
import '../../theme/app_colors.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() =>
      _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late TextEditingController usernameController;
  late TextEditingController townController;
  late TextEditingController bioController;

  @override
  void initState() {
    super.initState();

    usernameController =
        TextEditingController(text: ProfileData.username);

    townController =
        TextEditingController(text: ProfileData.town);

    bioController =
        TextEditingController(text: ProfileData.bio);
  }

  @override
  void dispose() {
    usernameController.dispose();
    townController.dispose();
    bioController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,

      appBar: AppBar(
        title: const Text(
          'Edit Profile',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),

      body: ListView(
        padding: const EdgeInsets.all(22),
        children: [
          Center(
            child: Stack(
              children: [
                CircleAvatar(
                  radius: 52,
                  backgroundColor: AppColors.lightBlue,
                  child: Text(
                    ProfileData.initials,
                    style: const TextStyle(
                      color: AppColors.primaryBlue,
                      fontSize: 27,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: const BoxDecoration(
                      color: AppColors.primaryBlue,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.camera_alt_outlined,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 30),

          const Center(
            child: Text(
              'PROFILE PREFERENCES',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.4,
                color: AppColors.textSecondary,
              ),
            ),
          ),

          const SizedBox(height: 18),

          _buildField(
            controller: usernameController,
            label: 'Username',
            icon: Icons.alternate_email,
          ),

          const SizedBox(height: 16),

          _buildField(
            controller: townController,
            label: 'Town / Location',
            icon: Icons.location_on_outlined,
          ),

          const SizedBox(height: 16),

          _buildField(
            controller: bioController,
            label: 'Bio',
            icon: Icons.edit_note_outlined,
            maxLines: 3,
          ),

          const SizedBox(height: 30),

          const Center(
            child: Text(
              'ACCOUNT DETAILS',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.4,
                color: AppColors.textSecondary,
              ),
            ),
          ),

          const SizedBox(height: 14),

          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              children: [
                _readOnlyRow(
                  'Name',
                  ProfileData.fullName,
                ),
                const Divider(),
                _readOnlyRow(
                  'Email',
                  ProfileData.email,
                ),
                const Divider(),
                _readOnlyRow(
                  'Phone',
                  ProfileData.phoneNumber,
                ),
              ],
            ),
          ),

          const SizedBox(height: 30),

          SizedBox(
            height: 52,
            child: ElevatedButton(
              onPressed: _saveProfile,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text(
                'Save Changes',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _readOnlyRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _saveProfile() {
    ProfileData.username = usernameController.text.trim();
    ProfileData.town = townController.text.trim();
    ProfileData.bio = bioController.text.trim();

    Navigator.pop(context);
  }
}