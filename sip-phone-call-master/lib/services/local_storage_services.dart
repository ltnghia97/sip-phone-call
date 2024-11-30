import 'dart:async';

import 'package:shared_preferences/shared_preferences.dart';

class LocalStorageService {
  static LocalStorageService? _localStorageService;
  late SharedPreferences _prefs;
  Completer<bool> completer = Completer<bool>();

  LocalStorageService._();

  factory LocalStorageService.getInstance() {
    if (_localStorageService == null) {
      _localStorageService = LocalStorageService._();
      _localStorageService!._init();
    }
    return _localStorageService!;
  }

  _init() async {
    _prefs = await SharedPreferences.getInstance();
    completer.complete(true);
  }

  Future<T> _handle<T>(Function fn) async {
    if (!completer.isCompleted) {
      await completer.future;
    }
    return fn.call();
  }

  setData<T>(String key, T value) async {
    _handle(() {
      if (value is bool) {
        _prefs.setBool(key, value);
      } else if (value is int) {
        _prefs.setInt(key, value);
      } else if (value is double) {
        _prefs.setDouble(key, value);
      } else if (value is String) {
        _prefs.setString(key, value);
      }
    });
  }

  Future<bool> containsKey(String key) async {
    return _handle(() {
      return _prefs.containsKey(key);
    });
  }

  Future<T> getData<T>(String key) async {
    return _handle(() {
      return _prefs.get(key) as T;
    });
  }

  remove(String key) {
    _handle(() {
      _prefs.remove(key);
    });
  }

  clear() {
    _handle(() {
      _prefs.clear();
    });
  }
}
