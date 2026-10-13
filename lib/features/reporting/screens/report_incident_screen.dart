
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../components/BottomNav/bottom_nav_scaffold.dart';
import '../models/crime_category.dart';
import '../models/crime_report.dart';
import '../services/crime_category_service.dart';
import '../services/crime_report_service.dart';

class ReportIncidentScreen extends StatefulWidget {
  const ReportIncidentScreen({super.key});

  @override
  State<ReportIncidentScreen> createState() =>
      _ReportIncidentScreenState();
}

class _ReportIncidentScreenState extends State<ReportIncidentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();

  int? _selectedCategoryId;
  DateTime? _incidentDateTime;
  bool _isAnonymous = false;
  bool _isSubmitting = false;

  late final CrimeCategoryService _categoryService;
  late final CrimeReportService _reportService;
  late Future<List<CrimeCategory>> _categoriesFuture;

  @override
  void initState() {
    super.initState();

    final supabase = Supabase.instance.client;

    _categoryService = CrimeCategoryService(supabase);
    _reportService = CrimeReportService(supabase);

    _categoriesFuture = _categoryService.getCategories();
  }

  void _retryLoadingCategories() {
    setState(() {
      _selectedCategoryId = null;
      _categoriesFuture = _categoryService.getCategories();
    });
  }

  Future<void> _selectIncidentDateTime() async {
    if (_isSubmitting) return;

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
      _showMessage(
        'The incident date and time cannot be in the future.',
      );
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

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _submitReport() async {
    if (_isSubmitting) return;

    if (!_formKey.currentState!.validate()) return;

    if (_selectedCategoryId == null) {
      _showMessage('Please select an incident type.');
      return;
    }

    if (_incidentDateTime == null) {
      _showMessage('Please select the incident date and time.');
      return;
    }

    if (_incidentDateTime!.isAfter(DateTime.now())) {
      _showMessage(
        'The incident date and time cannot be in the future.',
      );
      return;
    }

    final user = Supabase.instance.client.auth.currentUser;

    if (user == null) {
      _showMessage('Please log in before submitting a report.');
      return;
    }

    final report = CrimeReport(
      userId: user.id,
      categoryId: _selectedCategoryId!,
      description: _descriptionController.text.trim(),
      incidentDateTime: _incidentDateTime!,
      isAnonymous: _isAnonymous,
    );

    setState(() {
      _isSubmitting = true;
    });

    try {
      final reportId = await _reportService.submitReport(report);

      if (!mounted) return;

      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) {
          return AlertDialog(
            title: const Text('Report Submitted'),
            content: SelectableText(
              'Your incident report has been submitted.\n\n'
              'Status: Submitted\n\n'
              'Report ID:\n$reportId\n\n'
              'Keep this ID for future reference.',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                },
                child: const Text('Done'),
              ),
            ],
          );
        },
      );

      if (!mounted) return;

      _descriptionController.clear();

      setState(() {
        _selectedCategoryId = null;
        _incidentDateTime = null;
        _isAnonymous = false;
      });
    } catch (error) {
      if (!mounted) return;

      _showMessage(
        'Unable to submit the report. Please try again.',
      );

      debugPrint('Crime report submission error: $error');
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BottomNavScaffold(
      currentIndex: 2,
      title: 'Report Incident',
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Report an Incident',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 8),

              const Text(
                'Provide the details of the incident below.',
              ),

              const SizedBox(height: 20),

              // Navigate to My Reports without changing the bottom tabs.
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _isSubmitting
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
                  if (snapshot.connectionState ==
                      ConnectionState.waiting) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Center(
                        child: CircularProgressIndicator(),
                      ),
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
                          onPressed: _isSubmitting
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
                          onPressed: _isSubmitting
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
                      prefixIcon: Icon(
                        Icons.warning_amber_outlined,
                      ),
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
                    onChanged: _isSubmitting
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
                enabled: !_isSubmitting,
                maxLines: 5,
                maxLength: 1000,
                textCapitalization:
                    TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  hintText: 'Describe what happened',
                  alignLabelWithHint: true,
                  prefixIcon: Icon(
                    Icons.description_outlined,
                  ),
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
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 8),

              InkWell(
                onTap: _isSubmitting
                    ? null
                    : _selectIncidentDateTime,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    prefixIcon: Icon(
                      Icons.access_time_outlined,
                    ),
                    border: OutlineInputBorder(),
                  ),
                  child: Text(
                    _formatIncidentDateTime(),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              const Text(
                'Incident Location',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 8),

              const ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  Icons.location_on_outlined,
                ),
                title: Text(
                  'Location will be added in the next stage.',
                ),
                subtitle: Text(
                  'SafeSense will support approximate GPS location '
                  'and a manual location fallback.',
                ),
              ),

              const Divider(height: 32),

              const ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  Icons.add_photo_alternate_outlined,
                ),
                title: Text('Photo / Video Evidence'),
                subtitle: Text(
                  'Optional evidence upload will be added later.',
                ),
              ),

              const Divider(height: 32),

              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text(
                  'Submit anonymously',
                ),
                subtitle: const Text(
                  'Your identity will not be displayed with the report.',
                ),
                value: _isAnonymous,
                onChanged: _isSubmitting
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
                  onPressed: _isSubmitting ? null : _submitReport,
                  icon: _isSubmitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.send_outlined),
                  label: Text(
                    _isSubmitting
                        ? 'Submitting...'
                        : 'Submit Report',
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
