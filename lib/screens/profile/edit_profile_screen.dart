
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../services/profile_repository.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _neighborhoodController = TextEditingController();

  final ImagePicker _imagePicker = ImagePicker();

  ProfileRecord? _profile;

  bool _loading = true;
  bool _saving = false;
  bool _uploadingPicture = false;
  bool _removingPicture = false;

  String? _loadError;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _usernameController.dispose();
    _phoneController.dispose();
    _neighborhoodController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    try {
      final profile = await ProfileRepository.loadCurrentProfile();

      if (!mounted) return;

      _profile = profile;
      _fullNameController.text = profile.fullName;
      _usernameController.text = profile.username;
      _phoneController.text = profile.phoneNumber;
      _neighborhoodController.text = profile.neighborhood;

      setState(() {
        _loading = false;
        _loadError = null;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _loading = false;
        _loadError = error.toString().replaceFirst('Bad state: ', '');
      });
    }
  }

  Future<void> _pickAndUploadPicture() async {
    if (_uploadingPicture || _removingPicture) return;

    try {
      final pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1600,
        maxHeight: 1600,
      );

      if (pickedFile == null) return;

      final imageBytes = await pickedFile.readAsBytes();

      if (imageBytes.length > 5 * 1024 * 1024) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select an image smaller than 5 MB.'),
          ),
        );
        return;
      }

      final extensionIndex = pickedFile.name.lastIndexOf('.');

      if (extensionIndex == -1) {
        throw Exception('The selected image has an unsupported file format.');
      }

      final extension = pickedFile.name
          .substring(extensionIndex + 1)
          .toLowerCase();

      setState(() => _uploadingPicture = true);

      final updatedProfile = await ProfileRepository.uploadProfilePicture(
        imageBytes: imageBytes,
        fileExtension: extension,
      );

      if (!mounted) return;

      setState(() {
        _profile = updatedProfile;
        _uploadingPicture = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile picture updated successfully.'),
        ),
      );
    } catch (error) {
      if (!mounted) return;

      setState(() => _uploadingPicture = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error.toString().replaceFirst('Exception: ', ''),
          ),
        ),
      );
    }
  }

  Future<void> _removePicture() async {
    if (_uploadingPicture || _removingPicture) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Remove profile picture?'),
        content: const Text(
          'Your profile picture will be removed and your initials '
          'will be displayed instead.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _removingPicture = true);

    try {
      final updatedProfile =
          await ProfileRepository.removeProfilePicture();

      if (!mounted) return;

      setState(() {
        _profile = updatedProfile;
        _removingPicture = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile picture removed.'),
        ),
      );
    } catch (error) {
      if (!mounted) return;

      setState(() => _removingPicture = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error.toString().replaceFirst('Exception: ', ''),
          ),
        ),
      );
    }
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);

    try {
      await ProfileRepository.saveCurrentProfile(
        fullName: _fullNameController.text,
        username: _usernameController.text,
        phoneNumber: _phoneController.text,
        neighborhood: _neighborhoodController.text,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated successfully.'),
        ),
      );

      Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;

      final message = error.toString()
          .replaceFirst('Exception: ', '')
          .replaceFirst('Bad state: ', '')
          .replaceFirst('Invalid argument(s): ', '');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _buildProfilePicture(ThemeData theme) {
    final colors = theme.colorScheme;
    final profile = _profile;

    final avatarUrl = ProfileRepository.getAvatarUrl(
      profile?.avatarPath,
    );

    final busy = _uploadingPicture || _removingPicture;

    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            CircleAvatar(
              radius: 43,
              backgroundColor: colors.primaryContainer,
              backgroundImage: avatarUrl != null
                  ? NetworkImage(avatarUrl)
                  : null,
              child: avatarUrl == null
                  ? Text(
                      profile?.initials ?? 'S',
                      style: TextStyle(
                        color: colors.onPrimaryContainer,
                        fontSize: 25,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : null,
            ),
            if (busy)
              Container(
                width: 86,
                height: 86,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.55),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 3,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 8,
          runSpacing: 8,
          children: [
            OutlinedButton.icon(
              onPressed: busy ? null : _pickAndUploadPicture,
              icon: const Icon(Icons.camera_alt_outlined, size: 18),
              label: Text(
                avatarUrl == null ? 'Add photo' : 'Change photo',
              ),
            ),
            if (avatarUrl != null)
              TextButton.icon(
                onPressed: busy ? null : _removePicture,
                icon: const Icon(Icons.delete_outline, size: 18),
                label: const Text('Remove'),
                style: TextButton.styleFrom(
                  foregroundColor: colors.error,
                ),
              ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Edit Profile')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _loadError != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.cloud_off_outlined, size: 42),
                        const SizedBox(height: 12),
                        Text(
                          _loadError!,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        OutlinedButton.icon(
                          onPressed: () {
                            setState(() {
                              _loading = true;
                              _loadError = null;
                            });
                            _loadProfile();
                          },
                          icon: const Icon(Icons.refresh),
                          label: const Text('Try again'),
                        ),
                      ],
                    ),
                  ),
                )
              : Form(
                  key: _formKey,
                  child: ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: colors.surface,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: colors.outlineVariant,
                          ),
                        ),
                        child: Column(
                          children: [
                            _buildProfilePicture(theme),
                            const SizedBox(height: 16),
                            Text(
                              'Your account details',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Manage your profile picture and account information.',
                              textAlign: TextAlign.center,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colors.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 22),
                      TextFormField(
                        controller: _fullNameController,
                        textCapitalization: TextCapitalization.words,
                        decoration: const InputDecoration(
                          labelText: 'Full name',
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                        validator: (value) =>
                            value == null || value.trim().isEmpty
                                ? 'Enter your full name.'
                                : null,
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _usernameController,
                        autocorrect: false,
                        decoration: const InputDecoration(
                          labelText: 'Username',
                          prefixIcon: Icon(Icons.alternate_email),
                          helperText:
                              '3–30 letters, numbers, underscores or periods.',
                        ),
                        validator: (value) {
                          final username = (value ?? '').trim().replaceFirst(
                                RegExp(r'^@'),
                                '',
                              );

                          if (!RegExp(r'^[a-zA-Z0-9_.]{3,30}$')
                              .hasMatch(username)) {
                            return 'Enter a valid username (3–30 characters).';
                          }

                          return null;
                        },
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          labelText: 'Phone number',
                          prefixIcon: Icon(Icons.phone_outlined),
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _neighborhoodController,
                        textCapitalization: TextCapitalization.words,
                        decoration: const InputDecoration(
                          labelText: 'Town / neighbourhood',
                          prefixIcon: Icon(Icons.location_on_outlined),
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        height: 52,
                        child: FilledButton.icon(
                          onPressed: _saving ? null : _save,
                          icon: _saving
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.save_outlined),
                          label: Text(
                            _saving ? 'Saving…' : 'Save changes',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}
