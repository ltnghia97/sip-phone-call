import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sip_phone_call/bloc/transfer_call_cubit.dart';
import 'package:sip_phone_call/services/sip_call_services.dart';
import 'package:sip_phone_call/utils/locale_translate.dart';

import '../models/transfer_call_item.dart';
import 'custom_button.dart';

class TransferCallDialog extends StatefulWidget {
  const TransferCallDialog({
    Key? key,
    required this.onCancelPressed,
    required this.onBlindTransferPressed,
    required this.onCallPressed,
    required this.locale,
  }) : super(key: key);
  final VoidCallback onCancelPressed;
  final Function(String) onBlindTransferPressed;
  final Function(String, String?) onCallPressed;
  final Locale locale;

  @override
  State<TransferCallDialog> createState() => _TransferCallDialogState();
}

class _TransferCallDialogState extends State<TransferCallDialog> {
  final TextEditingController transferTargetController = TextEditingController(text: "");
  final ValueNotifier<String> targetNotifier = ValueNotifier<String>("");
  List<TransferCallItem> listTransfer = [];

  @override
  void initState() {
    super.initState();
    SipCallService.getInstance().transferCallCubit?.getListCallTransfer();
  }

  ButtonState getButtonState({required int listTransferLength, required String input}) {
    /// if list transfer has only 1 result
    ///   if user does not type anything -> Active & get that 1 result as target
    ///   else -> Active
    /// else
    ///   if user does not type anything -> Inactive
    ///   else -> Active
    if (listTransferLength == 1) {
      return ButtonState.active;
    }
    return int.tryParse(input) == null ? ButtonState.inactive : ButtonState.active;
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<TransferCallCubit, TransferCallState>(
      bloc: SipCallService.getInstance().transferCallCubit,
      listener: (context, state) {
        if (state is TransferCallInProcessing) {
          listTransfer = [];
        } else if (state is GetListCallTransferSuccess) {
          listTransfer = state.items;
        }
      },
      builder: (context, state) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          insetPadding: const EdgeInsets.all(24),
          child: Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      widget.locale.translate('titleTransferCall'),
                      textAlign: TextAlign.left,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    IconButton(
                      onPressed: widget.onCancelPressed,
                      icon: const Icon(Icons.close),
                      padding: const EdgeInsets.all(0),
                      alignment: Alignment.topCenter,
                    ),
                  ],
                ),

                /// Input field
                TextFormField(
                  autofocus: true,
                  controller: transferTargetController,
                  decoration: InputDecoration(
                    filled: true,
                    contentPadding: const EdgeInsets.only(left: 15, right: 15, top: 0, bottom: 0),
                    hintText: widget.locale.translate('hintSearchTransferCall'),
                    suffix: Builder(
                      builder: (context) {
                        return SizedBox(
                            width: 20,
                            height: 20,
                            child: state is TransferCallInProcessing
                                ? const CircularProgressIndicator(
                                    strokeWidth: 2,
                                  )
                                : const Icon(
                                    Icons.search,
                                    size: 20,
                                  ));
                      },
                    ),
                    enabledBorder: const OutlineInputBorder(
                      borderSide: BorderSide(width: 1, color: Color(0xffC8C8C8)),
                      borderRadius: BorderRadius.all(
                        Radius.circular(10),
                      ),
                    ),
                    border: const OutlineInputBorder(
                      borderSide: BorderSide(width: 1, color: Color(0xffC8C8C8)),
                      borderRadius: BorderRadius.all(
                        Radius.circular(10),
                      ),
                    ),
                    focusedBorder: const OutlineInputBorder(
                      borderSide: BorderSide(
                        width: 1,
                        color: Color(0xffC8C8C8),
                      ),
                      borderRadius: BorderRadius.all(
                        Radius.circular(10),
                      ),
                    ),
                  ),
                  onChanged: (value) {
                    targetNotifier.value = value;
                    SipCallService.getInstance().transferCallCubit?.getListCallTransfer(searchKeyword: value);
                  },
                  // textAlign: TextAlign.center,
                ),

                const SizedBox(
                  height: 8,
                ),

                /// Suggestion
                SizedBox(
                  height: 90,
                  child: listTransfer.isNotEmpty
                      ? SingleChildScrollView(
                          child: Column(
                            children: listTransfer.asMap().entries.map((e) {
                              return GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTap: () {
                                  targetNotifier.value = e.value.extension;
                                  setState(() {
                                    transferTargetController.text = e.value.extension;
                                  });
                                  SipCallService.getInstance().transferCallCubit?.onSelectItem(e.value.id);
                                },
                                child: Container(
                                  padding: const EdgeInsets.only(top: 8, bottom: 8),
                                  decoration: e.key != (listTransfer.length - 1) ? BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey.withOpacity(0.5)))) : null,
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      /// Group
                                      Expanded(
                                        child: Text(
                                          e.value.group,
                                          style: const TextStyle(fontSize: 16),
                                        ),
                                      ),
                                      const SizedBox(
                                        width: 16,
                                      ),

                                      /// Extension
                                      Text(
                                        e.value.extension,
                                        style: const TextStyle(fontSize: 16, color: Color(0xffA96C12)),
                                      ),
                                      const SizedBox(
                                        width: 10,
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        )
                      : Container(),
                ),

                /// Buttons
                Container(
                  margin: const EdgeInsets.only(top: 40),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ValueListenableBuilder(
                        valueListenable: targetNotifier,
                        builder: (context, value, child) {
                          return Button(
                            strokeOnly: true,
                            borderRadius: 10,
                            state: getButtonState(listTransferLength: listTransfer.length, input: targetNotifier.value),
                            child: Text(widget.locale.translate("Attended")),
                            onPressed: () {
                              if (listTransfer.length == 1 && targetNotifier.value.isEmpty) {
                                transferTargetController.text = listTransfer.first.extension;
                              }
                              Navigator.of(context).pop();
                              String? name;
                              for (var item in listTransfer) {
                                if (item.extension == transferTargetController.text) {
                                  name = item.group;
                                  break;
                                }
                              }
                              widget.onCallPressed(transferTargetController.text, name);
                            },
                          );
                        },
                      ),
                      ValueListenableBuilder(
                        valueListenable: targetNotifier,
                        builder: (context, value, child) {
                          return Button(
                            strokeOnly: true,
                            borderRadius: 10,
                            state: getButtonState(listTransferLength: listTransfer.length, input: targetNotifier.value),
                            child: Text(widget.locale.translate("Blind")),
                            onPressed: () {
                              if (listTransfer.length == 1 && targetNotifier.value.isEmpty) {
                                transferTargetController.text = listTransfer.first.extension;
                              }
                              Navigator.of(context).pop();

                              widget.onBlindTransferPressed(transferTargetController.text);
                            },
                          );
                        },
                      ),
                    ],
                  ),
                )
              ],
            ),
          ),
        );
      },
    );
  }
}
