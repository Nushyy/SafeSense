import 'dart:typed_data';
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

/// A type of crime: one row of the crime_categories table in Supabase.
class CrimeCategory {
  final int id;
  final String name;
  final String description;
  const CrimeCategory(this.id, this.name, this.description);

  /// The table has no colour column, so the tag colour is picked from the name.
  Color get color {
    final n = name.toLowerCase();
    if (n.contains('violence') || n.contains('weapon') || n.contains('arson')) {
      return AppColors.danger;
    }
    if (n.contains('theft') ||
        n.contains('robbery') ||
        n.contains('burglary') ||
        n.contains('shoplifting') ||
        n.contains('vehicle') ||
        n.contains('bicycle')) {
      return AppColors.warning;
    }
    if (n.contains('drug') ||
        n.contains('antisocial') ||
        n.contains('public order')) {
      return AppColors.primaryBlue;
    }
    return AppColors.darkBlue;
  }

  // Categories are reloaded from the database, so compare them by id.
  @override
  bool operator ==(Object other) => other is CrimeCategory && other.id == id;
  @override
  int get hashCode => id.hashCode;
}

enum AttachmentType { picture, document }

/// "12 KB" / "3.4 MB"
String formatFileSize(int bytes) {
  if (bytes < 1024 * 1024) return '${(bytes / 1024).ceil()} KB';
  return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
}

/// The one picture or document a post can have.
/// Right after the user picks a file it has [bytes] (in memory). Once it is
/// saved in Supabase Storage, posts loaded from the database have a [url] instead.
class PostAttachment {
  final AttachmentType type;
  final String name;
  final int sizeBytes;
  final Uint8List? bytes;
  final String? url;
  const PostAttachment({
    required this.type,
    required this.name,
    required this.sizeBytes,
    this.bytes,
    this.url,
  });

  String get sizeLabel => formatFileSize(sizeBytes);

  String get mimeType {
    final ext = name.contains('.') ? name.split('.').last.toLowerCase() : '';
    switch (ext) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'pdf':
        return 'application/pdf';
      case 'docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
    }
    return 'application/octet-stream';
  }
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
  final String? areaId; // null when the author chose 'Other'
  final String? otherArea; // free-text town/village for 'Other'
  final AppUser author;
  final CrimeCategory category;
  final String title;
  final String body;
  final DateTime createdAt;
  final bool hasImage;
  final PostAttachment? attachment;
  final List<Comment> comments;

  Post({
    required this.id,
    this.areaId,
    this.otherArea,
    required this.author,
    required this.category,
    required this.title,
    required this.body,
    required this.createdAt,
    this.hasImage = false,
    this.attachment,
    List<Comment>? comments,
  }) : comments = comments ?? <Comment>[];
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
  /// Load data (areas, posts). The in-memory demo version has nothing to load.
  Future<void> init() async {}
  Future<void> refresh() async {}
  bool get isLoading => false;
  String? get errorMessage => null;

  AppUser get currentUser;
  List<City> get cities;
  Suburb? suburbById(String id);
  List<CrimeCategory> get categories;
  List<Post> posts({Suburb? area, CrimeCategory? category});

  /// Pass either [area] or [otherArea] (free text, when the user chose 'Other').
  Future<void> addPost({
    Suburb? area,
    String? otherArea,
    required CrimeCategory category,
    required String title,
    required String body,
    PostAttachment? attachment,
  });
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

  // Same types as the crime_categories table (used only for the dummy data).
  static const _categories = [
    CrimeCategory(1, 'Antisocial Behavior', 'Suspicious behavior from individual'),
    CrimeCategory(2, 'Bicycle Theft', 'Stolen bicycle'),
    CrimeCategory(3, 'Burglary', 'Unlawful entry into a property'),
    CrimeCategory(4, 'Criminal Damage & Arson', 'Vandalism and attempts of combustion'),
    CrimeCategory(5, 'Drugs', 'Drug use'),
    CrimeCategory(6, 'Other Crime', 'Other crimes not mentioned in the crime categories'),
    CrimeCategory(7, 'Other Theft', 'Other theft not mentioned in crime categories'),
    CrimeCategory(8, 'Possession of Weapons', 'Persons have weapons on them'),
    CrimeCategory(9, 'Public Order', 'Disorderly conduct and disturbing peace'),
    CrimeCategory(10, 'Robbery', 'Persons stealing others belongings'),
    CrimeCategory(11, 'Shoplifting', 'Persons stealing items from within stores'),
    CrimeCategory(12, 'Theft from Person', 'Stealing items directly from a person'),
    CrimeCategory(13, 'Vehicle Crime', 'Crimes done upon vehicles'),
    CrimeCategory(14, 'Violence & Sexual Offences', 'Assault and GBV'),
  ];

  @override
  List<CrimeCategory> get categories => _categories;

  CrimeCategory _c(int id) => _categories.firstWhere((c) => c.id == id);

  late final List<Post> _posts = [
    Post(
      id: 'p1',
      areaId: 'jhb-soweto',
      author: nomsa,
      category: _c(6),
      title: 'Missing: Thabo Dlamini, 14 years old',
      body:
          'Last seen near Protea Glen Mall on Friday evening wearing blue school uniform. If seen please call 082 555 0123.',
      createdAt: _at(0, 9, 15),
      hasImage: true,
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
      category: _c(1),
      title: 'Patrol schedule – this week',
      body:
          'Patrols run nightly 20:00–02:00. Volunteers needed for Wednesday and Friday shifts. Reply here to sign up.',
      createdAt: _at(1, 18, 40),
    ),
    Post(
      id: 'p3',
      areaId: 'jhb-florida',
      author: priya,
      category: _c(7),
      title: 'Lost – golden retriever named Biscuit',
      body:
          'Missing from Florida Park since Sunday morning. Microchipped and wearing red collar. Reward offered.',
      createdAt: _at(3, 14, 20),
      hasImage: true,
    ),
    Post(
      id: 'p4',
      areaId: 'jhb-sandton',
      author: metro,
      category: _c(13),
      title: 'Vehicle break-ins: keep valuables out of sight',
      body:
          'We have seen an increase in smash-and-grab incidents around Sandton CBD. Do not leave bags or phones visible in parked cars.',
      createdAt: _at(4, 8, 0),
    ),
    Post(
      id: 'p5',
      areaId: 'bfn-heidedal',
      author: thabo,
      category: _c(1),
      title: 'Suspicious vehicle near Heidedal main road',
      body:
          'White bakkie with no number plates driving slowly past houses around 19:00. Please lock gates and report to SAPS if you see it.',
      createdAt: _at(5, 19, 30),
    ),
    Post(
      id: 'p6',
      areaId: 'bfn-universitas',
      author: watchGroup,
      category: _c(9),
      title: 'Neighbourhood meeting – Thursday 18:00',
      body:
          'Open meeting at the community hall to discuss street lighting and the new alert system. Everyone is welcome.',
      createdAt: _at(6, 12, 10),
    ),
  ];

  @override
  List<Post> posts({Suburb? area, CrimeCategory? category}) {
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
    Suburb? area,
    String? otherArea,
    required CrimeCategory category,
    required String title,
    required String body,
    PostAttachment? attachment,
  }) async {
    _posts.add(Post(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      areaId: area?.id,
      otherArea: otherArea,
      author: currentUser,
      category: category,
      title: title,
      body: body,
      createdAt: DateTime.now(),
      attachment: attachment,
    ));
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
/// main.dart swaps in SupabaseCommunityRepository once the Supabase details are filled in.
CommunityRepository communityRepo = InMemoryCommunityRepository();