import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lottie/lottie.dart';
import 'package:proximity_sensor/proximity_sensor.dart';
import 'package:sip_phone_call/components/call_info_notification/presentation/call_info_noti_management.dart';
import 'package:sip_phone_call/models/base_call.dart';
import 'package:sip_phone_call/services/call_management_services.dart';
import 'package:sip_phone_call/utils/locale_translate.dart';
import 'package:sip_phone_call/utils/logger.dart';
import 'package:sip_ua/sip_ua.dart';

import '../bloc/call_cubit.dart';
import '../bloc/call_display_info_cubit.dart';
import '../components/button_control.dart';
import '../services/sip_call_services.dart';
import '../utils/app_util.dart';
import '../widgets/time_counter.dart';

class CallScreenParams {
  Widget? iconStartCall;
  Widget? iconHangUp;
  Widget? iconMicOn;
  Widget? iconMicOff;
  Widget? iconSpeakerOn;
  Widget? iconSpeakerOff;
  String? displayName;
  String? calleeAvatar;
  Locale locale;
  Function() onPop;

  CallScreenParams({
    this.iconHangUp,
    this.iconMicOff,
    this.iconMicOn,
    this.iconSpeakerOff,
    this.iconSpeakerOn,
    this.iconStartCall,
    this.displayName,
    this.calleeAvatar,
    required this.locale,
    required this.onPop,
  });
}

class CallScreen extends StatefulWidget {
  const CallScreen({Key? key, required this.params}) : super(key: key);

  final CallScreenParams params;
  static bool isExist = false;

  @override
  State<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> with WidgetsBindingObserver {
  String statusMessage = '';
  bool shouldStatusHasBackgroundColor = false;

  final double bottomMargin = 100;

  String? avatar;
  String? displayName;
  Duration? callDuration;

  late CallCubit callCubit;
  late ValueNotifier<bool?> callStartCountNotifier = ValueNotifier(null);

  SipCallService sipCallService = SipCallService.getInstance();

  @override
  void initState() {
    super.initState();
    Logger.log('call screen init ${widget.params}');
    callCubit = CallCubit(
      sipCallService: sipCallService,
    );

    avatar = widget.params.calleeAvatar;
    displayName = widget.params.displayName;

    if (sipCallService.currentCallInfo != null && sipCallService.currentCallInfo!.id != null) {
      Logger.log("update call display info in init call screen - call id = ${sipCallService.currentCallInfo!.id!}");
      sipCallService.updateCallDisplayInfoById(
        callId: sipCallService.currentCallInfo!.id!,
        info: CallDisplayInfo(
          avatar: widget.params.calleeAvatar,
          displayName: widget.params.displayName,
        ),
      );
    } else {
      sipCallService.currentCalUpdateNotifier.addListener(updateDisplayCurrentCallInfo);
    }

    sipCallService.updateAvatarAndDisplayName(
      avatar: widget.params.calleeAvatar,
      displayName: widget.params.displayName,
    );

    callStartCountNotifier.value = sipCallService.callStartCountNotifier.value;
    statusMessage = widget.params.locale.translate('Connecting');

    /// Solution for iOS issue: app foreground, lock screen -> caller ends call or another device received call -> open screen -> show call screen with connecting state
    /// In this case, the last call state is FAILED -> pop this screen
    if (Platform.isIOS) {
      if (sipCallService.callState?.state == CallStateEnum.FAILED) {
        /// Make sure that the screen is rendered, then pop it immediately
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            widget.params.onPop();
            return;
          }
        });
      }
    }

    Future.delayed(const Duration(seconds: 5), () {
      if (!sipCallService.helper.registered || callCubit.state is CallInitialState) {
        sipCallService.handleEndCall(isHangUp: false);
        sipCallService.endCurrentCallCloseNotification();
        widget.params.onPop();
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    /// If don't have any call active, must pop this screen. It may happen if the call ended before resume the app.
    if (!sipCallService.isInCall) {
      widget.params.onPop();
      return;
    }
  }

  @override
  void dispose() {
    CallScreen.isExist = false;
    callCubit.close();
    CallManagementService.getInstance().removeCurrentCall;
    sipCallService.currentCalUpdateNotifier.removeListener(updateDisplayCurrentCallInfo);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !sipCallService.isInCall,
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        body: StreamBuilder(
            stream: ProximitySensor.events,
            builder: (context, snapshot) {
              return Stack(
                children: [
                  Scaffold(
                    backgroundColor: Colors.amber,
                    body: Container(
                      decoration: BoxDecoration(
                          gradient: LinearGradient(
                        begin: Alignment.topRight,
                        end: Alignment.bottomLeft,
                        colors: [
                          Colors.amber[100]!,
                          Colors.amber[900]!,
                        ],
                      )),
                      child: BlocConsumer(
                        bloc: callCubit,
                        listener: (context, state) {
                          if (state is CallEnded) {
                            if (CallManagementService.getInstance().hasNoCall()) {
                              clearScreenAndPop();
                            }
                          }
                        },
                        builder: (context, state) {
                          print('call screen builder state = $state');
                          if (state is CallConnectingState) {
                            shouldStatusHasBackgroundColor = false;
                            statusMessage = widget.params.locale.translate('Connecting');
                          } else if (state is CallOutBoundRingingState) {
                            shouldStatusHasBackgroundColor = false;
                            statusMessage = widget.params.locale.translate('Ringing');
                          } else if (state is CallConnectedState || state is CallUnHoldState) {
                            statusMessage = '';
                            shouldStatusHasBackgroundColor = false;
                          } else if (state is CallBusyState) {
                            statusMessage = widget.params.locale.translate('Callee is busy');
                            shouldStatusHasBackgroundColor = true;
                          } else if (state is CallDenyState) {
                            statusMessage = widget.params.locale.translate('Call is declined');
                            shouldStatusHasBackgroundColor = true;
                          } else if (state is CallEnded) {
                            statusMessage = widget.params.locale.translate('Call ended');
                            shouldStatusHasBackgroundColor = true;
                          } else if (state is CallInBoundRingingState) {
                            shouldStatusHasBackgroundColor = false;
                            statusMessage = widget.params.locale.translate('Calling');
                          } else if (state is CallHoldState) {
                            shouldStatusHasBackgroundColor = true;
                            statusMessage = widget.params.locale.translate('Holding');
                          }
                          return Stack(
                            fit: StackFit.expand,
                            alignment: Alignment.center,
                            children: [
                              Container(
                                margin: const EdgeInsets.only(top: 45),
                                child: Stack(
                                  alignment: Alignment.topCenter,
                                  children: [
                                    Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Image.asset(
                                          sipCallService.uiConfig.logoAssetName,
                                          fit: BoxFit.contain,
                                          height: 84,
                                        ),
                                        SizedBox(
                                          height: 235,
                                          child: Stack(
                                            alignment: Alignment.center,
                                            children: [
                                              if (state is CallInitialState || state is CallConnectingState || state is CallOutBoundRingingState || state is CallInBoundRingingState)
                                                Center(
                                                  child: Lottie.asset(sipCallService.uiConfig.effectRingingLottie),
                                                ),

                                              /// Avatar
                                              BlocConsumer<CallDisplayInfoCubit, CallDisplayInfoState>(
                                                bloc: sipCallService.callDisplayInfoController,
                                                listener: (context, state) {
                                                  if (state is UpdateAvatarSuccess) {
                                                    avatar = state.avatar;
                                                  } else if (state is UpdateDisplayNameSuccess) {
                                                    displayName = state.name;
                                                  }
                                                },
                                                builder: (context, state) {
                                                  return Center(
                                                    child: CircleAvatar(
                                                      radius: 60,
                                                      backgroundColor: const Color(0xffAE7129),
                                                      child: CircleAvatar(
                                                        radius: 58,
                                                        foregroundImage: avatar != null ? NetworkImage(avatar!) : null,
                                                        backgroundColor: const Color(0xffF9E7D2),
                                                        child: avatar == null
                                                            ? Text(
                                                                AppUtil.getShortName(displayName ?? ""),
                                                                style: const TextStyle(
                                                                  fontSize: 36,
                                                                  color: Color(0xffAE7129),
                                                                  fontWeight: FontWeight.bold,
                                                                  overflow: TextOverflow.ellipsis,
                                                                ),
                                                              )
                                                            : null,
                                                      ),
                                                    ),
                                                  );
                                                },
                                              ),
                                            ],
                                          ),
                                        ),
                                        Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          crossAxisAlignment: CrossAxisAlignment.center,
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            /// Display name
                                            BlocBuilder<CallDisplayInfoCubit, CallDisplayInfoState>(
                                              bloc: sipCallService.callDisplayInfoController,
                                              builder: (context, state) {
                                                if (state is UpdateDisplayNameSuccess) {
                                                  displayName = state.name;
                                                }
                                                if ((displayName ?? '').isEmpty) {
                                                  return Text(
                                                    displayName ?? '',
                                                    style: const TextStyle(fontSize: 22, color: Colors.black, fontWeight: FontWeight.bold),
                                                  );
                                                }
                                                List<String> displayNameSplit = displayName!.split("-");
                                                if (displayNameSplit.length == 1) {
                                                  return Text(
                                                    displayName ?? '',
                                                    style: const TextStyle(fontSize: 22, color: Colors.black, fontWeight: FontWeight.bold),
                                                  );
                                                }
                                                String firstPart = displayNameSplit.first.trim();
                                                String secondPart = displayNameSplit.last.trim();
                                                return Column(
                                                  mainAxisAlignment: MainAxisAlignment.center,
                                                  crossAxisAlignment: CrossAxisAlignment.center,
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    Text(
                                                      firstPart,
                                                      style: const TextStyle(fontSize: 22, color: Colors.black, fontWeight: FontWeight.bold),
                                                    ),
                                                    if (secondPart.isNotEmpty) ...[
                                                      Text(
                                                        secondPart,
                                                        style: const TextStyle(fontSize: 22, color: Colors.black, fontWeight: FontWeight.bold, height: 2),
                                                      ),
                                                    ],
                                                  ],
                                                );
                                              },
                                            ),

                                            const SizedBox(
                                              height: 15,
                                            ),
                                            ValueListenableBuilder<bool?>(
                                                valueListenable: sipCallService.callStartCountNotifier,
                                                builder: (context, value, child) {
                                                  if ((value != null) && (SipCallService.getInstance().currentCall != null) && value) {
                                                    return Container(
                                                      margin: const EdgeInsets.only(top: 20),
                                                      child: Material(
                                                          key: ValueKey(SipCallService.getInstance().currentCall!.duration.inSeconds),
                                                          color: Colors.transparent,
                                                          child: TimeCounter.countUp(
                                                            duration: SipCallService.getInstance().currentCall!.duration,
                                                            start: value,
                                                            style: const TextStyle(fontSize: 16),
                                                          )),
                                                    );
                                                  }
                                                  return Container();
                                                }),
                                            const SizedBox(
                                              height: 20,
                                            ),
                                            if (statusMessage.isNotEmpty) ...[
                                              Container(
                                                padding: const EdgeInsets.all(10),
                                                decoration: BoxDecoration(color: shouldStatusHasBackgroundColor ? Colors.black.withOpacity(0.6) : null, borderRadius: BorderRadius.circular(10)),
                                                child: Text(statusMessage, style: TextStyle(color: shouldStatusHasBackgroundColor ? Colors.white : Colors.black)),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ],
                                    ),

                                    /// Message
                                    // ValueListenableBuilder(
                                    //   valueListenable: sipCallService.callMessageNotifier,
                                    //   builder: (context, value, child) {
                                    //     if (sipCallService.callMessageNotifier.value.isEmpty) return Container();
                                    //     return Container(
                                    //       padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                                    //       width: double.infinity,
                                    //       constraints: const BoxConstraints(maxHeight: 50),
                                    //       color: Colors.black.withOpacity(0.5),
                                    //       alignment: Alignment.center,
                                    //       child: SingleChildScrollView(
                                    //         child: Text(
                                    //           sipCallService.callMessageNotifier.value,
                                    //           style: const TextStyle(color: Colors.white),
                                    //         ),
                                    //       ),
                                    //     );
                                    //   },
                                    // ),
                                    CallInfoNotificationManagement(
                                      locale: widget.params.locale,
                                    ),
                                  ],
                                ),
                              ),

                              /// Button control
                              if (MediaQuery.of(context).viewInsets.bottom == 0) ...[
                                Positioned(
                                  bottom: 120,
                                  child: IgnorePointer(
                                    ignoring: state is CallEnded || state is CallDenyState,
                                    child: ButtonControl(
                                      callCubit: callCubit,
                                      locale: widget.params.locale,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                  if (snapshot.hasData)
                    if (snapshot.data != null && (snapshot.data! > 0))
                      Scaffold(
                        backgroundColor: Colors.black,
                        body: Container(),
                      ),
                ],
              );
            }),
      ),
    );
  }

  void clearScreenAndPop() {
    Navigator.of(context).popUntil((route) => route.settings.name == '/voip_call');
    Timer(const Duration(seconds: 2), () {
      widget.params.onPop();
    });
  }

  void updateDisplayCurrentCallInfo() {
    if (sipCallService.currentCallInfo != null && sipCallService.currentCallInfo!.id != null) {
      Logger.log("update call display info in init call screen after has data current call - call id = ${sipCallService.currentCallInfo!.id!}");
      sipCallService.updateCallDisplayInfoById(
        callId: sipCallService.currentCallInfo!.id!,
        info: CallDisplayInfo(
          avatar: widget.params.calleeAvatar,
          displayName: widget.params.displayName,
        ),
      );
    }
  }
}
