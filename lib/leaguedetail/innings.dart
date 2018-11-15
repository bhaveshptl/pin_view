import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

import 'package:playfantasy/modal/league.dart';
import 'package:playfantasy/modal/myteam.dart';
import 'package:playfantasy/utils/apiutil.dart';
import 'package:playfantasy/modal/l1.dart' as L1;
import 'package:playfantasy/leaguedetail/inningdetail.dart';
import 'package:playfantasy/utils/sharedprefhelper.dart';

class Innings extends StatefulWidget {
  final L1.L1 l1Data;
  final League league;
  final List<League> leagues;
  final List<MyTeam> myTeams;
  final Function onSportChange;
  final GlobalKey<ScaffoldState> scaffoldKey;
  final Map<int, List<MyTeam>> mapContestTeams;

  Innings({
    this.league,
    this.l1Data,
    this.leagues,
    this.myTeams,
    this.scaffoldKey,
    this.onSportChange,
    this.mapContestTeams,
  });

  @override
  State<StatefulWidget> createState() => InningsState();
}

class InningsState extends State<Innings> {
  int _sportType;
  Map<String, dynamic> _inningsData;

  @override
  void initState() {
    super.initState();
    _getInitData();
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

  _getInitData() async {
    await _getSportsType();
    Future<dynamic> futureInitData =
        SharedPrefHelper().getFromSharedPref(ApiUtil.KEY_INIT_DATA);
    await futureInitData.then((onValue) {
      Map<String, dynamic> data = json.decode(onValue)["inningsData"];
      setState(() {
        _inningsData = _sportType == 1
            ? data["cricketInningsData"]
            : _sportType == 2
                ? data["footballInningsData"]
                : data["kabaddiInningsData"];
      });
    });
  }

  showInningDetails(BuildContext context, L1.Team team) async {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => InningDetails(
              team: team,
              league: widget.league,
              leagues: widget.leagues,
              onSportChange: widget.onSportChange,
            ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: 8.0),
      child: Column(
        children: <Widget>[
          Padding(
            padding: EdgeInsets.only(left: 8.0, right: 8.0),
            child: Card(
              elevation: 6.0,
              child: FlatButton(
                onPressed: () {
                  showInningDetails(
                      context, widget.l1Data.league.rounds[0].matches[0].teamA);
                },
                padding: EdgeInsets.all(8.0),
                child: Row(
                  children: <Widget>[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4.0),
                      child: CachedNetworkImage(
                        imageUrl: widget
                            .l1Data.league.rounds[0].matches[0].teamA.logoUrl,
                        placeholder: CircularProgressIndicator(),
                        errorWidget: Icon(Icons.error),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.only(left: 8.0),
                      child: Text(
                          widget.l1Data.league.rounds[0].matches[0].teamA.name +
                              " " +
                              "INNING"),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 8.0, right: 8.0),
            child: Card(
              elevation: 6.0,
              child: FlatButton(
                onPressed: () {
                  showInningDetails(
                      context, widget.l1Data.league.rounds[0].matches[0].teamB);
                },
                padding: EdgeInsets.all(8.0),
                child: Row(
                  children: <Widget>[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4.0),
                      child: CachedNetworkImage(
                        imageUrl: widget
                            .l1Data.league.rounds[0].matches[0].teamB.logoUrl,
                        placeholder: CircularProgressIndicator(),
                        errorWidget: Icon(Icons.error),
                        fit: BoxFit.cover,
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.only(left: 8.0),
                      child: Text(
                          widget.l1Data.league.rounds[0].matches[0].teamB.name +
                              " " +
                              "INNING"),
                    ),
                  ],
                ),
              ),
            ),
          ),
          _inningsData != null
              ? Container(
                  padding: EdgeInsets.only(top: 48.0),
                  child: Column(
                    children:
                        (_inningsData["body"] as List).map((dynamic text) {
                      return Padding(
                        padding: EdgeInsets.fromLTRB(16.0, 0.0, 16.0, 4.0),
                        child: Row(
                          children: <Widget>[
                            Padding(
                              padding: EdgeInsets.only(right: 8.0),
                              child: Icon(
                                Icons.chevron_right,
                                color: Colors.black45,
                              ),
                            ),
                            Expanded(
                              child: Text(
                                text.toString().replaceAll("<br /> ", "\n"),
                                style: TextStyle(
                                  color: Colors.black45,
                                  fontSize: Theme.of(context)
                                      .primaryTextTheme
                                      .subhead
                                      .fontSize,
                                ),
                                textAlign: TextAlign.left,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                )
              : Container(),
        ],
      ),
    );
  }
}
