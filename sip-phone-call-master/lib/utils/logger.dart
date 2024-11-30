import 'package:flutter/foundation.dart';

class Logger {
  static void log(String str) {
    if (kDebugMode) {
      print(str);
    }
  }
}
