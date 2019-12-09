import 'package:flutter_svg/svg.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

import 'package:playfantasy/modal/league.dart';
import 'package:playfantasy/commonwidgets/epoc.dart';

const double TEAM_LOGO_HEIGHT = 48.0;

class LeagueCard extends StatelessWidget {
  final League _league;
  final bool clickable;
  final Function onClick;
  final int contestCount;
  final Function onTimeComplete;
  LeagueCard(
    this._league, {
    this.onClick,
    this.clickable = true,
    this.contestCount = 0,
    this.onTimeComplete,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(16.0, 2.0, 16.0, 2.0),
      child: Tooltip(
        message: _league != null && _league.matchId != null
            ? _league.matchId.toString() + " - " + _league.matchName
            : "",
        child: Card(
          elevation: 3.0,
          clipBehavior: Clip.antiAliasWithSaveLayer,
          margin: EdgeInsets.symmetric(vertical: 4.0),
          child: Stack(
            children: <Widget>[
              FlatButton(
                padding: EdgeInsets.all(0.0),
                onPressed: () {
                  if (clickable && onClick != null) {
                    onClick(_league);
                  }
                },
                child: Container(
                  margin:
                      EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
                  child: Column(
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: Text(
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
                          )
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          Column(
                            children: <Widget>[
                              Row(
                                children: <Widget>[
                                  Container(
                                    padding: EdgeInsets.all(2.0),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.white,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black12,
                                          blurRadius: 1.0,
                                          spreadRadius: 0.5,
                                          offset: Offset(0.0, 2.0),
                                        )
                                      ],
                                    ),
                                    child: ClipRRect(
                                      clipBehavior: Clip.hardEdge,
                                      borderRadius: BorderRadius.circular(
                                        TEAM_LOGO_HEIGHT,
                                      ),
                                      child: CachedNetworkImage(
                                        imageUrl: _league.teamA != null
                                            ? _league.teamA.logoUrl
                                            : "",
                                        fit: BoxFit.fitHeight,
                                        placeholder: (context, string) {
                                          return Container(
                                            padding: EdgeInsets.all(12.0),
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2.0,
                                            ),
                                            width: TEAM_LOGO_HEIGHT,
                                            height: TEAM_LOGO_HEIGHT,
                                          );
                                        },
                                        height: TEAM_LOGO_HEIGHT,
                                        width: TEAM_LOGO_HEIGHT,
                                      ),
                                    ),
                                  ),
                                  Padding(
                                    padding: EdgeInsets.only(left: 8.0),
                                    child: Text(
                                      _league.teamA.name,
                                      style: Theme.of(context)
                                          .primaryTextTheme
                                          .title
                                          .copyWith(
                                            color: Colors.black,
                                            fontWeight: FontWeight.w600,
                                          ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          _league.status == LeagueStatus.COMPLETED
                              ? Container(
                                  height: 32.0,
                                  alignment: Alignment.center,
                                  child: Text(
                                    "Completed",
                                    style: Theme.of(context)
                                        .primaryTextTheme
                                        .subhead
                                        .copyWith(
                                          fontWeight: FontWeight.w700,
                                          color: Theme.of(context).primaryColor,
                                        ),
                                  ),
                                )
                              : Container(
                                  child: _league.status ==
                                              LeagueStatus.COMPLETED ||
                                          _league.status == LeagueStatus.LIVE
                                      ? Container(
                                          alignment: Alignment.center,
                                          child: Text(
                                            contestCount.toString() +
                                                " Contest Joined",
                                            style: Theme.of(context)
                                                .primaryTextTheme
                                                .body1
                                                .copyWith(
                                                  color: Colors.black,
                                                ),
                                          ),
                                        )
                                      : EPOC(
                                          onTimeComplete: onTimeComplete,
                                          timeInMiliseconds:
                                              _league.matchStartTime,
                                        ),
                                  // width: 32.0,
                                  // height: 32.0,
                                  // decoration: BoxDecoration(
                                  //   border: Border.all(
                                  //     color: Colors.grey.shade400,
                                  //     width: 1.0,
                                  //   ),
                                  //   shape: BoxShape.circle,
                                  // ),
                                  // child: Column(
                                  //   mainAxisAlignment: MainAxisAlignment.center,
                                  //   children: <Widget>[
                                  //     Text(
                                  //       "vs".toUpperCase(),
                                  //       textAlign: TextAlign.center,
                                  //       style: TextStyle(
                                  //         fontSize: Theme.of(context)
                                  //             .primaryTextTheme
                                  //             .caption
                                  //             .fontSize,
                                  //         fontWeight: FontWeight.w900,
                                  //         color: Colors.black87,
                                  //       ),
                                  //     ),
                                  //   ],
                                  // ),
                                ),
                          Column(
                            children: <Widget>[
                              Row(
                                children: <Widget>[
                                  Padding(
                                    padding: EdgeInsets.only(right: 8.0),
                                    child: Text(
                                      _league.teamB.name,
                                      style: Theme.of(context)
                                          .primaryTextTheme
                                          .title
                                          .copyWith(
                                            color: Colors.black,
                                            fontWeight: FontWeight.w600,
                                          ),
                                    ),
                                  ),
                                  Container(
                                    padding: EdgeInsets.all(2.0),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.white,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black12,
                                          blurRadius: 1.0,
                                          spreadRadius: 0.5,
                                          offset: Offset(0.0, 2.0),
                                        )
                                      ],
                                    ),
                                    child: ClipRRect(
                                      clipBehavior: Clip.hardEdge,
                                      borderRadius: BorderRadius.circular(
                                        TEAM_LOGO_HEIGHT,
                                      ),
                                      child: CachedNetworkImage(
                                        imageUrl: _league.teamA != null
                                            ? _league.teamB.logoUrl
                                            : "",
                                        fit: BoxFit.fitHeight,
                                        placeholder: (context, string) {
                                          return Container(
                                            padding: EdgeInsets.all(4.0),
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2.0,
                                            ),
                                            width: TEAM_LOGO_HEIGHT,
                                            height: TEAM_LOGO_HEIGHT,
                                          );
                                        },
                                        height: TEAM_LOGO_HEIGHT,
                                        width: TEAM_LOGO_HEIGHT,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                      // Row(
                      //   mainAxisAlignment: MainAxisAlignment.center,
                      //   children: <Widget>[
                      //     Expanded(
                      //       child: _league.status == LeagueStatus.COMPLETED ||
                      //               _league.status == LeagueStatus.LIVE
                      //           ? Container(
                      //               alignment: Alignment.center,
                      //               child: Text(
                      //                 contestCount.toString() +
                      //                     " Contest Joined",
                      //                 style: Theme.of(context)
                      //                     .primaryTextTheme
                      //                     .body1
                      //                     .copyWith(
                      //                       color: Colors.black,
                      //                     ),
                      //               ),
                      //             )
                      //           : EPOC(
                      //               onTimeComplete: onTimeComplete,
                      //               timeInMiliseconds: _league.matchStartTime,
                      //             ),
                      //     )
                      //   ],
                      // )
                    ],
                  ),
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
