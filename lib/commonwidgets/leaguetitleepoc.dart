import 'dart:async';

import 'package:flutter/material.dart';

class LeagueTitleEPOC extends StatefulWidget {
  final TextStyle style;
  final int timeInMiliseconds;
  final Function onTimeComplete;
  final String title;
  LeagueTitleEPOC({
    this.title,
    this.timeInMiliseconds,
    this.style,
    this.onTimeComplete,
  });

  @override
  LeagueTitleEPOCState createState() => LeagueTitleEPOCState();
}

class LeagueTitleEPOCState extends State<LeagueTitleEPOC> {
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
    return Container(
      margin: EdgeInsets.symmetric(vertical: 8.0),
      padding: EdgeInsets.symmetric(horizontal: 4.0),
      decoration: BoxDecoration(
        color: Color.fromRGBO(148, 21, 19, 1),
        borderRadius: BorderRadius.circular(4.0),
        border: Border.all(
          width: 1.0,
          color: Color.fromRGBO(173, 55, 53, 1),
        ),
      ),
      child: Row(
        children: <Widget>[
          Padding(
            padding: EdgeInsets.only(right: 8.0, left: 8.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Text(
                  widget.title,
                  style: Theme.of(context).primaryTextTheme.subhead.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
          ),
          bIsTimerClosed
              ? Container(
                  child: Text("CLOSED"),
                  padding: EdgeInsets.all(4.0),
                  decoration: BoxDecoration(
                    color: Color.fromRGBO(100, 12, 10, 1),
                    borderRadius: BorderRadius.circular(4.0),
                  ),
                )
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Container(
                      padding: EdgeInsets.all(2.0),
                      decoration: BoxDecoration(
                        color: Color.fromRGBO(100, 12, 10, 1),
                        borderRadius: BorderRadius.circular(4.0),
                      ),
                      child: Row(
                        children: <Widget>[
                          leftDays != 0
                              ? Container(
                                  width: 16.0,
                                  child: Text(
                                    leftDays < 10
                                        ? "0" + leftDays.toString()
                                        : leftDays.toString(),
                                    style: Theme.of(context)
                                        .primaryTextTheme
                                        .subhead
                                        .copyWith(
                                          color: Colors.white,
                                        ),
                                    textAlign: TextAlign.center,
                                  ),
                                )
                              : Container(),
                          leftDays != 0
                              ? Container(
                                  width: 14.0,
                                  child: Text(
                                    " : ",
                                    style: TextStyle(
                                      color: Color.fromRGBO(193, 80, 79, 1),
                                    ),
                                  ),
                                )
                              : Container(),
                          Container(
                            width: 16.0,
                            child: Text(
                              leftHours < 10
                                  ? "0" + leftHours.toString()
                                  : leftHours.toString(),
                              style: Theme.of(context)
                                  .primaryTextTheme
                                  .subhead
                                  .copyWith(
                                    color: Colors.white,
                                  ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          Container(
                            width: 14.0,
                            child: Text(
                              " : ",
                              style: TextStyle(
                                color: Color.fromRGBO(193, 80, 79, 1),
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
                                  .subhead
                                  .copyWith(
                                    color: Colors.white,
                                  ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          leftDays == 0
                              ? Container(
                                  width: 14.0,
                                  child: Text(
                                    " : ",
                                    style: TextStyle(
                                      color: Color.fromRGBO(193, 80, 79, 1),
                                    ),
                                  ),
                                )
                              : Container(),
                          leftDays == 0
                              ? Container(
                                  width: 16.0,
                                  child: Text(
                                    leftSeconds < 10
                                        ? "0" + leftSeconds.toString()
                                        : leftSeconds.toString(),
                                    style: Theme.of(context)
                                        .primaryTextTheme
                                        .subhead
                                        .copyWith(
                                          color: Colors.white,
                                        ),
                                    textAlign: TextAlign.center,
                                  ),
                                )
                              : Container(),
                        ],
                      ),
                    ),
                    Row(
                      children: <Widget>[
                        leftDays != 0
                            ? Container(
                                width: 16.0,
                                alignment: Alignment.center,
                                child: Text(
                                  "D",
                                  style: Theme.of(context)
                                      .primaryTextTheme
                                      .caption
                                      .copyWith(
                                        color: Color.fromRGBO(255, 149, 147, 1),
                                      ),
                                ),
                              )
                            : Container(),
                        leftDays != 0
                            ? Container(
                                width: 14.0,
                              )
                            : Container(),
                        Container(
                          width: 16.0,
                          alignment: Alignment.center,
                          child: Text(
                            "H",
                            style: Theme.of(context)
                                .primaryTextTheme
                                .caption
                                .copyWith(
                                  color: Color.fromRGBO(255, 149, 147, 1),
                                ),
                          ),
                        ),
                        Container(
                          width: 14.0,
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
                                  color: Color.fromRGBO(255, 149, 147, 1),
                                ),
                          ),
                        ),
                        leftDays == 0
                            ? Container(
                                width: 14.0,
                              )
                            : Container(),
                        leftDays == 0
                            ? Container(
                                width: 16.0,
                                alignment: Alignment.center,
                                child: Text(
                                  "S",
                                  style: Theme.of(context)
                                      .primaryTextTheme
                                      .caption
                                      .copyWith(
                                        color: Color.fromRGBO(255, 149, 147, 1),
                                      ),
                                ),
                              )
                            : Container(),
                      ],
                    ),
                  ],
                ),
        ],
      ),
    );
  }
}
