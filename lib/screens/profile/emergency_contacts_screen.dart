
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class EmergencyContactsScreen extends StatefulWidget {
  const EmergencyContactsScreen({super.key});

  @override
  State<EmergencyContactsScreen> createState() =>
      _EmergencyContactsScreenState();
}

class _EmergencyContactsScreenState
    extends State<EmergencyContactsScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;

  List<Map<String, dynamic>> contacts = [];

  bool _loading = true;
  bool _saving = false;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _loadContacts();
  }

  Future<void> _loadContacts() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });

    try {
      final user = _supabase.auth.currentUser;

      if (user == null) {
        throw Exception('Please sign in to view emergency contacts.');
      }

      final data = await _supabase
          .from('emergency_contacts')
          .select(
            'id, user_id, contact_name, phone_number, relationship, created_at',
          )
          .eq('user_id', user.id)
          .order('created_at', ascending: true);

      if (!mounted) return;

      setState(() {
        contacts = List<Map<String, dynamic>>.from(data);
      });
    } catch (error) {
      if (mounted) {
        setState(() {
          _loadError =
              'Could not load emergency contacts. Please try again.';
        });
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _addContact() async {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final relationshipController = TextEditingController();

    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Add emergency contact'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Phone number',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: relationshipController,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Relationship',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final name = nameController.text.trim();
              final phone = phoneController.text.trim();

              if (name.isEmpty || phone.isEmpty) {
                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  const SnackBar(
                    content: Text('Enter a name and phone number.'),
                  ),
                );
                return;
              }

              Navigator.pop(dialogContext, {
                'name': name,
                'phone': phone,
                'relationship':
                    relationshipController.text.trim().isEmpty
                        ? 'Contact'
                        : relationshipController.text.trim(),
              });
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );

    nameController.dispose();
    phoneController.dispose();
    relationshipController.dispose();

    if (result == null || !mounted) return;

    await _saveContact(result);
  }

  Future<void> _saveContact(Map<String, String> contact) async {
    final user = _supabase.auth.currentUser;

    if (user == null) {
      _showMessage('Please sign in before adding a contact.');
      return;
    }

    setState(() => _saving = true);

    try {
      final savedContact = await _supabase
          .from('emergency_contacts')
          .insert({
            'user_id': user.id,
            'contact_name': contact['name'],
            'phone_number': contact['phone'],
            'relationship': contact['relationship'],
          })
          .select(
            'id, user_id, contact_name, phone_number, relationship, created_at',
          )
          .single();

      if (!mounted) return;

      setState(() {
        contacts.add(Map<String, dynamic>.from(savedContact));
      });

      _showMessage('Emergency contact saved.');
    } catch (error) {
      if (mounted) {
        _showMessage(
          'Could not save the contact. Please check your connection and try again.',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  Future<void> _deleteContact(Map<String, dynamic> contact) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete contact?'),
        content: Text(
          'Remove ${contact['contact_name']} from your emergency contacts?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final user = _supabase.auth.currentUser;
    final contactId = contact['id'];

    if (user == null || contactId == null) {
      _showMessage('Could not identify this contact.');
      return;
    }

    setState(() => _saving = true);

    try {
      await _supabase
          .from('emergency_contacts')
          .delete()
          .eq('id', contactId)
          .eq('user_id', user.id);

      if (!mounted) return;

      setState(() {
        contacts.removeWhere((item) => item['id'] == contactId);
      });

      _showMessage('Emergency contact deleted.');
    } catch (error) {
      if (mounted) {
        _showMessage('Could not delete the contact. Please try again.');
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Emergency Contacts')),
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
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: _loadContacts,
                          child: const Text('Try again'),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    Text(
                      'YOUR EMERGENCY CONTACTS',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: colors.onSurfaceVariant,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.4,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Keep important people easy to find when you need assistance.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 20),
                    if (contacts.isEmpty)
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            children: [
                              Icon(
                                Icons.contact_phone_outlined,
                                size: 42,
                                color: colors.onSurfaceVariant,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'No emergency contacts added',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Add a trusted contact below. Your saved contacts will be available when you return.',
                                textAlign: TextAlign.center,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: colors.onSurfaceVariant,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      ...contacts.map(
                        (contact) => _contactCard(context, contact),
                      ),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 52,
                      child: FilledButton.icon(
                        onPressed: _saving ? null : _addContact,
                        icon: const Icon(Icons.person_add_alt_1),
                        label: const Text('Add emergency contact'),
                      ),
                    ),
                    if (_saving) ...[
                      const SizedBox(height: 12),
                      const LinearProgressIndicator(),
                    ],
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: colors.errorContainer,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.warning_amber_outlined,
                            color: colors.onErrorContainer,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Emergency services',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: colors.onErrorContainer,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            'If you are in immediate danger, contact the appropriate emergency service directly.',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colors.onErrorContainer,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _contactCard(
    BuildContext context,
    Map<String, dynamic> contact,
  ) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    final name = contact['contact_name'] as String? ?? 'Unknown';
    final phone = contact['phone_number'] as String? ?? '';
    final relationship = contact['relationship'] as String? ?? 'Contact';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 8,
        ),
        leading: CircleAvatar(
          backgroundColor: colors.errorContainer,
          child: Icon(
            Icons.person_outline,
            color: colors.onErrorContainer,
          ),
        ),
        title: Text(
          name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            '$phone • $relationship',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
        ),
        trailing: IconButton(
          tooltip: 'Delete contact',
          onPressed: _saving ? null : () => _deleteContact(contact),
          icon: Icon(Icons.delete_outline, color: colors.error),
        ),
      ),
    );
  }
}
