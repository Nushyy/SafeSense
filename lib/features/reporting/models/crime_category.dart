class CrimeCategory {
  final int id;
  final String name;

  const CrimeCategory({
    required this.id,
    required this.name,
  });

  factory CrimeCategory.fromJson(
    Map<String, dynamic> json,
  ) {
    return CrimeCategory(
      id: json['id'] as int,
      name: json['name'] as String,
    );
  }
}