import 'dart:io';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_vibration/flutter_vibration.dart';

import '../services/sip_call_services.dart';

part 'button_control_state.dart';

class ButtonControlCubit extends Cubit<ButtonControlState> {
  bool isMicOn = true;
  bool isSpeakerOn = false;
  final SipCallService sipCallService;
  ButtonControlCubit(this.sipCallService) : super(ButtonControlInitial());

  void toggleMic() {
    emit(ButtonInProgress());
    isMicOn = !isMicOn;
    sipCallService.setMic(isMicOn);
    emit(MicChange(isMicOn));
  }

  void toggleSpeaker() {
    emit(ButtonInProgress());
    isSpeakerOn = !isSpeakerOn;
    sipCallService.setSpeaker(isSpeakerOn);
    emit(SpeakerChange(isSpeakerOn));
  }

  void hangUp() {
    if (Platform.isAndroid) {
      FlutterVibration().stop();
    }
    print('call handleEndCall from hangup');
    sipCallService.handleEndCall(isFromUI: true);
  }

  void accept() {
    if (Platform.isAndroid) {
      FlutterVibration().stop();
    }
    sipCallService.handleAccept();
  }

  void toggleUnHold() {
    sipCallService.unHoldCall();
  }

  void makeAttendedTransferCall(String target) async {
    sipCallService.makeAttendedTransferCall(target: target);
  }
}
