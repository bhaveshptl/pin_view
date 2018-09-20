import 'package:flutter/material.dart';
import 'package:playfantasy/lobby/tabs/leaguecard.dart';
import 'package:playfantasy/modal/l1.dart';
import 'package:playfantasy/modal/league.dart';

class ContestDetail extends StatefulWidget {
  final L1 _l1Data;
  final League _league;
  final Contest _contest;

  ContestDetail(this._league, this._l1Data, this._contest);

  @override
  State<StatefulWidget> createState() => ContestDetailState();
}

class ContestDetailState extends State<ContestDetail> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Contest details"),
      ),
      body: Container(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: LeagueCard(widget._league, clickable: false),
                ),
              ],
            ),
            Divider(
              color: Colors.black12,
            ),
            Padding(
              padding: const EdgeInsets.only(left: 16.0, right: 16.0),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Row(
                          children: <Widget>[
                            Expanded(
                              flex: 2,
                              child: Row(
                                children: <Widget>[
                                  FlatButton(
                                    onPressed: () {},
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceAround,
                                      children: <Widget>[
                                        Text(
                                          "₹" +
                                              widget
                                                  ._contest
                                                  .prizeDetails[0]
                                                      ["totalPrizeAmount"]
                                                  .toString(),
                                          textAlign: TextAlign.left,
                                          style: TextStyle(
                                              color: Theme.of(context)
                                                  .primaryColorDark,
                                              fontSize: Theme.of(context)
                                                  .primaryTextTheme
                                                  .display1
                                                  .fontSize),
                                        ),
                                        Icon(
                                          Icons.chevron_right,
                                          color: Theme.of(context)
                                              .primaryColorDark,
                                        )
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              flex: 1,
                              child: Container(),
                            ),
                            Expanded(
                              flex: 1,
                              child: RaisedButton(
                                onPressed: () {},
                                color: Theme.of(context).primaryColorDark,
                                child: Text(
                                  "₹" + widget._contest.entryFee.toString(),
                                  style: TextStyle(color: Colors.white70),
                                ),
                              ),
                            )
                          ],
                        ),
                        Row(
                          children: <Widget>[
                            Expanded(
                              flex: 1,
                              child: Column(
                                children: <Widget>[
                                  Padding(
                                    padding: EdgeInsets.only(bottom: 5.0),
                                    child: Row(
                                      children: <Widget>[
                                        widget._contest.teamsAllowed > 1
                                            ? Tooltip(
                                                message: "You can use " +
                                                    widget._contest.bonusAllowed
                                                        .toString() +
                                                    "% of entry fee amount from bonus.",
                                                child: Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                          right: 4.0),
                                                  child: CircleAvatar(
                                                    backgroundColor:
                                                        Colors.redAccent,
                                                    maxRadius: 10.0,
                                                    child: Text(
                                                      "B",
                                                      style: TextStyle(
                                                          color: Colors.white70,
                                                          fontSize: Theme.of(
                                                                  context)
                                                              .primaryTextTheme
                                                              .caption
                                                              .fontSize),
                                                    ),
                                                  ),
                                                ),
                                              )
                                            : Container(),
                                        widget._contest.teamsAllowed > 1
                                            ? Text(
                                                widget._contest.bonusAllowed
                                                        .toString() +
                                                    "% bonus allowed.",
                                                style: TextStyle(
                                                    fontSize: Theme.of(context)
                                                        .primaryTextTheme
                                                        .caption
                                                        .fontSize),
                                              )
                                            : Container()
                                      ],
                                    ),
                                  ),
                                  Container(
                                    child: Row(
                                      children: <Widget>[
                                        widget._contest.teamsAllowed > 1
                                            ? Tooltip(
                                                message:
                                                    "You can participate with " +
                                                        widget._contest
                                                            .teamsAllowed
                                                            .toString() +
                                                        " different teams.",
                                                child: Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                          right: 4.0),
                                                  child: CircleAvatar(
                                                    backgroundColor:
                                                        Colors.redAccent,
                                                    maxRadius: 10.0,
                                                    child: Text(
                                                      "M",
                                                      style: TextStyle(
                                                          color: Colors.white70,
                                                          fontSize: Theme.of(
                                                                  context)
                                                              .primaryTextTheme
                                                              .caption
                                                              .fontSize),
                                                    ),
                                                  ),
                                                ),
                                              )
                                            : Container(),
                                        widget._contest.teamsAllowed > 1
                                            ? Text(
                                                "Maximum " +
                                                    widget._contest.teamsAllowed
                                                        .toString() +
                                                    " entries allowed.",
                                                style: TextStyle(
                                                    fontSize: Theme.of(context)
                                                        .primaryTextTheme
                                                        .caption
                                                        .fontSize),
                                              )
                                            : Container()
                                      ],
                                    ),
                                  )
                                ],
                              ),
                            ),
                            Expanded(
                              flex: 1,
                              child: Text(
                                widget._contest.joined.toString() +
                                    "/" +
                                    widget._contest.size.toString() +
                                    " joined",
                                textAlign: TextAlign.right,
                              ),
                            )
                          ],
                        )
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Divider(
              color: Colors.black12,
            ),
          ],
        ),
      ),
    );
  }
}
