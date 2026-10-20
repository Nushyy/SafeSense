import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'community_data.dart';
import 'post_card.dart';

class CreatePostScreen extends StatefulWidget {
  final Suburb? initialArea;
  const CreatePostScreen({super.key, this.initialArea});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  // ---- Upload rules (change here if needed) ----
  static const _maxPictureBytes = 5 * 1024 * 1024; // 5 MB
  static const _maxDocumentBytes = 10 * 1024 * 1024; // 10 MB
  static const _pictureExtensions = ['jpg', 'jpeg', 'png'];
  static const _documentExtensions = ['pdf', 'docx'];

  static const _pictureTypes = XTypeGroup(
    label: 'Pictures',
    extensions: _pictureExtensions,
    mimeTypes: ['image/jpeg', 'image/png'],
    uniformTypeIdentifiers: ['public.jpeg', 'public.png'],
  );
  static const _documentTypes = XTypeGroup(
    label: 'Documents',
    extensions: _documentExtensions,
    mimeTypes: [
      'application/pdf',
      'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
    ],
    uniformTypeIdentifiers: [
      'com.adobe.pdf',
      'org.openxmlformats.wordprocessingml.document',
    ],
  );

  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  PostCategory _category = PostCategory.watch;
  Suburb? _area;
  PostAttachment? _attachment; // only 1 picture or document per post

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

  // ------------------------------------------------------------------
  // Upload: 1 picture (JPG/JPEG/PNG, max 5 MB) or 1 document (PDF/DOCX, max 10 MB)
  // ------------------------------------------------------------------

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  void _showUploadOptions() {
    showModalBottomSheet<void>(
      context: context,
      builder: (sheet) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.image_outlined),
              title: const Text('Picture'),
              subtitle: const Text('JPG or PNG, up to 5 MB'),
              onTap: () {
                Navigator.pop(sheet);
                _pickFile(AttachmentType.picture);
              },
            ),
            ListTile(
              leading: const Icon(Icons.description_outlined),
              title: const Text('Document'),
              subtitle: const Text('PDF or Word (.docx), up to 10 MB'),
              onTap: () {
                Navigator.pop(sheet);
                _pickFile(AttachmentType.document);
              },
            ),
          ],
        ),
      ),
    );
  }

  bool _startsWith(List<int> bytes, List<int> signature) {
    if (bytes.length < signature.length) return false;
    for (var i = 0; i < signature.length; i++) {
      if (bytes[i] != signature[i]) return false;
    }
    return true;
  }

  /// Checks the first bytes of the file so a renamed file is not accepted.
  bool _matchesFormat(String ext, List<int> bytes) {
    switch (ext) {
      case 'jpg':
      case 'jpeg':
        return _startsWith(bytes, [0xFF, 0xD8, 0xFF]);
      case 'png':
        return _startsWith(bytes, [0x89, 0x50, 0x4E, 0x47]);
      case 'pdf':
        return _startsWith(bytes, [0x25, 0x50, 0x44, 0x46]); // %PDF
      case 'docx':
        return _startsWith(bytes, [0x50, 0x4B, 0x03, 0x04]); // zip container
    }
    return false;
  }

  Future<void> _pickFile(AttachmentType type) async {
    final isPicture = type == AttachmentType.picture;
    final allowed = isPicture ? _pictureExtensions : _documentExtensions;
    final maxBytes = isPicture ? _maxPictureBytes : _maxDocumentBytes;

    final file = await openFile(
      acceptedTypeGroups: [isPicture ? _pictureTypes : _documentTypes],
    );
    if (file == null) return; // user cancelled

    final ext =
        file.name.contains('.') ? file.name.split('.').last.toLowerCase() : '';
    if (!allowed.contains(ext)) {
      _snack(isPicture
          ? 'Only JPG, JPEG or PNG pictures are allowed.'
          : 'Only PDF or Word (.docx) documents are allowed.');
      return;
    }

    final size = await file.length();
    if (size > maxBytes) {
      _snack(
          'That file is ${formatFileSize(size)}. The limit is ${isPicture ? '5 MB' : '10 MB'}.');
      return;
    }

    final bytes = await file.readAsBytes();
    if (!_matchesFormat(ext, bytes)) {
      _snack('That file is damaged or is not a real .$ext file.');
      return;
    }

    if (!mounted) return;
    setState(() => _attachment = PostAttachment(
          type: type,
          name: file.name,
          sizeBytes: size,
          bytes: bytes,
        ));
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final area = _area!;
    await communityRepo.addPost(
      area: area,
      category: _category,
      title: _titleController.text.trim(),
      body: _bodyController.text.trim(),
      attachment: _attachment,
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
              const SizedBox(height: 12),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primaryBlue,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: _showUploadOptions,
                icon: const Icon(Icons.upload_file),
                label: Text(_attachment == null
                    ? 'Upload picture or document'
                    : 'Replace file'),
              ),
              const SizedBox(height: 4),
              const Text(
                'Attach 1 file. Pictures: JPG or PNG, up to 5 MB. Documents: PDF or Word (.docx), up to 10 MB.',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
              if (_attachment != null) ...[
                const SizedBox(height: 12),
                AttachmentView(
                  attachment: _attachment!,
                  pictureHeight: 160,
                  onRemove: () => setState(() => _attachment = null),
                ),
              ],
              const SizedBox(height: 12),
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