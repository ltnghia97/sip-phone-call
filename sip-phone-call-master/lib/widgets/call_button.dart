import 'package:flutter/material.dart';

class CallButton extends StatefulWidget {
  const CallButton({Key? key, required this.icon, required this.onTap, this.backgroundColor, this.margin, this.shouldShowRipple = false}) : super(key: key);

  final Widget icon;
  final Function() onTap;
  final Color? backgroundColor;
  final EdgeInsets? margin;
  final bool shouldShowRipple;
  @override
  State<CallButton> createState() => _CallButtonState();
}

class _CallButtonState extends State<CallButton> {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        widget.onTap.call();
      },
      child: Container(
        margin: widget.margin,
        height: 64,
        width: 64,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: widget.backgroundColor,
        ),
        child: widget.icon,
      ),
    );
  }
}
