import 'package:flutter/material.dart';

import 'package:playfantasy/modal/l1.dart';
import 'package:playfantasy/modal/league.dart';
import 'package:playfantasy/modal/myteam.dart';
import 'package:playfantasy/leaguedetail/contestcards/live.dart';
import 'package:playfantasy/leaguedetail/contestcards/result.dart';
import 'package:playfantasy/leaguedetail/contestcards/upcoming.dart';

class ContestCard extends StatelessWidget {
  final League league;
  final Contest contest;
  final Function onJoin;
  final Function onClick;
  final List<MyTeam> myJoinedTeams;

  ContestCard(
      {this.contest,
      this.onClick,
      this.onJoin,
      this.league,
      this.myJoinedTeams});

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
                child: league.status == LeagueStatus.UPCOMING
                    ? UpcomingContest(
                        contest: contest,
                        myJoinedTeams: myJoinedTeams,
                        onJoin: onJoin,
                      )
                    : league.status == LeagueStatus.LIVE
                        ? LiveContest(
                            contest: contest,
                            myJoinedTeams: myJoinedTeams,
                          )
                        : ResultContest(
                            contest: contest,
                            myJoinedTeams: myJoinedTeams,
                          ),
              ),
              Banner(
                textStyle: TextStyle(fontSize: 10.0),
                message: contest.brand["info"],
                location: BannerLocation.topStart,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
