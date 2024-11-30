import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:sip_phone_call/bloc/call_cubit.dart';
import 'package:sip_phone_call/services/sip_call_services.dart';
import 'package:sip_phone_call/utils/locale_translate.dart';
import 'package:sip_phone_call/widgets/transfer_call_dialog.dart';

import '../bloc/button_control_cubit.dart';
import '../widgets/call_button.dart';

class ButtonControl extends StatefulWidget {
  final CallCubit callCubit;
  final Locale locale;
  final EdgeInsets? margin;

  const ButtonControl({
    Key? key,
    this.margin,
    required this.callCubit,
    required this.locale,
  }) : super(key: key);

  @override
  State<ButtonControl> createState() {
    return _ButtonControlState();
  }
}

class _ButtonControlState extends State<ButtonControl> {
  late ButtonControlCubit buttonControlCubit;
  late EdgeInsets buttonMargin;
  bool isSpeakerOn = false;
  bool isMicOn = true;
  final double iconSize = 40;
  final Color iconColor = Colors.white;

  String attendedTransferTarget = '';

  SipCallService sipCallService = SipCallService.getInstance();

  @override
  void initState() {
    super.initState();
    buttonControlCubit = ButtonControlCubit(sipCallService);
    buttonMargin = const EdgeInsets.symmetric(horizontal: 30);
  }

  @override
  void dispose() {
    buttonControlCubit.close();
    super.dispose();
  }

  EdgeInsets getButtonMargin(state) {
    EdgeInsets buttonMargin = const EdgeInsets.symmetric(horizontal: 30);
    if (state is CallInBoundRingingState) {
      buttonMargin = const EdgeInsets.symmetric(horizontal: 60);
    }
    return buttonMargin;
  }

  Future<void> _showTransferDialog() async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext childContext) {
        return TransferCallDialog(
          onCancelPressed: () {
            attendedTransferTarget = '';
            Navigator.of(context).pop();
          },
          onCallPressed: (target, displayName) async {
            sipCallService.updateAvatarAndDisplayName(
              displayName: displayName ?? target,
              shouldUpdateCurrentCall: false,
            );

            /// Init attended transfer call
            await sipCallService.initAttendedTransfer(
                target: target,
                onTransferFailed: (String message) async {
                  attendedTransferTarget = "";
                  sipCallService.updateAvatarAndDisplayName(
                    displayName: displayName ?? target,
                  );
                  if (message.isNotEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          widget.locale.translate(message),
                        ),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  }
                },
                onTransferTargetReceived: () async {
                  attendedTransferTarget = target;
                  sipCallService.updateAvatarAndDisplayName(
                    displayName: displayName ?? target,
                  );
                });
          },
          onBlindTransferPressed: (target) async {
            sipCallService.currentCallInfo?.refer(target);

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  "${widget.locale.translate("transferredTo")} $target",
                ),
                duration: const Duration(milliseconds: 1500),
              ),
            );
            Future.delayed(const Duration(milliseconds: 1200), () {
              buttonControlCubit.hangUp();
            });
          },
          locale: widget.locale,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: widget.margin,
      // width: MediaQuery.of(context).size.width,
      child: BlocBuilder(
        bloc: buttonControlCubit,
        builder: (context, state) {
          if (state is SpeakerChange) {
            isSpeakerOn = state.value;
          } else if (state is MicChange) {
            isMicOn = state.value;
          }
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  /// Speaker
                  BlocBuilder(
                    bloc: widget.callCubit,
                    // buildWhen: (previous, current) => current is CallConnectedState || previous is CallConnectedState,
                    builder: (context, state) {
                      // if (state is CallConnectedState) {
                      if (widget.callCubit.shouldShowMicAndSpeaker()) {
                        return CallButton(
                          margin: getButtonMargin(state),
                          backgroundColor: Colors.black.withOpacity(0.1),
                          icon: isSpeakerOn
                              ? Icon(
                                  Icons.volume_up,
                                  size: iconSize,
                                  color: iconColor,
                                )
                              : Icon(
                                  Icons.volume_off,
                                  size: iconSize,
                                  color: iconColor,
                                ),
                          onTap: () async {
                            buttonControlCubit.toggleSpeaker();
                          },
                        );
                      }
                      return Container();
                    },
                  ),

                  /// Accept
                  BlocBuilder(
                    bloc: widget.callCubit,
                    //buildWhen: (previous, current) => current is CallInBoundRingingState || previous is CallInBoundRingingState,
                    builder: (context, state) {
                      if (state is CallInBoundRingingState) {
                        return CallButton(
                          shouldShowRipple: true,
                          margin: getButtonMargin(state),
                          backgroundColor: Colors.green,
                          icon: Icon(
                            Icons.phone,
                            size: iconSize,
                            color: iconColor,
                          ),
                          onTap: () async {
                            buttonControlCubit.accept();
                          },
                        );
                      }
                      return Container();
                    },
                  ),

                  /// Unhold or hangup button
                  /// If the call is held, the transferor cannot end the call
                  /// They must unhold the call to talk to the transferee, so they can end the call later
                  ValueListenableBuilder<bool>(
                    valueListenable: sipCallService.unHoldButtonNotifier,
                    builder: (context, value, child) {
                      if (sipCallService.unHoldButtonNotifier.value) {
                        /// Unhold button: unhold transferee
                        return CallButton(
                          margin: const EdgeInsets.only(left: 30, right: 30),
                          backgroundColor: Colors.green,
                          icon: Center(
                            child: SizedBox(
                              height: iconSize,
                              width: iconSize,
                              child: SvgPicture.asset(
                                sipCallService.uiConfig.iconUnHoldCall,
                                theme: SvgTheme(
                                  currentColor: iconColor,
                                ),
                                fit: BoxFit.scaleDown,
                              ),
                            ),
                          ),
                          onTap: () async {
                            buttonControlCubit.toggleUnHold();
                          },
                        );
                      }

                      /// Hangup button
                      return BlocBuilder(
                        bloc: widget.callCubit,
                        builder: (context, state) {
                          if (state is! CallInitialState) {
                            return CallButton(
                              shouldShowRipple: state is CallConnectingState || state is CallOutBoundRingingState,
                              margin: getButtonMargin(state),
                              backgroundColor: Colors.red,
                              icon: Transform.rotate(
                                angle: math.pi * 3 / 4,
                                child: Icon(Icons.phone, size: iconSize, color: iconColor),
                              ),
                              onTap: () async {
                                buttonControlCubit.hangUp();
                              },
                            );
                          }
                          return Container();
                        },
                      );
                    },
                  ),

                  /// Mic
                  BlocBuilder(
                    bloc: widget.callCubit,
                    //buildWhen: (previous, current) => current is CallConnectedState || previous is CallConnectedState,
                    builder: (context, state) {
                      //if (state is CallConnectedState) {
                      if (widget.callCubit.shouldShowMicAndSpeaker()) {
                        return CallButton(
                          margin: getButtonMargin(state),
                          backgroundColor: Colors.black.withOpacity(0.1),
                          icon: isMicOn
                              ? Icon(
                                  Icons.mic,
                                  size: iconSize,
                                  color: iconColor,
                                )
                              : Icon(
                                  Icons.mic_off,
                                  size: iconSize,
                                  color: iconColor,
                                ),
                          onTap: () async {
                            buttonControlCubit.toggleMic();
                          },
                        );
                      }
                      return Container();
                    },
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  /// Transfer button dialog
                  /// Showing when in call and there is no other calls
                  ValueListenableBuilder<bool>(
                    valueListenable: sipCallService.transferDialogButtonNotifier,
                    builder: (context, value, child) {
                      if (sipCallService.transferDialogButtonNotifier.value && (sipCallService.shouldActiveTransferCall?.call() ?? true)) {
                        return CallButton(
                          margin: const EdgeInsets.only(top: 40, left: 30, right: 30),
                          backgroundColor: Colors.black.withOpacity(0.1),
                          icon: Center(
                            child: SizedBox(
                              height: iconSize,
                              width: iconSize,
                              child: SvgPicture.asset(
                                sipCallService.uiConfig.iconTransferCall,
                                theme: SvgTheme(
                                  currentColor: iconColor,
                                ),
                                // fit: BoxFit.scaleDown,
                              ),
                            ),
                          ),
                          onTap: () async {
                            await _showTransferDialog();
                          },
                        );
                      }
                      return Container();
                    },
                  ),

                  /// Button transfer: transfer transferee to transfer target
                  ValueListenableBuilder<bool>(
                    valueListenable: sipCallService.transferButtonNotifier,
                    builder: (context, value, child) {
                      if (sipCallService.transferButtonNotifier.value) {
                        return CallButton(
                          margin: const EdgeInsets.only(top: 40, left: 30, right: 30),
                          backgroundColor: const Color(0xFF2CAFD6),
                          icon: Icon(
                            Icons.phone_forwarded,
                            size: iconSize,
                            color: iconColor,
                          ),
                          onTap: () async {
                            buttonControlCubit.makeAttendedTransferCall(attendedTransferTarget);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  widget.locale.translate("transferCallSuccessfully"),
                                ),
                                duration: const Duration(milliseconds: 1500),
                              ),
                            );
                            Future.delayed(const Duration(milliseconds: 1000), () {
                              buttonControlCubit.hangUp();
                            });
                          },
                        );
                      }
                      return Container();
                    },
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}
