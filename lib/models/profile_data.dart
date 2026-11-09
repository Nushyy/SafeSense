class ProfileData {
  static String firstName = 'Kamo';
  static String lastName = 'Mahao';
  static String username = '@kamo';
  static String email = 'your@email.com';
  static String phoneNumber = '082 000 0000';
  static String town = 'Bloemfontein';
  static String bio = 'SafeSense community member';

  static String get fullName => '$firstName $lastName';

  static String get initials {
    final first = firstName.isNotEmpty ? firstName[0] : '';
    final last = lastName.isNotEmpty ? lastName[0] : '';
    return '$first$last'.toUpperCase();
  }
}