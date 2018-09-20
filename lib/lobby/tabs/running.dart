import 'package:flutter/material.dart';

import 'package:playfantasy/modal/league.dart';
import 'package:playfantasy/lobby/tabs/leaguecard.dart';

class Running extends StatelessWidget {
  final List<League> _allLeagues;
  Running(this._allLeagues);

  @override
  Widget build(BuildContext context) {
    if (_allLeagues.length > 0) {
      return ListView.builder(
        itemCount: _allLeagues.length,
        itemBuilder: (context, index) {
          return LeagueCard(_allLeagues[index]);
        },
      );
    } else {
      return Container(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              "There are no running matches.",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Theme.of(context).errorColor,
                fontSize: Theme.of(context).primaryTextTheme.display1.fontSize,
              ),
            ),
          ],
        ),
      );
    }
  }
}
