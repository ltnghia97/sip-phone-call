import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../models/transfer_call_item.dart';

part 'transfer_call_state.dart';

abstract class TransferCallCubit extends Cubit<TransferCallState> {
  TransferCallCubit({required this.tenant}) : super(TransferCallInitial());

  List<TransferCallItem> data = [];
  String tenant;

  getListCallTransfer({String? searchKeyword});

  onSelectItem(String id) {
    data.retainWhere((element) => element.id == id);
    emit(GetListCallTransferSuccess(List.of(data)));
  }
}
