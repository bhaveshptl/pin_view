import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_svg/svg.dart';

import 'package:playfantasy/modal/league.dart';
import 'package:playfantasy/commonwidgets/epoc.dart';

const double TEAM_LOGO_HEIGHT = 32.0;

class LeagueCard extends StatelessWidget {
  final TabBar tabBar;
  final League _league;
  final bool clickable;
  final Function onClick;
  LeagueCard(this._league, {this.onClick, this.tabBar, this.clickable = true});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(5.0, 2.0, 5.0, 2.0),
      child: Tooltip(
        message: _league != null && _league.matchId != null
            ? _league.matchId.toString() + " - " + _league.matchName
            : "",
        child: Card(
          elevation: 3.0,
          clipBehavior: Clip.antiAliasWithSaveLayer,
          child: Stack(
            children: <Widget>[
              FlatButton(
                padding: EdgeInsets.all(0.0),
                onPressed: () {
                  if (clickable && onClick != null) {
                    onClick(_league);
                  }
                },
                child: Column(
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Expanded(
                          flex: 2,
                          child: Padding(
                            padding: EdgeInsets.fromLTRB(24.0, 8.0, 24.0, 8.0),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[
                                Padding(
                                  padding:
                                      EdgeInsets.only(top: 8.0, bottom: 8.0),
                                  child: Row(
                                    children: <Widget>[
                                      Column(
                                        children: <Widget>[
                                          Row(
                                            children: <Widget>[
                                              Padding(
                                                padding: EdgeInsets.only(
                                                  left: 12.0,
                                                  right: 16.0,
                                                ),
                                                child: Column(
                                                  children: <Widget>[
                                                    ClipRRect(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              2.0),
                                                      child: CachedNetworkImage(
                                                        imageUrl:
                                                            _league.teamA !=
                                                                    null
                                                                ? _league.teamA
                                                                    .logoUrl
                                                                : "",
                                                        placeholder: Container(
                                                          padding:
                                                              EdgeInsets.all(
                                                                  4.0),
                                                          child:
                                                              CircularProgressIndicator(
                                                            strokeWidth: 2.0,
                                                          ),
                                                          width:
                                                              TEAM_LOGO_HEIGHT,
                                                          height:
                                                              TEAM_LOGO_HEIGHT,
                                                        ),
                                                        height:
                                                            TEAM_LOGO_HEIGHT,
                                                      ),
                                                    ),
                                                    Padding(
                                                      padding: EdgeInsets.only(
                                                          top: 8.0),
                                                      child: Text(
                                                        _league.teamA.name,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                      Expanded(
                                        // flex: 2,
                                        child: Column(
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
                                              textAlign: TextAlign.center,
                                            ),
                                            Padding(
                                              padding: EdgeInsets.only(
                                                  top: 6.0, bottom: 6.0),
                                              child: Text(
                                                "vs",
                                                textAlign: TextAlign.center,
                                                style: TextStyle(
                                                  fontSize: Theme.of(context)
                                                      .primaryTextTheme
                                                      .title
                                                      .fontSize,
                                                  color: Colors.black87,
                                                ),
                                              ),
                                            ),
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: <Widget>[
                                                Padding(
                                                  padding: EdgeInsets.only(
                                                      right: 8.0),
                                                  child: Icon(
                                                    Icons.alarm,
                                                    size: 16.0,
                                                    color: Colors.black54,
                                                  ),
                                                ),
                                                _league.status ==
                                                        LeagueStatus.UPCOMING
                                                    ? EPOC(
                                                        timeInMiliseconds:
                                                            _league
                                                                .matchStartTime,
                                                      )
                                                    : (_league.status ==
                                                            LeagueStatus.LIVE
                                                        ? Text("LIVE")
                                                        : Text("COMPLETED")),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.end,
                                        children: <Widget>[
                                          Padding(
                                            padding: EdgeInsets.only(
                                              right: 12.0,
                                              left: 16.0,
                                            ),
                                            child: Column(
                                              children: <Widget>[
                                                ClipRRect(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          2.0),
                                                  child: CachedNetworkImage(
                                                    imageUrl: _league.teamB !=
                                                            null
                                                        ? _league.teamB.logoUrl
                                                        : null,
                                                    placeholder: Container(
                                                      padding:
                                                          EdgeInsets.all(4.0),
                                                      child:
                                                          CircularProgressIndicator(
                                                        strokeWidth: 2.0,
                                                      ),
                                                      width: TEAM_LOGO_HEIGHT,
                                                      height: TEAM_LOGO_HEIGHT,
                                                    ),
                                                    height: TEAM_LOGO_HEIGHT,
                                                  ),
                                                ),
                                                Padding(
                                                  padding:
                                                      EdgeInsets.only(top: 8.0),
                                                  child: Text(
                                                    _league.teamB.name,
                                                  ),
                                                ),
                                              ],
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
                        ),
                      ],
                    ),
                    tabBar != null
                        ? Row(
                            children: <Widget>[
                              Expanded(
                                child: Container(
                                  height: 0.5,
                                  color: Colors.black12,
                                ),
                              ),
                            ],
                          )
                        : Container(),
                    tabBar != null
                        ? Row(
                            children: <Widget>[Expanded(child: tabBar)],
                          )
                        : Container(),
                  ],
                ),
              ),
              _league.prediction == 1
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: <Widget>[
                        ClipPath(
                          clipper: TriangleClipper(),
                          child: Container(
                            width: 48.0,
                            height: 32.0,
                            padding: EdgeInsets.symmetric(
                                vertical: 3.0, horizontal: 4.0),
                            alignment: Alignment.topRight,
                            color: Theme.of(context).primaryColor,
                            child: SvgPicture.asset(
                              "images/prediction.svg",
                              height: 18.0,
                            ),
                          ),
                        ),
                      ],
                    )
                  : Container(),
            ],
          ),
        ),
      ),
    );
  }
}

class TriangleClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(size.width, 0.0);
    path.lineTo(size.width, size.height);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(TriangleClipper oldClipper) => false;
}
