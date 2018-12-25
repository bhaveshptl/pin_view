import 'package:flutter/material.dart';

class GradientButton extends StatelessWidget {
  final RaisedButton button;
  final Gradient gradient;
  final double height;
  final bool disabled;
  GradientButton({
    @required this.button,
    this.height = 28.0,
    this.gradient,
    this.disabled = false,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.all(
        Radius.circular(20.0),
      ),
      child: Container(
        height: height,
        decoration: BoxDecoration(
          gradient: gradient == null
              ? LinearGradient(
                  colors: disabled
                      ? [
                          Colors.black26,
                          Colors.black26,
                        ]
                      : [
                          Theme.of(context).primaryColor.withAlpha(150),
                          Theme.of(context).primaryColor.withAlpha(220),
                          Theme.of(context).primaryColor,
                          Theme.of(context).primaryColor,
                          Theme.of(context).primaryColor.withAlpha(220),
                          Theme.of(context).primaryColor.withAlpha(150),
                        ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                )
              : gradient,
        ),
        child: button,
      ),
    );
  }
}
