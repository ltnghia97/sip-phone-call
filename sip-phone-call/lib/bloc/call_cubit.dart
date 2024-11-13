import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:sip_phone_call/services/call_management_services.dart';
import 'package:sip_ua/sip_ua.dart';
import 'package:sip_ua/sip_ua.dart' as call_state_sip show CallState;

import '../screens/call_screen.dart';
import '../services/sip_call_services.dart';
import '../utils/logger.dart';

part 'call_state.dart';

class CallCubit extends Cubit<CallState> {
  final SipCallService sipCallService;
  CallState? initState;
  late int listenerId;

  handleCallState(call_state_sip.CallState state) {
    Logger.log('handle call state cubit = ${state.state}');
    switch (state.state) {
      case CallStateEnum.CONFIRMED:
        emit(CallConnectedState());
        break;
      case CallStateEnum.NONE:
        // TODO: Handle this case.
        break;
      case CallStateEnum.STREAM:
        if (sipCallService.isOutBoundCall) {
          emit(CallOutBoundRingingState());
        }
        if (sipCallService.callStartCountNotifier.value != null) {
          emit(CallConnectedState());
        }
        break;
      case CallStateEnum.UNMUTED:
        // TODO: Handle this case.
        break;
      case CallStateEnum.MUTED:
        // TODO: Handle this case.
        break;
      case CallStateEnum.CONNECTING:
        emit(CallConnectingState());
        break;
      case CallStateEnum.PROGRESS:
        sipCallService.isInBoundCall ? emit(CallInBoundRingingState()) : emit(CallOutBoundRingingState());
        break;
      case CallStateEnum.FAILED:
        if (CallManagementService.getInstance().isInTransferCall()) {
          emit(CallHoldState());
        } else {
          CallScreen.isExist = false;
          emit(CallEnded());
        }
        sipCallService.handleEndCall(isHangUp: false);
        break;
      case CallStateEnum.ENDED:
        if (CallManagementService.getInstance().currentCallInfo?.isHolding ?? false) {
          emit(CallHoldState());
        } else {
          CallScreen.isExist = false;
          emit(CallEnded());
          sipCallService.handleEndCall(isHangUp: false);
        }
        break;
      case CallStateEnum.ACCEPTED:
        // TODO: Handle this case.
        break;
      case CallStateEnum.REFER:
        // TODO: Handle this case.
        break;
      case CallStateEnum.HOLD:
        emit(CallHoldState());
        break;
      case CallStateEnum.UNHOLD:
        emit(CallUnHoldState());
        break;
      case CallStateEnum.CALL_INITIATION:
        emit(CallConnectingState());
        break;
    }
  }

  bool shouldShowMicAndSpeaker() {
    return state is CallOutBoundRingingState || state is CallConnectedState || state is CallConnectingState || state is CallHoldState || state is CallUnHoldState;
  }

  CallCubit({required this.sipCallService, this.initState}) : super(initState ?? CallInitialState()) {
    if (sipCallService.currentCallInfo != null) {
      handleCallState(sipCallService.callState!);
    }

    listenerId = sipCallService.addListener((callState) {
      handleCallState(callState);
    });
  }

  @override
  Future<void> close() {
    sipCallService.removeListener(listenerId);
    return super.close();
  }
}
