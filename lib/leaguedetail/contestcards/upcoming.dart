import 'package:flutter/material.dart';

import 'package:playfantasy/modal/l1.dart';
import 'package:playfantasy/modal/myteam.dart';

class UpcomingContest extends StatelessWidget {
  final Contest contest;
  final Function onJoin;
  final Function onPrizeStructure;
  final List<MyTeam> myJoinedTeams;

  UpcomingContest(
      {this.contest, this.myJoinedTeams, this.onJoin, this.onPrizeStructure});

  @override
  Widget build(BuildContext context) {
    bool bIsContestFull = myJoinedTeams != null &&
        (contest.teamsAllowed <= myJoinedTeams.length ||
            contest.size == contest.joined);
    return Column(
      children: <Widget>[
        Stack(
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Padding(
                  padding: EdgeInsets.fromLTRB(10.0, 5.0, 10.0, 5.0),
                  child: Text(
                    contest.name,
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: <Widget>[
                Padding(
                  padding: EdgeInsets.fromLTRB(10.0, 5.0, 10.0, 5.0),
                  child: Text(
                    "#" + contest.id.toString(),
                    textAlign: TextAlign.right,
                    style: TextStyle(color: Colors.black12),
                  ),
                ),
              ],
            )
          ],
        ),
        Divider(
          height: 2.0,
          color: Colors.black12,
        ),
        Row(
          children: <Widget>[
            Expanded(
              flex: 2,
              child: Column(
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          "₹" +
                              contest.prizeDetails[0]["totalPrizeAmount"]
                                  .toString(),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: Theme.of(context).primaryColorDark,
                              fontSize: Theme.of(context)
                                  .primaryTextTheme
                                  .headline
                                  .fontSize),
                        ),
                      ),
                      Container(
                        height: 20.0,
                        width: 1.0,
                        color: Colors.black12,
                      ),
                      Expanded(
                        child: Tooltip(
                          message: "Number of winners.",
                          child: FlatButton(
                            padding: EdgeInsets.all(0.0),
                            onPressed: () {
                              if (onPrizeStructure != null) {
                                onPrizeStructure(contest);
                              }
                            },
                            child: Column(
                              children: <Widget>[
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: <Widget>[
                                    Padding(
                                      padding:
                                          const EdgeInsets.only(left: 16.0),
                                      child: Text(
                                        "WINNERS",
                                        style: TextStyle(
                                          color: Colors.black45,
                                          fontSize: Theme.of(context)
                                              .primaryTextTheme
                                              .caption
                                              .fontSize,
                                        ),
                                      ),
                                    ),
                                    Icon(
                                      Icons.chevron_right,
                                      size: 16.0,
                                      color: Colors.black26,
                                    )
                                  ],
                                ),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: <Widget>[
                                    Text(contest.prizeDetails[0]["noOfPrizes"]
                                        .toString())
                                  ],
                                )
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  Container(
                    child: Padding(
                      padding: EdgeInsets.only(left: 10.0, bottom: 5.0),
                      child: Row(
                        children: <Widget>[
                          contest.bonusAllowed > 0
                              ? Tooltip(
                                  message: "You can use " +
                                      contest.bonusAllowed.toString() +
                                      "% of entry fee amount from bonus.",
                                  child: Padding(
                                    padding: const EdgeInsets.only(right: 8.0),
                                    child: CircleAvatar(
                                      backgroundColor: Colors.redAccent,
                                      maxRadius: 10.0,
                                      child: Text(
                                        "B",
                                        style: TextStyle(
                                            color: Colors.white70,
                                            fontSize: Theme.of(context)
                                                .primaryTextTheme
                                                .caption
                                                .fontSize),
                                      ),
                                    ),
                                  ),
                                )
                              : Container(),
                          contest.teamsAllowed > 1
                              ? Tooltip(
                                  message: "You can participate with " +
                                      contest.teamsAllowed.toString() +
                                      " different teams.",
                                  child: CircleAvatar(
                                    backgroundColor: Colors.redAccent,
                                    maxRadius: 10.0,
                                    child: Text(
                                      "M",
                                      style: TextStyle(
                                          color: Colors.white70,
                                          fontSize: Theme.of(context)
                                              .primaryTextTheme
                                              .caption
                                              .fontSize),
                                    ),
                                  ),
                                )
                              : Container(),
                          Expanded(
                            child: Text(
                              contest.joined.toString() +
                                  "/" +
                                  contest.size.toString() +
                                  " joined",
                              textAlign: TextAlign.center,
                            ),
                          )
                        ],
                      ),
                    ),
                  )
                ],
              ),
            ),
            Container(
              height: 40.0,
              width: 1.0,
              color: Colors.black12,
            ),
            Expanded(
              flex: 1,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: <Widget>[
                  Tooltip(
                    message: "Join contest with ₹" +
                        contest.entryFee.toString() +
                        " entry fee.",
                    child: RaisedButton(
                      onPressed: () {
                        if (!bIsContestFull && onJoin != null) {
                          onJoin(contest);
                        }
                      },
                      color: bIsContestFull
                          ? Theme.of(context).disabledColor
                          : Theme.of(context).primaryColorDark,
                      child: Row(
                        children: <Widget>[
                          myJoinedTeams != null && myJoinedTeams.length > 0
                              ? Icon(
                                  Icons.add,
                                  color: Colors.white70,
                                  size: 20.0,
                                )
                              : Container(),
                          Padding(
                            padding: const EdgeInsets.only(left: 8.0),
                            child: Text(
                              "₹" + contest.entryFee.toString(),
                              style: TextStyle(color: Colors.white70),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            )
          ],
        )
      ],
    );
  }
}
