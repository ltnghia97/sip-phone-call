part of 'call_info_notification_cubit.dart';

abstract class CallInfoNotificationState extends Equatable {
  const CallInfoNotificationState();
}

class CallInfoNotificationInitial extends CallInfoNotificationState {
  @override
  List<Object> get props => [];
}

class UpdateCallInfoNotificationSuccess extends CallInfoNotificationState {
  // final List<CallInfoNotificationEntity> list;
  final Map<String, CallInfoNotificationEntity> mapCall;

  const UpdateCallInfoNotificationSuccess(this.mapCall);

  @override
  List<Object?> get props => [mapCall, DateTime.now()];
}
