class UserProfile {
  String firstName;
  String surname;
  String cellphone;
  String email;
  String location;
  String username;

  UserProfile({
    required this.firstName,
    required this.surname,
    required this.cellphone,
    required this.email,
    required this.location,
    required this.username,
  });

  String get fullName => '$firstName $surname';
}