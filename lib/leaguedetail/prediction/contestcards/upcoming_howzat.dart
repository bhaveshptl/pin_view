import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';

import 'package:playfantasy/modal/l1.dart';
import 'package:playfantasy/modal/league.dart';
import 'package:playfantasy/modal/mysheet.dart';
import 'package:playfantasy/utils/stringtable.dart';

class UpcomingHowzatPredictionContest extends StatelessWidget {
  final League league;
  final Contest contest;
  final Function onJoin;
  final bool bShowBrandInfo;
  final Function onPrizeStructure;
  final List<MySheet> myJoinedSheets;

  UpcomingHowzatPredictionContest({
    this.league,
    this.onJoin,
    this.contest,
    this.myJoinedSheets,
    this.onPrizeStructure,
    this.bShowBrandInfo = false,
  });

  @override
  Widget build(BuildContext context) {
    bool bIsContestFull = contest.size <= contest.joined ||
        (myJoinedSheets != null &&
            (contest.teamsAllowed <= myJoinedSheets.length));
    final formatCurrency =
        NumberFormat.currency(locale: "hi_IN", symbol: "", decimalDigits: 0);

    return Container(
      child: Column(
        children: <Widget>[
          Padding(
            padding: EdgeInsets.fromLTRB(8.0, 8.0, 8.0, 0.0),
            child: Row(
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
              ],
            ),
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
            padding: EdgeInsets.fromLTRB(8.0, 0.0, 0.0, 8.0),
            child: Row(
              children: <Widget>[
                Expanded(
                  flex: 4,
                  child: Padding(
                    padding: EdgeInsets.only(right: 16.0),
                    child: Column(
                      children: <Widget>[
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: <Widget>[
                            Expanded(
                              child: Column(
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
                                        formatCurrency.format(
                                            contest.prizeDetails[0]
                                                ["totalPrizeAmount"]),
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                            color: contest.prizeType == 1
                                                ? Colors.blue.shade900
                                                : Theme.of(context)
                                                    .primaryColorDark,
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
                              child: Text(
                                contest.joined.toString() +
                                    "/" +
                                    contest.size.toString(),
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.black),
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: EdgeInsets.only(top: 4.0, bottom: 4.0),
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
                      ],
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Column(
                    children: <Widget>[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          Text(
                            "Entry",
                            style: Theme.of(context)
                                .primaryTextTheme
                                .caption
                                .copyWith(
                                  color: Colors.black87,
                                ),
                          ),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          Expanded(
                            child: Tooltip(
                              message: "Join contest with ₹" +
                                  contest.entryFee.toString() +
                                  " entry fee.",
                              child: Padding(
                                padding: EdgeInsets.symmetric(horizontal: 16.0),
                                child: RaisedButton(
                                  onPressed: bIsContestFull || onJoin == null
                                      ? null
                                      : () {
                                          onJoin(contest);
                                        },
                                  elevation: 0.0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(5.0),
                                  ),
                                  color: Colors.green,
                                  padding: EdgeInsets.all(0.0),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: <Widget>[
                                      myJoinedSheets != null &&
                                              myJoinedSheets.length > 0
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
                                          Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.center,
                                            children: <Widget>[
                                              contest.prizeType == 1
                                                  ? Padding(
                                                      padding:
                                                          EdgeInsets.symmetric(
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
                                                          .button
                                                          .copyWith(
                                                            color:
                                                                Colors.white70,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                          ),
                                                    ),
                                              Text(
                                                contest.entryFee.toString(),
                                                style: Theme.of(context)
                                                    .primaryTextTheme
                                                    .button
                                                    .copyWith(
                                                      color: Colors.white70,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                              ),
                                            ],
                                          )
                                        ],
                                      ),
                                    ],
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
            ),
          ),
          Container(
            color: Colors.black.withAlpha(15),
            child: Row(
              children: <Widget>[
                Expanded(
                  flex: 5,
                  child: Container(
                    height: 32.0,
                    child: Tooltip(
                      message: strings.get("NO_OF_WINNERS"),
                      child: FlatButton(
                        padding: EdgeInsets.only(left: 8.0),
                        onPressed: () {
                          if (onPrizeStructure != null) {
                            onPrizeStructure(contest);
                          }
                        },
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            Padding(
                              padding: EdgeInsets.only(right: 8.0),
                              child: Text(
                                strings.get("WINNERS").toUpperCase(),
                                style: TextStyle(
                                  color: Colors.black45,
                                  fontSize: Theme.of(context)
                                      .primaryTextTheme
                                      .caption
                                      .fontSize,
                                ),
                              ),
                            ),
                            Text(
                              contest.prizeDetails[0]["noOfPrizes"].toString(),
                            ),
                            Icon(
                              Icons.chevron_right,
                              size: 16.0,
                              color: Colors.black26,
                            )
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: 4.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        contest.teamsAllowed > 1
                            ? Tooltip(
                                message: strings
                                    .get("MAXIMUM_ENTRY")
                                    .replaceAll("\$count",
                                        contest.teamsAllowed.toString()),
                                child: CircleAvatar(
                                  backgroundColor: Colors.indigo,
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
                                    backgroundColor: Colors.green,
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
                  ),
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}
