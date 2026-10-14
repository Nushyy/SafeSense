import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

// =====================================================================
// MODELS
// =====================================================================

class City {
  final String name;
  final List<Suburb> suburbs;
  const City(this.name, this.suburbs);
}

class Suburb {
  final String id;
  final String name;
  final String city;
  const Suburb(this.id, this.name, this.city);
  String get label => '$name, $city';
}

class AppUser {
  final String id;
  final String name;
  final Color color;
  final bool verified;
  const AppUser({
    required this.id,
    required this.name,
    required this.color,
    this.verified = false,
  });

  String get initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }
}

enum PostCategory { missing, watch, safety, pets, meeting }

extension PostCategoryInfo on PostCategory {
  /// Short label used on the filter chips.
  String get chipLabel => switch (this) {
        PostCategory.missing => 'Missing',
        PostCategory.watch => 'Watch',
        PostCategory.safety => 'Safety',
        PostCategory.pets => 'Pets',
        PostCategory.meeting => 'Meetings',
      };

  /// Label used on the coloured tag on each card.
  String get tagLabel => switch (this) {
        PostCategory.missing => 'Missing Person',
        PostCategory.watch => 'Neighbourhood Watch',
        PostCategory.safety => 'Safety Announcement',
        PostCategory.pets => 'Lost Pet',
        PostCategory.meeting => 'Meeting',
      };

  Color get color => switch (this) {
        PostCategory.missing => AppColors.danger,
        PostCategory.watch => AppColors.darkBlue,
        PostCategory.safety => AppColors.success,
        PostCategory.pets => AppColors.warning,
        PostCategory.meeting => AppColors.primaryBlue,
      };
}

class Comment {
  final String id;
  final AppUser author;
  final String text;
  final DateTime createdAt;
  const Comment({
    required this.id,
    required this.author,
    required this.text,
    required this.createdAt,
  });
}

class Post {
  final String id;
  final String areaId;
  final AppUser author;
  final PostCategory category;
  final String title;
  final String body;
  final DateTime createdAt;
  final bool hasImage;
  final Set<String> likedBy; // user ids
  final List<Comment> comments;

  Post({
    required this.id,
    required this.areaId,
    required this.author,
    required this.category,
    required this.title,
    required this.body,
    required this.createdAt,
    this.hasImage = false,
    Set<String>? likedBy,
    List<Comment>? comments,
  })  : likedBy = likedBy ?? <String>{},
        comments = comments ?? <Comment>[];

  int get likeCount => likedBy.length;
}

const _weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
const _months = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
];

/// "Today, 09:15" / "Yesterday, 18:40" / "Mon, 14:20" / "12 Sep, 10:05"
String formatPostTime(DateTime t) {
  String two(int n) => n.toString().padLeft(2, '0');
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final day = DateTime(t.year, t.month, t.day);
  final diff = today.difference(day).inDays;
  final hm = '${two(t.hour)}:${two(t.minute)}';
  if (diff <= 0) return 'Today, $hm';
  if (diff == 1) return 'Yesterday, $hm';
  if (diff < 7) return '${_weekdays[t.weekday - 1]}, $hm';
  return '${t.day} ${_months[t.month - 1]}, $hm';
}

// =====================================================================
// REPOSITORY
// The screens only use this interface. When Supabase is ready, write a
// SupabaseCommunityRepository that implements it and change the last line.
// =====================================================================

abstract class CommunityRepository extends ChangeNotifier {
  AppUser get currentUser;
  List<City> get cities;
  Suburb? suburbById(String id);
  List<Post> posts({Suburb? area, PostCategory? category});
  Future<void> addPost({
    required Suburb area,
    required PostCategory category,
    required String title,
    required String body,
  });
  Future<void> toggleLike(Post post);
  Future<void> addComment(Post post, String text);
}

class InMemoryCommunityRepository extends CommunityRepository {
  // ---- Dummy accounts ----
  static const nomsa = AppUser(
      id: 'u1', name: 'Nomsa Dlamini', color: AppColors.danger, verified: true);
  static const watchGroup = AppUser(
      id: 'u2',
      name: 'Community Watch Eldorado Park',
      color: AppColors.darkBlue,
      verified: true);
  static const priya =
      AppUser(id: 'u3', name: 'Priya Naidoo', color: AppColors.warning);
  static const metro = AppUser(
      id: 'u4',
      name: 'Johannesburg Metro Police',
      color: AppColors.success,
      verified: true);
  static const thabo =
      AppUser(id: 'u5', name: 'Thabo Molefe', color: AppColors.primaryBlue);
  static const me =
      AppUser(id: 'me', name: 'Lerato Mokoena', color: AppColors.heroBlue);

  @override
  AppUser get currentUser => me;

  static const _cities = [
    City('Bloemfontein', [
      Suburb('bfn-heidedal', 'Heidedal', 'Bloemfontein'),
      Suburb('bfn-universitas', 'Universitas', 'Bloemfontein'),
      Suburb('bfn-langenhoven', 'Langenhoven Park', 'Bloemfontein'),
      Suburb('bfn-pentagon', 'Pentagon Park', 'Bloemfontein'),
    ]),
    City('Johannesburg', [
      Suburb('jhb-soweto', 'Soweto', 'Johannesburg'),
      Suburb('jhb-sandton', 'Sandton', 'Johannesburg'),
      Suburb('jhb-randburg', 'Randburg', 'Johannesburg'),
      Suburb('jhb-eldorado', 'Eldorado Park', 'Johannesburg'),
      Suburb('jhb-florida', 'Florida Park', 'Johannesburg'),
    ]),
  ];

  @override
  List<City> get cities => _cities;

  @override
  Suburb? suburbById(String id) {
    for (final city in _cities) {
      for (final s in city.suburbs) {
        if (s.id == id) return s;
      }
    }
    return null;
  }

  static DateTime _at(int daysAgo, int hour, int minute) {
    final n = DateTime.now();
    return DateTime(n.year, n.month, n.day - daysAgo, hour, minute);
  }

  late final List<Post> _posts = [
    Post(
      id: 'p1',
      areaId: 'jhb-soweto',
      author: nomsa,
      category: PostCategory.missing,
      title: 'Missing: Thabo Dlamini, 14 years old',
      body:
          'Last seen near Protea Glen Mall on Friday evening wearing blue school uniform. If seen please call 082 555 0123.',
      createdAt: _at(0, 9, 15),
      hasImage: true,
      likedBy: {'a', 'b', 'c', 'd'},
      comments: [
        Comment(
            id: 'c1',
            author: thabo,
            text: 'Shared with our street group. Praying he is found safe.',
            createdAt: _at(0, 9, 40)),
      ],
    ),
    Post(
      id: 'p2',
      areaId: 'jhb-eldorado',
      author: watchGroup,
      category: PostCategory.watch,
      title: 'Patrol schedule – this week',
      body:
          'Patrols run nightly 20:00–02:00. Volunteers needed for Wednesday and Friday shifts. Reply here to sign up.',
      createdAt: _at(1, 18, 40),
      likedBy: {'a', 'b'},
    ),
    Post(
      id: 'p3',
      areaId: 'jhb-florida',
      author: priya,
      category: PostCategory.pets,
      title: 'Lost – golden retriever named Biscuit',
      body:
          'Missing from Florida Park since Sunday morning. Microchipped and wearing red collar. Reward offered.',
      createdAt: _at(3, 14, 20),
      hasImage: true,
      likedBy: {'a'},
    ),
    Post(
      id: 'p4',
      areaId: 'jhb-sandton',
      author: metro,
      category: PostCategory.safety,
      title: 'Vehicle break-ins: keep valuables out of sight',
      body:
          'We have seen an increase in smash-and-grab incidents around Sandton CBD. Do not leave bags or phones visible in parked cars.',
      createdAt: _at(4, 8, 0),
      likedBy: {'a', 'b', 'c'},
    ),
    Post(
      id: 'p5',
      areaId: 'bfn-heidedal',
      author: thabo,
      category: PostCategory.watch,
      title: 'Suspicious vehicle near Heidedal main road',
      body:
          'White bakkie with no number plates driving slowly past houses around 19:00. Please lock gates and report to SAPS if you see it.',
      createdAt: _at(5, 19, 30),
      likedBy: {'a'},
    ),
    Post(
      id: 'p6',
      areaId: 'bfn-universitas',
      author: watchGroup,
      category: PostCategory.meeting,
      title: 'Neighbourhood meeting – Thursday 18:00',
      body:
          'Open meeting at the community hall to discuss street lighting and the new alert system. Everyone is welcome.',
      createdAt: _at(6, 12, 10),
    ),
  ];

  @override
  List<Post> posts({Suburb? area, PostCategory? category}) {
    final result = _posts.where((p) {
      final areaOk = area == null || p.areaId == area.id;
      final categoryOk = category == null || p.category == category;
      return areaOk && categoryOk;
    }).toList();
    result.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return result;
  }

  @override
  Future<void> addPost({
    required Suburb area,
    required PostCategory category,
    required String title,
    required String body,
  }) async {
    _posts.add(Post(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      areaId: area.id,
      author: currentUser,
      category: category,
      title: title,
      body: body,
      createdAt: DateTime.now(),
    ));
    notifyListeners();
  }

  @override
  Future<void> toggleLike(Post post) async {
    if (!post.likedBy.remove(currentUser.id)) {
      post.likedBy.add(currentUser.id);
    }
    notifyListeners();
  }

  @override
  Future<void> addComment(Post post, String text) async {
    post.comments.add(Comment(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      author: currentUser,
      text: text,
      createdAt: DateTime.now(),
    ));
    notifyListeners();
  }
}

/// One shared instance used by all screens.
/// Later: final CommunityRepository communityRepo = SupabaseCommunityRepository();
final CommunityRepository communityRepo = InMemoryCommunityRepository();