import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:playfantasy/appconfig.dart';

import 'package:playfantasy/modal/league.dart';
import 'package:playfantasy/redux/actions/loader_actions.dart';
import 'package:playfantasy/utils/apiutil.dart';
import 'package:playfantasy/utils/httpmanager.dart';
import 'package:playfantasy/mymatches/my_matches_sport_tab.dart';

class MyMatches extends StatefulWidget {
  final int sportsId;
  final Function onSportChange;
  final Map<String, int> mapSportTypes;
  final Function changeBottomNavigationIndex;
  MyMatches({
    this.sportsId,
    this.mapSportTypes,
    this.onSportChange,
    this.changeBottomNavigationIndex,
  });

  @override
  MyMatchesState createState() => MyMatchesState();
}

class MyMatchesState extends State<MyMatches>
    with SingleTickerProviderStateMixin {
  int _sportType;
  List<League> _allLeagues;
  TabController _sportsController;
  Map<int, List<League>> myLeagues;
  Map<String, dynamic> myContestIds;

  void initState() {
    _sportType = widget.sportsId;
    _listenSportChange();
    _initializeMyLeagues();
    _getMyMatches(bShowLoader: false);
    super.initState();
  }

  _initializeMyLeagues() {
    myLeagues = {
      1: [],
      2: [],
      3: [],
    };
  }

  showLoader(bool bShow) {
    AppConfig.of(context)
        .store
        .dispatch(bShow ? LoaderShowAction() : LoaderHideAction());
  }

  _listenSportChange() {
    _sportsController =
        TabController(vsync: this, length: widget.mapSportTypes.keys.length);
    _sportsController.index = getSportTabIndex(_sportType);
    _sportsController.addListener(() {
      showLoader(true);
      if (!_sportsController.indexIsChanging) {
        _sportType = widget.mapSportTypes[
            widget.mapSportTypes.keys.toList()[_sportsController.index]];
        setState(() {
          _sportType = _sportType;
        });
        _initializeMyLeagues();
        widget.onSportChange(_sportsController.index);
        _getMyMatches(bShowLoader: true);
      }
    });
  }

  getSportTabIndex(sportType) {
    int i = 0;
    int tabIndex = 0;
    widget.mapSportTypes.keys.forEach((sport) {
      if (widget.mapSportTypes[sport] == sportType) {
        tabIndex = i;
      }
      i++;
    });
    return tabIndex;
  }

  int getLeagueIndex(List<League> _leagues, League _league) {
    int index = 0;
    for (League _curLeague in _leagues) {
      if (_curLeague.leagueId == _league.leagueId) {
        return index;
      }
      index++;
    }
    return -1;
  }

  _getMyMatches({bool bShowLoader = true}) async {
    if (bShowLoader) {
      showLoader(true);
    }
    var sporttype = _sportType;
    http.Request req = http.Request(
      "GET",
      Uri.parse(BaseUrl().apiUrl +
          ApiUtil.GET_MY_ALL_MATCHES +
          _sportType.toString()),
    );

    return HttpManager(http.Client())
        .sendRequest(req)
        .then((http.Response res) {
      if (res.statusCode >= 200 && res.statusCode <= 299) {
        print(_sportType);
        print(sporttype);
        print(_sportsController.indexIsChanging);
        showLoader(false);
        myContestIds = {};
        List<League> _leagues = [];
        Map<String, dynamic> response = json.decode(res.body);
        List<dynamic> _mapLeagues = response["myLeagues"];
        myContestIds = response["myContestIds"];

        for (dynamic league in _mapLeagues) {
          _leagues.add(League.fromJson(league));
        }

        _groupLeagues(_leagues);
      }
    }).whenComplete(() {
      showLoader(false);
    });
  }

  getLeagueFromId(leagueId) {
    League foundLeague;
    _allLeagues.forEach((League league) {
      if (league.leagueId.toString() == leagueId) {
        foundLeague = league;
      }
    });
    return foundLeague;
  }

  _groupLeagues(List<League> leagues) {
    _initializeMyLeagues();
    leagues.forEach((League league) {
      if (DateTime.fromMillisecondsSinceEpoch(league.matchStartTime)
                  .difference(DateTime.now())
                  .inMilliseconds <=
              0 &&
          league.status != LeagueStatus.COMPLETED) {
        league.status = LeagueStatus.LIVE;
      }
      myLeagues[league.status].add(league);
    });

    if (myLeagues[2] != null) {
      myLeagues[2].sort((a, b) {
        return b.matchStartTime - a.matchStartTime;
      });
    }
    if (myLeagues[3] != null) {
      myLeagues[3].sort((a, b) {
        return b.matchStartTime - a.matchStartTime;
      });
    }

    setState(() {
      myLeagues = myLeagues;
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Container(
          color: Colors.white,
          child: TabBar(
            controller: _sportsController,
            labelColor: Theme.of(context).primaryColor,
            unselectedLabelColor: Colors.black,
            labelStyle: Theme.of(context).primaryTextTheme.title.copyWith(
                  fontWeight: FontWeight.w700,
                ),
            indicator: UnderlineTabIndicator(
              borderSide: BorderSide(
                width: 4.0,
                color: Theme.of(context).primaryColor,
              ),
            ),
            tabs: widget.mapSportTypes.keys.map<Tab>((page) {
              return Tab(
                text: page,
              );
            }).toList(),
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _sportsController,
            physics: NeverScrollableScrollPhysics(),
            children: widget.mapSportTypes.keys.map<Widget>((sportType) {
              final sportsId = widget.mapSportTypes[sportType];
              return MyMatchesSportsTab(
                sportsType: sportsId,
                myLeagues: myLeagues,
                myContestIds: myContestIds,
                onLeagueStatusChange: () {
                  List<League> _leagues = [];
                  myLeagues.keys.forEach((int key) {
                    _leagues.addAll(myLeagues[key]);
                  });
                  _groupLeagues(_leagues);
                },
                onJoinContest: () {
                  widget.changeBottomNavigationIndex(0);
                },
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}
