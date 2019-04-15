import 'dart:async';
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_share_me/flutter_share_me.dart';
import 'package:playfantasy/commonwidgets/leaguetitle.dart';
import 'package:playfantasy/contestdetail/contestdetailscard.dart';
import 'package:playfantasy/leaguedetail/prediction/predictiondetailscard.dart';

import 'package:playfantasy/modal/l1.dart';
import 'package:playfantasy/appconfig.dart';
import 'package:playfantasy/modal/league.dart';
import 'package:playfantasy/modal/mysheet.dart';
import 'package:playfantasy/utils/apiutil.dart';
import 'package:playfantasy/modal/prediction.dart';
import 'package:playfantasy/utils/httpmanager.dart';
import 'package:playfantasy/utils/stringtable.dart';
import 'package:playfantasy/commonwidgets/loader.dart';
import 'package:playfantasy/profilepages/statedob.dart';
import 'package:playfantasy/lobby/tabs/leaguecard.dart';
import 'package:playfantasy/utils/fantasywebsocket.dart';
import 'package:playfantasy/utils/joincontesterror.dart';
import 'package:playfantasy/utils/sharedprefhelper.dart';
import 'package:playfantasy/contestdetail/contestdetail.dart';
import 'package:playfantasy/commonwidgets/routelauncher.dart';
import 'package:playfantasy/commonwidgets/gradientbutton.dart';
import 'package:playfantasy/prizestructure/prizestructure.dart';
import 'package:playfantasy/commonwidgets/fantasypageroute.dart';
import 'package:playfantasy/leaguedetail/prediction/viewsheet.dart';
import 'package:playfantasy/leaguedetail/prediction/joinpredictioncontest.dart';
import 'package:playfantasy/leaguedetail/prediction/createsheet/createsheet.dart';

class PredictionContestDetail extends StatefulWidget {
  final League league;
  final Contest contest;

  final List<MySheet> mySheets;
  final List<MySheet> mapContestSheets;
  final Prediction predictionData;

  PredictionContestDetail({
    this.league,
    this.contest,
    this.mySheets,
    this.predictionData,
    this.mapContestSheets,
  });

  @override
  State<StatefulWidget> createState() => PredictionContestDetailState();
}

class PredictionContestDetailState extends State<PredictionContestDetail>
    with RouteAware {
  int _sportType = 1;
  int _curPageOffset = 0;
  bool bShowLoader = false;
  final int rowsPerPage = 25;
  List<MySheet> mySheets = [];

  bool bShowJoinContest = false;
  bool bWaitingForSheetCreation = false;

  SheetDataSource _sheetDataSource;

  MySheet sheetToView;
  Prediction predictionData;
  List<MySheet> _mapContestSheets = [];
  StreamSubscription _streamSubscription;
  Map<String, dynamic> l1UpdatePackate = {};
  bool waitForPredictionDataToViewSheet = false;
  GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  initState() {
    super.initState();
    _streamSubscription =
        FantasyWebSocket().subscriber().stream.listen(_onWsMsg);
    _createAndReqL1WS();
    createDataSource();
    _mapContestSheets =
        widget.mapContestSheets == null ? [] : widget.mapContestSheets;
    _getContestSheets(0);
    if (_mapContestSheets.length == 0) {
      getMyContestMySheets();
    }
  }

  createDataSource() {
    _sheetDataSource = SheetDataSource(
        widget.league, widget.contest, widget.mySheets,
        onViewSheet: onViewSheet);
    _sheetDataSource.setMyContestSheets(widget.contest, _mapContestSheets);
    _sheetDataSource.changeLeagueStatus(widget.league.status);
  }

  _getSportsType() async {
    Future<dynamic> futureSportType =
        SharedPrefHelper.internal().getSportsType();
    await futureSportType.then((value) {
      if (value != null) {
        _sportType = int.parse(value);
      }
    });
  }

  _createAndReqL1WS() async {
    await _getSportsType();

    l1UpdatePackate["iType"] = RequestType.GET_ALL_L1;
    l1UpdatePackate["bResAvail"] = true;
    l1UpdatePackate["sportsId"] = _sportType;
    l1UpdatePackate["id"] = widget.league.leagueId;
    l1UpdatePackate["withPrediction"] = true;

    if (widget.mySheets == null || widget.predictionData == null) {
      _getL1Data();
    } else {
      predictionData = widget.predictionData;
      mySheets = widget.mySheets;
    }
  }

  onViewSheet(MySheet sheet) {
    if (predictionData == null) {
      sheetToView = sheet;
      waitForPredictionDataToViewSheet = true;
    } else {
      sheetToView = null;
      waitForPredictionDataToViewSheet = false;
      Navigator.of(context).push(
        FantasyPageRoute(
            pageBuilder: (context) => ViewSheet(
                  sheet: sheet,
                  league: widget.league,
                  contest: widget.contest,
                  mySheet: widget.mySheets,
                  predictionData: predictionData,
                ),
            fullscreenDialog: true),
      );
    }
  }

  _getL1Data() {
    FantasyWebSocket().sendMessage(l1UpdatePackate);
  }

  _onWsMsg(data) {
    if (data["iType"] == RequestType.GET_ALL_L1 &&
        data["bSuccessful"] == true) {
      if (waitForPredictionDataToViewSheet) {
        if (data["data"]["prediction"] != null) {
          predictionData = Prediction.fromJson(data["data"]["prediction"]);
        }
        if (data["data"]["mySheets"] != null &&
            data["data"]["mySheets"] != "") {
          mySheets = (data["data"]["mySheets"] as List<dynamic>).map((f) {
            return MySheet.fromJson(f);
          }).toList();
          _sheetDataSource.updateMyAllSheets(mySheets);
        }

        onViewSheet(sheetToView);
      } else {
        setState(() {
          if (data["data"]["prediction"] != null) {
            predictionData = Prediction.fromJson(data["data"]["prediction"]);
          }
          if (data["data"]["mySheets"] != null &&
              data["data"]["mySheets"] != "") {
            mySheets = (data["data"]["mySheets"] as List<dynamic>).map((f) {
              return MySheet.fromJson(f);
            }).toList();
            _sheetDataSource.updateMyAllSheets(mySheets);
          }
        });
      }
    } else if (data["iType"] == RequestType.MY_SHEET_ADDED &&
        data["bSuccessful"] == true) {
      MySheet sheetAdded = MySheet.fromJson(data["data"]);
      int existingIndex = -1;
      List<int>.generate(mySheets.length, (index) {
        MySheet mySheet = mySheets[index];
        if (mySheet.id == sheetAdded.id) {
          existingIndex = index;
        }
      });
      if (existingIndex == -1) {
        setState(() {
          mySheets.add(sheetAdded);
          _sheetDataSource.updateMyAllSheets(mySheets);
        });
      } else {
        setState(() {
          mySheets[existingIndex] = sheetAdded;
          _sheetDataSource.updateMyAllSheets(mySheets);
        });
      }

      if (bShowJoinContest) {
        joinPredictionContest(widget.contest);
      } else if (bWaitingForSheetCreation) {
        bWaitingForSheetCreation = false;
      }
    } else if (data["iType"] == RequestType.PREDICTION_DATA_UPDATE) {
      if (data["leagueId"] == widget.league.leagueId &&
          predictionData != null) {
        _applyPredictionUpdate(data["diffData"]);
      }
      getMyContestMySheets();
    }
  }

  _applyPredictionUpdate(List<dynamic> updates) {
    Map<String, dynamic> predictionJson = predictionData.toJson();
    updates.forEach((diff) {
      if (diff["kind"] == "E") {
        dynamic tmpData = predictionJson;
        List<int>.generate(diff["path"].length - 1, (index) {
          tmpData = tmpData[diff["path"][index]];
        });
        tmpData[diff["path"][diff["path"].length - 1]] = diff["rhs"];
      } else if (diff["kind"] == "A" && diff["item"]["kind"] == "N") {
        dynamic tmpData = predictionJson;
        List<int>.generate(diff["path"].length - 1, (index) {
          tmpData = tmpData[diff["path"][index]];
        });
        if (tmpData[diff["path"][diff["path"].length - 1]].length <=
            diff["index"]) {
          tmpData[diff["path"][diff["path"].length - 1]]
              .add(diff["item"]["rhs"]);
        }
      }
    });
    setState(() {
      predictionData = Prediction.fromJson(predictionJson);
      predictionData.contests.forEach((contest) {
        if (contest.id == widget.contest.id) {
          widget.contest.copyFrom(contest);
        }
      });

      if (_curPageOffset > (widget.contest.joined - rowsPerPage)) {
        _getContestSheets(_curPageOffset);
      }
    });
  }

  getMyContestMySheets() {
    http.Request req = http.Request(
        "POST", Uri.parse(BaseUrl().apiUrl + ApiUtil.GET_MY_CONTEST_MY_SHEETS));
    req.body = json.encode([widget.contest.id]);
    return HttpManager(http.Client())
        .sendRequest(req)
        .then((http.Response res) {
      if (res.statusCode >= 200 && res.statusCode <= 299) {
        Map<int, List<MySheet>> _mapContestMySheets = {};
        Map<String, dynamic> response = json.decode(res.body);
        response.keys.forEach((k) {
          List<dynamic> sheetIds = response[k];
          List<MySheet> _mySheets = [];
          sheetIds.forEach((sheetId) {
            mySheets.forEach((sheet) {
              if (sheet.id == sheetId) {
                _mySheets.add(sheet);
              }
            });
          });
          if (_mySheets.length > 0) {
            _mapContestMySheets[int.parse(k)] = _mySheets;
          }
        });
        setState(() {
          _mapContestSheets = _mapContestMySheets[widget.contest.id] == null
              ? []
              : _mapContestMySheets[widget.contest.id];
          _sheetDataSource.updateMyContestSheet(
              widget.contest, _mapContestSheets);
        });
      }
    });
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
    showLoader(true);
    routeLauncher.launchAddCash(context, onSuccess: (result) {
      if (result != null) {
        joinPredictionContest(contest);
      }
    }, onComplete: () {
      showLoader(false);
    });
  }

  joinPredictionContest(Contest contest) async {
    if (predictionData == null) {
      return null;
    }
    Quiz quiz = predictionData.quizSet.quiz["0"];
    if (predictionData.league.qfVisibility == 0 &&
        !(quiz != null &&
            quiz.questions != null &&
            quiz.questions.length > 0)) {
      _scaffoldKey.currentState.showSnackBar(SnackBar(
        content: Text(
            "Questions are not yet set for this prediction. Please try again later!!"),
      ));
      return null;
    }
    bShowJoinContest = false;
    if (mySheets.length > 0) {
      final result = await showDialog(
        context: context,
        builder: (BuildContext context) {
          return JoinPredictionContest(
            contest: contest,
            mySheets: mySheets,
            prediction: predictionData,
            onError: onJoinContestError,
            onCreateSheet: _onCreateSheet,
          );
        },
      );

      if (result != null) {
        final response = json.decode(result);
        if (!response["error"]) {
          MySheet sheet = getSheetById(response["answerSheetId"]);
          if (sheet != null) {
            if (_mapContestSheets == null) {
              _mapContestSheets = [];
            }
            setState(() {
              _mapContestSheets.add(sheet);
            });
          }
        }
        _scaffoldKey.currentState
            .showSnackBar(SnackBar(content: Text(response["message"])));
      }
    } else {
      if (AppConfig.of(context).channelId == "10") {
        _onCreateSheet(context, contest);
      } else {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text(strings.get("ALERT").toUpperCase()),
              content: Text(
                "No sheet created for this match. Please create one to join contest.",
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
                    _onCreateSheet(context, contest);
                  },
                  child: Text(strings.get("CREATE").toUpperCase()),
                )
              ],
            );
          },
        );
      }
    }
  }

  getSheetById(int id) {
    MySheet sheet;
    mySheets.forEach((mySheet) {
      if (mySheet.id == id) {
        sheet = mySheet;
      }
    });
    return sheet;
  }

  void _onCreateSheet(BuildContext context, Contest contest) async {
    final curContest = contest;
    bWaitingForSheetCreation = true;

    if (AppConfig.of(context).channelId != "10") {
      Navigator.of(context).pop();
    }

    final result = await Navigator.of(context).push(
      FantasyPageRoute(
        pageBuilder: (context) => CreateSheet(
              league: widget.league,
              predictionData: predictionData,
              mode: SheetCreationMode.CREATE_SHEET,
            ),
      ),
    );

    if (result != null) {
      _scaffoldKey.currentState.showSnackBar(
        SnackBar(
          content: Text(result),
        ),
      );
      if (curContest != null) {
        if (bWaitingForSheetCreation) {
          bShowJoinContest = true;
        } else {
          joinPredictionContest(curContest);
        }
      }
    }
  }

  showLoader(bool bShow) {
    setState(() {
      bShowLoader = bShow;
    });
  }

  void _showPrizeStructure() async {
    List<dynamic> prizeStructure = await _getPrizeStructure(widget.contest);
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return PrizeStructure(
          contest: widget.contest,
          prizeStructure: prizeStructure,
        );
      },
    );
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

  _shareContestDialog(BuildContext context) {
    String contestVisibility =
        widget.contest.visibilityId == 1 ? "PUBLIC" : "PRIVATE";
    String contestCode = widget.contest.contestJoinCode;
    String contestShareUrl = BaseUrl().contestShareUrl;
    String inviteMsg = AppConfig.of(context).appName.toUpperCase() +
        " - $contestVisibility LEAGUE \nHey! I created a Contest for our folks to play. Use this contest code *$contestCode* and join us. \n $contestShareUrl";

    FlutterShareMe().shareToSystem(msg: inviteMsg);
  }

  _getContestSheets(int offset) async {
    _curPageOffset = offset;
    int sheetListOffset = offset;
    if (offset == 0) {
      _sheetDataSource.setSheets(offset, _mapContestSheets);
    } else {
      sheetListOffset = offset - _mapContestSheets.length;
    }

    http.Request req = http.Request(
      "GET",
      Uri.parse(
        BaseUrl().apiUrl +
            ApiUtil.GET_CONTEST_SHEETS +
            widget.contest.id.toString() +
            "/answer-sheets/" +
            sheetListOffset.toString() +
            "/" +
            (offset == 0
                ? (rowsPerPage + _mapContestSheets.length).toString()
                : rowsPerPage.toString()),
      ),
    );
    return HttpManager(http.Client()).sendRequest(req).then(
      (http.Response res) {
        if (res.statusCode >= 200 && res.statusCode <= 299) {
          List<dynamic> response = json.decode(res.body);
          List<MySheet> _mySheets = [];
          List<MySheet> _sheets =
              response.map((i) => MySheet.fromJson(i)).toList();
          List<MySheet> uniqueSheets = [];
          _sheets.forEach((MySheet sheet) {
            bool bSheetFound = false;
            _mapContestSheets.forEach((MySheet mySheet) {
              if (sheet.id == mySheet.id) {
                bSheetFound = true;
              }
            });
            if (!bSheetFound) {
              uniqueSheets.add(sheet);
            } else {
              _mySheets.add(sheet);
            }
          });
          _mapContestSheets.forEach((sheet) {
            _mySheets.forEach((mySheet) {
              if (sheet.id == mySheet.id) {
                sheet.rank = mySheet.rank;
                sheet.score = mySheet.score;
                sheet.prize = mySheet.prize;
              }
            });
          });

          _sheetDataSource.updateMyContestSheet(
              widget.contest, _mapContestSheets);

          _sheetDataSource.setSheets(
              offset == 0 ? (offset + _mapContestSheets.length) : offset,
              uniqueSheets);
        }
      },
    );
  }

  List<DataColumn> _getDataTableHeader() {
    double width = MediaQuery.of(context).size.width - 20.0;
    List<DataColumn> _header = [
      DataColumn(
        onSort: (int index, bool bIsAscending) {},
        label: Container(
          padding: EdgeInsets.only(right: 4.0),
          width: width - (TABLE_COLUMN_PADDING * 2),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Container(
                child: Text(
                  strings.get("TEAMS"),
                ),
              ),
              widget.league.status == LeagueStatus.COMPLETED ||
                      widget.league.status == LeagueStatus.LIVE
                  ? Container(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: <Widget>[
                          Container(
                            width: 50.0,
                            child: Text(
                              strings.get("SCORE").toUpperCase(),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          Container(
                            width: 50.0,
                            child: Text(
                              strings.get("RANK").toUpperCase(),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          widget.league.status == LeagueStatus.COMPLETED
                              ? Container(
                                  width: 60.0,
                                  child: Text(
                                    strings.get("PRIZE").toUpperCase(),
                                    textAlign: TextAlign.center,
                                  ),
                                )
                              : Container(),
                        ],
                      ),
                    )
                  : Container(),
            ],
          ),
        ),
      ),
    ];

    return _header;
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    bool bIsContestFull = widget.contest.size <= widget.contest.joined ||
        (_mapContestSheets != null &&
            widget.contest.teamsAllowed <= _mapContestSheets.length) ||
        widget.league.status == LeagueStatus.LIVE ||
        widget.league.status == LeagueStatus.COMPLETED;
    final formatCurrency =
        NumberFormat.currency(locale: "hi_IN", symbol: "", decimalDigits: 0);

    _sheetDataSource.setWidth(width);
    _sheetDataSource.setContext(context);

    return Stack(
      children: <Widget>[
        Scaffold(
          key: _scaffoldKey,
          appBar: AppBar(
            title: Text(
              strings.get("CONTEST_DETAILS").toUpperCase(),
            ),
          ),
          body: Container(
            decoration: AppConfig.of(context).showBackground
                ? BoxDecoration(
                    image: DecorationImage(
                        image: AssetImage("images/background.png"),
                        repeat: ImageRepeat.repeat),
                  )
                : null,
            child: NestedScrollView(
              headerSliverBuilder:
                  (BuildContext context, bool innerBoxIsScrolled) {
                return <Widget>[
                  SliverPadding(
                    padding: new EdgeInsets.all(0.0),
                    sliver: new SliverList(
                      delegate: new SliverChildListDelegate(
                        [
                          LeagueTitle(
                            league: widget.league,
                          ),
                          PredictionDetailsCard(
                            league: widget.league,
                            contest: widget.contest,
                            predictionSheets: _mapContestSheets,
                            onJoinContest: (Contest contest) {
                              joinPredictionContest(contest);
                            },
                            onPrizeStructure: () {
                              _showPrizeStructure();
                            },
                            onShareContest: () {
                              _shareContestDialog(context);
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ];
              },
              body: Container(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Expanded(
                      child: ListView(
                        children: <Widget>[
                          widget.contest.joined == 0
                              ? Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                      16.0, 64.0, 16.0, 64.0),
                                  child: Center(
                                    child: Text(
                                      strings.get("NO_JOINED"),
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                          color: Theme.of(context).errorColor,
                                          fontSize: Theme.of(context)
                                              .primaryTextTheme
                                              .title
                                              .fontSize),
                                    ),
                                  ),
                                )
                              : PaginatedDataTable(
                                  header: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: <Widget>[
                                      Text(
                                        strings.get("LEADERBOARD"),
                                      ),
                                    ],
                                  ),
                                  rowsPerPage:
                                      widget.contest.joined < rowsPerPage
                                          ? (widget.contest.joined == 0
                                              ? 1
                                              : widget.contest.joined)
                                          : rowsPerPage,
                                  onPageChanged: (int firstVisibleIndex) {
                                    // if (firstVisibleIndex == 0) {
                                    //   getMyContestMySheets();
                                    // }
                                    _getContestSheets(firstVisibleIndex);
                                  },
                                  columns: _getDataTableHeader(),
                                  source: _sheetDataSource,
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
        bShowLoader ? Loader() : Container(),
      ],
    );
  }

  @override
  void dispose() {
    _streamSubscription.cancel();
    super.dispose();
  }
}

class SheetDataSource extends DataTableSource {
  int size;
  double width;
  League league;
  Contest contest;
  int _leagueStatus;
  Function onViewSheet;
  BuildContext context;
  Function onSwitchSheet;
  List<MySheet> _sheets = [];
  List<MySheet> myContestSheets;
  List<MySheet> _myAllSheets = [];
  List<MySheet> _myUniqueSheets = [];

  SheetDataSource(League _league, Contest _contest, List<MySheet> myAllSheets,
      {Function onViewSheet, Function onSwitchSheet}) {
    league = _league;
    this.contest = _contest;
    this.size = _contest.size;
    this.onViewSheet = onViewSheet;
    this.onSwitchSheet = onSwitchSheet;
    _leagueStatus = _league.status;
    this._myAllSheets = myAllSheets;
  }

  setMyContestSheets(Contest contest, List<MySheet> _myContestSheets) {
    this.size = contest.joined;
    myContestSheets = _myContestSheets;
    for (int i = 0; i < size; i++) {
      if (i < _myContestSheets.length) {
        _sheets.add(_myContestSheets[i]);
      } else {
        _sheets.add(MySheet());
      }
    }

    setUniqueSheets();
  }

  updateMyContestSheet(Contest contest, List<MySheet> _myContestSheets) {
    this.size = contest.joined;
    myContestSheets = _myContestSheets;

    for (int i = 0; i < myContestSheets.length; i++) {
      if (i >= _sheets.length) {
        _sheets.add(myContestSheets[i]);
      } else {
        _sheets[i] = myContestSheets[i];
      }
    }

    setUniqueSheets();
    this.notifyListeners();
  }

  updateMyAllSheets(List<MySheet> _sheets) {
    _myAllSheets = _sheets;

    setUniqueSheets();
    notifyListeners();
  }

  changeLeagueStatus(int _status) {
    _leagueStatus = _status;
  }

  setUniqueSheets() {
    List<MySheet> myUniqueSheets = [];
    for (MySheet sheet in (_myAllSheets == null ? [] : _myAllSheets)) {
      MySheet usedSheet;
      for (MySheet contestSheet in myContestSheets) {
        if (sheet.id == contestSheet.id) {
          usedSheet = contestSheet;
          break;
        }
      }
      if (usedSheet != null) {
        myUniqueSheets.add(usedSheet);
      }
    }
    _myUniqueSheets = myUniqueSheets;
  }

  setContext(BuildContext context) {
    this.context = context;
  }

  setWidth(double width) {
    this.width = width;
  }

  setSheets(int offset, List<MySheet> _sheets) {
    int curIndex = 0;
    int length = offset + _sheets.length;
    for (int i = offset; i < length; i++) {
      if (this._sheets.length <= i) {
        this._sheets.add(MySheet());
      }
      this._sheets[i] = _sheets[curIndex];
      curIndex++;
    }
    this.notifyListeners();
  }

  void updateSheets(int oldSheet, int newSheet) {
    _sheets.forEach((MySheet sheet) {
      if (sheet.id == oldSheet) {}
    });
  }

  @override
  DataRow getRow(int index) {
    assert(index >= 0);
    if (index >= _sheets.length) return null;
    final MySheet _sheet = _sheets[index];

    return DataRow.byIndex(
      index: index,
      cells: _getBody(_sheet, index < myContestSheets.length),
    );
  }

  List<DataCell> _getBody(MySheet _sheet, bool bIsMyJoinedSheet) {
    List<DataCell> _header = [
      DataCell(
        Container(
          width: width - (TABLE_COLUMN_PADDING * 2),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Text(
                      _sheet.name == null
                          ? ""
                          : _sheet.name.length >= 15
                              ? _sheet.name.substring(0, 14) + "..."
                              : _sheet.name,
                    ),
                    bIsMyJoinedSheet
                        ? Padding(
                            padding: EdgeInsets.only(right: 4.0),
                            child: Icon(
                              Icons.people,
                              color: Colors.black26,
                            ),
                          )
                        : Container(),
                  ],
                ),
              ),
              _leagueStatus == LeagueStatus.UPCOMING
                  ? Row(
                      mainAxisSize: MainAxisSize.max,
                      children: <Widget>[
                        // bIsMyJoinedSheet
                        //     ? Padding(
                        //         padding: const EdgeInsets.only(right: 8.0),
                        //         child: Container(
                        //           width: 72.0,
                        //           child: OutlineButton(
                        //             padding: EdgeInsets.all(0.0),
                        //             shape: RoundedRectangleBorder(
                        //               borderRadius: BorderRadius.circular(24.0),
                        //             ),
                        //             color: Theme.of(context).primaryColorDark,
                        //             onPressed: () {
                        //               onSwitchSheet(_sheet, _myUniqueSheets);
                        //             },
                        //             child: Text(
                        //               strings.get("SWITCH").toUpperCase(),
                        //               style: TextStyle(fontSize: 10.0),
                        //             ),
                        //           ),
                        //         ),
                        //       )
                        //     : Container(),
                        bIsMyJoinedSheet
                            ? Icon(Icons.chevron_right)
                            : Container(),
                      ],
                    )
                  : Row(
                      children: <Widget>[
                        Container(
                          width: 50.0,
                          child: Text(
                            _sheet.score != null
                                ? _sheet.score.toString()
                                : "-",
                            textAlign: TextAlign.center,
                          ),
                        ),
                        Container(
                          width: 50.0,
                          child: Text(
                            _sheet.score != null ? _sheet.rank.toString() : "-",
                            textAlign: TextAlign.center,
                          ),
                        ),
                        _leagueStatus == LeagueStatus.COMPLETED
                            ? Container(
                                width: 60.0,
                                child: Text(
                                  _sheet.score != null
                                      ? _sheet.prize.toStringAsFixed(2)
                                      : "-",
                                  textAlign: TextAlign.center,
                                ),
                              )
                            : Container(),
                        _sheet.score != null
                            ? Icon(Icons.chevron_right)
                            : Container(
                                width: 20.0,
                              )
                      ],
                    ),
            ],
          ),
        ),
        onTap: () {
          if (_sheet != null &&
              _sheet.id != null &&
              ((bIsMyJoinedSheet && _leagueStatus == LeagueStatus.UPCOMING) ||
                  _leagueStatus != LeagueStatus.UPCOMING)) {
            onViewSheet(_sheet);
          }
        },
      ),
    ];

    return _header;
  }

  @override
  int get rowCount => size;

  @override
  bool get isRowCountApproximate => false;

  @override
  int get selectedRowCount => 0;
}
