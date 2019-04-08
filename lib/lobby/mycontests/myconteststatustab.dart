import 'package:flutter/material.dart';
import 'package:playfantasy/lobby/mycontests/mycontestleaguecard.dart';
import 'package:playfantasy/modal/l1.dart';
import 'package:playfantasy/modal/league.dart';
import 'package:playfantasy/modal/mysheet.dart';
import 'package:playfantasy/modal/myteam.dart';
import 'package:playfantasy/utils/stringtable.dart';

class MyContestStatusTab extends StatefulWidget {
  final int tabStatus;
  final bool leagueContests;
  final List<League> leagues;
  final Function onContestDetails;
  final Function onJoinNormalContest;
  final Map<int, List<MySheet>> mapMySheets;
  final Function onJoinPredictionContest;
  final Map<int, List<MyTeam>> mapMyTeams;
  final Function onPredictionContestDetails;
  final Map<String, MyAllContest> mapContests;

  MyContestStatusTab({
    this.leagues,
    this.tabStatus,
    this.mapMyTeams,
    this.mapContests,
    this.mapMySheets,
    this.onContestDetails,
    this.onJoinNormalContest,
    this.leagueContests = false,
    this.onJoinPredictionContest,
    this.onPredictionContestDetails,
  });

  @override
  MyContestStatusTabState createState() => MyContestStatusTabState();
}

class MyContestStatusTabState extends State<MyContestStatusTab> {
  League getLeague(int _leagueId) {
    for (League _league in widget.leagues) {
      if (_league.leagueId == _leagueId) {
        return _league;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    List<String> leagues = widget.mapContests.keys.toList();
    final noLeaguesMsg = widget.leagueContests
        ? "You have not joined any contests for this match."
        : widget.tabStatus == LeagueStatus.COMPLETED
            ? strings.get("NO_COMPLETED_CONTEST")
            : widget.tabStatus == LeagueStatus.LIVE
                ? strings.get("NO_RUNNING_CONTEST")
                : strings.get("NO_UPCOMING_CONTEST");
    return Container(
      child: leagues.length != 0
          ? ListView.builder(
              itemCount: leagues.length,
              itemBuilder: (context, index) {
                League league = getLeague(int.parse(leagues[index]));
                if (league != null) {
                  return Padding(
                    padding: EdgeInsets.only(bottom: 16.0),
                    child: MyContestLeagueCard(
                      league: league,
                      mapMyTeams: widget.mapMyTeams,
                      mapMySheets: widget.mapMySheets,
                      onContestDetails: widget.onContestDetails,
                      onJoinNormalContest: widget.onJoinNormalContest,
                      mapContests: widget.mapContests[leagues[index]],
                      onJoinPredictionContest: widget.onJoinPredictionContest,
                      onPredictionContestDetail:
                          widget.onPredictionContestDetails,
                    ),
                  );
                }
                return Container();
              },
            )
          : Column(
              mainAxisSize: MainAxisSize.max,
              children: <Widget>[
                Container(
                  padding: EdgeInsets.only(top: 32.0),
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          noLeaguesMsg,
                          style:
                              Theme.of(context).primaryTextTheme.title.copyWith(
                                    color: Colors.red,
                                  ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
