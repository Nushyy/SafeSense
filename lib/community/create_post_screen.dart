import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'community_data.dart';
import '../components/BottomNav/bottom_nav_scaffold.dart';

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
  bool _isSubmitting = false;

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
    if (_isSubmitting || !_formKey.currentState!.validate()) return;
    final area = _area;
    if (area == null) return;

    setState(() => _isSubmitting = true);
    try {
      await communityRepo.addPost(
        area: area,
        category: _category,
        title: _titleController.text.trim(),
        body: _bodyController.text.trim(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Posted to ${area.name}')),
      );
      Navigator.pop(context);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not publish your post. Please try again.'),
        ),
      );
      debugPrint('Community post submission failed: $error');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final allSuburbs = [for (final c in communityRepo.cities) ...c.suburbs];

    return BottomNavScaffold(
      currentIndex: 3,
      title: 'SafeSense',
      child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back),
                    tooltip: 'Back to Bulletin Board',
                    color: AppColors.textPrimary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'New Post',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: (Theme.of(context).textTheme.titleLarge?.fontSize ?? 22) - 1,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
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
                validator: (v) {
                  final title = v?.trim() ?? '';
                  if (title.isEmpty) return 'Add a short title';
                  if (title.length > 150) return 'Use 150 characters or fewer';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _bodyController,
                textCapitalization: TextCapitalization.sentences,
                minLines: 4,
                maxLines: 8,
                decoration: _decoration('What is happening?'),
                validator: (v) {
                  final body = v?.trim() ?? '';
                  if (body.isEmpty) return 'Describe what happened';
                  if (body.length > 5000) return 'Use 5000 characters or fewer';
                  return null;
                },
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
                onPressed: _isSubmitting ? null : _submit,
                child: _isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Post to bulletin board'),
              ),
            ],
          ),
      ),
    );
  }
}