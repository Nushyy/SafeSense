import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'community_data.dart';

class CreatePostScreen extends StatefulWidget {
  final Suburb? initialArea;
  const CreatePostScreen({super.key, this.initialArea});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  PostCategory _category = PostCategory.watch;
  Suburb? _area;

  @override
  void initState() {
    super.initState();
    _area = widget.initialArea;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  InputDecoration _decoration(String label) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.divider),
    );
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: AppColors.surface,
      border: border,
      enabledBorder: border,
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final area = _area!;
    await communityRepo.addPost(
      area: area,
      category: _category,
      title: _titleController.text.trim(),
      body: _bodyController.text.trim(),
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('Posted to ${area.name}')));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final allSuburbs = [for (final c in communityRepo.cities) ...c.suburbs];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.darkBlue,
        foregroundColor: Colors.white,
        title: const Text('New post'),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text('Category',
                  style: TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final c in PostCategory.values)
                    ChoiceChip(
                      label: Text(c.tagLabel),
                      selected: _category == c,
                      selectedColor: c.color.withValues(alpha: 0.18),
                      labelStyle: TextStyle(
                        color: _category == c
                            ? c.color
                            : AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                      onSelected: (_) => setState(() => _category = c),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<Suburb>(
                initialValue: _area,
                isExpanded: true,
                decoration: _decoration('Area'),
                items: [
                  for (final s in allSuburbs)
                    DropdownMenuItem(value: s, child: Text(s.label)),
                ],
                onChanged: (v) => setState(() => _area = v),
                validator: (v) => v == null ? 'Choose an area' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _titleController,
                textCapitalization: TextCapitalization.sentences,
                decoration: _decoration('Title'),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Add a short title'
                    : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _bodyController,
                textCapitalization: TextCapitalization.sentences,
                minLines: 4,
                maxLines: 8,
                decoration: _decoration('What is happening?'),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Describe what happened'
                    : null,
              ),
              const SizedBox(height: 8),
              const Text(
                'Share what you saw, not who you think did it. In an emergency, call 10111.',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
              const SizedBox(height: 20),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: _submit,
                child: const Text('Post to bulletin board'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}