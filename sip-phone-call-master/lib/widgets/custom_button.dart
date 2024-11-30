import 'package:flutter/material.dart';

enum ButtonState { active, inactive }

class Button extends StatelessWidget {
  final ButtonState state;
  final Widget child;
  final VoidCallback? onPressed;
  final Color? color;
  final Color strokeColor;
  final Color strokeOnlyColor;
  final Color strokeInActiveColor;
  final Color backgroundColor;
  final double borderRadius;
  final double height;
  final double minWidth;
  final bool strokeOnly;
  final bool hasContentPadding;
  final double borderWidth;

  Button({
    Key? key,
    this.state = ButtonState.active,
    required this.child,
    this.onPressed,
    this.backgroundColor = Colors.white,
    this.color,
    this.borderRadius = 25,
    this.height = 42,
    this.minWidth = 120,
    this.strokeOnly = false,
    this.hasContentPadding = true,
    this.strokeInActiveColor = Colors.grey,
    this.strokeOnlyColor = const Color(0xffA96C12),
    this.strokeColor = const Color(0xffA96C12),
    this.borderWidth = 1,
  }) : super(key: key);

  const Button.rect({
    Key? key,
    this.state = ButtonState.active,
    required this.child,
    this.onPressed,
    this.backgroundColor = Colors.white,
    this.color,
    this.borderRadius = 5,
    this.height = 48,
    this.minWidth = 120,
    this.strokeOnly = false,
    this.strokeColor = const Color(0xffA96C12),
    this.hasContentPadding = true,
    this.strokeInActiveColor = Colors.grey,
    this.strokeOnlyColor = const Color(0xffA96C12),
    this.borderWidth = 1,
  }) : super(key: key);

  const Button.underline({
    Key? key,
    this.state = ButtonState.active,
    required this.child,
    this.onPressed,
    this.backgroundColor = Colors.white,
    this.color,
    this.borderRadius = 5,
    this.height = 48,
    this.minWidth = 0,
    this.strokeOnly = true,
    this.strokeColor = Colors.transparent,
    this.hasContentPadding = false,
    this.strokeInActiveColor = Colors.transparent,
    this.strokeOnlyColor = Colors.transparent,
    this.borderWidth = 1,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      child: TextButton(
        style: ButtonStyle(
          padding: hasContentPadding ? MaterialStateProperty.all(const EdgeInsets.symmetric(vertical: 0, horizontal: 14)) : MaterialStateProperty.all(EdgeInsets.zero),
          shape: MaterialStateProperty.all(
            RoundedRectangleBorder(
              side: BorderSide(
                width: borderWidth,
                color: state == ButtonState.active
                    ? strokeOnly
                        ? strokeOnlyColor
                        : strokeColor
                    : strokeInActiveColor,
              ),
              borderRadius: BorderRadius.all(
                Radius.circular(borderRadius),
              ),
            ),
          ),
          minimumSize: MaterialStateProperty.all(
            Size.fromWidth(minWidth),
          ),
          foregroundColor: MaterialStateProperty.all(
            strokeOnly ? const Color(0xffA96C12) : Colors.white,
          ),
          backgroundColor: MaterialStateProperty.all(
            strokeOnly
                ? backgroundColor
                : state == ButtonState.active
                    ? color ?? Theme.of(context).primaryColor
                    : Colors.grey,
          ),
          overlayColor: MaterialStateProperty.all(Colors.transparent),
        ),
        onPressed: state == ButtonState.active ? onPressed : null,
        child: child,
      ),
    );
  }
}
