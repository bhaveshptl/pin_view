import 'dart:convert';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_webview_plugin/flutter_webview_plugin.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:playfantasy/commonwidgets/color_button.dart';

import 'package:playfantasy/modal/l1.dart';
import 'package:playfantasy/modal/myteam.dart';
import 'package:playfantasy/utils/apiutil.dart';
import 'package:playfantasy/utils/httpmanager.dart';
import 'package:playfantasy/utils/stringtable.dart';

class JoinContest extends StatefulWidget {
  final L1 l1Data;
  final int sportsType;
  final Contest contest;
  final Function onError;
  final List<MyTeam> myTeams;
  final Function onCreateTeam;
  final Map<String, dynamic> createContestPayload;

  JoinContest({
    this.l1Data,
    this.contest,
    this.myTeams,
    this.onError,
    this.sportsType,
    this.onCreateTeam,
    this.createContestPayload,
  });

  @override
  State<StatefulWidget> createState() => JoinContestState();
}

class JoinContestState extends State<JoinContest> {
  String cookie = "";
  int _selectedTeamId = -1;
  List<MyTeam> _myUniqueTeams = [];

  double _cashBalance = 0.0;
  double _bonusBalance = 0.0;
  double _playableBonus = 0.0;

  TapGestureRecognizer termsGesture = TapGestureRecognizer();

  @override
  void initState() {
    super.initState();
    if (widget.contest != null) {
      getMyContestTeams();
    } else {
      setUniqueTeams([]);
    }
    _getUserBalance();
    termsGesture.onTap = () {
      _launchStaticPage("T&C");
    };
  }

  _joinContest(BuildContext context) async {
    if (_selectedTeamId == null || _selectedTeamId == -1) {
      widget.onCreateTeam(
        context,
        widget.contest,
      );
    } else {
      http.Request req = http.Request(
          "POST", Uri.parse(BaseUrl().apiUrl + ApiUtil.JOIN_CONTEST));
      req.body = json.encode({
        "teamId": _selectedTeamId,
        "context": {"channel_id": HttpManager.channelId},
        "sportsId": widget.sportsType,
        "contestId": widget.contest.id,
        "leagueId": widget.contest.leagueId,
        "entryFee": widget.contest.entryFee,
        "prizeType": widget.contest.prizeType,
        "inningsId": widget.contest.inningsId,
        "realTeamId": widget.contest.realTeamId,
        "visibilityId": widget.contest.visibilityId,
        "bonusAllowed": widget.contest.bonusAllowed,
        "contestCode": widget.contest.contestJoinCode,
        "matchId": widget.l1Data.league.rounds[0].matches[0].id,
      });
      await HttpManager(http.Client()).sendRequest(req).then(
        (http.Response res) {
          if (res.statusCode >= 200 && res.statusCode <= 299) {
            Map<String, dynamic> response = json.decode(res.body);
            if (response["error"] == false) {
              Navigator.of(context).pop(response["message"]);
            } else if (response["error"] == true) {
              Navigator.of(context).pop(response["message"]);
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

  _createAndJoinContest(BuildContext context) async {
    if (_selectedTeamId == null || _selectedTeamId == -1) {
      widget.onCreateTeam(context, widget.contest,
          createContestPayload: widget.createContestPayload);
    } else {
      Map<String, dynamic> payload = widget.createContestPayload;
      payload["fanTeamId"] = _selectedTeamId;

      http.Request req = http.Request("POST",
          Uri.parse(BaseUrl().apiUrl + ApiUtil.CREATE_AND_JOIN_CONTEST));
      req.body = json.encode(payload);
      await HttpManager(http.Client()).sendRequest(req).then(
        (http.Response res) {
          if (res.statusCode >= 200 && res.statusCode <= 299) {
            Map<String, dynamic> response = json.decode(res.body);
            if (response["error"] == false) {
              Navigator.of(context).pop(res.body);
            } else if (response["error"] == true) {
              Navigator.of(context).pop(json.encode(response));
              // widget.onError(null, response["error"]);
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

  setUniqueTeams(List<dynamic> contestMyTeams) {
    List<MyTeam> myUniqueTeams = [];
    for (MyTeam team in widget.myTeams) {
      bool bIsTeamUsed = false;
      for (dynamic contestTeam in contestMyTeams) {
        if (team.id == contestTeam["id"]) {
          bIsTeamUsed = true;
          break;
        }
      }
      if (!bIsTeamUsed) {
        myUniqueTeams.add(team);
      }
    }
    if (myUniqueTeams.length > 0) {
      setState(() {
        _selectedTeamId = myUniqueTeams[0].id;
        _myUniqueTeams = myUniqueTeams;
      });
    }
  }

  getMyContestTeams() async {
    http.Request req = http.Request(
        "POST", Uri.parse(BaseUrl().apiUrl + ApiUtil.GET_MY_CONTEST_MY_TEAMS));
    req.body = json.encode([widget.contest.id]);
    await HttpManager(http.Client()).sendRequest(req).then(
      (http.Response res) {
        if (res.statusCode >= 200 && res.statusCode <= 299) {
          Map<String, dynamic> response = json.decode(res.body);
          if (response[widget.contest.id.toString()] != null) {
            List<dynamic> contestMyTeams =
                (response[widget.contest.id.toString()] as List);
            setUniqueTeams(contestMyTeams);
          } else {
            setState(() {
              setUniqueTeams([]);
            });
          }
        }
      },
    );
  }

  _getUserBalance() async {
    http.Request req = http.Request(
        "POST", Uri.parse(BaseUrl().apiUrl + ApiUtil.USER_BALANCE));
    req.body = json.encode({
      "contestId": widget.contest == null ? "" : widget.contest.id,
      "leagueId": widget.contest == null
          ? widget.createContestPayload["leagueId"]
          : widget.contest.leagueId
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

  List<DropdownMenuItem> _getTeamList() {
    List<DropdownMenuItem> listTeams = [];
    if (_myUniqueTeams != null && _myUniqueTeams.length > 0) {
      for (MyTeam team in _myUniqueTeams) {
        listTeams.add(
          DropdownMenuItem(
            child: Container(
              child: Text(
                team.name,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            value: team.id,
          ),
        );
      }
    }
    listTeams.add(
      DropdownMenuItem(
        child: Container(
          width: 110.0,
          child: Text(strings.get("CREATE_TEAM")),
        ),
        value: -1,
      ),
    );
    return listTeams;
  }

  _launchStaticPage(String name) {
    String url = "";
    String title = "";
    switch (name.toUpperCase()) {
      case "T&C":
        title = "TERMS AND CONDITIONS";
        url = BaseUrl().staticPageUrls["TERMS"];
        break;
    }
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => WebviewScaffold(
              url: url,
              clearCache: true,
              appBar: AppBar(
                title: Text(title),
              ),
            ),
        fullscreenDialog: true,
      ),
    );
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

    final formatCurrency = NumberFormat.currency(
      locale: "hi_IN",
      symbol: strings.rupee,
      decimalDigits: 2,
    );

    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(5.0),
      ),
      elevation: 0.0,
      title: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              strings.get("CONFIRMATION").toUpperCase(),
              style: Theme.of(context).primaryTextTheme.title.copyWith(
                    color: Colors.black,
                    fontWeight: FontWeight.w800,
                  ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
      contentPadding: EdgeInsets.all(0.0),
      content: Container(
        width: MediaQuery.of(context).size.width,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Padding(
              padding:
                  const EdgeInsets.only(top: 24.0, left: 24.0, right: 24.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Text(
                    "Current Balance:",
                    style: Theme.of(context).primaryTextTheme.body2.copyWith(
                          fontWeight: FontWeight.w900,
                          color: Theme.of(context).primaryColor,
                        ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: <Widget>[
                      (widget.contest == null &&
                                  widget.createContestPayload["prizeType"] ==
                                      1) ||
                              (widget.contest != null &&
                                  widget.contest.prizeType == 1)
                          ? Image.asset(
                              strings.chips,
                              width: 16.0,
                              height: 12.0,
                              fit: BoxFit.contain,
                            )
                          : Container(),
                      Text(
                        formatCurrency.format(_cashBalance),
                        textAlign: TextAlign.right,
                        style:
                            Theme.of(context).primaryTextTheme.body2.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).primaryColor,
                                ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: Divider(
                color: Colors.black26,
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Text(
                    "Joining Amount:",
                    style: Theme.of(context).primaryTextTheme.body2.copyWith(
                          fontWeight: FontWeight.w900,
                          color: Colors.black,
                        ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: <Widget>[
                      (widget.contest == null &&
                                  widget.createContestPayload["prizeType"] ==
                                      1) ||
                              (widget.contest != null &&
                                  widget.contest.prizeType == 1)
                          ? Image.asset(
                              strings.chips,
                              width: 16.0,
                              height: 12.0,
                              fit: BoxFit.contain,
                            )
                          : Container(),
                      Text(
                        widget.contest == null
                            ? formatCurrency
                                .format(widget.createContestPayload["entryFee"])
                            : formatCurrency.format(widget.contest.entryFee),
                        textAlign: TextAlign.right,
                        style:
                            Theme.of(context).primaryTextTheme.body2.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: Colors.black,
                                ),
                      ),
                    ],
                  )
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(24.0, 16.0, 24.0, 0.0),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      "Usable Cash Bonus: " +
                          formatCurrency.format(_playableBonus) +
                          " OR " +
                          widget.contest.bonusAllowed.toString() +
                          "% of the total Entry* per match(whichever is higher)",
                      style:
                          Theme.of(context).primaryTextTheme.caption.copyWith(
                                color: Colors.black38,
                                fontWeight: FontWeight.w800,
                              ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(24.0, 16.0, 24.0, 0.0),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: RichText(
                      text: TextSpan(
                        style:
                            Theme.of(context).primaryTextTheme.caption.copyWith(
                                  color: Colors.black38,
                                  fontWeight: FontWeight.w800,
                                ),
                        children: [
                          TextSpan(
                            children: [
                              TextSpan(
                                text:
                                    "By joining this contest, you accept Howzat's",
                              ),
                              TextSpan(
                                text: " T&C ",
                                style: TextStyle(
                                  decoration: TextDecoration.underline,
                                  color: Colors.blue,
                                ),
                                recognizer: termsGesture,
                              ),
                              TextSpan(
                                text:
                                    "and confirm that you are not a resident of Assam, Odisha, Telangana, Nagaland or Sikkim.",
                              )
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(24.0, 16.0, 24.0, 0.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Text(
                    strings.get("TEAM"),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize:
                          Theme.of(context).primaryTextTheme.body2.fontSize,
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: <Widget>[
                      DropdownButton(
                        value: _selectedTeamId,
                        isDense: false,
                        items: _getTeamList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedTeamId = value;
                          });
                        },
                      )
                    ],
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(vertical: 24.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  ColorButton(
                    onPressed: () {
                      if (widget.contest != null) {
                        _joinContest(context);
                      } else if (widget.createContestPayload != null) {
                        _createAndJoinContest(context);
                      }
                    },
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                          vertical: 12.0, horizontal: 20.0),
                      child: Text(
                        "Join now".toUpperCase(),
                        style: Theme.of(context)
                            .primaryTextTheme
                            .title
                            .copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w800),
                      ),
                    ),
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
