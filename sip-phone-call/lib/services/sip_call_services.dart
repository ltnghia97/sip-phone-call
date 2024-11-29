import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:callkeep/callkeep.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_broadcasts/flutter_broadcasts.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_vibration/flutter_vibration.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:package_info/package_info.dart';
import 'package:sip_phone_call/bloc/call_display_info_cubit.dart';
import 'package:sip_phone_call/components/call_info_notification/presentation/cubit/call_info_notification_cubit.dart';
import 'package:sip_phone_call/models/base_call.dart';
import 'package:sip_phone_call/models/fcm_message_model.dart';
import 'package:sip_phone_call/services/call_management_services.dart';
import 'package:sip_phone_call/services/socket_service.dart';
import 'package:sip_phone_call/utils/app_util.dart';
import 'package:sip_phone_call/utils/logger.dart';
import 'package:sip_phone_call/utils/ui_helper.dart';
import 'package:sip_ua/sip_ua.dart';

import '../bloc/transfer_call_cubit.dart';
import '../config.dart';
import '../constants/api_path.dart';
import '../constants/constants.dart';
import '../models/sip_account.dart';
import '../models/ui_config.dart';
import 'local_storage_services.dart';

part 'call_keep_setting.dart';

typedef OnCallInBound = Function(String phoneNumber, String callerName, String note);
typedef OnCallOutBound = Function(String phoneNumber, String calleeName, String note);
typedef OnRemoveDevice = Function;
typedef OnCallEnded = Function;
typedef OnInformEndCall = Function(String callId);

class SipCallService implements SipUaHelperListener {
  static SipCallService? _sipCallService;
  final FlutterCallkeep _callKeep = FlutterCallkeep();
  late Function(String) _onDetectApnsToken;
  ValueNotifier<RegistrationState> registrationStateNotifier = ValueNotifier(RegistrationState(state: RegistrationStateEnum.NONE));
  SIPUAHelper helper = SIPUAHelper();
  CallState? callState;
  CallState? otherCallState;

  CallDisplayInfoCubit callDisplayInfoController = CallDisplayInfoCubit();
  CallInfoNotificationCubit callInfoNotificationCubit = CallInfoNotificationCubit();

  final CallManagementService _callManagement = CallManagementService.getInstance();

  Call? get currentCallInfo => _callManagement.currentCallInfo;
  late LocalStorageService localStorageService;

  String callerName = '';

  BaseCall? get currentCall => _callManagement.currentCall;

  ValueNotifier<BaseCall?> get currentCalUpdateNotifier => _callManagement.currentCalUpdateNotifier;

  bool get isInBoundCall {
    return _callManagement.currentCallInfo?.direction == 'INCOMING';
  }

  bool isCallConnected = false;

  bool isButtonEndCallPressed = false;

  bool isOutBoundCall = false;
  bool isSetSpeaker = false;
  bool isInCall = false;
  MediaStream? localStream;
  OnCallInBound? _onCallInBound;
  OnCallOutBound? _onCallOutBound;
  OnCallEnded? _onCallEnded;
  OnRemoveDevice? _onRemoveDevice;
  Uri _socketUri = Uri();
  String _fcmToken = '';
  String _userAgent = '';
  String _deviceId = '';
  SipAccount _sipAccount = SipAccount.empty();
  List<Map<String, String>> _iceServers = [];
  SocketService? socketService;
  late UiConfig uiConfig;
  ValueNotifier<bool?> callStartCountNotifier = ValueNotifier(null);
  ValueNotifier<String> callMessageNotifier = ValueNotifier<String>("");

  String _authToken = '';
  FlutterLocalNotificationsPlugin? localNotification;
  Completer<SipCallService>? initializedCompleter;
  Completer? callKitDidActivateAudioSession;
  TransferCallCubit? transferCallCubit;

  ValueNotifier<bool> unHoldButtonNotifier = ValueNotifier<bool>(false);
  ValueNotifier<bool> transferButtonNotifier = ValueNotifier<bool>(false);
  ValueNotifier<bool> transferDialogButtonNotifier = ValueNotifier<bool>(false);
  String? latestCallId;
  String? latestCallerName;
  String? latestCallerPhone;

  /// id call from call center
  String _currentIdCallCC = '';
  String _answeredIdCallCC = '';

  Map<int, Function(CallState)> listenerCallStateChange = {};
  Function()? _onTransferTargetReceived;
  Function(String)? _onTransferFailed;
  bool Function()? shouldActiveTransferCall;

  BroadcastReceiver receiver = BroadcastReceiver(
    names: <String>['fcmbackground.broadcast'],
  );

  SipCallService._();

  factory SipCallService.getInstance() {
    _sipCallService ??= SipCallService._();
    return _sipCallService!;
  }

  void updateCallDisplayInfoById({required String callId, required CallDisplayInfo info}) {
    _callManagement.updateCallDisplayInfo(callId: callId, info: info);
  }

  void updateUI() {
    /// Update transfer dialog button
    /// True when:
    /// - transfer cubit is not null and there is no attended transfer
    transferDialogButtonNotifier.value = isInBoundCall && transferCallCubit != null && _callManagement.mapCall.length == 1 && (_callManagement.currentCallInfo?.session.isEstablished() ?? false);

    /// Update unhold button
    /// True when:
    /// - No attended transfer, the primary call is still exists and it's being held
    unHoldButtonNotifier.value = _callManagement.currentCall != null && (_callManagement.currentCallInfo?.isHolding ?? false);

    /// Update transfer button
    /// True when:
    /// - In attended transfer call and the transfer call is confirmed
    transferButtonNotifier.value = _callManagement.isInTransferCall() && [CallStateEnum.ACCEPTED, CallStateEnum.CONFIRMED].contains(_callManagement.currentCallInfo?.state);

    /// Update message
    String message = '';
    List<BaseCall> listCall = _callManagement.mapCall.values.toList();
    if (listCall.isNotEmpty) {
      for (BaseCall call in listCall) {
        if (call.call.isHolding) {
          message += 'Holding ${call.displayInfo?.displayName}\n';
        }
      }
    }
    callMessageNotifier.value = message;

    callInfoNotificationCubit.updateCallInfoNotification();
  }

  void configUI({required int mainColor}) {
    UIHelper.getInstance().setMainColor(mainColor);
  }

  /// Start ua with the following settings
  /// It also send REGISTER SIP to opensip
  void _startUaSettings({required SipAccount sipAccount, required Uri socketUri, required String userAgent, required List<Map<String, String>> iceServers}) {
    Logger.log('start ua settings - iceServer = $iceServers');
    UaSettings settings = UaSettings();
    settings.webSocketUrl = sipAccount.webSocketUrl;
    settings.webSocketSettings.extraHeaders = {'Origin': socketUri.origin};
    settings.webSocketSettings.allowBadCertificate = true;
    settings.uri = sipAccount.uri;
    settings.authorizationUser = sipAccount.authorizationUser;
    settings.password = sipAccount.password;
    settings.displayName = sipAccount.displayName;
    settings.userAgent = userAgent;
    settings.contactName = sipAccount.authorizationUser;
    settings.viaHost = sipAccount.host;
    settings.dtmfMode = DtmfMode.RFC2833;
    settings.iceServers = iceServers;
    helper.start(settings);
  }

  Future<SipCallService> init({
    onDetectApnsToken,
    SipAccount? sipAccount,
    OnCallInBound? onCallInBound,
    OnCallOutBound? onCallOutBound,
    OnCallEnded? onCallEnded,
    OnRemoveDevice? onRemovedDevice,
    String socketUrl = "",
    String fcmToken = '',
    String userAgent = '',
    String deviceId = '',
    required UiConfig uiConfig,
    TransferCallCubit? transferCallCubit,
    FlutterLocalNotificationsPlugin? localNotificationsPlugin,
    bool Function()? shouldActiveTransferCall,
    required List<Map<String, String>> iceServers,
  }) async {
    Logger.log('lib sip call init');
    this.transferCallCubit = transferCallCubit;
    localNotification = localNotificationsPlugin;
    localStorageService = LocalStorageService.getInstance();
    this.shouldActiveTransferCall = shouldActiveTransferCall;

    if (sipAccount != null) {
      localStorageService.setData<String>(Config.keyDataSipAccount, jsonEncode(sipAccount));
      localStorageService.setData<String>(Config.keyDataDomainSocket, socketUrl);
      localStorageService.setData<String>(Config.keyDataFcmToken, fcmToken);
      localStorageService.setData<String?>(Config.keyTenant, transferCallCubit?.tenant);
      localStorageService.setData<String>(Config.keyDeviceId, deviceId);
      localStorageService.setData<String>(Config.keyIceServer, jsonEncode(iceServers));
    }
    if (initializedCompleter == null) {
      initializedCompleter = Completer();
    } else {
      return initializedCompleter!.future;
    }

    if (sipAccount == null) {
      if (await localStorageService.containsKey(Config.keyDataSipAccount) && await localStorageService.containsKey(Config.keyDataDomainSocket) && await localStorageService.containsKey(Config.keyDataFcmToken)) {
        sipAccount = SipAccount.fromJson(jsonDecode(await localStorageService.getData<String>(Config.keyDataSipAccount)));
        socketUrl = await localStorageService.getData<String>(Config.keyDataDomainSocket);
        fcmToken = await localStorageService.getData<String>(Config.keyDataFcmToken);
        iceServers = AppUtil.castToListMapStrStr(jsonDecode(await LocalStorageService.getInstance().getData(Config.keyIceServer)));
        this.transferCallCubit?.tenant = await localStorageService.getData<String?>(Config.keyTenant) ?? '';
      } else {
        initializedCompleter = null;
        throw 'No sip account to init the service';
      }
    }

    this.uiConfig = uiConfig;
    _onDetectApnsToken = onDetectApnsToken;
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    _callKeep.addAllEventHandlers(eventManager);
    _callKeep.setup(null, {
      'ios': {'appName': packageInfo.appName, 'imageName': 'AppIcon-VoIP', 'supportsVideo': false}
    }).catchError((e) => {log(e.toString())});

    _sipAccount = sipAccount;
    _onCallInBound = onCallInBound;
    _onCallOutBound = onCallOutBound;
    _onCallEnded = onCallEnded;
    _onRemoveDevice = onRemovedDevice;
    _socketUri = Uri.parse(socketUrl);
    _fcmToken = fcmToken;
    _userAgent = userAgent;
    _deviceId = deviceId;
    _iceServers = iceServers;

    localStorageService.setData<String>(Config.keyUserAgent, _userAgent);

    helper.addSipUaHelperListener(this);
    _startUaSettings(
      sipAccount: _sipAccount,
      socketUri: _socketUri,
      userAgent: _userAgent,
      iceServers: _iceServers,
    );

    addListener((callState) {
      if (callState.state == CallStateEnum.PROGRESS) {
        if (handleCallAction != null) {
          handleCallAction!();
          handleCallAction = null;
        }
      }
    });

    if (Platform.isAndroid) {
      receiver.start();
      receiver.messages.listen((event) {
        if (event.data != null) {
          if (event.data!['register'] ?? false) {
            helper.register();
            sendBroadcast(
              BroadcastMessage(name: 'fcmbackground.feedback.broadcast', data: {
                'register': true,
              }),
            );
          } else if (event.data!['decline'] ?? false) {
            isInCall = true;
            handleEndCall();
            sendBroadcast(
              BroadcastMessage(name: 'fcmbackground.feedback.broadcast', data: {
                'decline': true,
              }),
            );
          } else if (event.data!['force-in-call'] ?? false) {
            isInCall = true;
          }
        }
      });
    }

    Future.delayed(const Duration(milliseconds: 100), () {
      if (Platform.isAndroid) {
        register();
      }
    });

    initializedCompleter!.complete(this);
    return this;
  }

  void setMic(bool active) {
    Call? currentCall = _callManagement.currentCallInfo;
    active ? currentCall?.unmute(true, false) : currentCall?.mute();
  }

  void updateAvatarAndDisplayName({String? avatar, String? displayName, bool shouldUpdateCurrentCall = true}) {
    callDisplayInfoController.updateAvatar(avatar ?? _callManagement.currentCall?.displayInfo?.avatar);
    callDisplayInfoController.updateDisplayName(displayName ?? _callManagement.currentCall?.displayInfo?.displayName);
    if (displayName != null && shouldUpdateCurrentCall) {
      _callManagement.currentCall?.displayInfo?.displayName = displayName;
    }
  }

  @override
  void callStateChanged(Call call, CallState state) {
    Logger.log('CallStateChange changed: ${state.state}');
    Logger.log('CallStateChange session: ${call.session.data} - ${call.session.request}');
    Logger.log('call id = ${call.id} - call id in session = ${call.session.id} - request call id = ${call.session.request.call_id}');
    Logger.log('call info remote_display_name = ${call.remote_display_name} - session contact = ${call.session.contact}');
    _callManagement.addCall(call: call);
    Logger.log('current call id = ${_callManagement.currentCallInfo?.id}');
    updateUI();
    print('map call with status = $mapCallWithStatus');

    /// Handle current call
    if (call.id == _callManagement.currentCallInfo!.id) {
      Logger.log('CallStateChange current handle call state change - state = ${state.state} - isButtonEndCallPressed = $isButtonEndCallPressed');
      callState = state;
      switch (state.state) {
        case CallStateEnum.CALL_INITIATION:
          if (isOutBoundCall) {
            socketService?.emitStartCallInDevice(call.id ?? '');
          }
          callStartCountNotifier.value = null;
          _callManagement.currentCall?.resetDuration();
          break;
        case CallStateEnum.NONE:
          // TODO: Handle this case.
          break;
        case CallStateEnum.STREAM:
          if (state.originator == 'local') {
            localStream = state.stream;
            setSpeaker(false);
          }
          break;
        case CallStateEnum.UNMUTED:
          // TODO: Handle this case.
          break;
        case CallStateEnum.MUTED:
          // TODO: Handle this case.
          break;
        case CallStateEnum.CONNECTING:
          // TODO: Handle this case.
          break;
        case CallStateEnum.PROGRESS:
          break;
        case CallStateEnum.FAILED:
          listenerCallStateChange.forEach((key, value) => value(state));
          Logger.log('current call failed isInTransferCall = ${_callManagement.isInTransferCall()} - isInBoundCall = $isInBoundCall');
          if (_callManagement.isInTransferCall()) {
            Logger.log('set callStartCountNotifier to true current call failed in transfer - isButtonEndCallPressed = $isButtonEndCallPressed');
            String errorMessage = isButtonEndCallPressed ? "" : "transferTargetReject";
            callStartCountNotifier.value = true;

            isButtonEndCallPressed = false;
            _onTransferFailed?.call(errorMessage);
          } else {
            // listenerCallStateChange.forEach((key, value) => value(state));
            if (isInBoundCall) {
              Logger.log('call endCurrentCallCloseNotification from call state change inbound call');
              endCurrentCallCloseNotification();
            } else {
              callerName = '';
              isOutBoundCall = false;
              Logger.log('call endCurrentCallCloseNotification from call state change outbound call');
              endCurrentCallCloseNotification();
            }
            resetCurrentIdCallCC();
            Logger.log('set callStartCountNotifier to false current call failed');
            callStartCountNotifier.value = false;
            socketService?.emitCallEnded();
          }
          Logger.log('remove call from current call state failed');
          _callManagement.removeCall(callId: call.id!);

          updateAvatarAndDisplayName();
          updateUI();
          return;
        case CallStateEnum.ENDED:
          isButtonEndCallPressed = false;
          bool callStartCountValue = false;
          bool isInTransferCall = _callManagement.isInTransferCall();
          Logger.log('isInTransferCall in call state end = $isInTransferCall');

          if (!isInTransferCall) {
            Logger.log('current call state end is not in transfer call');
            // listenerCallStateChange.forEach((key, value) => value(state));
            if (isInBoundCall) {
              Logger.log('call endCurrentCallCloseNotification from call state change inbound call');
              endCurrentCallCloseNotification();
            } else {
              callerName = '';
              isOutBoundCall = false;
              Logger.log('call endCurrentCallCloseNotification from call state change outbound call');
              endCurrentCallCloseNotification();
            }
            resetCurrentIdCallCC();
            socketService?.emitCallEnded();
          } else {
            callStartCountValue = true;
          }
          Logger.log('remove call from current call state end');

          _callManagement.removeCall(callId: call.id!);

          if (callStartCountNotifier.value == callStartCountValue) {
            callStartCountNotifier.value = null;
          }
          callStartCountNotifier.value = callStartCountValue;

          /// Do not update UI if end the last call
          if (isInTransferCall) {
            updateAvatarAndDisplayName();
          }

          Logger.log('stopwatch - current call id = ${_callManagement.currentCall?.id} is not null = ${_callManagement.currentCall != null} - timer = ${_callManagement.currentCall?.duration}');
          updateUI();
          listenerCallStateChange.forEach((key, value) => value(state));
          return;
        case CallStateEnum.ACCEPTED:
          break;
        case CallStateEnum.CONFIRMED:
          isCallConnected = true;
          if (_callManagement.isInTransferCall()) {
            transferButtonNotifier.value = true;
            _onTransferTargetReceived?.call();
          }
          Logger.log('set callStartCountNotifier to true current call confirm - current call id = ${_callManagement.currentCall?.id} is not null = ${_callManagement.currentCall != null}');
          _callManagement.currentCall?.startDuration();
          callStartCountNotifier.value = true;
          callInfoNotificationCubit.updateCallInfoNotification();

          if (isOutBoundCall) {
            latestCallId = call.session.request.call_id;
          }
          break;
        case CallStateEnum.REFER:
          // TODO: Handle this case.
          break;
        case CallStateEnum.HOLD:
          // TODO: Handle this case.
          break;
        case CallStateEnum.UNHOLD:
          // TODO: Handle this case.
          break;
      }
      listenerCallStateChange.forEach((key, value) => value(state));
    } else if (_callManagement.isHasCall(callId: call.id)) {
      Logger.log('CallStateChange other handle call state change - state = ${state.state}');
      otherCallState = state;
      switch (state.state) {
        case CallStateEnum.CALL_INITIATION:
          // _callStopwatch.reset();
          // callStartCountNotifier.value = null;

          break;
        case CallStateEnum.NONE:
          // TODO: Handle this case.
          break;
        case CallStateEnum.STREAM:
          if (state.originator == 'local') {
            localStream = state.stream;
            setSpeaker(false);
          }
          break;
        case CallStateEnum.UNMUTED:
          // TODO: Handle this case.
          break;
        case CallStateEnum.MUTED:
          // TODO: Handle this case.
          break;
        case CallStateEnum.CONNECTING:
          // TODO: Handle this case.
          break;
        case CallStateEnum.PROGRESS:
          break;
        case CallStateEnum.FAILED:
        case CallStateEnum.ENDED:
          Logger.log('remove call from transfer call state end');
          _callManagement.removeCall(callId: call.id);
          updateUI();
          return;
        case CallStateEnum.ACCEPTED:
          break;
        case CallStateEnum.CONFIRMED:
          if (_callManagement.isInTransferCall()) {
            _onTransferTargetReceived?.call();
          }
          updateUI();
          break;
        case CallStateEnum.REFER:
          // TODO: Handle this case.
          break;
        case CallStateEnum.HOLD:
          // TODO: Handle this case.
          break;
        case CallStateEnum.UNHOLD:
          // TODO: Handle this case.
          break;
      }
      listenerCallStateChange.forEach((key, value) => value(state));
    } else {
      /// Force not accept any call when a call activated before
      if (call.state == CallStateEnum.CALL_INITIATION) {
        try {
          Logger.log('call state change hangup call 486 call id = ${call.id} - call id in session = ${call.session.id} - request call id = ${call.session.request.call_id}');
          if (Platform.isAndroid) {
            FlutterVibration().stop();
          } else {
            removeAllInterfereCalls();
          }
          call.hangup({'status_code': 486});
        } catch (_) {}
      }
    }
  }

  SipAccount get sipAccount => _sipAccount;

  @override
  void onNewMessage(SIPMessageRequest msg) {
    // TODO: implement onNewMessage
  }

  @override
  void onNewNotify(Notify ntf) {
    // TODO: implement onNewNotify
  }

  @override
  void registrationStateChanged(RegistrationState state) {
    registrationStateNotifier.value = state;
  }

  @override
  void transportStateChanged(TransportState state) {
    // TODO: implement transportStateChanged
  }

  void register({String voipToken = ''}) async {
    bool registerWithoutConnectCallCenter = false;

    /// Check if register without connect to call center, must use local data.
    if (initializedCompleter == null) {
      try {
        _fcmToken = await LocalStorageService.getInstance().getData<String>(Config.keyDataFcmToken);
        _socketUri = Uri.parse(await LocalStorageService.getInstance().getData<String>(Config.keyDataDomainSocket));
        _sipAccount = SipAccount.fromJson(jsonDecode(await LocalStorageService.getInstance().getData<String>(Config.keyDataSipAccount)));
        _deviceId = await LocalStorageService.getInstance().getData<String>(Config.keyDeviceId);
        registerWithoutConnectCallCenter = true;
      } catch (e) {
        if (kDebugMode) {
          print(e);
        }
        return;
      }
    }

    if (((voipToken.isNotEmpty || _fcmToken.isNotEmpty) && (initializedCompleter?.isCompleted ?? false)) || registerWithoutConnectCallCenter) {
      // var url = _socketUri.replace(pathSegments: [_socketUri.path, ApiPath.register]);
      var url = _socketUri.replace(path: '${_socketUri.path}${ApiPath.register}');
      /// Await the http get response, then decode the json-formatted response.
      String body = jsonEncode({
        'id': _deviceId,
        'extension': _sipAccount.authorizationUser,
        'voip_token': voipToken,
        'fcm_token': _fcmToken,
      });
      try {
        http.Response response = await http.post(url, body: body);
        if (response.statusCode == 200) {
          var resBody = jsonDecode(response.body);
          if (resBody['result'] == 1) {
            var data = resBody['data'];
            _authToken = data['token'];
            socketService = SocketService(
                url: _socketUri.toString(),
                userAgent: _userAgent,
                ext: _sipAccount.authorizationUser,
                authToken: data['token'],
                onCallerCancel: () {
                  if (Platform.isAndroid) {
                    Logger.log('call endCurrentCallCloseNotification from onCallerCancel init socket service');
                    endCurrentCallCloseNotification();
                    return;
                  }
                  if (hasInterfereCall()) {
                    removeAllInterfereCalls();
                  } else {
                    Logger.log('call endCurrentCallCloseNotification from onCallerCancel init socket service');
                    endCurrentCallCloseNotification();
                  }
                },
                onRemoveDevice: () {
                  _onRemoveDevice?.call();
                  clear();
                },
                onNewInBoundCall: (value) {
                  callerName = value;
                },
                onCallStateAnswered: (callId) {
                  if (_answeredIdCallCC != callId) {
                    Logger.log('call endCurrentCallCloseNotification from onCallStateAnswered init socket service');
                    endCurrentCallCloseNotification();
                  }
                });
            if (data['call'] != null) {
              callerName = data['call']['caller_name'] ?? "";
            }
          } else {
            clear();
            throw 'Register logic business failed ${response.body}';
          }
        } else {
          throw 'Register failed ${response.body}';
        }
      } catch (e, stackTrace) {
        if (kDebugMode) {
          print(e);
          print(stackTrace);
        }
        rethrow;
      }
    }
  }

  Future<void> unregister() async {
    if (_authToken.isNotEmpty) {
      // var url = _socketUri.replace(pathSegments: [_socketUri.path, ApiPath.unregister]);
      var url = _socketUri.replace(path: '${_socketUri.path}${ApiPath.unregister}');
      try {
        await http.post(url, headers: {
          HttpHeaders.authorizationHeader: "Bearer $_authToken",
        });
      } catch (e, stackTrace) {
        if (kDebugMode) {
          print(e);
          print(stackTrace);
        }
        rethrow;
      }
    }
  }

  bool localNotificationForegroundResponseHandler({required NotificationResponse response, required FlutterLocalNotificationsPlugin localNotification}) {
    Logger.log('localNotificationForegroundResponseHandler sip call lib');
    if (Platform.isAndroid) {
      FCMMessageModel fcmMessage = FCMMessageModel.fromJson(json.decode(response.payload!));
      if (response.actionId == Config.callActionAnswer) {
        Logger.log('localNotificationForegroundResponseHandler handle action answer');
        if (response.payload != null) {
          Logger.log('displayIncomingCall from localNotificationForegroundResponseHandler 1');
          displayIncomingCall(callerName: fcmMessage.callerName, callId: fcmMessage.callUUID);
          executeAnswerCallAction();
        }
        return true;
      }

      /// When user tap the head up notification, not buttons, application will go to foreground without action id.
      if (response.actionId == null) {
        this.localNotification = localNotification;
        localNotification.cancel(Config.idInboundCallNotification);
        Logger.log('displayIncomingCall from localNotificationForegroundResponseHandler 2');
        displayIncomingCall(callerName: fcmMessage.callerName, callId: fcmMessage.callUUID);
        return true;
      }
    }
    return false;
  }

  Future<bool> localNotificationBackgroundResponseHandler({required NotificationResponse response, VoidCallback? callback}) async {
    Logger.log('localNotificationBackgroundResponseHandler sip call lib');
    if (Platform.isAndroid) {
      if (response.actionId == Config.callActionDecline) {
        /// shouldInitServices: flag to trigger sip call service's initialization in case of app termination
        bool shouldInitServices = true;

        /// Notify the main isolate executing the foreground to decline the call
        BroadcastReceiver receiver = BroadcastReceiver(names: ['fcmbackground.feedback.broadcast']);
        receiver.start().then((value) {
          receiver.messages.listen((event) {
            Logger.log('localNotificationBackgroundResponseHandler event data = ${event.data}');
            if (event.data != null) {
              if (event.data!['decline'] ?? false) {
                shouldInitServices = false;
              }
            }
          });
        });

        Logger.log('send broadcast decline');
        sendBroadcast(
          BroadcastMessage(name: 'fcmbackground.broadcast', data: {
            'decline': true,
          }),
        );

        /// Waiting for the response of the main isolate
        /// if no main isolate -> app is terminated -> shouldInitServices = true -> init sipcall via callback
        await Future.delayed(const Duration(milliseconds: 600));
        Logger.log('shouldInitServices = $shouldInitServices');
        if (shouldInitServices) {
          Logger.log('callback to init sip call service');

          callback?.call();

          Logger.log('waiting for init completion');

          /// Wait for the sip call service to init
          await Future.delayed(const Duration(milliseconds: 1000));
          sendBroadcast(
            BroadcastMessage(name: 'fcmbackground.broadcast', data: {
              'force-in-call': true,
            }),
          );

          /// Wait for the broadcast to set isInCall to true
          await Future.delayed(const Duration(milliseconds: 1000));
          Logger.log('complete init sip call service');
        }

        executeEndCallAction();
      }
    }
    return false;
  }

  /// Check if the call-id is in local storage
  /// If its value is true, it means that app receives cancel message before having call of that call-id
  ///   -> don't show notification
  ///   -> remove that call-id from local storage
  Future<bool> shouldHandleIncomingCall(String callId) async {
    LocalStorageService localStorageService = LocalStorageService.getInstance();
    String? id = await localStorageService.getData<String?>(callId);
    if (id != null) {
      localStorageService.remove(callId);
      return false;
    }
    return true;
  }

  /// This code is run in a different isolate to handle fcm in background
  Future<bool> firebaseMessagingBackgroundHandler({
    required RemoteMessage message,
    required FlutterLocalNotificationsPlugin localNotification,
  }) async {
    FCMMessageModel fcmMessage = FCMMessageModel.fromJson(message.data);
    if (Platform.isAndroid) {
      if (fcmMessage.type == "INCOMING_CALL") {
        /// Receive feedback handle register from main isolate. In case app in background not terminated, shouldn't register call state controller service to ovoid override socket id.
        bool shouldRegisterSocket = true;
        BroadcastReceiver receiver = BroadcastReceiver(names: ['fcmbackground.feedback.broadcast']);
        receiver.start().then((value) {
          receiver.messages.listen((event) {
            if (event.data != null) {
              if (event.data!['register'] ?? false) {
                shouldRegisterSocket = false;
              }
            }
          });
        });

        /// Notify the main isolate executing the foreground to register again, but not sure main isolate always exist.
        sendBroadcast(
          BroadcastMessage(name: 'fcmbackground.broadcast', data: {
            'register': true,
          }),
        );

        this.localNotification = localNotification;

        /// Register socket control to close notification in case app was terminated.
        await Future.delayed(const Duration(milliseconds: 100));
        if (shouldRegisterSocket) {
          register();
        }

        if (await shouldHandleIncomingCall(fcmMessage.uuid)) {
          localNotification.show(
            Config.idInboundCallNotification,
            Constants.incomingCallNotification,
            fcmMessage.callerName,
            const NotificationDetails(
              android: AndroidNotificationDetails(
                'call full screen id',
                'call full screen channel',
                priority: Priority.max,
                importance: Importance.max,
                fullScreenIntent: true,
                autoCancel: true,
                category: AndroidNotificationCategory.call,
                actions: [
                  AndroidNotificationAction(
                    Config.callActionDecline,
                    "Decline",
                    icon: DrawableResourceAndroidBitmap("decline"),
                    titleColor: Colors.red,
                  ),
                  AndroidNotificationAction(
                    Config.callActionAnswer,
                    "Answer",
                    icon: DrawableResourceAndroidBitmap("answer"),
                    showsUserInterface: true,
                    titleColor: Colors.green,
                  ),
                ],
                enableVibration: false,
                playSound: false,
              ),
            ),
            payload: json.encode(fcmMessage.toJson()),
          );
          FlutterVibration().play();
          return true;
        }
      }
    }
    return false;
  }

  Future<bool> firebaseMessagingForegroundHandler({required RemoteMessage message}) async {
    FCMMessageModel fcmMessage = FCMMessageModel.fromJson(message.data);
    if (Platform.isAndroid) {
      if (fcmMessage.type == 'INCOMING_CALL' && await shouldHandleIncomingCall(fcmMessage.uuid)) {
        FlutterVibration().play();
        Logger.log('displayIncomingCall from firebaseMessagingForegroundHandler');
        displayIncomingCall(callerName: fcmMessage.callerName, callId: fcmMessage.callUUID);
        return true;
      }
    }
    return true;
  }

  void _handleDidPushToken(String voipToken) async {
    await Future.delayed(const Duration(milliseconds: 150), () async {
      register(voipToken: voipToken);
    });
  }

  void updateFCMToken(String fcmToken) async {
    if (fcmToken.isNotEmpty) {
      LocalStorageService.getInstance().setData<String>(Config.keyDataFcmToken, fcmToken);
      socketService?.emitUpdateFcmToken(fcmToken);
    }
  }

  void informNewOutboundCall({required String phoneNumber, String? leadId, String? phoneContactId, String? salesId, required String salesExtension, required Function onCallSuccess, required Function(String) onCallError}) async {
    // var url = _socketUri.replace(pathSegments: [_socketUri.path, ApiPath.informNewOutbound]);
    var url = _socketUri.replace(path: '${_socketUri.path}${ApiPath.informNewOutbound}');
    Map<String, String> body = {
      'phone_number': phoneNumber,
      'sales_extension': salesExtension,
    };
    if (leadId != null) {
      body.addAll({'lead_id': leadId});
    }
    if (phoneContactId != null) {
      body.addAll({'phone_contact_id': phoneContactId});
    }
    if (salesId != null) {
      body.addAll({'sales_id': salesId});
    }
    try {
      http.Response response = await http.post(
        url,
        headers: {
          HttpHeaders.authorizationHeader: 'Bearer $_authToken',
        },
        body: jsonEncode(body),
      );
      if (response.statusCode == 200) {
        var resBody = jsonDecode(response.body);
        if (resBody['result'] == 1) {
          onCallSuccess.call();
        } else {
          onCallError.call(resBody['message']);
        }
      } else {
        onCallError.call('Something error! Please try again later.');
      }
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print(e);
        print(stackTrace);
      }
      rethrow;
    }
  }

  Future<void> initAttendedTransfer({required String target, Function(String)? onTransferFailed, Function()? onTransferTargetReceived}) async {
    final mediaConstraints = <String, dynamic>{'audio': true, 'video': false};

    MediaStream mediaStream = await navigator.mediaDevices.getUserMedia(mediaConstraints);
    bool? initAttendedTransferResult = await helper.initAttendedTransferCall(
      currentCallId: _callManagement.getCallBeforeTransfer()?.call.id ?? "",
      target: target,
      mediaStream: mediaStream,
    );

    String errorMessage = '';
    if (initAttendedTransferResult == null) {
      errorMessage = "noCallAtAll";
    } else if (initAttendedTransferResult == false) {
      errorMessage = "notRegistered";
    }

    if (initAttendedTransferResult != true) {
      onTransferFailed?.call(errorMessage);
      return;
    }
    _onTransferFailed = onTransferFailed;
    _onTransferTargetReceived = onTransferTargetReceived;
  }

  void makeAttendedTransferCall({required String target}) {
    if (_callManagement.isInTransferCall()) {
      _callManagement.getCallBeforeTransfer()?.call.attendedTransfer(
            targetNumber: target,
            replaceSession: _callManagement.currentCallInfo!.session,
          );
    }
  }

  void unHoldCall() {
    if (_callManagement.currentCallInfo != null) {
      _callManagement.currentCallInfo!.unhold();
      updateUI();
    }
  }

  void startCall({required String destNumber, required String displayName, String note = "", String? leadId, String? salesId, String? phoneContactId}) async {
    isInCall = true;
    informNewOutboundCall(
        phoneNumber: destNumber,
        salesExtension: _sipAccount.authorizationUser,
        leadId: leadId,
        phoneContactId: phoneContactId,
        salesId: salesId,
        onCallSuccess: () async {
          isOutBoundCall = true;
          final mediaConstraints = <String, dynamic>{'audio': true, 'video': false};

          MediaStream mediaStream = await navigator.mediaDevices.getUserMedia(mediaConstraints);

          helper.call(destNumber, voiceonly: true, mediaStream: mediaStream);
          latestCallerName = displayName;
          latestCallerPhone = destNumber;
          _onCallOutBound?.call(destNumber, displayName, note);
        },
        onCallError: (String err) {
          Logger.log('informNewOutboundCall set is in call false');
          isInCall = false;
          Fluttertoast.showToast(
            msg: err,
            toastLength: Toast.LENGTH_LONG,
            gravity: ToastGravity.BOTTOM,
            backgroundColor: Colors.orange,
            textColor: Colors.white,
            fontSize: 16.0,
          );
          _onCallEnded?.call();
        });
  }

  void displayIncomingCall({required String callerName, String note = "", required String callId, bool forceRegister = true}) {
    Logger.log('displayIncomingCall callId = $callId - ${mapCallWithStatus[callId]}');
    _currentIdCallCC = callId;

    /// Force register when receive incoming call notification. OpenSIPS will trigger this event to send SIP messages to device.
    if (forceRegister) {
      helper.register();
    }
    isInCall = true;
    this.callerName = callerName;

    latestCallerName = callerName;
    latestCallerPhone = '';
    _onCallInBound?.call('', this.callerName, note);
  }

  void handleAccept([bool isFromCallKit = true]) async {
    _answeredIdCallCC = _currentIdCallCC;
    latestCallId = _currentIdCallCC;
    socketService?.emitAcceptedCall(_currentIdCallCC);
    bool isRemoteHasVideo = _callManagement.currentCallInfo!.remote_has_video;
    final mediaConstraints = <String, dynamic>{'audio': true, 'video': isRemoteHasVideo, 'isFromCallKit': isFromCallKit};

    /// Waiting the audio session is activated
    if (isFromCallKit && callKitDidActivateAudioSession != null) {
      await callKitDidActivateAudioSession!.future;
    }
    MediaStream mediaStream = await navigator.mediaDevices.getUserMedia(mediaConstraints);
    _callManagement.currentCallInfo!.answer(helper.buildCallOptions(!isRemoteHasVideo), mediaStream: mediaStream);
  }

  void handleEndCall({bool isHangUp = true, bool isFromUI = false}) {
    Logger.log('handleEndCall isFromUI = $isFromUI');

    /// This function is called 2 times when the user end a transfer call
    /// The 1st time: it's called from UI -> isButtonEndCallPressed = true;
    /// The 2nd time: it's called from call cubit
    /// So if isButtonEndCallPressed is true -> don't assign it to any value until it's set to false when the transfer call ends
    if (!isButtonEndCallPressed) {
      isButtonEndCallPressed = isFromUI;
    }
    if (_callManagement.isInTransferCall()) {
      Logger.log('handleEndCall hangup transfer call');
      try {
        Logger.log("603 from here end");
        _callManagement.currentCallInfo?.hangup({'status_code': 603});
        Logger.log('remove call from handle end call is in transfer call');
        // _callManagement.removeCall(callId: _callManagement.currentCallInfo?.id);
      } catch (_) {}
    } else {
      Logger.log('handleEndCall isInCall = $isInCall');
      if (isInCall || _callManagement.mapCall.length == 1) {
        Logger.log('handleEndCall set is in call false');
        isInCall = false;
        if (isHangUp) {
          try {
            Logger.log("603 from here");
            _callManagement.currentCallInfo?.hangup({'status_code': 603});
            Logger.log('remove call from handle end call is not in transfer call');
            // _callManagement.removeCall(callId: _callManagement.currentCallInfo?.id);
          } catch (_) {}
        }
        _onCallEnded?.call();
      }
    }
    updateUI();
  }

  bool isRinging() {
    if (_callManagement.currentCallInfo != null && isInBoundCall) {
      return _callManagement.currentCallInfo!.state == CallStateEnum.PROGRESS;
    }
    return false;
  }

  int addListener(Function(CallState callState) onChange) {
    listenerCallStateChange.putIfAbsent(onChange.hashCode, () => onChange);
    return onChange.hashCode;
  }

  void removeListener(int id) {
    listenerCallStateChange.remove(id);
  }

  void endCurrentCallCloseNotification() {
    if (Platform.isAndroid) {
      Logger.log('endCurrentCallCloseNotification android');
      FlutterVibration().stop();
      localNotification?.cancel(Config.idInboundCallNotification);
    } else {
      print("endCurrentCallCloseNotification end all call");
      _callKeep.endAllCalls();
    }
  }

  Future<void> endCallWithUUID({required String uuid}) async {
    Logger.log("end call with uuid = $uuid");
    await _callKeep.endCall(uuid);
  }

  void setSpeaker(bool active) {
    if (localStream != null) {
      localStream!.getAudioTracks().first.enableSpeakerphone(active);
    }
  }

  void clear() async {
    resetCurrentIdCallCC();
    if (helper.registered) {
      helper.unregister(true);
    }
    LocalStorageService.getInstance().remove(Config.keyDataFcmToken);
    LocalStorageService.getInstance().remove(Config.keyDataSipAccount);
    LocalStorageService.getInstance().remove(Config.keyDataDomainSocket);
    socketService?.close();
    receiver.stop();
    initializedCompleter = null;
  }

  void resetCurrentIdCallCC() {
    _currentIdCallCC = '';
    _answeredIdCallCC = '';
  }
}
