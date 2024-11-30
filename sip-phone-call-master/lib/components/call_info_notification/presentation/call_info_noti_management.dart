import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sip_phone_call/components/call_info_notification/presentation/call_info_noti_item.dart';
import 'package:sip_phone_call/services/sip_call_services.dart';

import '../domain/entities/call_info_noti_entity.dart';
import 'cubit/call_info_notification_cubit.dart';

class CallInfoNotificationManagement extends StatefulWidget {
  const CallInfoNotificationManagement({super.key, required this.locale});

  final Locale locale;

  @override
  State<CallInfoNotificationManagement> createState() => _CallInfoNotificationManagementState();
}

class _CallInfoNotificationManagementState extends State<CallInfoNotificationManagement> {
  Map<String, CallInfoNotificationEntity> mapCall = {};

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CallInfoNotificationCubit, CallInfoNotificationState>(
      bloc: SipCallService.getInstance().callInfoNotificationCubit,
      builder: (context, state) {
        if (state is UpdateCallInfoNotificationSuccess) {
          mapCall = state.mapCall;
        }
        if (mapCall.isEmpty) return Container();
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: mapCall.entries.map((item) {
            return CallInfoNotificationItem(
              infoNotificationEntity: item.value,
              locale: widget.locale,
            );
          }).toList(),
        );
      },
    );
  }
}
