import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:playfantasy/modal/l1.dart';
import 'package:playfantasy/modal/mysheet.dart';
import 'package:playfantasy/modal/prediction.dart';

import 'package:playfantasy/utils/apiutil.dart';
import 'package:playfantasy/utils/httpmanager.dart';
import 'package:playfantasy/utils/stringtable.dart';

class JoinPredictionContest extends StatefulWidget {
  final Contest contest;
  final Function onError;
  final Prediction prediction;
  final Function onCreateSheet;
  final List<MySheet> mySheets;

  JoinPredictionContest({
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
  int _selectedSheetId = -1;
  List<MySheet> _myUniqueSheets = [];

  double _cashBalance = 0.0;
  double _bonusBalance = 0.0;
  double _playableBonus = 0.0;

  @override
  void initState() {
    super.initState();
    _getUserBalance();
    getMyContestMySheets([widget.contest.id]);
  }

  _joinContest(BuildContext context) async {
    if (_selectedSheetId == null || _selectedSheetId == -1) {
      widget.onCreateSheet(
        context,
        widget.contest,
      );
    } else {
      http.Request req = http.Request(
          "POST", Uri.parse(BaseUrl.apiUrl + ApiUtil.JOIN_PREDICTION_CONTEST));
      req.body = json.encode({
        "answerSheetId": _selectedSheetId,
        "contestId": widget.contest.id,
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
                "answerSheetId": _selectedSheetId,
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
      );
    }
  }

  _getUserBalance() async {
    http.Request req =
        http.Request("POST", Uri.parse(BaseUrl.apiUrl + ApiUtil.USER_BALANCE));
    req.body = json.encode({
      "leagueId": widget.contest.leagueId,
      "contestId": widget.contest == null ? "" : widget.contest.id
    });
    await HttpManager(http.Client()).sendRequest(req).then(
      (http.Response res) {
        if (res.statusCode >= 200 && res.statusCode <= 299) {
          Map<String, dynamic> response = json.decode(res.body);
          setState(() {
            _cashBalance =
                (response["withdrawable"] + response["depositBucket"])
                    .toDouble();
            _bonusBalance = (response["nonWithdrawable"]).toDouble();
            _playableBonus = response["playablebonus"].toDouble();
          });
        }
      },
    );
  }

  getMyContestMySheets(List<int> contests) {
    if (contests != null && contests.length > 0) {
      http.Request req = http.Request(
          "POST", Uri.parse(BaseUrl.apiUrl + ApiUtil.GET_MY_CONTEST_MY_SHEETS));
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
        _selectedSheetId = myUniqueSheets[0].id;
        _myUniqueSheets = myUniqueSheets;
      });
    }
  }

  List<DropdownMenuItem> _getSheetList() {
    List<DropdownMenuItem> lstSheets = [];
    if (_myUniqueSheets != null && _myUniqueSheets.length > 0) {
      for (MySheet answerSheet in _myUniqueSheets) {
        lstSheets.add(
          DropdownMenuItem(
            child: Container(
              child: Text(
                answerSheet.name == ""
                    ? answerSheet.id.toString()
                    : answerSheet.name,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            value: answerSheet.id,
          ),
        );
      }
    }
    lstSheets.add(
      DropdownMenuItem(
        child: Container(
          width: 110.0,
          child: Text("Create sheet"),
        ),
        value: -1,
      ),
    );
    return lstSheets;
  }

  @override
  Widget build(BuildContext context) {
    double bonusUsable = widget.contest == null
        ? 0.0
        : (widget.contest.entryFee * widget.contest.bonusAllowed) / 100;
    double usableBonus = widget.contest == null
        ? 0.0
        : _bonusBalance > bonusUsable
            ? (bonusUsable > _playableBonus ? _playableBonus : bonusUsable)
            : _bonusBalance;

    return AlertDialog(
      title: Text(strings.get("CONFIRMATION").toUpperCase()),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Column(
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Text(
                          strings.get("CASH").toUpperCase() + " ",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: Theme.of(context)
                                .primaryTextTheme
                                .body2
                                .fontSize,
                          ),
                        ),
                        Text(
                          strings.rupee + _cashBalance.toStringAsFixed(2),
                          style: TextStyle(
                            fontSize: Theme.of(context)
                                .primaryTextTheme
                                .caption
                                .fontSize,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Column(
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Text(
                          strings.get("BONUS").toUpperCase() + " ",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: Theme.of(context)
                                .primaryTextTheme
                                .body2
                                .fontSize,
                          ),
                        ),
                        Text(
                          strings.rupee + _bonusBalance.toStringAsFixed(2),
                          style: TextStyle(
                            fontSize: Theme.of(context)
                                .primaryTextTheme
                                .caption
                                .fontSize,
                          ),
                        ),
                      ],
                    )
                  ],
                )
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Text(
                  strings.get("ENTRY_FEE"),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: Theme.of(context).primaryTextTheme.body2.fontSize,
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: <Widget>[
                    (widget.contest != null && widget.contest.prizeType == 1)
                        ? Image.asset(
                            strings.chips,
                            width: 16.0,
                            height: 12.0,
                            fit: BoxFit.contain,
                          )
                        : Text(strings.rupee),
                    Text(
                      widget.contest.entryFee.toStringAsFixed(2),
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontSize:
                            Theme.of(context).primaryTextTheme.body2.fontSize,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Text(
                  strings.get("BONUS_USABLE"),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: Theme.of(context).primaryTextTheme.body2.fontSize,
                  ),
                ),
                Text(
                  strings.rupee + usableBonus.toStringAsFixed(2),
                  style: TextStyle(
                    fontSize: Theme.of(context).primaryTextTheme.body2.fontSize,
                  ),
                ),
              ],
            ),
          ),
          Divider(
            color: Colors.black12,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Text(
                strings.get("CASH_TO_PAY"),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: Theme.of(context).primaryTextTheme.body2.fontSize,
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: <Widget>[
                  (widget.contest != null && widget.contest.prizeType == 1)
                      ? Image.asset(
                          strings.chips,
                          width: 16.0,
                          height: 12.0,
                          fit: BoxFit.contain,
                        )
                      : Text(strings.rupee),
                  Text(
                    (widget.contest.entryFee - usableBonus).toStringAsFixed(2),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize:
                          Theme.of(context).primaryTextTheme.body2.fontSize,
                    ),
                    textAlign: TextAlign.right,
                  ),
                ],
              ),
            ],
          ),
          Divider(
            color: Colors.black12,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Text(
                "Sheets",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: Theme.of(context).primaryTextTheme.body2.fontSize,
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: <Widget>[
                  DropdownButton(
                    value: _selectedSheetId,
                    isDense: false,
                    items: _getSheetList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedSheetId = value;
                      });
                    },
                  )
                ],
              ),
            ],
          ),
        ],
      ),
      actions: <Widget>[
        FlatButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: Text(strings.get("CANCEL").toUpperCase()),
        ),
        FlatButton(
          onPressed: () {
            _joinContest(context);
          },
          child: Text(strings.get("JOIN").toUpperCase()),
        ),
      ],
    );
  }
}
