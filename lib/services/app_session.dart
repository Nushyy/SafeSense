import '../models/trusted_user.dart';
import '../models/user_profile.dart';

class AppSession {
  static UserProfile currentUser = UserProfile(
    firstName: 'Your',
    surname: 'Name',
    cellphone: 'Your cellphone',
    email: 'your@email.com',
    location: 'Your town',
    username: '@username',
  );

  static final List<TrustedUser> trustedUsers = [];

  static void updateUser(UserProfile user) {
    currentUser = user;
  }

  static void addTrustedUser(TrustedUser user) {
    trustedUsers.add(user);
  }

  static void removeTrustedUser(TrustedUser user) {
    trustedUsers.remove(user);
  }
}