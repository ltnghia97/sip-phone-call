import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:sip_phone_call/constants/constants.dart';
import 'package:sip_phone_call/services/call_management_services.dart';
import 'package:sip_phone_call/services/sip_call_services.dart';

import '../../domain/entities/call_info_noti_entity.dart';

part 'call_info_notification_state.dart';

class CallInfoNotificationCubit extends Cubit<CallInfoNotificationState> {
  CallInfoNotificationCubit() : super(CallInfoNotificationInitial());

  Map<String, CallInfoNotificationEntity> _mapCall = {};

  updateCallInfoNotification() {
    Map<String, CallInfoNotificationEntity> mapCallNotification = {};
    if (CallManagementService.getInstance().isInTransferCall()) {
      CallManagementService.getInstance().mapCall.forEach((key, value) {
        if (value.call.isHolding && value.call.id != null) {
          mapCallNotification.addAll({
            value.call.id!: CallInfoNotificationEntity(
              callDuration: value.duration,
              status: Constants.messageHolding,
              displayName: value.displayInfo?.displayName ?? "",
            )
          });
        }
      });
    }

    _mapCall = mapCallNotification;

    /// Show end call in notification
    // Map<String, CallInfoNotificationEntity> concatMapCall = {}
    //   ..addAll(_mapCall)
    //   ..addAll(mapCallNotification);
    // for (var entry in concatMapCall.entries) {
    //   /// call in old map but not in new map -> set its status to end call
    //   if (_mapCall[entry.key] != null && mapCallNotification[entry.key] == null) {
    //     entry.value.status = Constants.messageCallEnded;
    //   }
    // }
    // _mapCall = mapCallNotification;
    // emit(UpdateCallInfoNotificationSuccess(concatMapCall));
    //
    // Future.delayed(const Duration(seconds: 3), () {
    //   emit(UpdateCallInfoNotificationSuccess(_mapCall));
    // });

    emit(UpdateCallInfoNotificationSuccess(_mapCall));
  }
}
