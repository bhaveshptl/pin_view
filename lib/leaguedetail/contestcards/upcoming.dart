import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:playfantasy/appconfig.dart';
import 'package:playfantasy/commonwidgets/gradientbutton.dart';

import 'package:playfantasy/modal/l1.dart';
import 'package:playfantasy/modal/league.dart';
import 'package:playfantasy/modal/myteam.dart';
import 'package:playfantasy/utils/stringtable.dart';

class UpcomingContest extends StatelessWidget {
  final League league;
  final Contest contest;
  final Function onJoin;
  final bool isMyContest;
  final bool bShowBrandInfo;
  final Function onPrizeStructure;
  final List<MyTeam> myJoinedTeams;

  UpcomingContest({
    this.league,
    this.onJoin,
    this.contest,
    this.myJoinedTeams,
    this.onPrizeStructure,
    this.isMyContest = false,
    this.bShowBrandInfo = false,
  });

  @override
  Widget build(BuildContext context) {
    String title = "";
    bool bMyContest = isMyContest == null ? false : isMyContest;
    bool bIsContestFull = myJoinedTeams != null &&
        (contest.teamsAllowed <= myJoinedTeams.length ||
            contest.size == contest.joined);

    if (contest.inningsId != 0 &&
        league.teamA != null &&
        league.teamA.sportType == 1) {
      if (league.teamA.inningsId == contest.inningsId) {
        title = league.teamA.name;
      } else {
        title = league.teamB.name;
      }
    } else if (contest.inningsId != 0 && league.teamA != null) {
      if (league.teamA.inningsId == contest.inningsId) {
        title = "First";
      } else {
        title = "Second";
      }
    }

    final formatCurrency =
        NumberFormat.currency(locale: "hi_IN", symbol: "", decimalDigits: 0);

    return Container(
      child: Column(
        children: <Widget>[
          Row(
            children: <Widget>[
              contest.brand != null && bShowBrandInfo
                  ? Column(
                      children: <Widget>[
                        CachedNetworkImage(
                          imageUrl: contest.brand["brandLogoUrl"],
                          width: 32.0,
                          placeholder: Container(
                            padding: EdgeInsets.all(4.0),
                            width: 32.0,
                            height: 32.0,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.0,
                            ),
                          ),
                        ),
                      ],
                    )
                  : Container(),
              Expanded(
                child: contest.brand != null && bShowBrandInfo
                    ? Column(
                        children: <Widget>[
                          Row(
                            children: <Widget>[
                              Padding(
                                padding: EdgeInsets.only(left: 8.0),
                                child: Text(
                                  contest.brand["info"],
                                  style: Theme.of(context)
                                      .primaryTextTheme
                                      .title
                                      .copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
                                      ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      )
                    : Container(),
              ),
              (bMyContest && title.isNotEmpty)
                  ? Container(
                      padding: EdgeInsets.symmetric(horizontal: 4.0),
                      color: Colors.redAccent,
                      child: Text(
                        title,
                        style: TextStyle(color: Colors.white54),
                      ),
                    )
                  : Container(),
            ],
          ),
          Padding(
            padding: EdgeInsets.only(top: 6.0, bottom: 2.0),
            child: bShowBrandInfo
                ? Row(
                    children: <Widget>[
                      Expanded(
                        flex: 2,
                        child: Container(
                          height: 1.0,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.black38,
                                Colors.white,
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 1,
                        child: Container(),
                      )
                    ],
                  )
                : Container(),
          ),
          Padding(
            padding: EdgeInsets.only(right: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Text(
                  contest.name,
                  style: Theme.of(context).primaryTextTheme.caption.copyWith(
                        color: Colors.black45,
                      ),
                ),
                Row(
                  children: <Widget>[
                    contest.teamsAllowed > 1
                        ? Tooltip(
                            message: strings.get("MAXIMUM_ENTRY").replaceAll(
                                "\$count", contest.teamsAllowed.toString()),
                            child: CircleAvatar(
                              backgroundColor:
                                  Theme.of(context).primaryColorDark,
                              maxRadius: 10.0,
                              child: Text(
                                "M",
                                style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: Theme.of(context)
                                        .primaryTextTheme
                                        .caption
                                        .fontSize),
                              ),
                            ),
                          )
                        : Container(),
                    Padding(
                      padding: EdgeInsets.only(left: 8.0),
                      child: contest.bonusAllowed > 0
                          ? Tooltip(
                              message: strings.get("USE_BONUS").replaceAll(
                                  "\$bonusPercent",
                                  contest.bonusAllowed.toString()),
                              child: CircleAvatar(
                                backgroundColor:
                                    Theme.of(context).primaryColorDark,
                                maxRadius: 10.0,
                                child: Text(
                                  "B",
                                  style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: Theme.of(context)
                                          .primaryTextTheme
                                          .caption
                                          .fontSize),
                                ),
                              ),
                            )
                          : Container(),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Row(
            children: <Widget>[
              Expanded(
                flex: 5,
                child: Column(
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Row(
                                children: <Widget>[
                                  Text(
                                    "Prize",
                                    style: TextStyle(
                                      color: Colors.black54,
                                      fontSize: Theme.of(context)
                                          .primaryTextTheme
                                          .caption
                                          .fontSize,
                                    ),
                                  ),
                                ],
                              ),
                              Row(
                                children: <Widget>[
                                  contest.prizeType == 1
                                      ? Image.asset(
                                          strings.chips,
                                          width: 16.0,
                                          height: 12.0,
                                          fit: BoxFit.contain,
                                        )
                                      : Text(
                                          strings.rupee,
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                              color: Theme.of(context)
                                                  .primaryColorDark,
                                              fontSize: Theme.of(context)
                                                  .primaryTextTheme
                                                  .title
                                                  .fontSize),
                                        ),
                                  Text(
                                    formatCurrency.format(contest
                                        .prizeDetails[0]["totalPrizeAmount"]),
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                        color:
                                            Theme.of(context).primaryColorDark,
                                        fontSize: Theme.of(context)
                                            .primaryTextTheme
                                            .title
                                            .fontSize),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Container(
                          height: 32.0,
                          child: Tooltip(
                            message: strings.get("NO_OF_WINNERS"),
                            child: FlatButton(
                              padding: EdgeInsets.all(0.0),
                              onPressed: () {
                                if (onPrizeStructure != null) {
                                  onPrizeStructure(contest);
                                }
                              },
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: <Widget>[
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: <Widget>[
                                      Text(
                                        strings.get("WINNERS").toUpperCase(),
                                        style: TextStyle(
                                          color: Colors.black45,
                                          fontSize: Theme.of(context)
                                              .primaryTextTheme
                                              .caption
                                              .fontSize,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: <Widget>[
                                      Text(
                                        contest.prizeDetails[0]["noOfPrizes"]
                                            .toString(),
                                      ),
                                      Icon(
                                        Icons.chevron_right,
                                        size: 16.0,
                                        color: Colors.black26,
                                      )
                                    ],
                                  )
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding:
                          EdgeInsets.only(right: 24.0, top: 4.0, bottom: 4.0),
                      child: Row(
                        children: <Widget>[
                          Expanded(
                            flex: contest.joined,
                            child: ClipRRect(
                              borderRadius: contest.joined == contest.size
                                  ? BorderRadius.all(Radius.circular(15.0))
                                  : BorderRadius.only(
                                      topLeft: Radius.circular(15.0),
                                      bottomLeft: Radius.circular(15.0),
                                    ),
                              child: Container(
                                height: 3.0,
                                color: Theme.of(context).primaryColorDark,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: contest.size - contest.joined,
                            child: ClipRRect(
                              borderRadius: contest.joined == 0
                                  ? BorderRadius.all(Radius.circular(15.0))
                                  : BorderRadius.only(
                                      topRight: Radius.circular(15.0),
                                      bottomRight: Radius.circular(15.0),
                                    ),
                              child: Container(
                                height: 3.0,
                                color: Colors.black12.withAlpha(10),
                              ),
                            ),
                          )
                        ],
                      ),
                    ),
                    Container(
                      child: Row(
                        children: <Widget>[
                          Expanded(
                            child: Text(
                              contest.joined.toString() +
                                  "/" +
                                  contest.size.toString(),
                              textAlign: TextAlign.center,
                            ),
                          )
                        ],
                      ),
                    )
                  ],
                ),
              ),
              Expanded(
                flex: 2,
                child: Column(
                  children: <Widget>[
                    AppConfig.of(context).channelId == "10"
                        ? Container()
                        : Padding(
                            padding: EdgeInsets.only(bottom: 4.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Padding(
                                  padding: EdgeInsets.only(right: 4.0),
                                  child: Text(
                                    "Entry",
                                    style: Theme.of(context)
                                        .primaryTextTheme
                                        .caption
                                        .copyWith(
                                          color: Colors.black87,
                                        ),
                                  ),
                                ),
                                contest.prizeType == 1
                                    ? Padding(
                                        padding: EdgeInsets.symmetric(
                                            horizontal: 2.0),
                                        child: Image.asset(
                                          strings.chips,
                                          width: 10.0,
                                          height: 10.0,
                                          fit: BoxFit.contain,
                                        ))
                                    : Text(
                                        strings.rupee,
                                        style: Theme.of(context)
                                            .primaryTextTheme
                                            .caption
                                            .copyWith(
                                              color: Colors.black87,
                                              fontWeight: FontWeight.bold,
                                            ),
                                      ),
                                Text(
                                  contest.entryFee.toString(),
                                  style: Theme.of(context)
                                      .primaryTextTheme
                                      .caption
                                      .copyWith(
                                        color: Colors.black87,
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                              ],
                            ),
                          ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: <Widget>[
                        Expanded(
                          child: Tooltip(
                            message: "Join contest with ₹" +
                                contest.entryFee.toString() +
                                " entry fee.",
                            child: Padding(
                              padding: EdgeInsets.symmetric(horizontal: 8.0),
                              child: GradientButton(
                                disabled: bIsContestFull || onJoin == null,
                                button: RaisedButton(
                                  onPressed: () {
                                    if (!bIsContestFull && onJoin != null) {
                                      onJoin(contest);
                                    }
                                  },
                                  color: Colors.transparent,
                                  padding: EdgeInsets.all(0.0),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: <Widget>[
                                      myJoinedTeams != null &&
                                              myJoinedTeams.length > 0
                                          ? Icon(
                                              Icons.add,
                                              color: Colors.white70,
                                              size: Theme.of(context)
                                                  .primaryTextTheme
                                                  .subhead
                                                  .fontSize,
                                            )
                                          : Container(),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: <Widget>[
                                          AppConfig.of(context).channelId ==
                                                  "10"
                                              ? Row(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.center,
                                                  children: <Widget>[
                                                    contest.prizeType == 1
                                                        ? Padding(
                                                            padding: EdgeInsets
                                                                .symmetric(
                                                                    horizontal:
                                                                        2.0),
                                                            child: Image.asset(
                                                              strings.chips,
                                                              width: 10.0,
                                                              height: 10.0,
                                                              fit: BoxFit
                                                                  .contain,
                                                            ))
                                                        : Text(
                                                            strings.rupee,
                                                            style: Theme.of(
                                                                    context)
                                                                .primaryTextTheme
                                                                .button
                                                                .copyWith(
                                                                  color: Colors
                                                                      .white70,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold,
                                                                ),
                                                          ),
                                                    Text(
                                                      contest.entryFee
                                                          .toString(),
                                                      style: Theme.of(context)
                                                          .primaryTextTheme
                                                          .button
                                                          .copyWith(
                                                            color:
                                                                Colors.white70,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                          ),
                                                    ),
                                                  ],
                                                )
                                              : Text(
                                                  "JOIN",
                                                  style: TextStyle(
                                                    color: Colors.white70,
                                                    fontSize: Theme.of(context)
                                                        .primaryTextTheme
                                                        .button
                                                        .fontSize,
                                                  ),
                                                ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              )
            ],
          )
        ],
      ),
    );
  }
}
