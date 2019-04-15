import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:playfantasy/action_utils/action_util.dart';

import 'package:playfantasy/modal/l1.dart';
import 'package:playfantasy/appconfig.dart';
import 'package:playfantasy/modal/league.dart';
import 'package:playfantasy/modal/mysheet.dart';
import 'package:playfantasy/utils/apiutil.dart';
import 'package:playfantasy/modal/prediction.dart';
import 'package:playfantasy/utils/httpmanager.dart';
import 'package:playfantasy/utils/stringtable.dart';
import 'package:playfantasy/profilepages/statedob.dart';
import 'package:playfantasy/utils/fantasywebsocket.dart';
import 'package:playfantasy/utils/joincontesterror.dart';
import 'package:playfantasy/commonwidgets/routelauncher.dart';
import 'package:playfantasy/prizestructure/prizestructure.dart';
import 'package:playfantasy/commonwidgets/fantasypageroute.dart';
import 'package:playfantasy/leaguedetail/prediction/joinpredictioncontest.dart';
import 'package:playfantasy/leaguedetail/prediction/predictioncontestcard.dart';
import 'package:playfantasy/leaguedetail/prediction/createsheet/createsheet.dart';
import 'package:playfantasy/leaguedetail/prediction/predictioncontestdetails.dart';

class PredictionView extends StatefulWidget {
  final scaffoldKey;
  final League league;
  final Function showLoader;
  final Prediction prediction;
  final List<MySheet> mySheets;
  final List<int> predictionContestIds;
  final Map<int, List<MySheet>> mapContestSheets;

  PredictionView({
    this.league,
    this.mySheets,
    this.prediction,
    this.showLoader,
    this.scaffoldKey,
    this.mapContestSheets,
    this.predictionContestIds,
  });

  @override
  PredictionViewState createState() => PredictionViewState();
}

class PredictionViewState extends State<PredictionView> {
  Contest _curContest;
  bool bShowJoinContest = false;
  bool bWaitingForTeamCreation = false;
  StreamSubscription _streamSubscription;

  @override
  void initState() {
    super.initState();
    _streamSubscription =
        FantasyWebSocket().subscriber().stream.listen(_onWsMsg);
  }

  _onWsMsg(data) {
    if (data["iType"] == RequestType.MY_SHEET_ADDED &&
        data["bSuccessful"] == true) {
      if (bShowJoinContest) {
        onJoinContest(_curContest);
      }
      bWaitingForTeamCreation = false;
    }
  }

  getSheetById(int id) {
    MySheet sheet;
    widget.mySheets.forEach((mySheet) {
      if (mySheet.id == id) {
        sheet = mySheet;
      }
    });
    return sheet;
  }

  onJoinContest(Contest contest) async {
    Quiz quiz = widget.prediction.quizSet.quiz["0"];
    if (widget.prediction.league.qfVisibility == 0 &&
        !(quiz != null &&
            quiz.questions != null &&
            quiz.questions.length > 0)) {
      widget.scaffoldKey.currentState.showSnackBar(SnackBar(
        content: Text(
            "Questions are not yet set for this prediction. Please try again later!!"),
      ));
      return null;
    }
    bShowJoinContest = false;
    ActionUtil().launchJoinPrediction(
      contest: contest,
      league: widget.league,
      mySheets: widget.mySheets,
      scaffoldKey: widget.scaffoldKey,
      predictionData: widget.prediction,
    );
  }

  onJoinContestError(
      Contest contest, Map<String, dynamic> errorResponse) async {
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
            message: strings.get("ALERT"),
            title: strings.get("NOT_VERIFIED"),
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
              child: Text(
                strings.get("OK").toUpperCase(),
              ),
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
    widget.showLoader(true);
    routeLauncher.launchAddCash(context, onSuccess: (result) {
      if (result != null) {
        onJoinContest(curContest);
      }
    }, onComplete: () {
      widget.showLoader(false);
    });
  }

  void _onCreateSheet(BuildContext context, Contest contest) async {
    final curContest = contest;

    bWaitingForTeamCreation = true;
    if (AppConfig.of(context).channelId != "10") {
      Navigator.of(context).pop();
    }
    final result = await Navigator.of(context).push(
      FantasyPageRoute(
        pageBuilder: (context) => CreateSheet(
              league: widget.league,
              predictionData: widget.prediction,
              mode: SheetCreationMode.CREATE_SHEET,
            ),
      ),
    );

    if (result != null) {
      if (curContest != null) {
        if (bWaitingForTeamCreation) {
          _curContest = curContest;
          bShowJoinContest = true;
        } else {
          onJoinContest(curContest);
        }
      }
      widget.scaffoldKey.currentState.showSnackBar(
        SnackBar(
          content: Text(result),
        ),
      );
    }
    bWaitingForTeamCreation = false;
  }

  void _showPrizeStructure(Contest contest) async {
    widget.showLoader(true);
    List<dynamic> prizeStructure = await _getPrizeStructure(contest);
    widget.showLoader(false);
    if (prizeStructure != null) {
      showModalBottomSheet(
        context: context,
        builder: (BuildContext context) {
          return PrizeStructure(
            contest: contest,
            prizeStructure: prizeStructure,
          );
        },
      );
    }
  }

  _getPrizeStructure(Contest contest) async {
    http.Request req = http.Request(
      "GET",
      Uri.parse(BaseUrl().apiUrl +
          ApiUtil.GET_PREDICTION_PRIZESTRUCTURE +
          contest.id.toString()),
    );
    return HttpManager(http.Client()).sendRequest(req).then(
      (http.Response res) {
        if (res.statusCode >= 200 && res.statusCode <= 299) {
          return json.decode(res.body);
        } else {
          return Future.value(null);
        }
      },
    );
  }

  _onContestClick(Contest contest, League league) {
    Navigator.of(context).push(
      FantasyPageRoute(
        pageBuilder: (context) => PredictionContestDetail(
              league: league,
              contest: contest,
              mySheets: widget.mySheets,
              predictionData: widget.prediction,
              mapContestSheets: widget.mapContestSheets[contest.id],
            ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(top: 8.0),
      child: widget.prediction.contests.length == 0
          ? Padding(
              padding: EdgeInsets.all(16.0),
              child: Center(
                child: Text(
                  strings.get("CONTESTS_NOT_AVAILABLE"),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Theme.of(context).errorColor,
                    fontSize:
                        Theme.of(context).primaryTextTheme.headline.fontSize,
                  ),
                ),
              ),
            )
          : ListView.builder(
              itemCount: widget.prediction.contests.length,
              padding: EdgeInsets.only(bottom: 16.0),
              itemBuilder: (context, index) {
                bool bShowBrandInfo = index > 0
                    ? !((widget.prediction.contests[index - 1]).brand["info"] ==
                        widget.prediction.contests[index].brand["info"])
                    : true;

                return Padding(
                  padding: EdgeInsets.only(top: 8.0, right: 8.0, left: 8.0),
                  child: PredictionContestCard(
                    radius: BorderRadius.circular(
                      5.0,
                    ),
                    league: widget.league,
                    onJoin: onJoinContest,
                    onClick: _onContestClick,
                    bShowBrandInfo: bShowBrandInfo,
                    predictionData: widget.prediction,
                    onPrizeStructure: _showPrizeStructure,
                    contest: widget.prediction.contests[index],
                    myJoinedSheets: widget.mapContestSheets != null
                        ? widget.mapContestSheets[
                            widget.prediction.contests[index].id]
                        : null,
                  ),
                );
              },
            ),
    );
  }

  @override
  void dispose() {
    _streamSubscription.cancel();
    super.dispose();
  }
}
