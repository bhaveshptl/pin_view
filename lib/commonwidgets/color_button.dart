import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class ColorButton extends StatelessWidget {
  final Widget child;
  final Function onPressed;
  final Color color;
  final Color disabledColor;
  final double elevation;
  final BorderRadius borderRadius;
  final EdgeInsetsGeometry padding;

  ColorButton({
    @required this.child,
    @required this.onPressed,
    this.color,
    this.disabledColor,
    this.elevation,
    this.borderRadius,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return RaisedButton(
      child: child,
      onPressed: onPressed,
      color: color ?? Color.fromRGBO(70, 165, 12, 1),
      disabledColor: Colors.black26,
      shape: RoundedRectangleBorder(
        borderRadius: borderRadius ?? BorderRadius.circular(4.0),
      ),
      padding: padding,
      elevation: elevation,
    );
  }
}
