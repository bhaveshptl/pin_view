import 'package:flutter/material.dart';
import 'package:playfantasy/commonwidgets/joincontest.dart';
import 'package:playfantasy/commonwidgets/statedob.dart';
import 'package:playfantasy/leaguedetail/createteam.dart';
import 'package:playfantasy/lobby/addcash.dart';
import 'package:playfantasy/lobby/tabs/leaguecard.dart';
import 'package:playfantasy/modal/l1.dart';
import 'package:playfantasy/modal/league.dart';
import 'package:playfantasy/modal/myteam.dart';
import 'package:playfantasy/utils/joincontesterror.dart';
import 'package:playfantasy/utils/sharedprefhelper.dart';
import 'package:playfantasy/utils/stringtable.dart';

class ContestDetail extends StatefulWidget {
  final L1 l1Data;
  final League league;
  final Contest contest;
  final List<MyTeam> myTeams;

  ContestDetail({this.league, this.l1Data, this.contest, this.myTeams});

  @override
  State<StatefulWidget> createState() => ContestDetailState();
}

class ContestDetailState extends State<ContestDetail> {
  String cookie;
  GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  onJoinContest(Contest contest) async {
    if (widget.myTeams.length > 0) {
      final result = await showDialog(
        context: context,
        builder: (BuildContext context) {
          return JoinContest(
            contest: contest,
            myTeams: widget.myTeams,
            matchId: widget.l1Data.league.rounds[0].matches[0].id,
            onError: onJoinContestError,
          );
        },
      );

      if (result != null) {
        _scaffoldKey.currentState
            .showSnackBar(SnackBar(content: Text("$result")));
      }
    } else {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text(strings.get("ALERT").toUpperCase()),
            content: Text(
              strings.get("CREATE_TEAM_WARNING"),
            ),
            actions: <Widget>[
              FlatButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text(
                  strings.get("CANCEL").toUpperCase(),
                ),
              ),
              FlatButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _onCreateTeam(context, contest);
                },
                child: Text(strings.get("CREATE").toUpperCase()),
              )
            ],
          );
        },
      );
    }
  }

  void _onCreateTeam(BuildContext context, Contest contest) async {
    final curContest = contest;
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CreateTeam(
              league: widget.league,
              l1Data: widget.l1Data,
            ),
      ),
    );

    if (result != null) {
      Navigator.of(context).pop();
      _scaffoldKey.currentState
          .showSnackBar(SnackBar(content: Text("$result")));
      if (curContest != null) {
        onJoinContest(curContest);
      }
    }
  }

  onJoinContestError(Contest contest, Map<String, dynamic> errorResponse) {
    JoinContestError error;
    if (errorResponse["error"] == true) {
      error = JoinContestError([errorResponse["resultCode"]]);
    } else {
      error = JoinContestError(errorResponse["reasons"]);
    }

    Navigator.of(context).pop();
    if (error.isBlockedUser()) {
      _showJoinContestError(
        title: error.getTitle(),
        message: error.getErrorMessage(),
      );
    } else {
      int errorCode = error.getErrorCode();
      switch (errorCode) {
        case 3:
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return StateDob();
            },
          );
          break;
        case 12:
          _showAddCashConfirmation(contest);
          break;
        case 6:
          _showJoinContestError(
            message: "Alert",
            title: "User is not verified.",
          );
          break;
      }
    }
  }

  _showJoinContestError({String title, String message}) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: <Widget>[
            FlatButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text("OK"),
            )
          ],
        );
      },
    );
  }

  _showAddCashConfirmation(Contest contest) {
    final curContest = contest;
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            strings.get("INSUFFICIENT_FUND").toUpperCase(),
          ),
          content: Text(
            strings.get("INSUFFICIENT_FUND_MSG"),
          ),
          actions: <Widget>[
            FlatButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                strings.get("CANCEL").toUpperCase(),
              ),
            ),
            FlatButton(
              onPressed: () {
                Navigator.of(context).pop();
                _launchDepositJourneyForJoinContest(curContest);
              },
              child: Text(
                strings.get("DEPOSIT").toUpperCase(),
              ),
            )
          ],
        );
      },
    );
  }

  _launchDepositJourneyForJoinContest(Contest contest) async {
    final curContest = contest;
    if (cookie == null) {
      Future<dynamic> futureCookie = SharedPrefHelper.internal().getCookie();
      await futureCookie.then((value) {
        setState(() {
          cookie = value;
        });
      });
    }

    final result = await Navigator.of(context).push(new MaterialPageRoute(
        builder: (context) => AddCash(
              cookie: cookie,
            ),
        fullscreenDialog: true));
    if (result == true) {
      onJoinContest(curContest);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
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
                  child: LeagueCard(widget.league, clickable: false),
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
                                                  .contest
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
                                onPressed: () {
                                  onJoinContest(widget.contest);
                                },
                                color: Theme.of(context).primaryColorDark,
                                child: Text(
                                  "₹" + widget.contest.entryFee.toString(),
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
                                        widget.contest.teamsAllowed > 1
                                            ? Tooltip(
                                                message: "You can use " +
                                                    widget.contest.bonusAllowed
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
                                        widget.contest.teamsAllowed > 1
                                            ? Text(
                                                widget.contest.bonusAllowed
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
                                        widget.contest.teamsAllowed > 1
                                            ? Tooltip(
                                                message:
                                                    "You can participate with " +
                                                        widget.contest
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
                                        widget.contest.teamsAllowed > 1
                                            ? Text(
                                                "Maximum " +
                                                    widget.contest.teamsAllowed
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
                                widget.contest.joined.toString() +
                                    "/" +
                                    widget.contest.size.toString() +
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
