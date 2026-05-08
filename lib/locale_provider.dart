import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocaleProvider extends ChangeNotifier {
  static const String _key = 'app_locale';
  String _locale = 'en';

  String get locale => _locale;
  bool get isEnglish => _locale == 'en';

  Future<void> loadLocale() async {
    final prefs = await SharedPreferences.getInstance();
    _locale = prefs.getString(_key) ?? 'en';
    notifyListeners();
  }

  Future<void> setLocale(String locale) async {
    if (_locale == locale) return;
    _locale = locale;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, locale);
    notifyListeners();
  }

  Future<void> toggleLocale() async {
    await setLocale(_locale == 'en' ? 'vi' : 'en');
  }
}
