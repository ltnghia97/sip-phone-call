part of 'transfer_call_cubit.dart';

abstract class TransferCallState extends Equatable {
  const TransferCallState();
}

class TransferCallInitial extends TransferCallState {
  @override
  List<Object> get props => [];
}

class GetListCallTransferSuccess extends TransferCallState {
  final List<TransferCallItem> items;

  const GetListCallTransferSuccess(this.items);

  @override
  List<Object?> get props => [items];
}

class GetListCallTransferFailure extends TransferCallState {
  final String message;

  const GetListCallTransferFailure(this.message);

  @override
  List<Object?> get props => [message];
}

class TransferCallInProcessing extends TransferCallState {
  @override
  List<Object?> get props => [];
}
