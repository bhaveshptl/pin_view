import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:playfantasy/commonwidgets/color_button.dart';
import 'package:playfantasy/modal/l1.dart';
import 'package:playfantasy/modal/league.dart';
import 'package:playfantasy/modal/myteam.dart';
import 'package:playfantasy/utils/stringtable.dart';

class UpcomingHowzatContest extends StatelessWidget {
  final League league;
  final Contest contest;
  final Function onJoin;
  final Function onPrizeStructure;
  final List<MyTeam> myJoinedTeams;

  UpcomingHowzatContest({
    this.league,
    this.onJoin,
    this.contest,
    this.myJoinedTeams,
    this.onPrizeStructure,
  });

  @override
  Widget build(BuildContext context) {
    bool bIsContestFull = myJoinedTeams != null &&
        (contest.teamsAllowed <= myJoinedTeams.length ||
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
                    style: Theme.of(context).primaryTextTheme.body2.copyWith(
                          color: Colors.grey.shade500,
                        ),
                  ),
                  Text(
                    "Entry Fee",
                    style: Theme.of(context).primaryTextTheme.body2.copyWith(
                          color: Colors.grey.shade500,
                        ),
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  contest.multiplier
                      ? Row(
                          children: <Widget>[
                            Text(
                              contest.topPrecent.toString(),
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 24.0,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              "%",
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 18.0,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              " win ",
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 24.0,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              formatCurrency.format(
                                contest.entryFee * contest.winningsMultiplier,
                              ),
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 30.0,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        )
                      : Row(
                          children: <Widget>[
                            contest.prizeType == 1
                                ? Padding(
                                    padding:
                                        EdgeInsets.symmetric(horizontal: 2.0),
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
                                color: Colors.black,
                                fontSize: 30.0,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                  ColorButton(
                    onPressed: (bIsContestFull || onJoin == null)
                        ? null
                        : () {
                            onJoin(contest);
                          },
                    elevation: 0.0,
                    padding: EdgeInsets.all(0.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        myJoinedTeams != null && myJoinedTeams.length > 0
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
                                contest.prizeType == 1 && contest.entryFee > 0
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
                                  contest.entryFee > 0
                                      ? formatCurrency.format(contest.entryFee)
                                      : "FREE",
                                  style: Theme.of(context)
                                      .primaryTextTheme
                                      .title
                                      .copyWith(
                                        color: Colors.white,
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
                              color: Color.fromRGBO(70, 165, 12, 1),
                            ),
                          ),
                        ),
                        Expanded(
                          flex: contest.size - contest.joined,
                          child: Container(),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.only(top: 4.0, bottom: 4.0),
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
                          style: Theme.of(context)
                              .primaryTextTheme
                              .subhead
                              .copyWith(
                                color: Colors.grey.shade500,
                              ),
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
                          style: Theme.of(context)
                              .primaryTextTheme
                              .subhead
                              .copyWith(
                                color: Colors.grey.shade500,
                              ),
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
                            Theme.of(context).primaryTextTheme.subhead.copyWith(
                                  color: Colors.orange,
                                  fontWeight: FontWeight.w900,
                                ),
                      ),
                      Text(
                        contest.prizeDetails[0]["noOfPrizes"].toString() == "1"
                            ? "Winner"
                            : strings.get("WINNERS"),
                        style:
                            Theme.of(context).primaryTextTheme.subhead.copyWith(
                                  color: Colors.orange,
                                  fontWeight: FontWeight.w600,
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
                  contest.guaranteed
                      ? Container(
                          padding: EdgeInsets.all(4.0),
                          height: 24.0,
                          constraints: BoxConstraints(minWidth: 24.0),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(
                              color: Colors.grey.shade300,
                            ),
                            borderRadius: BorderRadius.circular(4.0),
                          ),
                          child: Text(
                            "G",
                            style: TextStyle(
                              color: Colors.orange,
                              fontSize: Theme.of(context)
                                  .primaryTextTheme
                                  .caption
                                  .fontSize,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        )
                      : Container(),
                  contest.teamsAllowed > 1
                      ? Padding(
                          padding: EdgeInsets.only(left: 8.0),
                          child: Container(
                            padding: EdgeInsets.all(4.0),
                            height: 24.0,
                            constraints: BoxConstraints(minWidth: 24.0),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              border: Border.all(
                                color: Colors.grey.shade300,
                              ),
                              borderRadius: BorderRadius.circular(4.0),
                            ),
                            child: Tooltip(
                              message: strings.get("MAXIMUM_ENTRY").replaceAll(
                                  "\$count", contest.teamsAllowed.toString()),
                              child: Text(
                                "M" + contest.teamsAllowed.toString(),
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
                          ),
                        )
                      : Container(),
                  contest.bonusAllowed > 0
                      ? Padding(
                          padding: EdgeInsets.only(left: 8.0),
                          child: Container(
                            padding: EdgeInsets.all(4.0),
                            height: 24.0,
                            constraints: BoxConstraints(minWidth: 24.0),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              border: Border.all(
                                color: Colors.grey.shade300,
                              ),
                              borderRadius: BorderRadius.circular(4.0),
                            ),
                            child: Tooltip(
                              message: strings.get("USE_BONUS").replaceAll(
                                  "\$bonusPercent",
                                  contest.bonusAllowed.toString()),
                              child: Text(
                                "B" + contest.bonusAllowed.toString() + "%",
                                style: TextStyle(
                                  color: Color.fromRGBO(70, 165, 12, 1),
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
