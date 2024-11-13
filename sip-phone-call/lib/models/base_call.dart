import 'package:sip_ua/sip_ua.dart';

class BaseCall {
  Call call;
  final Stopwatch _duration = Stopwatch();

  CallDisplayInfo? displayInfo = CallDisplayInfo();

  BaseCall({required this.call});

  void resetDuration() {
    _duration.reset();
  }

  void stopDuration() {
    _duration.stop();
  }

  void startDuration() {
    _duration.start();
  }

  String? get id => call.id;

  String get destination => call.session.contact ?? 'no_contact';

  Duration get duration => _duration.elapsed;
}

class CallDisplayInfo {
  String? avatar;
  String? displayName;
  CallDisplayInfo({this.displayName, this.avatar});

  CallDisplayInfo copyWith({
    String? avatar,
    String? displayName,
    String? message,
  }) {
    return CallDisplayInfo(
      avatar: avatar ?? this.avatar,
      displayName: displayName ?? this.displayName,
    );
  }
}
