import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

part 'call_display_info_state.dart';

class CallDisplayInfoCubit extends Cubit<CallDisplayInfoState> {
  CallDisplayInfoCubit() : super(CallDisplayInfoInitial());

  String? _name;
  String? _avatar;

  updateAvatar(String? avatar) {
    if (avatar != null) {
      _avatar = avatar;
    }
    emit(UpdateAvatarSuccess(_avatar));
  }

  updateDisplayName(String? name) {
    if (name != null) {
      _name = name;
    }
    emit(UpdateDisplayNameSuccess(_name));
  }

  updateDuration(Duration? duration) {
    emit(UpdateDurationSuccess(duration));
  }
}
