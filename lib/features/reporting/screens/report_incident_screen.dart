import 'package:flutter/material.dart';

class ReportIncidentScreen extends StatefulWidget {
  const ReportIncidentScreen({super.key});

  @override
  State<ReportIncidentScreen> createState() =>
      _ReportIncidentScreenState();
}

class _ReportIncidentScreenState extends State<ReportIncidentScreen> {
  final _formKey = GlobalKey<FormState>();

  final _descriptionController = TextEditingController();

  String? _selectedCategory;
  DateTime? _incidentDateTime;
  bool _isAnonymous = false;

  // Temporary categories for building the UI.
  // In Step 8B these will come from the crime_categories
  // table in Supabase instead.
  final List<String> _temporaryCategories = [
    'Robbery',
    'Assault',
    'Burglary',
    'Suspicious Activity',
    'Gender-Based Violence',
  ];

  Future<void> _selectIncidentDateTime() async {
    final now = DateTime.now();

    final selectedDate = await showDatePicker(
      context: context,
      initialDate: _incidentDateTime ?? now,
      firstDate: DateTime(2000),
      lastDate: now,
    );

    if (selectedDate == null || !mounted) {
      return;
    }

    final selectedTime = await showTimePicker(
      context: context,
      initialTime: _incidentDateTime != null
          ? TimeOfDay.fromDateTime(_incidentDateTime!)
          : TimeOfDay.now(),
    );

    if (selectedTime == null) {
      return;
    }

    setState(() {
      _incidentDateTime = DateTime(
        selectedDate.year,
        selectedDate.month,
        selectedDate.day,
        selectedTime.hour,
        selectedTime.minute,
      );
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

  void _continueReport() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_incidentDateTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please select the incident date and time.',
          ),
        ),
      );

      return;
    }

    // We are deliberately not sending anything to Supabase yet.
    // Database submission will be implemented in a later step.
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Report details are valid.',
        ),
      ),
    );
  }

  @override
  void dispose() {
    _descriptionController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Report Incident'),
      ),
      body: SafeArea(
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

                const SizedBox(height: 32),

                // Crime Category
                DropdownButtonFormField<String>(
                  initialValue: _selectedCategory,
                  decoration: const InputDecoration(
                    labelText: 'Incident Type',
                    prefixIcon: Icon(
                      Icons.warning_amber_outlined,
                    ),
                    border: OutlineInputBorder(),
                  ),
                  items: _temporaryCategories.map((category) {
                    return DropdownMenuItem<String>(
                      value: category,
                      child: Text(category),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedCategory = value;
                    });
                  },
                  validator: (value) {
                    if (value == null) {
                      return 'Please select an incident type';
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 20),

                // Incident Description
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 5,
                  maxLength: 1000,
                  textCapitalization: TextCapitalization.sentences,
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

                // Incident Date and Time
                const Text(
                  'Incident Date & Time',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 8),

                InkWell(
                  onTap: _selectIncidentDateTime,
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

                // Location placeholder
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

                // Evidence placeholder
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

                // Anonymous Reporting
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text(
                    'Submit anonymously',
                  ),
                  subtitle: const Text(
                    'Your identity will not be displayed with the report.',
                  ),
                  value: _isAnonymous,
                  onChanged: (value) {
                    setState(() {
                      _isAnonymous = value;
                    });
                  },
                ),

                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _continueReport,
                    icon: const Icon(
                      Icons.arrow_forward,
                    ),
                    label: const Text(
                      'Continue',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}