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
    return bIsTimerClosed
        ? Text(
            "CLOSED",
            style: widget.style ??
                Theme.of(context).primaryTextTheme.body1.copyWith(
                      color: Theme.of(context).primaryColor,
                    ),
          )
        : Container(
            child: Column(
              children: <Widget>[
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(2.0),
                    color: Colors.grey.shade100,
                  ),
                  padding: EdgeInsets.all(2.0),
                  alignment: Alignment.center,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Container(
                        width: 16.0,
                        child: Text(
                          leftDays < 10
                              ? "0" + leftDays.toString()
                              : leftDays.toString(),
                          style: Theme.of(context)
                              .primaryTextTheme
                              .subtitle
                              .copyWith(
                                color: Colors.black,
                                fontWeight: FontWeight.normal,
                              ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      Container(
                        width: 8.0,
                        alignment: Alignment.center,
                        child: Text(
                          " : ",
                          style: TextStyle(
                            color: Colors.black,
                          ),
                        ),
                      ),
                      Container(
                        width: 16.0,
                        child: Text(
                          leftHours < 10
                              ? "0" + leftHours.toString()
                              : leftHours.toString(),
                          style: Theme.of(context)
                              .primaryTextTheme
                              .subtitle
                              .copyWith(
                                color: Colors.black,
                                fontWeight: FontWeight.normal,
                              ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      Container(
                        width: 8.0,
                        alignment: Alignment.center,
                        child: Text(
                          " : ",
                          style: TextStyle(
                            color: Colors.black,
                          ),
                        ),
                      ),
                      Container(
                        width: 16.0,
                        child: Text(
                          leftMinutes < 10
                              ? "0" + leftMinutes.toString()
                              : leftMinutes.toString(),
                          style: Theme.of(context)
                              .primaryTextTheme
                              .subtitle
                              .copyWith(
                                color: Colors.black,
                                fontWeight: FontWeight.normal,
                              ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      Container(
                        width: 8.0,
                        alignment: Alignment.center,
                        child: Text(
                          " : ",
                          style: TextStyle(
                            color: Colors.black,
                          ),
                        ),
                      ),
                      Container(
                        width: 16.0,
                        child: Text(
                          leftSeconds < 10
                              ? "0" + leftSeconds.toString()
                              : leftSeconds.toString(),
                          style: Theme.of(context)
                              .primaryTextTheme
                              .subtitle
                              .copyWith(
                                color: Colors.black,
                                fontWeight: FontWeight.normal,
                              ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(top: 2.0),
                  child: Row(
                    children: <Widget>[
                      Container(
                        width: 16.0,
                        alignment: Alignment.center,
                        child: Text(
                          "D",
                          style: Theme.of(context)
                              .primaryTextTheme
                              .caption
                              .copyWith(
                                color: Colors.black,
                                fontWeight: FontWeight.w300,
                              ),
                        ),
                      ),
                      Container(
                        width: 8.0,
                      ),
                      Container(
                        width: 16.0,
                        alignment: Alignment.center,
                        child: Text(
                          "H",
                          style: Theme.of(context)
                              .primaryTextTheme
                              .caption
                              .copyWith(
                                color: Colors.black,
                                fontWeight: FontWeight.w300,
                              ),
                        ),
                      ),
                      Container(
                        width: 8.0,
                      ),
                      Container(
                        width: 16.0,
                        alignment: Alignment.center,
                        child: Text(
                          "M",
                          style: Theme.of(context)
                              .primaryTextTheme
                              .caption
                              .copyWith(
                                color: Colors.black,
                                fontWeight: FontWeight.w300,
                              ),
                        ),
                      ),
                      Container(
                        width: 8.0,
                      ),
                      Container(
                        width: 16.0,
                        alignment: Alignment.center,
                        child: Text(
                          "S",
                          style: Theme.of(context)
                              .primaryTextTheme
                              .caption
                              .copyWith(
                                color: Colors.black,
                                fontWeight: FontWeight.w300,
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
  }
}
