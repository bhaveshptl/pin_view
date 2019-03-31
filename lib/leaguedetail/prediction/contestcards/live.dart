import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:playfantasy/modal/l1.dart';
import 'package:playfantasy/modal/league.dart';
import 'package:playfantasy/modal/mysheet.dart';
import 'package:playfantasy/utils/stringtable.dart';

class LivePredictionContest extends StatelessWidget {
  final League league;
  final Contest contest;
  final Function onPrizeStructure;
  final List<MySheet> myJoinedSheets;

  LivePredictionContest({
    this.league,
    this.contest,
    this.myJoinedSheets,
    this.onPrizeStructure,
  });

  MySheet _getMyBestSheet() {
    if (myJoinedSheets != null) {
      myJoinedSheets.sort((a, b) {
        int sheetARank = a.rank == null ? 0 : a.rank;
        int sheetBRank = b.rank == null ? 0 : b.rank;
        return sheetARank - sheetBRank;
      });
      return myJoinedSheets[0];
    }
    return MySheet();
  }

  @override
  Widget build(BuildContext context) {
    MySheet _myBestSheet = _getMyBestSheet();

    final formatCurrency =
        NumberFormat.currency(locale: "hi_IN", symbol: "", decimalDigits: 0);

    return Column(
      children: <Widget>[
        Stack(
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Padding(
                  padding: EdgeInsets.fromLTRB(10.0, 5.0, 10.0, 5.0),
                  child: Text(
                    contest.name,
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: <Widget>[
                Padding(
                  padding: EdgeInsets.fromLTRB(10.0, 5.0, 10.0, 5.0),
                  child: Text(
                    "#" + contest.id.toString(),
                    textAlign: TextAlign.right,
                    style: TextStyle(color: Colors.black12),
                  ),
                ),
              ],
            ),
          ],
        ),
        Divider(
          height: 2.0,
          color: Colors.black12,
        ),
        Row(
          children: <Widget>[
            Expanded(
              flex: 2,
              child: Column(
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            contest.prizeType == 1
                                ? Image.asset(
                                    strings.chips,
                                    width: 12.0,
                                    height: 12.0,
                                    fit: BoxFit.contain,
                                  )
                                : Text(
                                    strings.rupee,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                        color:
                                            Theme.of(context).primaryColorDark,
                                        fontSize: Theme.of(context)
                                            .primaryTextTheme
                                            .headline
                                            .fontSize),
                                  ),
                            Text(
                              formatCurrency.format(
                                  contest.prizeDetails[0]["totalPrizeAmount"]),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  color: Theme.of(context).primaryColorDark,
                                  fontSize: Theme.of(context)
                                      .primaryTextTheme
                                      .headline
                                      .fontSize),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        height: 20.0,
                        width: 1.0,
                        color: Colors.black12,
                      ),
                      Expanded(
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
                              children: <Widget>[
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: <Widget>[
                                    Padding(
                                      padding:
                                          const EdgeInsets.only(left: 16.0),
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
                                    Icon(
                                      Icons.chevron_right,
                                      size: 16.0,
                                      color: Colors.black26,
                                    )
                                  ],
                                ),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: <Widget>[
                                    Text(contest.prizeDetails[0]["noOfPrizes"]
                                        .toString())
                                  ],
                                )
                              ],
                            ),
                          ),
                        ),
                      ),
                      Container(
                        height: 20.0,
                        width: 1.0,
                        color: Colors.black12,
                      ),
                      Expanded(
                        child: Column(
                          children: <Widget>[
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: <Widget>[
                                Text(
                                  strings.get("ENTRY_FEE"),
                                  textAlign: TextAlign.center,
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
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: <Widget>[
                                contest.prizeType == 1
                                    ? Image.asset(
                                        strings.chips,
                                        width: 12.0,
                                        height: 12.0,
                                        fit: BoxFit.contain,
                                      )
                                    : Text(
                                        strings.rupee,
                                        style: TextStyle(
                                            color: Theme.of(context)
                                                .primaryColorDark,
                                            fontSize: Theme.of(context)
                                                .primaryTextTheme
                                                .title
                                                .fontSize),
                                      ),
                                Text(
                                  contest.entryFee.toString(),
                                  style: TextStyle(
                                      color: Theme.of(context).primaryColorDark,
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
                    ],
                  ),
                  Divider(
                    height: 2.0,
                    color: Colors.black12,
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 4.0, bottom: 4.0),
                    child: Row(
                      children: <Widget>[
                        Expanded(
                          flex: 1,
                          child: Column(
                            children: <Widget>[
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: <Widget>[
                                  Text(
                                    strings.get("JOINED"),
                                    textAlign: TextAlign.center,
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
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: <Widget>[
                                  Text(
                                    contest.joined.toString(),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Container(
                          height: 20.0,
                          width: 1.0,
                          color: Colors.black12,
                        ),
                        Expanded(
                          flex: 2,
                          child: Column(
                            children: <Widget>[
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: <Widget>[
                                  Text(
                                    strings.get("BEST_TEAM"),
                                    textAlign: TextAlign.center,
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
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: <Widget>[
                                  Text(
                                    _myBestSheet.name == null
                                        ? "-"
                                        : _myBestSheet.name,
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Container(
                          height: 20.0,
                          width: 1.0,
                          color: Colors.black12,
                        ),
                        Expanded(
                          flex: 1,
                          child: Column(
                            children: <Widget>[
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: <Widget>[
                                  Text(
                                    strings.get("RANK"),
                                    textAlign: TextAlign.center,
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
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: <Widget>[
                                  Text(
                                    _myBestSheet.rank == null
                                        ? "-"
                                        : _myBestSheet.rank.toString(),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Container(
                          height: 20.0,
                          width: 1.0,
                          color: Colors.black12,
                        ),
                        Expanded(
                          flex: 1,
                          child: Column(
                            children: <Widget>[
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: <Widget>[
                                  Text(
                                    strings.get("SCORE"),
                                    textAlign: TextAlign.center,
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
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: <Widget>[
                                  Text(
                                    _myBestSheet.score == null
                                        ? "-"
                                        : _myBestSheet.score.toString(),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        )
      ],
    );
  }
}
