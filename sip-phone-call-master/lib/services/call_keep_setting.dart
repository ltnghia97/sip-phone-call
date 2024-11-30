part of 'sip_call_services.dart';

Function? handleCallAction;
Timer? timerCancelHandleCallAction;
Duration durationWillCallAction = const Duration(seconds: 5);
bool shouldEndInterfereCall = false;

/// true: can receive
/// false: can not receive
Map<String, bool> mapCallWithStatus = {};

EventManager eventManager = EventManager()
  ..on(CallKeepDidDisplayIncomingCall(), didDisplayIncomingCall)
  ..on(CallKeepPerformAnswerCallAction(), answerAction)
  ..on(CallKeepPerformEndCallAction(), endAction)
  ..on(CallKeepDidPerformSetMutedCallAction(), setMuted)
  ..on(CallKeepDidActivateAudioSession(), didActiveAudioSession)
  ..on(CallKeepPushKitToken(), didPushKitToken);

Function(CallKeepDidDisplayIncomingCall) didDisplayIncomingCall = (event) async {
  shouldEndInterfereCall = false;

  print('didDisplayIncomingCall called');
  print('call uuid = ${event.callUUID ?? ''}');

  CallManagementService callManagementService = CallManagementService.getInstance();
  SipCallService sipCallService = SipCallService.getInstance();

  print('didDisplayIncomingCall is in call = ${sipCallService.isInCall} - map call = ${callManagementService.mapCall}');

  if (event.callUUID != null) {
    mapCallWithStatus.putIfAbsent(event.callUUID!, () => mapCallWithStatus[event.callUUID!] = true);
  }

  // if ((sipCallService.isInCall) && callManagementService.currentCallInfo?.isHolding != true) {
  //   sipCallService.endCurrentCallCloseNotification(callId: event.callUUID);
  //   return;
  // }
  /// If the app is in call -> end the incoming call
  BaseCall? currentCall = callManagementService.getCallBeforeTransfer();
  if (currentCall != null && currentCall.call.isHolding != true && (event.callUUID ?? "").isNotEmpty) {
    shouldEndInterfereCall = true;
    mapCallWithStatus[event.callUUID!] = false;
  }

  if (!await sipCallService.shouldHandleIncomingCall(event.callUUID ?? '')) {
    print('didDisplayIncomingCall end current call close noti');
    sipCallService.endCurrentCallCloseNotification();
    // } else if (!callManagementService.canAddCall(newCallId: event.callUUID)) {
    //   sipCallService.endCurrentCallCloseNotification(callId: event.callUUID);
  } else {
    print('didDisplayIncomingCall register - event = $event');
    sipCallService.callerName = event.localizedCallerName ?? "";
    sipCallService.helper.register();
  }
};

void showCallScreen(event) {
  // CallManagementService callManagementService = CallManagementService.getInstance();
  // if (!callManagementService.canAddCall(newCallId: event.callUUID)) {
  //   return;
  // }
  SipCallService sipCallService = SipCallService.getInstance();

  sipCallService.callKitDidActivateAudioSession = Completer();
  print('displayIncomingCall from ios didDisplayIncomingCall');
  sipCallService.displayIncomingCall(callerName: sipCallService.callerName, callId: event.callUUID ?? '', forceRegister: false);
}

Function(CallKeepPerformAnswerCallAction) answerAction = (event) {
  showCallScreen(event);
  executeAnswerCallAction();
};

void executeAnswerCallAction() {
  if (Platform.isAndroid) {
    FlutterVibration().stop();
  }
  SipCallService sipCallService = SipCallService.getInstance();
  if (sipCallService.currentCallInfo?.state == CallStateEnum.PROGRESS) {
    sipCallService.handleAccept(true);
  } else {
    handleCallAction = () => sipCallService.handleAccept(true);
    if (timerCancelHandleCallAction != null) {
      timerCancelHandleCallAction!.cancel();
    }
    timerCancelHandleCallAction = Timer(durationWillCallAction, () {
      handleCallAction = null;
    });
  }
}

Function(CallKeepPerformEndCallAction) endAction = (event) {
  executeEndCallAction();
};

bool hasInterfereCall() {
  return mapCallWithStatus.containsValue(false);
}

void removeAllInterfereCalls() {
  SipCallService sipCallService = SipCallService.getInstance();
  mapCallWithStatus.forEach((key, value) {
    if (!value) {
      sipCallService.endCallWithUUID(uuid: key);
    }
  });
  // mapCallWithStatus.removeWhere((key, value) => !value);
}

void executeEndCallAction() {
  if (Platform.isAndroid) {
    FlutterVibration().stop();
  } else {
    if (shouldEndInterfereCall) {
      shouldEndInterfereCall = false;
      return;
    }
  }
  mapCallWithStatus = {};
  SipCallService sipCallService = SipCallService.getInstance();
  if ([CallStateEnum.PROGRESS, CallStateEnum.STREAM, CallStateEnum.CONFIRMED].contains(sipCallService.currentCallInfo?.state)) {
    print('call handleEndCall from executeEndCallAction call not null');
    sipCallService.handleEndCall();
  } else {
    print('assign handleEndCall from executeEndCallAction call is null');
    handleCallAction = sipCallService.handleEndCall;
    if (timerCancelHandleCallAction != null) {
      timerCancelHandleCallAction!.cancel();
    }
    timerCancelHandleCallAction = Timer(durationWillCallAction, () {
      handleCallAction = null;
    });
  }
}

Function(CallKeepDidPerformSetMutedCallAction) setMuted = (event) {
  print('set muted called - event.muted = ${event.muted}');
  SipCallService.getInstance().setMic(event.muted ?? false);
};

Function(CallKeepDidActivateAudioSession) didActiveAudioSession = (event) {
  print('did active audio session called');
  SipCallService sipCallService = SipCallService.getInstance();
  sipCallService.setSpeaker(false);
  sipCallService.callKitDidActivateAudioSession?.complete();
};

Function(CallKeepPushKitToken) didPushKitToken = (event) {
  print('didPushKitToken called');
  SipCallService sipCallService = SipCallService.getInstance();
  String token = event.token ?? '';
  sipCallService._handleDidPushToken(token);
  sipCallService._onDetectApnsToken(token);
};
