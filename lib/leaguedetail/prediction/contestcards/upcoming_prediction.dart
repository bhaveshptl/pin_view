import 'package:intl/intl.dart';
import 'package:flutter/material.dart';

import 'package:playfantasy/modal/l1.dart';
import 'package:playfantasy/modal/league.dart';
import 'package:playfantasy/modal/mysheet.dart';
import 'package:playfantasy/utils/stringtable.dart';

class UpcomingPrediction extends StatelessWidget {
  final League league;
  final Contest contest;
  final Function onJoin;

  final Function onPrizeStructure;
  final List<MySheet> myJoinedSheets;

  UpcomingPrediction({
    this.league,
    this.onJoin,
    this.contest,
    this.myJoinedSheets,
    this.onPrizeStructure,
  });

  @override
  Widget build(BuildContext context) {
    bool bIsContestFull = myJoinedSheets != null &&
        (contest.teamsAllowed <= myJoinedSheets.length ||
            contest.size == contest.joined);

    final formatCurrency = NumberFormat.currency(
      locale: "hi_IN",
      symbol: contest.prizeType == 1 ? "" : strings.rupee,
      decimalDigits: 0,
    );

    return Column(
      children: <Widget>[
        Container(
          padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Column(
            children: <Widget>[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Text(
                    "Prize Pool",
                    style: TextStyle(color: Colors.black38),
                  ),
                  Text(
                    "Entry Fee",
                    style: TextStyle(color: Colors.black38),
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      contest.prizeType == 1
                          ? Padding(
                              padding: EdgeInsets.symmetric(horizontal: 2.0),
                              child: Image.asset(
                                strings.chips,
                                width: 10.0,
                                height: 10.0,
                                fit: BoxFit.contain,
                              ),
                            )
                          : Container(),
                      Text(
                        formatCurrency.format(
                            contest.prizeDetails[0]["totalPrizeAmount"]),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Theme.of(context).primaryColorDark,
                          fontSize:
                              Theme.of(context).primaryTextTheme.title.fontSize,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                  RaisedButton(
                    onPressed: (bIsContestFull || onJoin == null)
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
                        myJoinedSheets != null && myJoinedSheets.length > 0
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
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: <Widget>[
                                contest.prizeType == 1
                                    ? Padding(
                                        padding: EdgeInsets.symmetric(
                                            horizontal: 2.0),
                                        child: Image.asset(
                                          strings.chips,
                                          width: 10.0,
                                          height: 10.0,
                                          fit: BoxFit.contain,
                                        ),
                                      )
                                    : Container(),
                                Text(
                                  formatCurrency.format(contest.entryFee),
                                  style: Theme.of(context)
                                      .primaryTextTheme
                                      .button
                                      .copyWith(
                                        color: Colors.white70,
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                              ],
                            )
                          ],
                        ),
                      ],
                    ),
                  )
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
            ],
          ),
        ),
        Container(
          color: Colors.black.withAlpha(15),
          padding: EdgeInsets.symmetric(horizontal: 16.0),
          height: 40.0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Tooltip(
                message: strings.get("NO_OF_WINNERS"),
                child: FlatButton(
                  padding: EdgeInsets.all(0.0),
                  onPressed: () {
                    if (onPrizeStructure != null) {
                      onPrizeStructure(contest);
                    }
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Text(
                        contest.prizeDetails[0]["noOfPrizes"].toString() + " ",
                        style:
                            Theme.of(context).primaryTextTheme.caption.copyWith(
                                  color: Colors.orange,
                                  fontWeight: FontWeight.w900,
                                ),
                      ),
                      Text(
                        contest.prizeDetails[0]["noOfPrizes"].toString() == "1"
                            ? "WINNER"
                            : strings.get("WINNERS").toUpperCase(),
                        style:
                            Theme.of(context).primaryTextTheme.caption.copyWith(
                                  color: Colors.orange,
                                  fontWeight: FontWeight.w800,
                                ),
                      ),
                      Icon(
                        Icons.arrow_drop_down,
                        size: 16.0,
                        color: Colors.orange,
                      )
                    ],
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  contest.teamsAllowed > 1
                      ? Container(
                          padding: EdgeInsets.all(4.0),
                          width: 24.0,
                          height: 24.0,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(
                              color: Colors.black38,
                            ),
                            borderRadius: BorderRadius.circular(4.0),
                          ),
                          child: Tooltip(
                            message: strings.get("MAXIMUM_ENTRY").replaceAll(
                                "\$count", contest.teamsAllowed.toString()),
                            child: Text(
                              "M",
                              style: TextStyle(
                                color: Colors.indigo,
                                fontSize: Theme.of(context)
                                    .primaryTextTheme
                                    .caption
                                    .fontSize,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        )
                      : Container(),
                  contest.bonusAllowed > 0
                      ? Padding(
                          padding: EdgeInsets.only(left: 8.0),
                          child: Container(
                            padding: EdgeInsets.all(4.0),
                            width: 24.0,
                            height: 24.0,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              border: Border.all(
                                color: Colors.black38,
                              ),
                              borderRadius: BorderRadius.circular(4.0),
                            ),
                            child: Tooltip(
                              message: strings.get("USE_BONUS").replaceAll(
                                  "\$bonusPercent",
                                  contest.bonusAllowed.toString()),
                              child: Text(
                                "B",
                                style: TextStyle(
                                  color: Colors.green,
                                  fontSize: Theme.of(context)
                                      .primaryTextTheme
                                      .caption
                                      .fontSize,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        )
                      : Container(),
                ],
              )
            ],
          ),
        )
      ],
    );
  }
}
