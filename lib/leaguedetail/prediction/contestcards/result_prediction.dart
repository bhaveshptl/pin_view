import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:playfantasy/modal/l1.dart';
import 'package:playfantasy/modal/league.dart';
import 'package:playfantasy/modal/mysheet.dart';
import 'package:playfantasy/utils/stringtable.dart';

class ResultPrediction extends StatelessWidget {
  final League league;
  final Contest contest;
  final Function onPrizeStructure;
  final List<MySheet> myJoinedSheets;

  ResultPrediction({
    this.league,
    this.contest,
    this.myJoinedSheets,
    this.onPrizeStructure,
  });

  MySheet _getMyBestSheet() {
    myJoinedSheets.sort((a, b) {
      int sheetARank = a.rank == null ? 0 : a.rank;
      int sheetBRank = b.rank == null ? 0 : b.rank;
      return sheetARank - sheetBRank;
    });
    return myJoinedSheets[0];
  }

  double _getTotalWinnings() {
    double winnings = 0.0;
    if (myJoinedSheets != null) {
      for (MySheet sheet in myJoinedSheets) {
        if (sheet.contestId == contest.id) {
          winnings += sheet.prize;
        }
      }
    }
    return winnings;
  }

  @override
  Widget build(BuildContext context) {
    double _totalWinnings = _getTotalWinnings();
    MySheet _myBestSheet = myJoinedSheets == null ? null : _getMyBestSheet();
    TextStyle bodyStyle = TextStyle(
      color: Theme.of(context).primaryColorDark,
      fontSize: Theme.of(context).primaryTextTheme.title.fontSize,
      fontWeight: FontWeight.w700,
    );

    final formatCurrency =
        NumberFormat.currency(locale: "hi_IN", symbol: "", decimalDigits: 0);

    return Column(
      children: <Widget>[
        Container(
          padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Column(
            children: <Widget>[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          "Prize Pool",
                          style: TextStyle(color: Colors.black38),
                        ),
                        Row(
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
                              style: bodyStyle,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      children: <Widget>[
                        Text(
                          "Winners",
                          style: TextStyle(color: Colors.black38),
                        ),
                        Text(
                          contest.prizeDetails[0]["noOfPrizes"].toString(),
                          style: bodyStyle,
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: <Widget>[
                        Text(
                          "Entry",
                          style: TextStyle(color: Colors.black38),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
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
                              formatCurrency.format(contest.entryFee),
                              style: bodyStyle,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              Divider(
                color: Colors.grey.shade300,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          "Team",
                          style: TextStyle(color: Colors.black38),
                        ),
                        Text(
                          _myBestSheet == null ? "-" : _myBestSheet.name,
                          textAlign: TextAlign.center,
                          style: bodyStyle,
                        )
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      children: <Widget>[
                        Text(
                          "Points",
                          style: TextStyle(color: Colors.black38),
                        ),
                        Text(
                          _myBestSheet == null
                              ? "-"
                              : _myBestSheet.score.toString(),
                          style: bodyStyle,
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: <Widget>[
                        Text(
                          "Rank",
                          style: TextStyle(color: Colors.black38),
                        ),
                        Text(
                          _myBestSheet == null
                              ? "-"
                              : _myBestSheet.rank.toString(),
                          style: bodyStyle,
                        ),
                      ],
                    ),
                  )
                ],
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
              Row(
                children: <Widget>[
                  Text(
                    "You Won ",
                    style: Theme.of(context).primaryTextTheme.body1.copyWith(
                          color: Colors.green,
                          fontWeight: FontWeight.w900,
                        ),
                  ),
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
                    formatCurrency.format(_totalWinnings),
                    style: Theme.of(context).primaryTextTheme.body1.copyWith(
                          color: Colors.green,
                          fontWeight: FontWeight.w900,
                        ),
                  )
                ],
              ),
            ],
          ),
        )
      ],
    );
  }
}
