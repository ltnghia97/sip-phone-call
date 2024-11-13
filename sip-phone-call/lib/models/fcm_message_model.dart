import 'package:uuid/uuid.dart';

class FCMMessageModel {
  String callerId = '';
  String callerName = '';
  String uuid = '';
  bool hasVideo = false;
  String callUUID = '';
  String type = '';

  FCMMessageModel.fromJson(Map<String, dynamic> json) {
    callerId = json['caller_id'] ?? '';
    callerName = json['caller_name'] ?? '';
    uuid = json['uuid'] ?? '';
    hasVideo = json['has_video'] == "true";
    callUUID = uuid.isNotEmpty ? uuid : const Uuid().v4();
    type = json['type'];
  }

  Map<String, dynamic> toJson() {
    return {
      "caller_id": callerId,
      "caller_name": callerName,
      "uuid": uuid,
      "has_video": hasVideo,
      "type": type,
    };
  }
}
