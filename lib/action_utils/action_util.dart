import 'package:flutter/material.dart';
import 'package:playfantasy/appconfig.dart';
import 'package:playfantasy/commonwidgets/fantasypageroute.dart';
import 'package:playfantasy/commonwidgets/routelauncher.dart';
import 'package:playfantasy/joincontest/joincontest.dart';
import 'package:playfantasy/joincontest/joincontestconfirmation.dart';
import 'package:playfantasy/modal/l1.dart';
import 'package:playfantasy/modal/league.dart';
import 'package:playfantasy/modal/myteam.dart';
import 'package:playfantasy/profilepages/statedob.dart';
import 'package:playfantasy/redux/actions/loader_actions.dart';
import 'package:playfantasy/utils/joincontesterror.dart';
import 'package:playfantasy/utils/stringtable.dart';

class ActionUtil {
  ActionUtil._internal();
  static final ActionUtil actionUtil = ActionUtil._internal();
  factory ActionUtil() => actionUtil;

  launchJoinContest({
    L1 l1Data,
    League league,
    Contest contest,
    List<MyTeam> myTeams,
    GlobalKey<ScaffoldState> scaffoldKey,
  }) async {
    showLoader(scaffoldKey.currentContext, true);
    final balance = await routeLauncher.getUserBalance(
        leagueId: league.leagueId, contestId: contest.id);
    showLoader(scaffoldKey.currentContext, false);
    final joinConfirmMsg = await showDialog(
      context: scaffoldKey.currentContext,
      builder: (BuildContext context) {
        return JoinContestConfirmation(
          userBalance: balance,
          entryFees: contest.entryFee,
          prizeType: contest.prizeType,
          bonusAllowed: contest.bonusAllowed,
        );
      },
    );
    if (joinConfirmMsg != null && joinConfirmMsg["confirm"]) {
      showLoader(scaffoldKey.currentContext, true);
      final result = await Navigator.of(scaffoldKey.currentContext).push(
        FantasyPageRoute(
          pageBuilder: (context) => JoinContest(
                league: league,
                l1Data: l1Data,
                contest: contest,
                myTeams: myTeams,
                onError:
                    ((Contest contest, Map<String, dynamic> errorResponse) {
                  final result = onJoinContestError(
                    scaffoldKey.currentContext,
                    contest,
                    errorResponse,
                    onJoin: () {
                      launchJoinContest(
                        league: league,
                        l1Data: l1Data,
                        contest: contest,
                        myTeams: myTeams,
                        scaffoldKey: scaffoldKey,
                      );
                    },
                  );
                }),
              ),
        ),
      );

      if (result != null) {
        scaffoldKey.currentState
            .showSnackBar(SnackBar(content: Text("$result")));
      }
    }
  }

  showLoader(context, bool bShow) {
    AppConfig.of(context).store.dispatch(
          bShow ? LoaderShowAction() : LoaderHideAction(),
        );
  }

  onJoinContestError(
      BuildContext context, Contest contest, Map<String, dynamic> errorResponse,
      {Function onJoin}) async {
    JoinContestError error;
    if (errorResponse["error"] == true) {
      error = JoinContestError([errorResponse["resultCode"]]);
    } else {
      error = JoinContestError(errorResponse["reasons"]);
    }

    Navigator.of(context).pop();
    if (error.isBlockedUser()) {
      _showJoinContestError(
        context,
        title: error.getTitle(),
        message: error.getErrorMessage(),
      );
    } else {
      int errorCode = error.getErrorCode();
      switch (errorCode) {
        case 3:
          final result = await showDialog(
            context: context,
            builder: (BuildContext context) {
              return StateDob();
            },
            barrierDismissible: false,
          );
          if (result["success"]) {
            onJoin();
          }
          break;
        case 12:
          final result = await _showAddCashConfirmation(context, contest);
          if (result["launchJoinConfirmation"]) {
            routeLauncher.launchAddCash(context, onSuccess: (result) {
              if (result != null) {
                onJoin();
              }
            });
          }
          break;
        case 6:
          _showJoinContestError(
            context,
            message: strings.get("ALERT"),
            title: strings.get("NOT_VERIFIED"),
          );
          break;
      }
    }
  }

  _showAddCashConfirmation(BuildContext context, Contest contest) {
    return showDialog(
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
                Navigator.pop(context, {
                  "launchJoinConfirmation": false,
                });
              },
              child: Text(
                strings.get("CANCEL").toUpperCase(),
              ),
            ),
            FlatButton(
              onPressed: () {
                Navigator.pop(context, {
                  "launchJoinConfirmation": true,
                });
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

  _showJoinContestError(BuildContext context, {String title, String message}) {
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
              child: Text(
                strings.get("OK").toUpperCase(),
              ),
            )
          ],
        );
      },
    );
  }
}
