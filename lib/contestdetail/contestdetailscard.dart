import 'package:intl/intl.dart';
import 'package:flutter/material.dart';

import 'package:playfantasy/modal/l1.dart';
import 'package:playfantasy/modal/league.dart';
import 'package:playfantasy/modal/myteam.dart';
import 'package:playfantasy/utils/stringtable.dart';
import 'package:playfantasy/commonwidgets/color_button.dart';

class ContestDetailsCard extends StatelessWidget {
  final League league;
  final Contest contest;
  final Function onJoinContest;
  final Function onShareContest;
  final Function onPrizeStructure;
  final List<MyTeam> contestTeams;
  ContestDetailsCard({
    this.league,
    this.contest,
    this.contestTeams,
    this.onJoinContest,
    this.onShareContest,
    this.onPrizeStructure,
  });

  @override
  Widget build(BuildContext context) {
    bool bIsContestFull =
        (contestTeams != null && contest.teamsAllowed <= contestTeams.length) ||
            contest.size == contest.joined ||
            league.status == LeagueStatus.LIVE ||
            league.status == LeagueStatus.COMPLETED;

    final formatCurrency = NumberFormat.currency(
        locale: "hi_IN", symbol: strings.rupee, decimalDigits: 0);

    return Card(
      margin: EdgeInsets.all(12.0),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Column(
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Text(
                          "Prize pool",
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
                                width: 12.0,
                                height: 12.0,
                                fit: BoxFit.contain,
                              )
                            : Container(),
                        Text(
                          contest.prizeDetails != null
                              ? formatCurrency.format(
                                  contest.prizeDetails[0]["totalPrizeAmount"])
                              : 0.toString(),
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: Theme.of(context)
                                .primaryTextTheme
                                .title
                                .fontSize,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                InkWell(
                  onTap: () {
                    if (onPrizeStructure != null) {
                      onPrizeStructure();
                    }
                  },
                  child: Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    child: Column(
                      children: <Widget>[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            Text(
                              "Winners",
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
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            Text(
                              contest.prizeDetails == null
                                  ? 0.toString()
                                  : contest.prizeDetails[0]["noOfPrizes"]
                                      .toString(),
                              style: TextStyle(
                                color: Colors.orange,
                                fontSize: Theme.of(context)
                                    .primaryTextTheme
                                    .title
                                    .fontSize,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        )
                      ],
                    ),
                  ),
                ),
                Column(
                  children: <Widget>[
                    Text(
                      "Entry",
                      style: TextStyle(
                        color: Colors.black54,
                        fontSize:
                            Theme.of(context).primaryTextTheme.caption.fontSize,
                      ),
                    ),
                    Text(
                      formatCurrency.format(contest.entryFee),
                      style: TextStyle(
                        color: Colors.green,
                        fontSize:
                            Theme.of(context).primaryTextTheme.title.fontSize,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            Divider(
              color: Colors.black26,
              height: 2.0,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: 8.0),
                      child: Container(
                        width: 20.0,
                        height: 20.0,
                        child: Text(
                          "B",
                          style: Theme.of(context)
                              .primaryTextTheme
                              .caption
                              .copyWith(
                                color: Colors.blue,
                              ),
                        ),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(5.0),
                          border: Border.all(
                            color: Colors.blueAccent,
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.only(left: 8.0),
                      child: Text(
                        "Entry with bonus amount",
                        style:
                            Theme.of(context).primaryTextTheme.caption.copyWith(
                                  color: Colors.black38,
                                ),
                      ),
                    ),
                  ],
                ),
                Row(
                  children: <Widget>[
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: 8.0),
                      child: Container(
                        width: 20.0,
                        height: 20.0,
                        child: Text(
                          "M",
                          style: Theme.of(context)
                              .primaryTextTheme
                              .caption
                              .copyWith(
                                color: Colors.green,
                              ),
                        ),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(5.0),
                          border: Border.all(
                            color: Colors.green,
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.only(left: 8.0),
                      child: Text(
                        "Join with multiple teams",
                        style:
                            Theme.of(context).primaryTextTheme.caption.copyWith(
                                  color: Colors.black38,
                                ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            Padding(
              padding: EdgeInsets.only(top: 4.0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8.0),
                child: Container(
                  color: Colors.black26,
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        flex: contest.joined,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8.0),
                          child: Container(
                            height: 6.0,
                            color: Colors.green,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: contest.size,
                        child: Container(),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.only(top: 4.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Text(
                        (contest.size - contest.joined).toString(),
                        style: TextStyle(
                          color: Colors.black38,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        " seats left",
                        style: TextStyle(color: Colors.black38),
                      ),
                    ],
                  ),
                  Row(
                    children: <Widget>[
                      Text(
                        contest.size.toString(),
                        style: TextStyle(
                          color: Colors.black38,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        " seats",
                        style: TextStyle(color: Colors.black38),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            bIsContestFull
                ? Container()
                : Padding(
                    padding: EdgeInsets.only(top: 8.0, bottom: 8.0),
                    child: Row(
                      children: <Widget>[
                        Expanded(
                          child: ColorButton(
                            onPressed: bIsContestFull
                                ? null
                                : () {
                                    onJoinContest(contest);
                                  },
                            child: Container(
                              padding: EdgeInsets.symmetric(vertical: 12.0),
                              child: Text(
                                "Join the contest".toUpperCase(),
                                style: Theme.of(context)
                                    .primaryTextTheme
                                    .headline
                                    .copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w800,
                                    ),
                              ),
                            ),
                          ),
                        )
                      ],
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}
