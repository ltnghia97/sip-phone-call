part of 'call_cubit.dart';

abstract class CallState extends Equatable {
  const CallState();
}

class CallInitial extends CallState {
  @override
  List<Object> get props => [];
}

class CallConnectingState extends CallState {
  @override
  List<Object?> get props => [];
}

class CallOutBoundRingingState extends CallState {
  @override
  List<Object?> get props => [];
}

class CallInBoundRingingState extends CallState {
  @override
  List<Object?> get props => [];
}

class CallConnectedState extends CallState {
  @override
  List<Object?> get props => [];
}

class CallEnded extends CallState {
  @override
  List<Object?> get props => [];
}

class CallBusyState extends CallState {
  @override
  List<Object?> get props => [];
}

class CallDenyState extends CallState {
  @override
  List<Object?> get props => [];
}

class CallInitialState extends CallState {
  @override
  List<Object?> get props => [];
}

class CallHoldState extends CallState {
  @override
  List<Object?> get props => [];
}

class CallUnHoldState extends CallState {
  @override
  List<Object?> get props => [];
}
