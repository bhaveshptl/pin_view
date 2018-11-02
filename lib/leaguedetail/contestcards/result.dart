import 'package:flutter/material.dart';
import 'package:playfantasy/modal/l1.dart';
import 'package:playfantasy/modal/myteam.dart';
import 'package:playfantasy/utils/stringtable.dart';

class ResultContest extends StatelessWidget {
  final Contest contest;
  final Function onPrizeStructure;
  final List<MyTeam> myJoinedTeams;

  ResultContest({this.contest, this.myJoinedTeams, this.onPrizeStructure});

  MyTeam _getMyBestTeam() {
    myJoinedTeams.sort((a, b) {
      int teamARank = a.rank == null ? 0 : a.rank;
      int teamBRank = b.rank == null ? 0 : b.rank;
      return teamARank - teamBRank;
    });
    return myJoinedTeams[0];
  }

  double _getTotalWinnings() {
    double winnings = 0.0;
    if (myJoinedTeams != null) {
      for (MyTeam team in myJoinedTeams) {
        if (team.contestId == contest.id) {
          winnings += team.prize;
        }
      }
    }
    return winnings;
  }

  @override
  Widget build(BuildContext context) {
    MyTeam _myBestTeam = myJoinedTeams == null ? null : _getMyBestTeam();
    double _totalWinnings = _getTotalWinnings();

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
                          message: strings.get("NO_OF_WINNERS"),
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
                                        strings.get("WINNERS").toUpperCase(),
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
                      Container(
                        height: 20.0,
                        width: 1.0,
                        color: Colors.black12,
                      ),
                      Expanded(
                        child: Column(
                          children: <Widget>[
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: <Widget>[
                                Text(
                                  strings.get("WINNINGS"),
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Colors.black45,
                                    fontSize: Theme.of(context)
                                        .primaryTextTheme
                                        .caption
                                        .fontSize,
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: <Widget>[
                                Text(
                                  "₹" + _totalWinnings.toString(),
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                      color: Theme.of(context).primaryColorDark,
                                      fontSize: Theme.of(context)
                                          .primaryTextTheme
                                          .title
                                          .fontSize),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  Divider(
                    height: 2.0,
                    color: Colors.black12,
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 4.0, bottom: 4.0),
                    child: Row(
                      children: <Widget>[
                        Expanded(
                          flex: 1,
                          child: Column(
                            children: <Widget>[
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: <Widget>[
                                  Text(
                                    strings.get("JOINED"),
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: Colors.black45,
                                      fontSize: Theme.of(context)
                                          .primaryTextTheme
                                          .caption
                                          .fontSize,
                                    ),
                                  ),
                                ],
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: <Widget>[
                                  Text(
                                    contest.joined.toString(),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Container(
                          height: 20.0,
                          width: 1.0,
                          color: Colors.black12,
                        ),
                        Expanded(
                          flex: 2,
                          child: Column(
                            children: <Widget>[
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: <Widget>[
                                  Text(
                                    strings.get("BEST_TEAM"),
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: Colors.black45,
                                      fontSize: Theme.of(context)
                                          .primaryTextTheme
                                          .caption
                                          .fontSize,
                                    ),
                                  ),
                                ],
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: <Widget>[
                                  Text(
                                    _myBestTeam == null
                                        ? "-"
                                        : _myBestTeam.name,
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Container(
                          height: 20.0,
                          width: 1.0,
                          color: Colors.black12,
                        ),
                        Expanded(
                          flex: 1,
                          child: Column(
                            children: <Widget>[
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: <Widget>[
                                  Text(
                                    strings.get("RANK"),
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: Colors.black45,
                                      fontSize: Theme.of(context)
                                          .primaryTextTheme
                                          .caption
                                          .fontSize,
                                    ),
                                  ),
                                ],
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: <Widget>[
                                  Text(
                                    _myBestTeam == null
                                        ? "-"
                                        : _myBestTeam.rank.toString(),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Container(
                          height: 20.0,
                          width: 1.0,
                          color: Colors.black12,
                        ),
                        Expanded(
                          flex: 1,
                          child: Column(
                            children: <Widget>[
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: <Widget>[
                                  Text(
                                    strings.get("SCORE"),
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: Colors.black45,
                                      fontSize: Theme.of(context)
                                          .primaryTextTheme
                                          .caption
                                          .fontSize,
                                    ),
                                  ),
                                ],
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: <Widget>[
                                  Text(
                                    _myBestTeam == null
                                        ? "-"
                                        : _myBestTeam.score.toString(),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        )
      ],
    );
  }
}
