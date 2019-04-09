import 'package:flutter/material.dart';
import 'package:playfantasy/appconfig.dart';
import 'package:playfantasy/commonwidgets/fantasypageroute.dart';

import 'package:playfantasy/modal/league.dart';
import 'package:playfantasy/redux/actions/loader_actions.dart';
import 'package:playfantasy/utils/stringtable.dart';
import 'package:playfantasy/lobby/tabs/leaguecard.dart';
import 'package:playfantasy/leaguedetail/leaguedetail.dart';

class StatusTab extends StatelessWidget {
  final int sportType;
  final int leagueStatus;
  final Function onSportChange;
  final List<League> allLeagues;
  final List<League> statusLeagues;
  final Map<String, int> mapSportTypes;

  StatusTab({
    this.sportType,
    this.allLeagues,
    this.leagueStatus,
    this.statusLeagues,
    this.onSportChange,
    this.mapSportTypes,
  });

  showLoader(bool bShow, BuildContext context) {
    AppConfig.of(context)
        .store
        .dispatch(bShow ? LoaderShowAction() : LoaderHideAction());
  }

  onLeagueSelect(BuildContext context, League league) {
    showLoader(true, context);
    Navigator.of(context).push(
      FantasyPageRoute(
        pageBuilder: (context) => LeagueDetail(
              league,
              leagues: allLeagues,
              sportType: sportType,
              onSportChange: onSportChange,
              mapSportTypes: mapSportTypes,
            ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final noLeaguesMsg = leagueStatus == LeagueStatus.COMPLETED
        ? strings.get("NO_COMPLETED_MATCHES")
        : leagueStatus == LeagueStatus.LIVE
            ? strings.get("NO_RUNNING_MATCHES")
            : strings.get("NO_UPCOMING_MATCHES");

    if (statusLeagues.length > 0) {
      return ListView.builder(
        physics: ClampingScrollPhysics(),
        shrinkWrap: true,
        itemCount: statusLeagues.length,
        itemBuilder: (context, index) {
          return LeagueCard(
            statusLeagues[index],
            onClick: (league) {
              onLeagueSelect(context, league);
            },
          );
        },
      );
    } else {
      return Container(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              noLeaguesMsg,
              textAlign: TextAlign.center,
              style: Theme.of(context).primaryTextTheme.title.copyWith(
                    color: Theme.of(context).errorColor,
                  ),
            ),
          ],
        ),
      );
    }
  }
}
