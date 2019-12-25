import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flushbar/flushbar.dart';
import 'package:flutter/material.dart';
import 'package:playfantasy/action_utils/insifficientfund.dart';
import 'package:playfantasy/appconfig.dart';
import 'package:playfantasy/commonwidgets/fantasypageroute.dart';
import 'package:playfantasy/commonwidgets/routelauncher.dart';
import 'package:playfantasy/contestdetail/contestdetail.dart';
import 'package:playfantasy/createteam/createteam.dart';
import 'package:playfantasy/joincontest/joincontest.dart';
import 'package:playfantasy/joincontest/joincontestconfirmation.dart';
import 'package:playfantasy/joincontest/joincontestsuccess.dart';
import 'package:playfantasy/leaguedetail/prediction/joinpredictioncontest.dart';
import 'package:playfantasy/modal/l1.dart';
import 'package:playfantasy/modal/league.dart';
import 'package:playfantasy/modal/mysheet.dart';
import 'package:playfantasy/modal/myteam.dart';
import 'package:playfantasy/modal/prediction.dart';
import 'package:playfantasy/profilepages/statedob.dart';
import 'package:playfantasy/providers/user.dart';
import 'package:playfantasy/redux/actions/loader_actions.dart';
import 'package:playfantasy/utils/apiutil.dart';
import 'package:playfantasy/utils/httpmanager.dart';
import 'package:playfantasy/utils/joincontesterror.dart';
import 'package:playfantasy/utils/stringtable.dart';
import 'package:provider/provider.dart';

class ActionUtil {
  ActionUtil._internal();
  static final ActionUtil actionUtil = ActionUtil._internal();
  factory ActionUtil() => actionUtil;

  Flushbar flushbar;

  launchJoinContest({
    L1 l1Data,
    League league,
    Contest contest,
    int sportsType,
    List<MyTeam> myTeams,
    GlobalKey<ScaffoldState> scaffoldKey,
    Map<String, dynamic> createContestPayload,
    String launchPageSource,
  }) async {
    showLoader(scaffoldKey.currentContext, true);
    final balance = await routeLauncher.getUserBalance(
      leagueId: league.leagueId,
      contestId: contest == null ? null : contest.id,
    );
    showLoader(scaffoldKey.currentContext, false);
    final joinConfirmMsg = await showDialog(
      context: scaffoldKey.currentContext,
      builder: (BuildContext context) {
        return JoinContestConfirmation(
          userBalance: balance,
          entryFees: contest == null
              ? createContestPayload["entryFee"]
              : contest.entryFee,
          prizeType: contest == null
              ? createContestPayload["prizeType"]
              : contest.prizeType,
          bonusAllowed: contest == null ? 0 : contest.bonusAllowed,
        );
      },
    );
    if (joinConfirmMsg != null && joinConfirmMsg["confirm"]) {
      showLoader(scaffoldKey.currentContext, contest == null ? false : true);
      final result = await Navigator.of(scaffoldKey.currentContext).push(
        FantasyPageRoute(
          routeSettings: RouteSettings(name: "JoinContest"),
          pageBuilder: (context) => JoinContest(
            league: league,
            l1Data: l1Data,
            sportsType: sportsType,
            contest: contest,
            myTeams: myTeams,
            createContestPayload: createContestPayload,
            onError: ((Contest contest, Map<String, dynamic> errorResponse) {
              if (errorResponse["resultCode"] == -2) {
                showMsgOnTop(errorResponse["message"], context);
              } else {
                final result = onJoinContestError(
                  scaffoldKey.currentContext,
                  contest,
                  errorResponse,
                  createContestPayload: createContestPayload,
                  onJoin: () {
                    launchJoinContest(
                      league: league,
                      l1Data: l1Data,
                      sportsType: sportsType,
                      contest: contest,
                      myTeams: myTeams,
                      scaffoldKey: scaffoldKey,
                    );
                  },
                  userBalance: balance,
                );
              }
            }),
          ),
        ),
      );

      if (createContestPayload != null && result != null) {
        final response = json.decode(result);
        if (!response["error"]) {
          final createdContest = Contest.fromJson(response["contest"]);
          Navigator.of(scaffoldKey.currentContext).push(
            FantasyPageRoute(
              routeSettings: RouteSettings(name: "ContestDetail"),
              pageBuilder: (context) => ContestDetail(
                  l1Data: l1Data,
                  contest: createdContest,
                  league: league,
                  sportsType: sportsType,
                  myTeams: myTeams,
                  launchPageSource: "privateContest"),
            ),
          );

          onContestJoinSuccess(
            response["message"].toString(),
            scaffoldKey,
            l1Data,
            league,
            myTeams,
            (launchPageSource != null && launchPageSource == "jc_cc")
                ? "jc_cc"
                : "privateContest",
            balance,
          );
        } else {
          final result = onJoinContestError(
            scaffoldKey.currentContext,
            contest,
            response,
            userBalance: balance,
            createContestPayload: createContestPayload,
            onJoin: () {
              launchJoinContest(
                league: league,
                l1Data: l1Data,
                contest: contest,
                sportsType: sportsType,
                myTeams: myTeams,
                scaffoldKey: scaffoldKey,
              );
            },
          );
        }
      } else if (result != null) {
        User userData = Provider.of<User>(scaffoldKey.currentContext);
        userData.updateDepositBucket(
          double.parse((result["userBalance"]["depositBucket"]).toString()),
        );
        userData.updateWithdrawable(
          double.parse((result["userBalance"]["withdrawable"]).toString()),
        );

        onContestJoinSuccess(
          result["message"].toString(),
          scaffoldKey,
          l1Data,
          league,
          myTeams,
          launchPageSource != null ? launchPageSource : "",
          balance,
          sportId: sportsType,
          contests: (result["contests"] as List)
              .map((i) => Contest.fromJson(i))
              .toList(),
        );
      }
    }
  }

  onContestJoinSuccess(
    String message,
    GlobalKey<ScaffoldState> scaffoldKey,
    L1 l1Data,
    League league,
    List<MyTeam> myTeams,
    String launchPageSource,
    Map<String, dynamic> balance, {
    List<Contest> contests,
    int sportId,
  }) async {
    var leagueContestIds =
        await getMyContestIds(scaffoldKey.currentContext, sportId);
    List<dynamic> contestIds = leagueContestIds == null
        ? []
        : (leagueContestIds[league.leagueId.toString()]);
    Map<int, List<MyTeam>> myJoinedTeams;
    if (contestIds == null) {
      myJoinedTeams = {};
    } else {
      myJoinedTeams =
          await getMyContestTeams(scaffoldKey.currentContext, contestIds);
    }

    Map<String, dynamic> result = await showDialog(
      context: scaffoldKey.currentContext,
      builder: (BuildContext context) {
        return JoinContestSuccess(
          l1Data: l1Data,
          league: league,
          myTeams: myTeams,
          scaffoldKey: scaffoldKey,
          balance: balance,
          successMessage: message,
          myContestJoinedTeams: myJoinedTeams,
          sportId: sportId,
          contests: contests,
          onJoin: (Contest contest) {
            Navigator.of(context).pop();
            launchJoinContest(
              league: league,
              l1Data: l1Data,
              contest: contest,
              sportsType: sportId,
              myTeams: myTeams,
              scaffoldKey: scaffoldKey,
            );
          },
          launchPageSource: launchPageSource,
        );
      },
    );

    if (result != null) {
      if (result["userOption"] == "joinContest") {
        Navigator.of(scaffoldKey.currentContext).pop();
      } else if (result["userOption"] == "createTeam") {
        final result = await Navigator.of(scaffoldKey.currentContext).push(
          FantasyPageRoute(
            routeSettings: RouteSettings(name: "CreateTeam"),
            pageBuilder: (context) => CreateTeam(
              league: league,
              l1Data: l1Data,
            ),
          ),
        );

        if (result != null) {
          ActionUtil()
              .showMsgOnTop(result.toString(), scaffoldKey.currentContext);
        }
      }
    }
  }

  Future<dynamic> getMyContestIds(BuildContext context, int sporttype) async {
    showLoader(context, true);

    http.Request req = http.Request(
      "GET",
      Uri.parse(
          BaseUrl().apiUrl + ApiUtil.GET_MY_ALL_MATCHES + sporttype.toString()),
    );

    return await HttpManager(http.Client())
        .sendRequest(req)
        .then((http.Response res) {
      if (res.statusCode >= 200 && res.statusCode <= 299) {
        showLoader(context, false);
        Map<String, dynamic> response = json.decode(res.body);

        return response["myContestIds"];
      }
      return null;
    }).whenComplete(() {
      showLoader(context, false);
    });
  }

  Future<Map<int, List<MyTeam>>> getMyContestTeams(
      BuildContext context, List<dynamic> contestIds) async {
    http.Request req = http.Request(
        "POST", Uri.parse(BaseUrl().apiUrl + ApiUtil.GET_MY_CONTEST_MY_TEAMS));
    req.body = json.encode(contestIds);
    return await HttpManager(http.Client()).sendRequest(req).then(
      (http.Response res) {
        if (res.statusCode >= 200 && res.statusCode <= 299) {
          // Map<String, dynamic> response = json.decode(res.body);

          Map<int, List<MyTeam>> _mapContestMyTeams = {};
          Map<String, dynamic> response = json.decode(res.body);
          response.forEach((String key, dynamic value) {
            List<MyTeam> _myTeams =
                (value as List).map((i) => MyTeam.fromJson(i)).toList();
            _mapContestMyTeams[int.parse(key)] = _myTeams;
          });

          return _mapContestMyTeams;
        }
        return null;
      },
    ).whenComplete(() {
      ActionUtil().showLoader(context, false);
    });
  }

  showLoader(BuildContext context, bool bShow) {
    AppConfig.of(context).store.dispatch(
          bShow ? LoaderShowAction() : LoaderHideAction(),
        );
  }

  onJoinContestError(
      BuildContext context, Contest contest, Map<String, dynamic> errorResponse,
      {Function onJoin,
      Map<String, dynamic> userBalance,
      Map<String, dynamic> createContestPayload}) async {
    JoinContestError error;
    if (errorResponse["error"] == true) {
      error = JoinContestError([errorResponse["resultCode"]]);
    } else {
      error = JoinContestError(errorResponse["reasons"]);
    }

    double bonusUsable = createContestPayload == null
        ? (contest.entryFee == null || contest.bonusAllowed == null
            ? 0.0
            : (contest.entryFee * contest.bonusAllowed) / 100)
        : 0.0;
    double usableBonus = userBalance["bonusBalance"] > bonusUsable
        ? (bonusUsable > userBalance["playableBonus"]
            ? userBalance["playableBonus"]
            : bonusUsable)
        : userBalance["bonusBalance"];

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
        case 2:
          _showJoinContestError(
            context,
            title: "ERROR",
            message: "Contest is full. Please join another contest.",
          );
          break;
        case 3:
          final result = await showDialog(
            context: context,
            builder: (BuildContext context) {
              return StateDob();
            },
            barrierDismissible: false,
          );
          if (result["success"] && createContestPayload == null) {
            onJoin();
          }
          break;
        case 12:
          final result = await _showAddCashConfirmation(
              context,
              contest,
              double.parse(userBalance["cashBalance"].toString()).toInt(),
              usableBonus.toInt());
          if (result != null && result["launchJoinConfirmation"]) {
            routeLauncher.launchAddCash(
              context,
              source: "contestbalance",
              prefilledAmount: contest.entryFee - usableBonus > 25
                  ? contest.entryFee - usableBonus
                  : 25,
              onSuccess: (result) {
                if (result != null) {
                  onJoin();
                }
              },
            );
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

  launchJoinPrediction({
    League league,
    Contest contest,
    List<MySheet> mySheets,
    Prediction predictionData,
    GlobalKey<ScaffoldState> scaffoldKey,
  }) async {
    showLoader(scaffoldKey.currentContext, true);
    final balance = await routeLauncher.getUserQuizBalance(
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
          routeSettings: RouteSettings(name: "JoinPredictionContest"),
          pageBuilder: (context) => JoinPredictionContest(
            league: league,
            contest: contest,
            mySheets: mySheets,
            prediction: predictionData,
            onError: ((Contest contest, Map<String, dynamic> errorResponse) {
              final result = onJoinContestError(
                scaffoldKey.currentContext,
                contest,
                errorResponse,
                onJoin: () {
                  launchJoinPrediction(
                    league: league,
                    contest: contest,
                    mySheets: mySheets,
                    scaffoldKey: scaffoldKey,
                    predictionData: predictionData,
                  );
                },
              );
            }),
          ),
        ),
      );

      if (result != null) {
        final msg = json.decode(result)["message"];
        showMsgOnTop(msg, scaffoldKey.currentContext);
        // scaffoldKey.currentState.showSnackBar(SnackBar(content: Text("$msg")));
      }
    }
  }

  showMsgOnTop(String msg, BuildContext context) {
    flushbar = Flushbar(
      boxShadows: [
        BoxShadow(
          blurRadius: 15.0,
          spreadRadius: 15.0,
          color: Colors.black12,
        )
      ],
      flushbarStyle: FlushbarStyle.FLOATING,
      messageText: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              msg,
              style: Theme.of(context).primaryTextTheme.subhead.copyWith(
                    color: Colors.black,
                  ),
            ),
          ),
          InkWell(
            child: Icon(
              Icons.close,
              color: Colors.black,
            ),
            onTap: () {
              flushbar.dismiss(true);
            },
          ),
        ],
      ),
      //aroundPadding: EdgeInsets.all(8.0),
      backgroundColor: Colors.white,
      duration: Duration(seconds: 3),
      flushbarPosition: FlushbarPosition.TOP,
    );
    flushbar.show(context);
  }

  _showAddCashConfirmation(
      BuildContext context, Contest contest, int userBalance, int usableBonus) {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return InsufficientFundDialog(
          contestFee: contest.entryFee,
          userBalance: userBalance + usableBonus,
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
