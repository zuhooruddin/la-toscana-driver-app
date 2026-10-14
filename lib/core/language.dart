import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppLanguage extends ChangeNotifier {
  AppLanguage([this.code = 'es']);
  String code;
  Locale get locale => Locale(code);
  String text(String es, String en) => code == 'en' ? en : es;

  Future<void> load() async {
    final saved = (await SharedPreferences.getInstance()).getString(
      'lt_language',
    );
    if (saved == 'es' || saved == 'en') code = saved!;
    notifyListeners();
  }

  Future<void> setLanguage(String next) async {
    if (next != 'es' && next != 'en') return;
    code = next;
    notifyListeners();
    await (await SharedPreferences.getInstance()).setString(
      'lt_language',
      next,
    );
  }
}
