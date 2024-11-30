part of 'button_control_cubit.dart';

abstract class ButtonControlState extends Equatable {
  const ButtonControlState();
}

class ButtonControlInitial extends ButtonControlState {
  @override
  List<Object> get props => [];
}

class ButtonInProgress extends ButtonControlState {
  @override
  List<Object?> get props => [];
}

class MicChange extends ButtonControlState {
  final bool value;

  const MicChange(this.value);

  @override
  List<Object?> get props => [value];
}

class SpeakerChange extends ButtonControlState {
  final bool value;

  const SpeakerChange(this.value);

  @override
  List<Object?> get props => [value];
}
