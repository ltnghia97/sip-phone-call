import 'dart:ui';

import 'package:sip_phone_call/services/local_storage_services.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

typedef OnCallerCancel = VoidCallback;
typedef OnNewInBoundCall = Function(String);
typedef OnRemoveDevice = VoidCallback;
typedef OnCallStateAnswered = Function(String);

class SocketService {
  late IO.Socket socket;
  late String userAgent;
  late String url;
  late String authToken;
  late String ext;
  OnCallerCancel? onCallerCancel;
  OnNewInBoundCall? onNewInBoundCall;
  OnRemoveDevice? onRemoveDevice;
  OnCallStateAnswered? onCallStateAnswered;

  /// Save the call-id to local storage
  /// Because FCM may be received AFTER receiving cancel message -> app may show incoming call AFTER the call is no longer exist
  /// Only save when the app is not in call
  saveCallIdToLocal(String callId) {
    print('inside saveCallIdToLocal - call id = $callId');
    // if (!(SipCallService.getInstance().isInCall && SipCallService.getInstance().call!.id == callId)) {
    LocalStorageService.getInstance().setData(callId, callId);
    // }
  }

  SocketService({
    required this.url,
    required this.userAgent,
    required this.ext,
    required this.authToken,
    this.onCallerCancel,
    this.onNewInBoundCall,
    this.onRemoveDevice,
    this.onCallStateAnswered,
  }) {
    socket = IO.io(
      url,
      IO.OptionBuilder().setTransports(['websocket']).setExtraHeaders({'user-agent': userAgent}).setAuth({'token': authToken}).enableForceNew().build(),
    );

    socket.onConnect((_) {
      print('Socket connected');
      socket.emit('update-sales-ext');
    });
    socket.on('update-call-state', (data) async {
      print('Socket event $data');
      switch (data['type']) {
        case 'CALLER_CANCEL':

          /// Save call-id to local
          saveCallIdToLocal(data['uuid']);
          print('call onCallerCancel from update-call-state');
          onCallerCancel?.call();
          break;
        case 'ANSWERED':
          onCallStateAnswered?.call(data['uuid']);
          break;
      }
    });
    socket.on('new-inbound-call', (data) {
      onNewInBoundCall?.call(data['caller_name']);
    });
    socket.on('remove-device', (_) {
      onRemoveDevice?.call();
    });
    socket.on('receive-call-other-device', (data) async {
      print('receive call other device');

      /// Save call-id to local
      saveCallIdToLocal(data['uuid']);
      print('call onCallerCancel from eceive call other device');
      onCallerCancel?.call();
    });
    socket.onDisconnect((_) => print('Socket disconnect'));

    socket.onConnectError((data) => print('Socket connect error $data'));
  }

  emitStartCallInDevice(String callId) {
    print('emit start call in device call id = $callId');
    socket.emit('start-call-in-device', {'call_id': callId});
  }

  emitCallEnded() {
    socket.emit('update-call-state', {'type': 'CALL_ENDED', 'extension': ext});
  }

  emitUpdateFcmToken(String token) {
    socket.emit('update-fcm-token', token);
  }

  emitAcceptedCall(String callId) {
    print('emit accept call call id = $callId');
    socket.emit('receive-call-in-device', {
      "call_id": callId,
    });
  }

  close() {
    socket.dispose();
    print('close socket');
  }
}
