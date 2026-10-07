import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

class TrustedCircleScreen extends StatefulWidget {
  const TrustedCircleScreen({super.key});

  @override
  State<TrustedCircleScreen> createState() =>
      _TrustedCircleScreenState();
}

class _TrustedCircleScreenState extends State<TrustedCircleScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // =========================
  // ACCEPTED TRUSTED FRIENDS
  // =========================
  final List<Map<String, dynamic>> trustedFriends = [
    {
      'name': 'Mom',
      'username': '@Mom',
      'sharing': true,
    },
  ];

  // =========================
  // OUTGOING REQUESTS
  // =========================
  final List<Map<String, dynamic>> sentRequests = [
    {
      'name': 'Thabo Mokoena',
      'username': '@thabo',
    },
  ];

  // =========================
  // INCOMING REQUESTS
  // =========================
  final List<Map<String, dynamic>> incomingRequests = [
    {
      'name': 'Lerato Mokoena',
      'username': '@lerato',
    },
  ];

  @override
  void initState() {
    super.initState();

    _tabController = TabController(
      length: 2,
      vsync: this,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  int get pendingCount =>
      sentRequests.length + incomingRequests.length;

  // =========================
  // SEND REQUEST
  // =========================

  void _showAddRequestDialog() {
    final usernameController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) {
        final theme = Theme.of(dialogContext);
        final isDark =
            theme.brightness == Brightness.dark;

        return AlertDialog(
          backgroundColor: theme.colorScheme.surface,
          title: const Text('Add to Trusted Circle'),
          content: TextField(
            controller: usernameController,
            decoration: const InputDecoration(
              labelText: 'Username',
              hintText: '@username',
              prefixIcon: Icon(Icons.person_search_outlined),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final username =
                    usernameController.text.trim();

                if (username.isEmpty) {
                  return;
                }

                setState(() {
                  sentRequests.add({
                    'name': username,
                    'username': username.startsWith('@')
                        ? username
                        : '@$username',
                  });
                });

                Navigator.pop(dialogContext);

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Trusted Circle request sent.',
                    ),
                  ),
                );
              },
              child: const Text('Send Request'),
            ),
          ],
        );
      },
    );
  }

  // =========================
  // ACCEPT REQUEST
  // =========================

  void _acceptRequest(Map<String, dynamic> request) {
    setState(() {
      incomingRequests.remove(request);

      trustedFriends.add({
        'name': request['name'],
        'username': request['username'],
        'sharing': false,
      });
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${request['name']} is now in your Trusted Circle.',
        ),
      ),
    );
  }

  // =========================
  // DECLINE REQUEST
  // =========================

  void _declineRequest(Map<String, dynamic> request) {
    setState(() {
      incomingRequests.remove(request);
    });
  }

  // =========================
  // REMOVE TRUSTED FRIEND
  // =========================

  void _removeTrustedFriend(
    Map<String, dynamic> friend,
  ) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Remove Trusted Person?'),
          content: Text(
            'Remove ${friend['name']} from your Trusted Circle?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  trustedFriends.remove(friend);
                });

                Navigator.pop(dialogContext);
              },
              child: const Text(
                'Remove',
                style: TextStyle(
                  color: AppColors.danger,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // =========================
  // BUILD
  // =========================

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,

      appBar: AppBar(
        title: const Text(
          'Trusted Circle',
          style: TextStyle(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddRequestDialog,
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.person_add_alt_1),
        label: const Text('Add Person'),
      ),

      body: Column(
        children: [
          // =========================
          // HEADER
          // =========================

          Container(
            width: double.infinity,
            margin: const EdgeInsets.fromLTRB(
              20,
              8,
              20,
              18,
            ),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  AppColors.darkBlue,
                  AppColors.primaryBlue,
                ],
              ),
              borderRadius: BorderRadius.circular(22),
            ),
            child: Row(
              children: [
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.16),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Icon(
                    Icons.people_alt_outlined,
                    color: Colors.white,
                    size: 30,
                  ),
                ),

                const SizedBox(width: 16),

                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Your Trusted Circle',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 19,
                          fontWeight: FontWeight.w700,
                        ),
                      ),

                      const SizedBox(height: 4),

                      Text(
                        '${trustedFriends.length} trusted ${trustedFriends.length == 1 ? 'person' : 'people'}',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.85),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // =========================
          // TABS
          // =========================

          Container(
            margin: const EdgeInsets.symmetric(
              horizontal: 20,
            ),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(14),
            ),
            child: TabBar(
              controller: _tabController,
              indicatorSize: TabBarIndicatorSize.tab,
              indicator: BoxDecoration(
                color: AppColors.primaryBlue,
                borderRadius: BorderRadius.circular(14),
              ),
              labelColor: Colors.white,
              unselectedLabelColor:
                  colorScheme.onSurfaceVariant,
              dividerColor: Colors.transparent,
              tabs: [
                Tab(
                  text:
                      'Trusted (${trustedFriends.length})',
                ),
                Tab(
                  text: 'Requests ($pendingCount)',
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildTrustedFriends(
                  colorScheme,
                  isDark,
                ),
                _buildRequests(
                  colorScheme,
                  isDark,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // =========================
  // TRUSTED FRIENDS
  // =========================

  Widget _buildTrustedFriends(
    ColorScheme colorScheme,
    bool isDark,
  ) {
    if (trustedFriends.isEmpty) {
      return _emptyState(
        icon: Icons.people_outline,
        title: 'No trusted people yet',
        message:
            'Add people you trust so they can be part of your safety network.',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(
        20,
        8,
        20,
        110,
      ),
      itemCount: trustedFriends.length,
      separatorBuilder: (_, __) =>
          const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final friend = trustedFriends[index];

        final bool sharing =
            friend['sharing'] == true;

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 25,
                  backgroundColor:
                      AppColors.lightBlue,
                  child: Text(
                    _initials(friend['name']),
                    style: const TextStyle(
                      color: AppColors.darkBlue,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),

                const SizedBox(width: 14),

                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        friend['name'],
                        style: TextStyle(
                          color: colorScheme.onSurface,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        friend['username'],
                        style: TextStyle(
                          color:
                              colorScheme.onSurfaceVariant,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 7),

                      Row(
                        children: [
                          Icon(
                            sharing
                                ? Icons.location_on
                                : Icons.location_off,
                            size: 14,
                            color: sharing
                                ? AppColors.primaryBlue
                                : colorScheme
                                    .onSurfaceVariant,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            sharing
                                ? 'Sharing location'
                                : 'Location not shared',
                            style: TextStyle(
                              color: colorScheme
                                  .onSurfaceVariant,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'remove') {
                      _removeTrustedFriend(friend);
                    }
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(
                      value: 'remove',
                      child: Text('Remove'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // =========================
  // REQUESTS
  // =========================

  Widget _buildRequests(
    ColorScheme colorScheme,
    bool isDark,
  ) {
    if (incomingRequests.isEmpty &&
        sentRequests.isEmpty) {
      return _emptyState(
        icon: Icons.mark_email_read_outlined,
        title: 'No pending requests',
        message:
            'New Trusted Circle requests will appear here.',
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        20,
        8,
        20,
        110,
      ),
      children: [
        // =========================
        // INCOMING
        // =========================

        if (incomingRequests.isNotEmpty) ...[
          _sectionTitle(
            'Incoming Requests',
            incomingRequests.length,
          ),

          const SizedBox(height: 10),

          ...incomingRequests.map(
            (request) => Padding(
              padding:
                  const EdgeInsets.only(bottom: 12),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor:
                            AppColors.lightBlue,
                        child: Text(
                          _initials(request['name']),
                          style: const TextStyle(
                            color:
                                AppColors.darkBlue,
                            fontWeight:
                                FontWeight.w700,
                          ),
                        ),
                      ),

                      const SizedBox(width: 14),

                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Text(
                              request['name'],
                              style: TextStyle(
                                color:
                                    colorScheme.onSurface,
                                fontWeight:
                                    FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              request['username'],
                              style: TextStyle(
                                color: colorScheme
                                    .onSurfaceVariant,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Wants to join your Trusted Circle',
                              style: TextStyle(
                                color: colorScheme
                                    .onSurfaceVariant,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),

                      Column(
                        children: [
                          IconButton(
                            tooltip: 'Accept',
                            onPressed: () {
                              _acceptRequest(request);
                            },
                            icon: const Icon(
                              Icons.check_circle,
                              color:
                                  AppColors.primaryBlue,
                            ),
                          ),
                          IconButton(
                            tooltip: 'Decline',
                            onPressed: () {
                              _declineRequest(request);
                            },
                            icon: const Icon(
                              Icons.cancel_outlined,
                              color: AppColors.danger,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],

        // =========================
        // OUTGOING
        // =========================

        if (sentRequests.isNotEmpty) ...[
          const SizedBox(height: 10),

          _sectionTitle(
            'Sent Requests',
            sentRequests.length,
          ),

          const SizedBox(height: 10),

          ...sentRequests.map(
            (request) => Padding(
              padding:
                  const EdgeInsets.only(bottom: 12),
              child: Card(
                child: ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 6,
                  ),
                  leading: CircleAvatar(
                    backgroundColor:
                        AppColors.lightBlue,
                    child: Text(
                      _initials(request['name']),
                      style: const TextStyle(
                        color: AppColors.darkBlue,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  title: Text(
                    request['name'],
                    style: TextStyle(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  subtitle: Text(
                    '${request['username']} • Waiting for response',
                    style: TextStyle(
                      color:
                          colorScheme.onSurfaceVariant,
                    ),
                  ),
                  trailing: const Chip(
                    label: Text('Pending'),
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  // =========================
  // HELPERS
  // =========================

  Widget _sectionTitle(
    String title,
    int count,
  ) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              color: colorScheme.onSurface,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 5,
          ),
          decoration: BoxDecoration(
            color: AppColors.lightBlue,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '$count',
            style: const TextStyle(
              color: AppColors.darkBlue,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }

  Widget _emptyState({
    required IconData icon,
    required String title,
    required String message,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 64,
              color: colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 18),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colorScheme.onSurface,
                fontSize: 19,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colorScheme.onSurfaceVariant,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _initials(String name) {
    final parts = name.split(' ');

    if (parts.length == 1) {
      return parts[0][0].toUpperCase();
    }

    return '${parts[0][0]}${parts[1][0]}'
        .toUpperCase();
  }
}