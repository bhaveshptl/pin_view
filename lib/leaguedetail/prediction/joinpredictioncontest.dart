import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:playfantasy/appconfig.dart';
import 'package:playfantasy/leaguedetail/prediction/viewsheet.dart';

import 'package:playfantasy/modal/l1.dart';
import 'package:playfantasy/modal/league.dart';
import 'package:playfantasy/modal/mysheet.dart';
import 'package:playfantasy/redux/actions/loader_actions.dart';
import 'package:playfantasy/utils/apiutil.dart';
import 'package:playfantasy/modal/prediction.dart';
import 'package:playfantasy/utils/httpmanager.dart';
import 'package:playfantasy/utils/fantasywebsocket.dart';
import 'package:playfantasy/action_utils/action_util.dart';
import 'package:playfantasy/commonwidgets/leaguetitle.dart';
import 'package:playfantasy/commonwidgets/color_button.dart';
import 'package:playfantasy/commonwidgets/scaffoldpage.dart';
import 'package:playfantasy/commonwidgets/fantasypageroute.dart';
import 'package:playfantasy/leaguedetail/prediction/createsheet/createsheet.dart';

class JoinPredictionContest extends StatefulWidget {
  final League league;
  final Contest contest;
  final Function onError;
  final Prediction prediction;
  final Function onCreateSheet;
  final List<MySheet> mySheets;

  JoinPredictionContest({
    this.league,
    this.contest,
    this.onError,
    this.mySheets,
    this.prediction,
    this.onCreateSheet,
  });

  @override
  JoinPredictionContestState createState() => JoinPredictionContestState();
}

class JoinPredictionContestState extends State<JoinPredictionContest> {
  MySheet _sheetToJoin;
  List<MySheet> _mySheets;
  List<MySheet> _myUniqueSheets = [];
  List<MySheet> contestMySheets = [];
  GlobalKey<ScaffoldState> scaffoldKey;
  StreamSubscription _streamSubscription;

  @override
  void initState() {
    super.initState();
    _mySheets = widget.mySheets;
    scaffoldKey = GlobalKey<ScaffoldState>();
    getMyContestMySheets([widget.contest.id]);
    _streamSubscription =
        FantasyWebSocket().subscriber().stream.listen(_onWsMsg);
  }

  _onWsMsg(data) {
    if (data["iType"] == RequestType.MY_SHEET_ADDED &&
        data["bSuccessful"] == true) {
      MySheet sheetAdded = MySheet.fromJson(data["data"]);
      int i = 0;
      bool bFound = false;
      for (MySheet _mySheet in _mySheets) {
        if (_mySheet.id == sheetAdded.id) {
          _mySheets[i] = sheetAdded;
          bFound = true;
        }
        i++;
      }
      if (!bFound) {
        _mySheets.add(sheetAdded);
      }
      setUniqueSheets(contestMySheets);
    }
  }

  _joinPrediction(BuildContext context) async {
    http.Request req = http.Request(
      "POST",
      Uri.parse(BaseUrl().apiUrl + ApiUtil.JOIN_PREDICTION_CONTEST),
    );
    req.body = json.encode({
      "contestId": widget.contest.id,
      "answerSheetId": _sheetToJoin.id,
      "channel_id": HttpManager.channelId,
      "leagueId": widget.contest.leagueId,
      "entryFee": widget.contest.entryFee,
      "prizeType": widget.contest.prizeType,
      "inningsId": widget.contest.inningsId,
      "serviceFee": widget.contest.serviceFee,
      "visibilityId": widget.contest.visibilityId,
      "bonusAllowed": widget.contest.bonusAllowed,
      "contestCode": widget.contest.contestJoinCode,
    });
    await HttpManager(http.Client()).sendRequest(req).then(
      (http.Response res) {
        if (res.statusCode >= 200 && res.statusCode <= 299) {
          Map<String, dynamic> response = json.decode(res.body);
          if (response["error"] != null) {
            Navigator.of(context).pop(json.encode({
              "message": response["message"],
              "contestId": widget.contest.id,
              "answerSheetId": _sheetToJoin.id,
              "error": response["error"],
            }));
          }
        } else if (res.statusCode == 401) {
          Map<String, dynamic> response = json.decode(res.body);
          if (response["error"]["reasons"].length > 0) {
            widget.onError(widget.contest, response["error"]);
          }
        }
      },
    ).whenComplete(() {
      showLoader(false);
    });
  }

  void _onCreateSheet(BuildContext context) async {
    final result = await Navigator.of(context).push(
      FantasyPageRoute(
        routeSettings: RouteSettings(name: "CreateSheet"),
        pageBuilder: (context) => CreateSheet(
              league: widget.league,
              predictionData: widget.prediction,
              mode: SheetCreationMode.CREATE_SHEET,
            ),
      ),
    );

    if (result != null) {
      scaffoldKey.currentState.showSnackBar(
        SnackBar(
          content: Text(result),
        ),
      );
    }
  }

  getMyContestMySheets(List<int> contests) {
    if (contests != null && contests.length > 0) {
      http.Request req = http.Request("POST",
          Uri.parse(BaseUrl().apiUrl + ApiUtil.GET_MY_CONTEST_MY_SHEETS));
      req.body = json.encode(contests);
      return HttpManager(http.Client())
          .sendRequest(req)
          .then((http.Response res) {
        if (res.statusCode >= 200 && res.statusCode <= 299) {
          Map<int, List<MySheet>> _mapContestMySheets = {};
          Map<String, dynamic> response = json.decode(res.body);
          if (response.keys.length > 0) {
            response.keys.forEach((k) {
              List<dynamic> sheetIds = response[k];
              List<MySheet> mySheets = [];
              sheetIds.forEach((sheetId) {
                widget.mySheets.forEach((sheet) {
                  if (sheet.id == sheetId) {
                    mySheets.add(sheet);
                  }
                });
              });
              if (mySheets.length > 0) {
                _mapContestMySheets[int.parse(k)] = mySheets;
              }
            });
          }
          setUniqueSheets(_mapContestMySheets[widget.contest.id] == null
              ? []
              : _mapContestMySheets[widget.contest.id]);
        }
      }).whenComplete(() {
        ActionUtil().showLoader(context, false);
      });
    }
  }

  setUniqueSheets(List<MySheet> contestMySheets) {
    List<MySheet> myUniqueSheets = [];
    for (MySheet sheet in widget.mySheets) {
      bool bIsSheetUsed = false;
      bool bIsSheetDraft = false;
      if (sheet.status == 0) {
        bIsSheetDraft = true;
      } else {
        for (MySheet contestSheet in contestMySheets) {
          if (sheet.id == contestSheet.id) {
            bIsSheetUsed = true;
            break;
          }
        }
      }
      if (!bIsSheetUsed && !bIsSheetDraft) {
        myUniqueSheets.add(sheet);
      }
    }
    if (myUniqueSheets.length > 0) {
      setState(() {
        _sheetToJoin = myUniqueSheets[0];
        _myUniqueSheets = myUniqueSheets;
      });
    }
  }

  showLoader(bool bShow) {
    AppConfig.of(context)
        .store
        .dispatch(bShow ? LoaderShowAction() : LoaderHideAction());
  }

  @override
  void dispose() {
    _streamSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldPage(
      scaffoldKey: scaffoldKey,
      appBar: AppBar(
        title: Text("My Teams".toUpperCase()),
        elevation: 0.0,
      ),
      body: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          LeagueTitle(
            league: widget.league,
          ),
          Row(
            children: <Widget>[
              Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 8.0),
                  child: Text(
                    "Choose answer sheet to join the prediction".toUpperCase(),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).primaryTextTheme.body1.copyWith(
                          color: Colors.black,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
              ),
            ],
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: _myUniqueSheets.map((MySheet sheet) {
                  return Row(
                    children: <Widget>[
                      Expanded(
                        child: Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Card(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4.0),
                            ),
                            clipBehavior: Clip.hardEdge,
                            child: FlatButton(
                              onPressed: () {
                                setState(() {
                                  _sheetToJoin = sheet;
                                });
                              },
                              padding: EdgeInsets.all(0.0),
                              child: Column(
                                children: <Widget>[
                                  Container(
                                    height: 40.0,
                                    color: Colors.grey.shade100,
                                    padding:
                                        EdgeInsets.symmetric(horizontal: 16.0),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: <Widget>[
                                        Row(
                                          children: <Widget>[
                                            Padding(
                                              padding:
                                                  EdgeInsets.only(right: 8.0),
                                              child: Container(
                                                decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  border: Border.all(
                                                    color: (_sheetToJoin ==
                                                                null ||
                                                            _sheetToJoin.id !=
                                                                sheet.id)
                                                        ? Colors.black
                                                        : Color.fromRGBO(
                                                            70, 165, 12, 1),
                                                    width: 1.0,
                                                  ),
                                                ),
                                                padding: EdgeInsets.all(2.0),
                                                child: (_sheetToJoin == null ||
                                                        _sheetToJoin.id !=
                                                            sheet.id)
                                                    ? CircleAvatar(
                                                        radius: 6.0,
                                                        backgroundColor:
                                                            Colors.transparent,
                                                      )
                                                    : CircleAvatar(
                                                        radius: 6.0,
                                                        backgroundColor:
                                                            Colors.white,
                                                        child: CircleAvatar(
                                                          radius: 6.0,
                                                          backgroundColor:
                                                              Color.fromRGBO(70,
                                                                  165, 12, 1),
                                                        ),
                                                      ),
                                              ),
                                            ),
                                            Text(
                                              sheet.name,
                                              style: Theme.of(context)
                                                  .primaryTextTheme
                                                  .subhead
                                                  .copyWith(
                                                    color: Colors.black,
                                                    fontWeight: FontWeight.w800,
                                                  ),
                                            ),
                                          ],
                                        ),
                                        InkWell(
                                          child: Container(
                                            height: 40.0,
                                            alignment: Alignment.center,
                                            child: Text(
                                              "Preview",
                                              style: Theme.of(context)
                                                  .primaryTextTheme
                                                  .button
                                                  .copyWith(
                                                    color: Colors.blue,
                                                    decoration: TextDecoration
                                                        .underline,
                                                  ),
                                            ),
                                          ),
                                          onTap: () {
                                            showLoader(true);
                                            Navigator.of(context).push(
                                              FantasyPageRoute(
                                                routeSettings: RouteSettings(name: "ViewSheet"),
                                                pageBuilder: (context) =>
                                                    ViewSheet(
                                                      sheet: sheet,
                                                      league: widget.league,
                                                      contest: widget.contest,
                                                      predictionData:
                                                          widget.prediction,
                                                    ),
                                                fullscreenDialog: true,
                                              ),
                                            );
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
          Container(
            height: 72.0,
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  spreadRadius: 1.0,
                  blurRadius: 2.0,
                  color: Colors.grey.shade300,
                )
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Expanded(
                  child: Container(
                    height: 48.0,
                    padding: EdgeInsets.only(right: 8.0, left: 40.0),
                    child: ColorButton(
                      onPressed: () {
                        _onCreateSheet(context);
                      },
                      color: Colors.orange,
                      child: Text(
                        "Create Sheet".toUpperCase(),
                        style:
                            Theme.of(context).primaryTextTheme.title.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Container(
                    height: 48.0,
                    padding: EdgeInsets.only(left: 8.0, right: 40.0),
                    child: ColorButton(
                      onPressed: _sheetToJoin == null
                          ? null
                          : () {
                              if (widget.contest != null) {
                                _joinPrediction(context);
                              }
                            },
                      child: Text(
                        "Join now".toUpperCase(),
                        style:
                            Theme.of(context).primaryTextTheme.title.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                ),
                      ),
                    ),
                  ),
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}
