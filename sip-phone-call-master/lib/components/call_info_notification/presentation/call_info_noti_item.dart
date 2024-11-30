import 'package:flutter/material.dart';
import 'package:sip_phone_call/utils/locale_translate.dart';

import '../../../widgets/time_counter.dart';
import '../domain/entities/call_info_noti_entity.dart';

class CallInfoNotificationItem extends StatefulWidget {
  const CallInfoNotificationItem({super.key, required this.infoNotificationEntity, this.padding, this.margin, required this.locale});

  final CallInfoNotificationEntity infoNotificationEntity;
  final EdgeInsets? margin;
  final Locale locale;
  final EdgeInsets? padding;

  @override
  State<CallInfoNotificationItem> createState() => _CallInfoNotificationItemState();
}

class _CallInfoNotificationItemState extends State<CallInfoNotificationItem> {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: widget.margin ?? const EdgeInsets.only(top: 10, left: 20, right: 20),
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        elevation: 3,
        child: Container(
          padding: widget.padding ?? const EdgeInsets.all(20.0),
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xffA96C12)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              /// Display name and Status
              Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.infoNotificationEntity.displayName,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, height: 1.5),
                  ),
                  Text(
                    widget.locale.translate(widget.infoNotificationEntity.status),
                    style: const TextStyle(height: 1.5),
                  ),
                ],
              ),

              /// Duration
              Material(
                key: ValueKey(widget.infoNotificationEntity.callDuration.inSeconds),
                color: Colors.transparent,
                child: TimeCounter.countUp(
                  duration: widget.infoNotificationEntity.callDuration,
                  start: true,
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
