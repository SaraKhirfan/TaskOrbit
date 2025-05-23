// File: lib/services/user_service.dart
import 'package:flutter/foundation.dart';

class UserService extends ChangeNotifier {
  String _userRole = '';
  String _userName = '';
  String _userEmail = '';

  String get userRole => _userRole;
  String get userName => _userName;
  String get userEmail => _userEmail;

  void setUserInfo({
    required String name,
    required String email,
    required String role,
  }) {
    _userName = name;
    _userEmail = email;
    _userRole = role;
    notifyListeners();
  }

  bool isProductOwner() => _userRole == 'Product_Owner';
  bool isScrumMaster() => _userRole == 'Scrum_Master';
  bool isTeamMember() => _userRole == 'Team_Member';
  bool isClient() => _userRole == 'Client';
}
