import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:playfantasy/action_utils/action_util.dart';
import 'package:playfantasy/commonwidgets/color_button.dart';
import 'package:playfantasy/commonwidgets/leadingbutton.dart';
import 'package:playfantasy/commonwidgets/scaffoldpage.dart';
import 'package:playfantasy/commonwidgets/textbox.dart';

import 'package:playfantasy/modal/l1.dart';
import 'package:playfantasy/modal/league.dart';
import 'package:playfantasy/utils/apiutil.dart';
import 'package:playfantasy/utils/httpmanager.dart';
import 'package:playfantasy/utils/stringtable.dart';
import 'package:playfantasy/contestdetail/contestdetail.dart';
import 'package:playfantasy/commonwidgets/fantasypageroute.dart';

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
      http.Request req = http.Request(
          "POST", Uri.parse(BaseUrl().apiUrl + ApiUtil.SEARCH_CONTEST));
      req.body = json.encode({
        "contestId": _contestCodeController.text,
      });
      await HttpManager(http.Client()).sendRequest(req).then(
        (http.Response res) {
          if (res.statusCode >= 200 && res.statusCode <= 299) {
            Map<String, dynamic> response = json.decode(res.body);
            Contest contest = Contest.fromJson(response["contest"]);
            League league = League.fromJson(response["league"]);
            if (league == null) {
              ActionUtil()
                  .showMsgOnTop(strings.get("LEAGUE_NOT_FOUND"), context);
              // _scaffoldKey.currentState.showSnackBar(
              //   SnackBar(
              //     content: Text(
              //       strings.get("LEAGUE_NOT_FOUND"),
              //     ),
              //   ),
              // );
            } else {
              Navigator.of(context).push(
                FantasyPageRoute(
                  routeSettings: RouteSettings(name: "ContestDetail"),
                  pageBuilder: (context) => ContestDetail(
                    contest: contest,
                    league: league,
                  ),
                ),
              );
            }
          } else {
            ActionUtil().showMsgOnTop(
                "Contest not available. Please check contest code.", context);
            // _scaffoldKey.currentState.showSnackBar(
            //   SnackBar(
            //     content: Text(
            //       "Contest not available. Please check contest code.",
            //     ),
            //   ),
            // );
          }
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldPage(
      scaffoldKey: _scaffoldKey,
      appBar: AppBar(
        leading: LeadingButton(),
        title: Text(
          strings.get("SEARCH_CONTEST").toUpperCase(),
        ),
        elevation: 0.0,
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
                          padding: EdgeInsets.fromLTRB(8.0, 24.0, 8.0, 8.0),
                          child: SimpleTextBox(
                            hintText: 'Contest code to search.',
                            validator: (value) {
                              if (value.isEmpty) {
                                return 'Contest code is required to search contest.';
                              }
                            },
                            controller: _contestCodeController,
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
                          padding: EdgeInsets.fromLTRB(8.0, 24.0, 8.0, 8.0),
                          child: Tooltip(
                            message: strings.get("SEARCH_CONTEST_WITH_CODE"),
                            child: Container(
                              height: 48.0,
                              child: ColorButton(
                                elevation: 0.0,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: <Widget>[
                                    Icon(
                                      Icons.search,
                                      color: Colors.white,
                                    ),
                                    Padding(
                                      padding: EdgeInsets.only(left: 8.0),
                                      child: Text(
                                        strings.get("SEARCH").toUpperCase(),
                                        style: Theme.of(context)
                                            .primaryTextTheme
                                            .title
                                            .copyWith(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w800,
                                            ),
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
