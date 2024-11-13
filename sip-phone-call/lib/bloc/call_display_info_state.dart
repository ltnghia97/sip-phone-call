part of 'call_display_info_cubit.dart';

abstract class CallDisplayInfoState extends Equatable {
  const CallDisplayInfoState();
}

class CallDisplayInfoInitial extends CallDisplayInfoState {
  @override
  List<Object> get props => [];
}

class UpdateAvatarSuccess extends CallDisplayInfoState {
  final String? avatar;

  const UpdateAvatarSuccess(this.avatar);
  @override
  List<Object?> get props => [avatar, DateTime.now()];
}

class UpdateDisplayNameSuccess extends CallDisplayInfoState {
  final String? name;

  const UpdateDisplayNameSuccess(this.name);
  @override
  List<Object?> get props => [name, DateTime.now()];
}

class UpdateDurationSuccess extends CallDisplayInfoState {
  final Duration? duration;

  const UpdateDurationSuccess(this.duration);
  @override
  List<Object?> get props => [duration, DateTime.now()];
}

class UpdateMessageSuccess extends CallDisplayInfoState {
  final String? message;

  const UpdateMessageSuccess(this.message);
  @override
  List<Object?> get props => [message, DateTime.now()];
}
