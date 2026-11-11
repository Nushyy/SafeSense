import 'dart:async';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:supabase_flutter/supabase_flutter.dart' as sb;
import '../theme/app_colors.dart';
import 'community_data.dart';

/// Real database version of the community repository.
/// Tables / views / security rules: supabase/setup_posts_and_profiles.sql
///   areas            -> the area pickers
///   crime_categories -> type of crime on every post
///   public_profiles  -> names shown on posts and replies (a safe view of profiles)
///   posts, comments  -> the bulletin board
class SupabaseCommunityRepository extends CommunityRepository {
  static const _bucket = 'post-attachments';
  static const _avatarColors = [
    AppColors.primaryBlue,
    AppColors.darkBlue,
    AppColors.heroBlue,
    AppColors.success,
    AppColors.warning,
    AppColors.danger,
  ];

  sb.SupabaseClient get _db => sb.Supabase.instance.client;

  List<City> _cities = [];
  final Map<String, Suburb> _areasById = {};
  List<CrimeCategory> _categories = [];
  final Map<int, CrimeCategory> _categoriesById = {};
  final Map<String, AppUser> _users = {};
  List<Post> _posts = [];
  AppUser _me =
      const AppUser(id: '', name: 'You', color: AppColors.primaryBlue);
  bool _loading = true;
  String? _error;
  sb.RealtimeChannel? _channel;
  Timer? _debounce;

  @override
  bool get isLoading => _loading;
  @override
  String? get errorMessage => _error;
  @override
  AppUser get currentUser => _me;
  @override
  List<City> get cities => _cities;
  @override
  List<CrimeCategory> get categories => _categories;
  @override
  Suburb? suburbById(String id) => _areasById[id];

  // ------------------------------------------------------------------
  // Loading
  // ------------------------------------------------------------------

  @override
  Future<void> init() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      // DUMMY ACCOUNTS: only used when nobody is signed in.
      // Turn on "Allow anonymous sign-ins" in Supabase > Authentication > Sign In / Providers.
      // Delete these 3 lines once the team's real login screen is connected.
      if (_db.auth.currentUser == null) {
        await _db.auth.signInAnonymously();
      }
      await _loadAreas();
      await _loadCategories();
      await _loadPosts();
      _subscribe();
    } catch (e, st) {
      debugPrint('Community init failed: $e\n$st');
      _error = e is StateError
          ? e.message
          : 'Could not connect to the server. Check your internet and try again.';
    }
    _loading = false;
    notifyListeners();
  }

  @override
  Future<void> refresh() async {
    try {
      await _loadPosts();
    } catch (e) {
      debugPrint('Community refresh failed: $e');
    }
    notifyListeners();
  }

  Future<void> _loadAreas() async {
    final all = <Map<String, dynamic>>[];
    var from = 0;
    const page = 1000; // Supabase returns at most 1000 rows per request
    while (true) {
      final rows = await _db
          .from('areas')
          .select('id, name, group_name')
          .order('group_name')
          .order('name')
          .range(from, from + page - 1);
      all.addAll(List<Map<String, dynamic>>.from(rows));
      if (rows.length < page) break;
      from += page;
    }
    if (all.isEmpty) {
      throw StateError('The areas table is empty.');
    }

    final groups = <String, List<Suburb>>{};
    for (final r in all) {
      final group = r['group_name'] as String;
      groups
          .putIfAbsent(group, () => [])
          .add(Suburb(r['id'] as String, r['name'] as String, group));
    }
    _cities = [for (final e in groups.entries) City(e.key, e.value)];
    _areasById
      ..clear()
      ..addAll({
        for (final c in _cities)
          for (final s in c.suburbs) s.id: s,
      });
  }

  Future<void> _loadCategories() async {
    final rows = await _db
        .from('crime_categories')
        .select('id, name, description')
        .order('name');
    _categories = [
      for (final r in rows)
        CrimeCategory(
          (r['id'] as num).toInt(),
          r['name'] as String,
          (r['description'] as String?) ?? '',
        ),
    ];
    if (_categories.isEmpty) {
      throw StateError('The crime_categories table is empty.');
    }
    _categoriesById
      ..clear()
      ..addAll({for (final c in _categories) c.id: c});
  }

  /// Names come from the public_profiles view (full name, else username).
  Future<void> _loadUsers(Set<String> ids) async {
    if (ids.isEmpty) return;
    final list = ids.toList();
    for (var i = 0; i < list.length; i += 100) {
      final end = i + 100 > list.length ? list.length : i + 100;
      final rows = await _db
          .from('public_profiles')
          .select('id, display_name, verified')
          .inFilter('id', list.sublist(i, end));
      for (final r in rows) {
        final m = Map<String, dynamic>.from(r as Map);
        _users[m['id'] as String] = _userFrom(m);
      }
    }
  }

  AppUser _userFrom(Map? m, {String fallbackId = ''}) {
    final id = (m?['id'] as String?) ?? fallbackId;
    return AppUser(
      id: id,
      name: (m?['display_name'] as String?) ?? 'Neighbour',
      color: _avatarColors[
          id.codeUnits.fold<int>(0, (a, b) => a + b) % _avatarColors.length],
      verified: (m?['verified'] as bool?) ?? false,
    );
  }

  AppUser _userFor(String id) => _users[id] ?? _userFrom(null, fallbackId: id);

  Future<void> _loadPosts() async {
    final rows = await _db
        .from('posts')
        .select('id, area_id, other_area, crime_category_id, title, body, '
            'created_at, author_id, attachment_type, attachment_name, '
            'attachment_size, attachment_url, '
            'comments(id, body, created_at, author_id)')
        .order('created_at', ascending: false)
        .limit(100);

    final data = [for (final r in rows) Map<String, dynamic>.from(r as Map)];

    // Look up everyone who wrote a post or a reply, then build the posts.
    final authorIds = <String>{
      _db.auth.currentUser!.id,
      for (final r in data) r['author_id'] as String,
      for (final r in data)
        for (final c in (r['comments'] as List? ?? []))
          (c as Map)['author_id'] as String,
    };
    await _loadUsers(authorIds);
    _me = _userFor(_db.auth.currentUser!.id);

    // Re-use existing Post objects so an open post screen keeps updating.
    final existing = {for (final p in _posts) p.id: p};
    final result = <Post>[];
    for (final r in data) {
      final fresh = _postFrom(r);
      final old = existing[fresh.id];
      if (old == null) {
        result.add(fresh);
      } else {
        old.comments
          ..clear()
          ..addAll(fresh.comments);
        result.add(old);
      }
    }
    _posts = result;
  }

  void _subscribe() {
    if (_channel != null) return;
    void changed(dynamic _) {
      _debounce?.cancel();
      _debounce = Timer(const Duration(milliseconds: 400), refresh);
    }

    var channel = _db.channel('community-feed');
    for (final table in ['posts', 'comments']) {
      channel = channel.onPostgresChanges(
        event: sb.PostgresChangeEvent.all,
        schema: 'public',
        table: table,
        callback: changed,
      );
    }
    _channel = channel.subscribe();
  }

  // ------------------------------------------------------------------
  // Database rows -> app models
  // ------------------------------------------------------------------

  Post _postFrom(Map<String, dynamic> r) {
    final url = r['attachment_url'] as String?;
    final attachment = url == null
        ? null
        : PostAttachment(
            type: AttachmentType.values.byName(r['attachment_type'] as String),
            name: r['attachment_name'] as String,
            sizeBytes: r['attachment_size'] as int,
            url: url,
          );

    final comments = <Comment>[
      for (final c in (r['comments'] as List? ?? []))
        Comment(
          id: (c as Map)['id'] as String,
          author: _userFor(c['author_id'] as String),
          text: c['body'] as String,
          createdAt: DateTime.parse(c['created_at'] as String).toLocal(),
        ),
    ]..sort((a, b) => a.createdAt.compareTo(b.createdAt));

    final categoryId = (r['crime_category_id'] as num).toInt();

    return Post(
      id: r['id'] as String,
      areaId: r['area_id'] as String?,
      otherArea: r['other_area'] as String?,
      author: _userFor(r['author_id'] as String),
      category: _categoriesById[categoryId] ??
          CrimeCategory(categoryId, 'Other Crime', ''),
      title: r['title'] as String,
      body: r['body'] as String,
      createdAt: DateTime.parse(r['created_at'] as String).toLocal(),
      attachment: attachment,
      comments: comments,
    );
  }

  // ------------------------------------------------------------------
  // Reading
  // ------------------------------------------------------------------

  @override
  List<Post> posts({Suburb? area, CrimeCategory? category}) {
    return _posts.where((p) {
      final areaOk = area == null || p.areaId == area.id;
      final categoryOk = category == null || p.category == category;
      return areaOk && categoryOk;
    }).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  // ------------------------------------------------------------------
  // Writing
  // ------------------------------------------------------------------

  @override
  Future<void> addPost({
    Suburb? area,
    String? otherArea,
    required CrimeCategory category,
    required String title,
    required String body,
    PostAttachment? attachment,
  }) async {
    final uid = _db.auth.currentUser!.id;

    // 1. Upload the picture/document (folder = the user's id, as the storage rule requires).
    String? path;
    String? url;
    if (attachment != null) {
  final bytes = attachment.bytes;

  if (bytes != null) {
    final safeName =
        attachment.name.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
    path = '$uid/${DateTime.now().microsecondsSinceEpoch}_$safeName';

    await _db.storage.from(_bucket).uploadBinary(
          path,
          bytes,
          fileOptions: sb.FileOptions(contentType: attachment.mimeType),
        );

    url = _db.storage.from(_bucket).getPublicUrl(path);
  } else {
    url = attachment.url;
  }
}

    // 2. Save the post. If this fails, remove the file we just uploaded.
    try {
      await _db.from('posts').insert({
        'area_id': area?.id,
        'other_area': area == null ? otherArea : null,
        'crime_category_id': category.id,
        'title': title,
        'body': body,
        if (attachment != null) ...{
          'attachment_type': attachment.type.name,
          'attachment_name': attachment.name,
          'attachment_size': attachment.sizeBytes,
          'attachment_path': path,
          'attachment_url': url,
        },
      });
    } catch (_) {
      if (path != null) {
        try {
          await _db.storage.from(_bucket).remove([path]);
        } catch (_) {}
      }
      rethrow;
    }
    await refresh();
  }

  @override
  Future<void> addComment(Post post, String text) async {
    await _db.from('comments').insert({'post_id': post.id, 'body': text});
    await refresh();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _channel?.unsubscribe();
    super.dispose();
  }
}