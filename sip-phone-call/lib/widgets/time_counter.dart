import 'dart:async';

import 'package:flutter/material.dart';


enum FormatTimeCounter { dHHMMss, dHHmm, day, hhMMss, hhMM, hh, mmSS, mm, ss, auto }


class TimeCounter extends StatefulWidget {
  final Duration duration;
  final bool start;
  final TextStyle? style;
  final bool countUp;
  final VoidCallback? onCountComplete;
  final Function(int)? onTimeRemain;
  final TextAlign textAlign;
  final bool onlyShowSeconds;
  final bool showHour;
  final bool keepCurrentValue;
  final bool showAllSeconds;
  final bool hideTimerWhenCountDownComplete;
  final Widget? icon;
  final String postfix;
  final String prefix;
  final FormatTimeCounter? formatTimeCounter;
  final VoidCallback? onTap;
  final int? stopTimerPoint;

  @override
  State<StatefulWidget> createState() => _TimeCounterState();

  String _formatDay(int days) {
    if (days > 1) {
      return 'days';
    }
    return 'day';
  }

  static const int _minutesOfDay = 1440;
  static const int _secondsOfDay = 86400;
  static const int _secondsOfHours = 3600;

  String formatDuration(Duration d,) {
    var seconds = d.inSeconds;
    final days = seconds ~/ Duration.secondsPerDay;
    seconds -= days * Duration.secondsPerDay;
    final hours = seconds ~/ Duration.secondsPerHour;
    seconds -= hours * Duration.secondsPerHour;
    final minutes = seconds ~/ Duration.secondsPerMinute;
    seconds -= minutes * Duration.secondsPerMinute;

    final List<String> tokens = [];

    if (formatTimeCounter != null) {
      switch (formatTimeCounter) {
        case FormatTimeCounter.dHHMMss:
          tokens.add('$days ${_formatDay(days)} ');
          tokens.add('${hours.toString().padLeft(2, '0')}:');
          tokens.add('${minutes.toString().padLeft(2, '0')}:');
          tokens.add(seconds.toString().padLeft(2, '0'));
          break;
        case FormatTimeCounter.dHHmm:
          tokens.add('$days ${_formatDay(days)} ');
          tokens.add('${hours.toString().padLeft(2, '0')}:');
          tokens.add(minutes.toString().padLeft(2, '0'));
          break;
        case FormatTimeCounter.day:
          if (days > 0) {
            tokens.add('$days ${_formatDay(days)}');
          } else {
            if (hours > 0) {
              tokens.add("${hours.toString().padLeft(2, '0')}:");
            }
            if (minutes > 0) {
              tokens.add("${minutes.toString().padLeft(2, '0')}:");
            }
            if (seconds > 0) {
              tokens.add("${seconds.toString().padLeft(2, '0')} ");
            }
            tokens.add('day');
          }
          break;
        case FormatTimeCounter.hhMMss:
          tokens.add('${((days * 24) + hours).toString().padLeft(2, '0')}:');
          tokens.add('${minutes.toString().padLeft(2, '0')}:');
          tokens.add(seconds.toString().padLeft(2, '0'));
          break;
        case FormatTimeCounter.hhMM:
          tokens.add('${((days * 24) + hours).toString().padLeft(2, '0')}:');
          tokens.add(minutes.toString().padLeft(2, '0'));
          break;
        case FormatTimeCounter.hh:
          int time = (days * 24) + hours;
          if (time > 0) {
            tokens.add("${time.toString().padLeft(2, '0')} ");
            tokens.add('later');
            // Todo dich lai
          } else {
            tokens.add('in 1 hour');
          }
          break;
        case FormatTimeCounter.mmSS:
          tokens.add('${((days * _minutesOfDay) + (hours * 60) + minutes).toString().padLeft(2, '0')}:');
          tokens.add(seconds.toString().padLeft(2, '0'));
          break;
        case FormatTimeCounter.mm:
          tokens.add(((days * _minutesOfDay) + (hours * 60) + minutes).toString().padLeft(2, '0'));
          break;
        case FormatTimeCounter.ss:
          tokens.add((((days * _secondsOfDay) + (hours * _secondsOfHours) + (60 * minutes)) + seconds).toString().padLeft(2, '0'));
          break;
        case FormatTimeCounter.auto:
          if (days > 0) {
            tokens.add('$days ${_formatDay(days)} ');
          }
          if (hours > 0) {
            tokens.add(("${hours.toString().padLeft(2, '0')}:"));
          }
          if (minutes > 0) {
            tokens.add(("${minutes.toString().padLeft(2, '0')}:"));
          }
          tokens.add((seconds.toString().padLeft(2, '0')));
          break;
        default:
          tokens.add('');
      }
    } else {
      if (days != 0) {
        tokens.add('$days ${_formatDay(days)}');
      } else {
        if (hours != 0 || showHour) tokens.add('${hours.toString().padLeft(2, '0')}:');
        if (!onlyShowSeconds) tokens.add('${minutes.toString().padLeft(2, '0')}:');
        tokens.add(seconds.toString().padLeft(2, '0'));
      }
    }

    return tokens.join('');
  }

  const TimeCounter({
    Key? key,
    required this.duration,
    this.onCountComplete,
    this.style,
    this.onTimeRemain,
    this.countUp = true,
    this.onlyShowSeconds = false,
    this.textAlign = TextAlign.left,
    required this.start,
    this.showHour = false,
    this.keepCurrentValue = false,
    this.icon,
    this.showAllSeconds = false,
    this.postfix = '',
    this.prefix = '',
    this.onTap,
    this.hideTimerWhenCountDownComplete = false,
    this.formatTimeCounter,
    this.stopTimerPoint,
  }) : super(key: key);

  const TimeCounter.countDown({
    Key? key,
    required this.duration,
    this.onCountComplete,
    this.style,
    this.onTimeRemain,
    this.countUp = false,
    this.onlyShowSeconds = false,
    this.textAlign = TextAlign.left,
    required this.start,
    this.showHour = false,
    this.keepCurrentValue = false,
    this.icon,
    this.showAllSeconds = false,
    this.postfix = '',
    this.prefix = '',
    this.onTap,
    this.hideTimerWhenCountDownComplete = false,
    this.formatTimeCounter,
    this.stopTimerPoint,
  }) : super(key: key);

  const TimeCounter.countUp({
    Key? key,
    required this.duration,
    this.onCountComplete,
    this.style,
    this.onTimeRemain,
    this.countUp = true,
    this.onlyShowSeconds = false,
    this.textAlign = TextAlign.left,
    required this.start,
    this.showHour = false,
    this.keepCurrentValue = false,
    this.icon,
    this.showAllSeconds = false,
    this.postfix = '',
    this.prefix = '',
    this.onTap,
    this.formatTimeCounter,
    this.stopTimerPoint,
  })  : hideTimerWhenCountDownComplete = false,
        super(key: key);
}

class _TimeCounterState extends State<TimeCounter> {
  late Timer _timer;
  late int _seconds;

  @override
  void initState() {
    super.initState();
    _seconds = widget.duration.inSeconds;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          if (widget.start) {
            widget.countUp ? _seconds += 1 : _seconds -= 1;
            if (_seconds <= 0 && widget.onCountComplete != null) widget.onCountComplete!();
          } else if (_seconds > 0 && !widget.keepCurrentValue) {
            _seconds = 0;
          }
          widget.onTimeRemain?.call(_seconds);

          if (widget.stopTimerPoint != null){
            if (_seconds == widget.stopTimerPoint!){
              timer.cancel();
            }
          }
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        if (widget.icon != null) widget.icon!,
        GestureDetector(
          onTap: widget.onTap,
          child: Text(
            '${widget.prefix}${(widget.hideTimerWhenCountDownComplete && _seconds == 0) ? '' : widget.showAllSeconds ? _seconds : widget.formatDuration(Duration(seconds: this._seconds))}${(widget.hideTimerWhenCountDownComplete && _seconds == 0) ? '' : widget.postfix}',
            style: widget.style,
            textAlign: widget.textAlign,
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }
}
