import 'package:flutter/material.dart';

import '../../services/notification_service.dart';

class NotificationInboxScreen extends StatelessWidget {
  const NotificationInboxScreen({super.key});

  Future<void> _markAsRead(BuildContext context, String id) async {
    try {
      await NotificationService.markAsRead(id);
    } catch (error) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to mark notification as read.')),
      );
    }
  }

  Future<void> _markAllAsRead(BuildContext context) async {
    try {
      await NotificationService.markAllAsRead();
    } catch (error) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to update notifications.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Notifications'),
        actions: [
          IconButton(
            tooltip: 'Mark all as read',
            icon: const Icon(Icons.done_all),
            onPressed: () => _markAllAsRead(context),
          ),
        ],
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: NotificationService.watchNotifications(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Unable to load notifications.'));
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final notifications = snapshot.data!;

          if (notifications.isEmpty) {
            return const Center(child: Text('You have no notifications yet.'));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: notifications.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final notification = notifications[index];

              final id = notification['id'].toString();

              final title = notification['title']?.toString() ?? 'Notification';

              final message = notification['message']?.toString() ?? '';

              final isRead = notification['is_read'] == true;

              final type =
                  notification['notification_type']?.toString() ?? 'general';

              IconData icon;

              switch (type) {
                case 'crime':
                  icon = Icons.warning_amber_rounded;
                  break;

                case 'emergency':
                case 'sos':
                  icon = Icons.sos_rounded;
                  break;

                case 'community':
                  icon = Icons.groups_outlined;
                  break;

                default:
                  icon = Icons.notifications_outlined;
              }

              return Card(
                color: isRead
                    ? null
                    : Theme.of(context).colorScheme.primaryContainer,
                child: ListTile(
                  leading: Icon(icon, color: type == 'sos' ? Colors.red : null),
                  title: Text(
                    title,
                    style: TextStyle(
                      fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(message),
                  trailing: isRead
                      ? const Icon(Icons.done, size: 18)
                      : const Icon(Icons.circle, size: 10),
                  onTap: () {
                    if (!isRead) {
                      _markAsRead(context, id);
                    }
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
