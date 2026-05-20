import 'package:flutter/material.dart';

class SettingsViewModel extends ChangeNotifier {
  bool _isDarkMode = false;
  bool _isSoundEnabled = true;
  bool _isNotificationsEnabled = true;

  bool get isDarkMode => _isDarkMode;
  bool get isSoundEnabled => _isSoundEnabled;
  bool get isNotificationsEnabled => _isNotificationsEnabled;

  void toggleTheme(bool value) {
    _isDarkMode = value;
    notifyListeners();
  }

  void toggleSound(bool value) {
    _isSoundEnabled = value;
    notifyListeners();
  }

  void toggleNotifications(bool value) {
    _isNotificationsEnabled = value;
    notifyListeners();
  }
}
