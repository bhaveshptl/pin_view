import 'dart:async';

import 'package:flutter/material.dart';

class EPOC extends StatefulWidget {
  final int timeInMiliseconds;
  final TextStyle style;
  EPOC({this.timeInMiliseconds, this.style});

  @override
  EPOCState createState() => EPOCState();
}

class EPOCState extends State<EPOC> {
  int leftDays = 0;
  int leftHours = 0;
  int leftMinutes = 0;
  int leftSeconds = 0;
  Timer _timer;

  @override
  void initState() {
    super.initState();
    startTimerToCalculateEPOC();
  }

  startTimerToCalculateEPOC() {
    Duration remainingTime =
        DateTime.fromMillisecondsSinceEpoch(widget.timeInMiliseconds)
            .difference(DateTime.now());
    setState(() {
      leftDays = remainingTime.inDays;
      leftHours = remainingTime.inHours - (leftDays * 24);
      leftMinutes =
          remainingTime.inMinutes - ((leftHours * 60) + (leftDays * 24 * 60));
      leftSeconds = remainingTime.inSeconds -
          ((leftHours * 60 * 60) +
              (leftDays * 24 * 60 * 60) +
              (leftMinutes * 60));
    });

    _timer = Timer(Duration(seconds: 1), () {
      startTimerToCalculateEPOC();
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      leftDays.toString() +
          "d : " +
          (leftHours >= 0 ? leftHours.toString() : "0") +
          "h : " +
          (leftMinutes >= 0 ? leftMinutes.toString() : "0") +
          "m : " +
          (leftSeconds >= 0 ? leftSeconds.toString() : "0") +
          "s",
      style: widget.style ??
          Theme.of(context).primaryTextTheme.body1.copyWith(
                color: Theme.of(context).primaryColor,
              ),
      textAlign: TextAlign.center,
    );
  }
}
