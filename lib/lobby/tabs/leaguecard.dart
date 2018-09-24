import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

import 'package:playfantasy/modal/league.dart';

const double TEAM_LOGO_HEIGHT = 24.0;

class LeagueCard extends StatelessWidget {
  final League _league;
  final bool clickable;
  final Function onClick;
  LeagueCard(this._league, {this.onClick, this.clickable = true});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(5.0, 2.0, 5.0, 2.0),
      child: Tooltip(
        message: _league.matchId.toString() + " - " + _league.matchName,
        child: Card(
          elevation: 3.0,
          child: FlatButton(
            padding: EdgeInsets.all(0.0),
            onPressed: () {
              if (clickable && onClick != null) {
                onClick(_league);
              }
            },
            child: Row(
              children: <Widget>[
                Expanded(
                  flex: 2,
                  child: Padding(
                    padding: EdgeInsets.all(7.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            Text(
                              _league.matchName,
                              style: TextStyle(
                                fontSize: Theme.of(context)
                                    .primaryTextTheme
                                    .caption
                                    .fontSize,
                                color: Colors.black54,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: <Widget>[
                            Expanded(
                              flex: 5,
                              child: Row(
                                children: <Widget>[
                                  Padding(
                                    padding: EdgeInsets.all(5.0),
                                    child: CachedNetworkImage(
                                      imageUrl: _league.teamA.logoUrl,
                                      placeholder: Container(
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.0,
                                        ),
                                        height: 18.0,
                                        width: 18.0,
                                      ),
                                      height: TEAM_LOGO_HEIGHT,
                                    ),
                                  ),
                                  Text(_league.teamA.name),
                                ],
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                "vs",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    fontSize: Theme.of(context)
                                        .primaryTextTheme
                                        .caption
                                        .fontSize,
                                    color: Colors.black54),
                              ),
                            ),
                            Expanded(
                              flex: 5,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: <Widget>[
                                  Text(_league.teamB.name),
                                  Padding(
                                    padding: EdgeInsets.all(5.0),
                                    child: CachedNetworkImage(
                                      imageUrl: _league.teamB.logoUrl,
                                      placeholder: Container(
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.0,
                                        ),
                                        height: 18.0,
                                        width: 18.0,
                                      ),
                                      height: TEAM_LOGO_HEIGHT,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          ],
                        )
                      ],
                    ),
                  ),
                ),
                Container(
                  height: 40.0,
                  width: 1.0,
                  color: Colors.black12,
                ),
                Expanded(
                  flex: 1,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      Text(
                        _league.status == LeagueStatus.COMPLETED
                            ? "Completed"
                            : (_league.status == LeagueStatus.LIVE
                                ? "In progress"
                                : "Timer"),
                        style: TextStyle(color: Theme.of(context).errorColor),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
