import 'dart:async';

import 'package:flutter/material.dart';

class EPOC extends StatefulWidget {
  final TextStyle style;
  final int timeInMiliseconds;
  final Function onTimeComplete;
  EPOC({this.timeInMiliseconds, this.style, this.onTimeComplete});

  @override
  EPOCState createState() => EPOCState();
}

class EPOCState extends State<EPOC> {
  Timer _timer;
  int leftDays = 0;
  int leftHours = 0;
  int leftMinutes = 0;
  int leftSeconds = 0;

  bool bIsTimerClosed = false;

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
      if (remainingTime.inMilliseconds > 0) {
        startTimerToCalculateEPOC();
      } else {
        if (widget.onTimeComplete != null) {
          widget.onTimeComplete();
        }
        setState(() {
          bIsTimerClosed = true;
        });
      }
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
      bIsTimerClosed
          ? "CLOSED"
          : (leftDays.toString() +
              "d : " +
              (leftHours >= 0 ? leftHours.toString() : "0") +
              "h : " +
              (leftMinutes >= 0 ? leftMinutes.toString() : "0") +
              "m : " +
              (leftSeconds >= 0 ? leftSeconds.toString() : "0") +
              "s"),
      style: widget.style ??
          Theme.of(context).primaryTextTheme.body1.copyWith(
                color: Theme.of(context).primaryColor,
              ),
      textAlign: TextAlign.center,
    );
  }
}
