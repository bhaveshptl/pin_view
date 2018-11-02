import 'package:flutter/material.dart';

import 'package:playfantasy/modal/l1.dart';
import 'package:playfantasy/modal/league.dart';
import 'package:playfantasy/modal/myteam.dart';
import 'package:playfantasy/leaguedetail/contestcards/live.dart';
import 'package:playfantasy/leaguedetail/contestcards/result.dart';
import 'package:playfantasy/leaguedetail/contestcards/upcoming.dart';

class ContestCard extends StatelessWidget {
  final L1 l1Data;
  final League league;
  final Contest contest;
  final Function onJoin;
  final Function onClick;
  final Function onPrizeStructure;
  final List<MyTeam> myJoinedTeams;

  ContestCard({
    this.l1Data,
    this.onJoin,
    this.league,
    this.contest,
    this.onClick,
    this.myJoinedTeams,
    this.onPrizeStructure,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: contest.id.toString() + " - " + contest.name,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(2.0, 0.0, 2.0, 4.0),
        child: Card(
          elevation: 3.0,
          clipBehavior: Clip.antiAliasWithSaveLayer,
          child: Stack(
            children: <Widget>[
              FlatButton(
                onPressed: () {
                  onClick(contest, league);
                },
                padding: EdgeInsets.all(0.0),
                child: (l1Data != null &&
                            l1Data.league.status == LeagueStatus.UPCOMING) ||
                        (l1Data == null &&
                            league.status == LeagueStatus.UPCOMING)
                    ? UpcomingContest(
                        onJoin: onJoin,
                        contest: contest,
                        myJoinedTeams: myJoinedTeams,
                        onPrizeStructure: onPrizeStructure,
                      )
                    : (l1Data != null &&
                            l1Data.league.status == LeagueStatus.LIVE)
                        ? LiveContest(
                            contest: contest,
                            myJoinedTeams: myJoinedTeams,
                            onPrizeStructure: onPrizeStructure,
                          )
                        : ResultContest(
                            contest: contest,
                            myJoinedTeams: myJoinedTeams,
                            onPrizeStructure: onPrizeStructure,
                          ),
              ),
              Banner(
                message: contest.brand["info"],
                location: BannerLocation.topStart,
                textStyle: TextStyle(fontSize: 10.0),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
