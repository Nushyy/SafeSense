import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../components/BottomNav/bottom_nav_scaffold.dart';
import '../models/crime_category.dart';
import '../models/crime_report.dart';
import '../services/crime_category_service.dart';
import '../services/crime_report_service.dart';
import '../services/crime_evidence_service.dart';

class _EvidenceFile {
  const _EvidenceFile({required this.name, required this.bytes});

  final String name;
  final Uint8List bytes;
  int get size => bytes.length;
  String get extension =>
      name.contains('.') ? name.split('.').last.toLowerCase() : '';
}

class ReportIncidentScreen extends StatefulWidget {
  const ReportIncidentScreen({super.key});

  @override
  State<ReportIncidentScreen> createState() => _ReportIncidentScreenState();
}

class _ReportIncidentScreenState extends State<ReportIncidentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _locationNameController = TextEditingController();

  int? _selectedCategoryId;
  DateTime? _incidentDateTime;
  bool _isAnonymous = false;
  bool _isSubmitting = false;
  bool _isPickingFiles = false;
  String? _pendingReportId;
  String? _uploadingFileName;
  final List<_EvidenceFile> _selectedFiles = [];
  late final CrimeEvidenceService _evidenceService;

  bool get _formLocked => _isSubmitting || _pendingReportId != null;

  late final CrimeCategoryService _categoryService;
  late final CrimeReportService _reportService;
  late Future<List<CrimeCategory>> _categoriesFuture;

  @override
  void initState() {
    super.initState();

    final supabase = Supabase.instance.client;

    _categoryService = CrimeCategoryService(supabase);
    _reportService = CrimeReportService(supabase);
    _evidenceService = CrimeEvidenceService(supabase);

    _categoriesFuture = _categoryService.getCategories();
  }

  void _retryLoadingCategories() {
    setState(() {
      _selectedCategoryId = null;
      _categoriesFuture = _categoryService.getCategories();
    });
  }

  Future<void> _selectIncidentDateTime() async {
    if (_formLocked) return;

    final now = DateTime.now();

    final selectedDate = await showDatePicker(
      context: context,
      initialDate: _incidentDateTime ?? now,
      firstDate: DateTime(2000),
      lastDate: now,
    );

    if (selectedDate == null || !mounted) return;

    final selectedTime = await showTimePicker(
      context: context,
      initialTime: _incidentDateTime != null
          ? TimeOfDay.fromDateTime(_incidentDateTime!)
          : TimeOfDay.now(),
    );

    if (selectedTime == null || !mounted) return;

    final incidentDateTime = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
      selectedTime.hour,
      selectedTime.minute,
    );

    if (incidentDateTime.isAfter(DateTime.now())) {
      _showMessage('The incident date and time cannot be in the future.');
      return;
    }

    setState(() {
      _incidentDateTime = incidentDateTime;
    });
  }

  String _formatIncidentDateTime() {
    if (_incidentDateTime == null) {
      return 'Select incident date and time';
    }

    final date = _incidentDateTime!;

    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year;

    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');

    return '$day/$month/$year at $hour:$minute';
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  String _displaySize(int size) =>
      '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';

  Future<void> _pickEvidence() async {
    if (_formLocked || _isPickingFiles) return;
    setState(() => _isPickingFiles = true);
    try {
      final files = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: CrimeEvidenceService.supportedMimeTypes.keys
            .toList(),
      );
      if (!mounted || files.isEmpty) return;

      final additions = <_EvidenceFile>[];
      var totalSize = _selectedFiles.fold<int>(
        0,
        (sum, file) => sum + file.size,
      );
      for (final file in files) {
        final extension = file.extension?.toLowerCase() ?? '';
        if (!CrimeEvidenceService.supportedMimeTypes.containsKey(extension)) {
          _showMessage('Unsupported format: ${file.name}');
          continue;
        }
        final fileSize = file.lengthSync() ?? await file.length();
        if (!mounted) return;
        if (fileSize == null ||
            fileSize <= 0 ||
            fileSize > CrimeEvidenceService.maxFileBytes) {
          _showMessage('${file.name} must be between 1 byte and 50 MB.');
          continue;
        }
        if (_selectedFiles.length + additions.length >=
                CrimeEvidenceService.maxFiles ||
            totalSize + fileSize > CrimeEvidenceService.maxTotalBytes) {
          _showMessage('Limit: 5 files and 100 MB combined.');
          break;
        }
        try {
          final bytes = await file.readAsBytes();
          if (!mounted) return;
          if (bytes.length != fileSize) {
            _showMessage(
              'Could not read ${file.name}. Please select it again.',
            );
            continue;
          }
          additions.add(_EvidenceFile(name: file.name, bytes: bytes));
          totalSize += bytes.length;
        } catch (error) {
          debugPrint('Unable to read evidence file: $error');
          _showMessage('Could not read ${file.name}. Please select it again.');
        }
      }
      if (mounted) setState(() => _selectedFiles.addAll(additions));
    } catch (error) {
      debugPrint('Evidence picker error: $error');
      _showMessage('Unable to select files. Please try again.');
    } finally {
      if (mounted) setState(() => _isPickingFiles = false);
    }
  }

  Future<void> _showSubmissionResult(String reportId, int failures) async {
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: Text(failures == 0 ? 'Report Submitted' : 'Report Saved'),
        content: SelectableText(
          failures == 0
              ? 'Your report and all selected evidence have been saved.\n\n'
                    'Report ID:\n$reportId\n\nKeep this ID for reference.'
              : 'Your crime report was saved successfully.\n\n'
                    '$failures evidence file(s) could not be uploaded.\n\n'
                    'Report ID:\n$reportId\n\n'
                    'Use Retry Evidence Upload on this screen. '
                    'Do not submit a new report.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _clearCompletedReport() {
    _descriptionController.clear();
    _locationNameController.clear();
    setState(() {
      _selectedCategoryId = null;
      _incidentDateTime = null;
      _isAnonymous = false;
      _pendingReportId = null;
      _selectedFiles.clear();
      _uploadingFileName = null;
    });
  }

  Future<void> _finishWithoutEvidence() async {
    if (_isSubmitting || _pendingReportId == null) return;
    final discard = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Finish without remaining evidence?'),
        content: const Text(
          'Your crime report is already saved. Any files still listed here '
          'have NOT been attached. You will lose the ability to retry them '
          'from this screen.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Keep files'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Finish'),
          ),
        ],
      ),
    );
    if (discard == true && mounted) _clearCompletedReport();
  }

  Future<void> _submitReport() async {
    if (_isSubmitting || _isPickingFiles) return;

    // A previous attempt may already have created the report. Retry only
    // remaining evidence, never the report INSERT itself.
    if (_pendingReportId == null) {
      if (!_formKey.currentState!.validate()) return;
      if (_selectedCategoryId == null) {
        _showMessage('Please select an incident type.');
        return;
      }
      if (_incidentDateTime == null ||
          _incidentDateTime!.isAfter(DateTime.now())) {
        _showMessage('Please select a valid incident date and time.');
        return;
      }
    }

    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      _showMessage('Please log in before submitting a report.');
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      String reportId;
      if (_pendingReportId != null) {
        reportId = _pendingReportId!;
      } else {
        final report = CrimeReport(
          userId: user.id,
          categoryId: _selectedCategoryId!,
          description: _descriptionController.text.trim(),
          incidentDateTime: _incidentDateTime!,
          isAnonymous: _isAnonymous,
        );
        reportId = await _reportService.submitReport(
          report,
          locationName: _locationNameController.text.trim(),
        );
        if (!mounted) return;
        setState(() => _pendingReportId = reportId);
      }

      // Keep failed files for retry; remove only successfully linked files.
      final filesToUpload = List<_EvidenceFile>.from(_selectedFiles);
      for (final file in filesToUpload) {
        if (!mounted) return;
        setState(() => _uploadingFileName = file.name);
        try {
          await _evidenceService.uploadEvidence(
            reportId: reportId,
            bytes: file.bytes,
            originalFileName: file.name,
          );
          if (mounted) setState(() => _selectedFiles.remove(file));
        } catch (error) {
          debugPrint('Evidence upload failed for ${file.name}: $error');
        }
      }
      if (!mounted) return;
      setState(() => _uploadingFileName = null);
      final failures = _selectedFiles.length;
      await _showSubmissionResult(reportId, failures);
      if (!mounted) return;
      if (failures == 0) _clearCompletedReport();
    } catch (error) {
      debugPrint('Crime report submission error: $error');
      if (_pendingReportId == null) {
        _showMessage('Unable to submit the report. Please try again.');
      } else {
        _showMessage('Report saved. Evidence upload can be retried.');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _uploadingFileName = null;
        });
      }
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _locationNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BottomNavScaffold(
      currentIndex: 2,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Page heading, one font-size unit
              // smaller than the SafeSense header.
              const Text(
                'Report Incident',
                style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 8),

              const Text('Provide the details of the incident below.'),

              const SizedBox(height: 20),

              // Navigate to My Reports.
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _formLocked
                      ? null
                      : () => context.push('/my-reports'),
                  icon: const Icon(Icons.assignment_outlined),
                  label: const Text('My Reports'),
                ),
              ),

              const SizedBox(height: 24),

              FutureBuilder<List<CrimeCategory>>(
                future: _categoriesFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }

                  if (snapshot.hasError) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Unable to load incident categories.',
                          style: TextStyle(color: Colors.red),
                        ),
                        const SizedBox(height: 8),
                        OutlinedButton.icon(
                          onPressed: _formLocked
                              ? null
                              : _retryLoadingCategories,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Try Again'),
                        ),
                      ],
                    );
                  }

                  final categories = snapshot.data ?? [];

                  if (categories.isEmpty) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'No incident categories are currently available.',
                        ),
                        const SizedBox(height: 8),
                        OutlinedButton.icon(
                          onPressed: _formLocked
                              ? null
                              : _retryLoadingCategories,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Refresh Categories'),
                        ),
                      ],
                    );
                  }

                  return DropdownButtonFormField<int>(
                    key: ValueKey(_selectedCategoryId),
                    initialValue: _selectedCategoryId,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Incident Type',
                      prefixIcon: Icon(Icons.warning_amber_outlined),
                      border: OutlineInputBorder(),
                    ),
                    items: categories.map((category) {
                      return DropdownMenuItem<int>(
                        value: category.id,
                        child: Text(
                          category.name,
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }).toList(),
                    onChanged: _formLocked
                        ? null
                        : (value) {
                            setState(() {
                              _selectedCategoryId = value;
                            });
                          },
                    validator: (value) {
                      if (value == null) {
                        return 'Please select an incident type';
                      }
                      return null;
                    },
                  );
                },
              ),

              const SizedBox(height: 20),

              TextFormField(
                controller: _descriptionController,
                enabled: !_formLocked,
                maxLines: 5,
                maxLength: 1000,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  hintText: 'Describe what happened',
                  alignLabelWithHint: true,
                  prefixIcon: Icon(Icons.description_outlined),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please describe the incident';
                  }

                  if (value.trim().length < 10) {
                    return 'Please provide more detail about the incident';
                  }

                  return null;
                },
              ),

              const SizedBox(height: 20),

              const Text(
                'Incident Date & Time',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),

              const SizedBox(height: 8),

              InkWell(
                onTap: _formLocked ? null : _selectIncidentDateTime,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.access_time_outlined),
                    border: OutlineInputBorder(),
                  ),
                  child: Text(_formatIncidentDateTime()),
                ),
              ),

              const SizedBox(height: 24),

              const Text(
                'Incident Location',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),

              const SizedBox(height: 8),

              const Text(
                'Enter the suburb, city, and province where the incident occurred.',
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _locationNameController,
                enabled: !_formLocked,
                maxLength: 200,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Location name',
                  hintText: 'Westdene, Bloemfontein, Free State',
                  prefixIcon: Icon(Icons.location_on_outlined),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter the incident location';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 8),
              const Text(
                'Enter the location of the incident, not necessarily your current location.',
                style: TextStyle(fontSize: 12),
              ),

              const Divider(height: 32),

              const Text(
                'Photo / Video Evidence (optional)',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              const Text(
                'Up to 5 files, 50 MB each, 100 MB combined. '
                'Supported: JPG, PNG, WebP, MP4, WebM and MOV.',
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _formLocked || _isPickingFiles
                    ? null
                    : _pickEvidence,
                icon: const Icon(Icons.add_photo_alternate_outlined),
                label: Text(
                  _isPickingFiles ? 'Selecting...' : 'Add Photos / Videos',
                ),
              ),
              if (_selectedFiles.isNotEmpty) ...[
                const SizedBox(height: 8),
                ..._selectedFiles.map(
                  (file) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      file.extension == 'mp4' ||
                              file.extension == 'webm' ||
                              file.extension == 'mov'
                          ? Icons.videocam_outlined
                          : Icons.image_outlined,
                    ),
                    title: Text(file.name, overflow: TextOverflow.ellipsis),
                    subtitle: Text(_displaySize(file.size)),
                    trailing: _formLocked
                        ? null
                        : IconButton(
                            tooltip: 'Remove file',
                            icon: const Icon(Icons.close),
                            onPressed: () =>
                                setState(() => _selectedFiles.remove(file)),
                          ),
                  ),
                ),
              ],
              if (_pendingReportId != null) ...[
                const SizedBox(height: 12),
                SelectableText('Report saved: $_pendingReportId'),
                const Text(
                  'Only the remaining files will be retried. '
                  'Do not create another report.',
                ),
                TextButton(
                  onPressed: _isSubmitting ? null : _finishWithoutEvidence,
                  child: const Text('Finish without remaining evidence'),
                ),
              ],
              if (_uploadingFileName != null) ...[
                const LinearProgressIndicator(),
                Text('Uploading: $_uploadingFileName'),
              ],

              const Divider(height: 32),

              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Submit anonymously'),
                subtitle: const Text(
                  'Your identity will not be displayed with the report.',
                ),
                value: _isAnonymous,
                onChanged: _formLocked
                    ? null
                    : (value) {
                        setState(() {
                          _isAnonymous = value;
                        });
                      },
              ),

              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isSubmitting || _isPickingFiles
                      ? null
                      : _submitReport,
                  icon: _isSubmitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.send_outlined),
                  label: Text(
                    _isSubmitting
                        ? (_pendingReportId == null
                              ? 'Submitting...'
                              : 'Uploading Evidence...')
                        : (_pendingReportId == null
                              ? 'Submit Report'
                              : 'Retry Evidence Upload'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
