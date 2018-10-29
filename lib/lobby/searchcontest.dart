import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'package:playfantasy/modal/l1.dart';
import 'package:playfantasy/modal/league.dart';
import 'package:playfantasy/utils/apiutil.dart';
import 'package:playfantasy/utils/stringtable.dart';
import 'package:playfantasy/utils/sharedprefhelper.dart';
import 'package:playfantasy/contestdetail/contestdetail.dart';

class SearchContest extends StatefulWidget {
  final List<League> leagues;

  SearchContest({this.leagues});

  @override
  State<StatefulWidget> createState() => SearchContestState();
}

class SearchContestState extends State<SearchContest> {
  String cookie = "";
  final _formKey = GlobalKey<FormState>();
  GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _contestCodeController = TextEditingController();

  _getLeague(int leagueId) {
    League _league;
    widget.leagues.forEach((League league) {
      if (league.leagueId == leagueId) {
        _league = league;
      }
    });
    return _league;
  }

  _onSearchContest() async {
    if (_formKey.currentState.validate()) {
      if (cookie == null || cookie == "") {
        Future<dynamic> futureCookie = SharedPrefHelper.internal().getCookie();
        await futureCookie.then((value) {
          cookie = value;
        });
      }

      await http.Client()
          .post(
        ApiUtil.SEARCH_CONTEST,
        headers: {'Content-type': 'application/json', "cookie": cookie},
        body: json.encode({"contestId": _contestCodeController.text}),
      )
          .then(
        (http.Response res) {
          if (res.statusCode >= 200 && res.statusCode <= 299) {
            Contest contest = Contest.fromJson(json.decode(res.body)[0]);
            League league = _getLeague(contest.leagueId);
            if (league == null) {
              _scaffoldKey.currentState.showSnackBar(
                SnackBar(
                  content: Text(
                    strings.get("LEAGUE_NOT_FOUND"),
                  ),
                ),
              );
            } else {
              Navigator.of(context).push(
                new MaterialPageRoute(
                  builder: (context) => ContestDetail(
                        contest: contest,
                        league: league,
                      ),
                ),
              );
            }
          } else if (res.statusCode == 401) {}
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text(strings.get("SEARCH_CONTEST")),
      ),
      body: Form(
        key: _formKey,
        child: Row(
          children: <Widget>[
            Expanded(
              child: Column(
                children: <Widget>[
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Expanded(
                        child: Padding(
                          padding:
                              const EdgeInsets.fromLTRB(8.0, 24.0, 8.0, 8.0),
                          child: TextFormField(
                            decoration: InputDecoration(
                                hintText: 'Contest code to search.'),
                            validator: (value) {
                              if (value.isEmpty) {
                                return 'Contest code is required to search contest.';
                              }
                            },
                            controller: _contestCodeController,
                            onEditingComplete: () {
                              _onSearchContest();
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Expanded(
                        child: Padding(
                          padding:
                              const EdgeInsets.fromLTRB(8.0, 24.0, 8.0, 8.0),
                          child: Tooltip(
                            message: strings.get("SEARCH_CONTEST_WITH_CODE"),
                            child: RaisedButton(
                              color: Theme.of(context).primaryColorDark,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: <Widget>[
                                  Icon(
                                    Icons.search,
                                    color: Colors.white70,
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.only(left: 8.0),
                                    child: Text(
                                      strings.get("SEARCH").toUpperCase(),
                                      style: TextStyle(color: Colors.white70),
                                    ),
                                  ),
                                ],
                              ),
                              onPressed: () {
                                _onSearchContest();
                              },
                            ),
                          ),
                        ),
                      ),
                    ],
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
