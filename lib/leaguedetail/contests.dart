import 'package:flutter/material.dart';

import 'package:playfantasy/modal/l1.dart';
import 'package:playfantasy/modal/league.dart';
import 'package:playfantasy/modal/myteam.dart';
import 'package:playfantasy/lobby/addcash.dart';
import 'package:playfantasy/utils/stringtable.dart';
import 'package:playfantasy/lobby/tabs/leaguecard.dart';
import 'package:playfantasy/utils/sharedprefhelper.dart';
import 'package:playfantasy/commonwidgets/statedob.dart';
import 'package:playfantasy/utils/joincontesterror.dart';
import 'package:playfantasy/leaguedetail/createteam.dart';
import 'package:playfantasy/leaguedetail/contestcard.dart';
import 'package:playfantasy/commonwidgets/joincontest.dart';
import 'package:playfantasy/contestdetail/contestdetail.dart';

class Contests extends StatefulWidget {
  final L1 l1Data;
  final League league;
  final List<MyTeam> myTeams;
  final Map<int, List<MyTeam>> mapContestTeams;
  final GlobalKey<ScaffoldState> scaffoldKey;

  Contests(
      {this.league,
      this.l1Data,
      this.myTeams,
      this.scaffoldKey,
      this.mapContestTeams});

  @override
  State<StatefulWidget> createState() => ContestsState();
}

class ContestsState extends State<Contests> {
  String cookie;
  List<Contest> _contests = [];
  @override
  void initState() {
    super.initState();
    _contests = widget.l1Data.contests;
  }

  _onContestClick(Contest contest, League league) {
    Navigator.of(context).push(
      new MaterialPageRoute(
        builder: (context) => ContestDetail(
              contest: contest,
              league: league,
              l1Data: widget.l1Data,
              myTeams: widget.myTeams,
            ),
      ),
    );
  }

  onJoinContest(Contest contest) async {
    if (widget.myTeams.length > 0) {
      final result = await showDialog(
        context: context,
        builder: (BuildContext context) {
          return JoinContest(
            contest: contest,
            myTeams: widget.myTeams,
            onCreateTeam: _onCreateTeam,
            matchId: widget.l1Data.league.rounds[0].matches[0].id,
            onError: onJoinContestError,
          );
        },
      );

      if (result != null) {
        widget.scaffoldKey.currentState
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
      widget.scaffoldKey.currentState
          .showSnackBar(SnackBar(content: Text("$result")));
      if (curContest != null) {
        onJoinContest(curContest);
      }
    }
  }

  onStateDobUpdate(String msg) {
    widget.scaffoldKey.currentState.showSnackBar(SnackBar(content: Text(msg)));
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

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: LeagueCard(
                widget.league,
                clickable: false,
              ),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 4.0),
          child: Divider(
            height: 2.0,
            color: Colors.black12,
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: _contests.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.all(0.0),
                child: ContestCard(
                  league: widget.league,
                  contest: _contests[index],
                  onClick: _onContestClick,
                  onJoin: onJoinContest,
                  myJoinedTeams: widget.mapContestTeams != null
                      ? widget.mapContestTeams[_contests[index].id]
                      : null,
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
