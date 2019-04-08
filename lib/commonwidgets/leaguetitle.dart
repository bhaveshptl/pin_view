import 'package:flutter/material.dart';
import 'package:playfantasy/commonwidgets/epoc.dart';
import 'package:playfantasy/modal/league.dart';

class LeagueTitle extends StatelessWidget {
  final League league;
  LeagueTitle({this.league});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: kToolbarHeight,
      padding: EdgeInsets.symmetric(horizontal: 16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(
            color: Colors.black12,
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Text(
            league.teamA.name.toUpperCase() +
                " VS " +
                league.teamB.name.toUpperCase(),
            style: Theme.of(context).primaryTextTheme.body2.copyWith(
                  color: Colors.black,
                  fontWeight: FontWeight.w900,
                ),
          ),
          EPOC(
            timeInMiliseconds: league.matchStartTime,
            style: Theme.of(context).primaryTextTheme.body1.copyWith(
                  color: Theme.of(context).primaryColor,
                  fontWeight: FontWeight.w900,
                ),
          ),
        ],
      ),
    );
  }
}
