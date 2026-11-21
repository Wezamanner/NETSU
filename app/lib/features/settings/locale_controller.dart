import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final localeControllerProvider = NotifierProvider<LocaleController, Locale>(LocaleController.new);

class LocaleController extends Notifier<Locale> {
  static const _key = 'preferred_language';
  var _alive = true;

  @override
  Locale build() {
    _alive = true;
    ref.onDispose(() => _alive = false);
    Future<void>.microtask(_load);
    return const Locale('en');
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_key);
    if (!_alive) return;
    if (code == 'am' || code == 'om' || code == 'en') {
      state = Locale(code!);
    }
  }

  Future<void> setCode(String code) async {
    state = Locale(code);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, code);
  }
}
