class CallInfoNotificationEntity {
  String displayName;
  String status;
  Duration callDuration;

  CallInfoNotificationEntity({required this.callDuration, required this.status, required this.displayName});
}
