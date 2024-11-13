import 'package:flutter/cupertino.dart';
import 'package:sip_ua/sip_ua.dart';

import '../models/base_call.dart';

class CallManagementService {
  static CallManagementService? _instance;

  CallManagementService._();

  factory CallManagementService.getInstance() {
    _instance ??= CallManagementService._();
    return _instance!;
  }

  final Map<String, BaseCall> _mapCall = {};
  BaseCall? _currentCall;

  BaseCall? get currentCall => _currentCall;

  set currentCall(BaseCall? value) {
    _currentCall = value;
    currentCalUpdateNotifier.value = _currentCall;
  }

  ValueNotifier<BaseCall?> currentCalUpdateNotifier = ValueNotifier(null);

  Map<String, BaseCall> get mapCall => _mapCall;

  Call? get currentCallInfo {
    return currentCall?.call;
  }

  bool hasNoCall() {
    return _mapCall.isEmpty;
  }

  void removeCall({String? callId}) {
    print('remove call id = $callId');
    if (callId == null) return;
    _mapCall[callId]?.stopDuration();
    _mapCall.removeWhere((key, value) => key == callId);
    _updateCurrentCall();
  }

  void removeCurrentCall() {
    removeCall(callId: currentCallInfo?.id);
  }
  //
  // bool canAddCall({String? newCallId}) {
  //   return ((_mapCall.isEmpty) || (currentCallInfo?.isHolding == true && currentCallInfo?.id != newCallId)) && ((newCallId ?? "").isNotEmpty);
  // }

  void addCall({required Call call}) {
    if (call.id != null) {
      if (_mapCall.isEmpty) {
        print('addCall first add');
        _mapCall.addAll({call.id!: BaseCall(call: call)});
      } else if (currentCallInfo?.isHolding == true) {
        print('addCall add transfer call');
        _mapCall.putIfAbsent(call.id!, () {
          return BaseCall(call: call);
        });
      } else {
        print('addCall no add call');
      }
    }
    print('addCall list callID = ${_mapCall.keys.toList()}');
    _updateCurrentCall();
  }

  void updateCallDisplayInfo({required String callId, required CallDisplayInfo info}) {
    _mapCall[callId]?.displayInfo?.displayName = info.displayName;
    _mapCall[callId]?.displayInfo?.avatar = info.avatar;
  }

  /// Current call:
  /// - Must not be held
  /// - If the map only has 1 item => get that element
  void _updateCurrentCall() {
    if (_mapCall.isEmpty) {
      currentCall = null;
      return;
    }
    if (_mapCall.length == 1) {
      currentCall = _mapCall.values.first;
      print("current call is the first object");
      return;
    }
    for (BaseCall? baseCall in _mapCall.values.toList()) {
      if (baseCall?.call.isHolding == false) {
        print("current call is not held");
        currentCall = baseCall;
        return;
      }
    }
    print('current call is null');
  }

  bool isInTransferCall() {
    print('map call length = ${_mapCall.length} - current call is not holding = ${currentCallInfo?.isHolding == false}');
    return _mapCall.length > 1 && (currentCallInfo?.isHolding == false);
  }

  bool isHasCall({String? callId}) {
    return _mapCall.containsKey(callId);
  }

  BaseCall? getCallBeforeTransfer() {
    if (_mapCall.isEmpty) return null;
    int totalCall = _mapCall.length;
    if (totalCall == 1) return _mapCall.values.toList().first;
    List<BaseCall?> listBaseCall = _mapCall.values.toList();
    for (int i = 0; i < totalCall - 1; i++) {
      if (listBaseCall[i] != null && listBaseCall[i]!.call.isHolding) {
        if (listBaseCall[i + 1] != null && !listBaseCall[i + 1]!.call.isHolding) {
          return listBaseCall[i];
        }
      }
    }
    return null;
  }
}
