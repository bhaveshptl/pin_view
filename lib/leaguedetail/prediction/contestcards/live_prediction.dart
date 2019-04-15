import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:playfantasy/modal/l1.dart';
import 'package:playfantasy/modal/league.dart';
import 'package:playfantasy/modal/mysheet.dart';
import 'package:playfantasy/utils/stringtable.dart';

class LivePrediction extends StatelessWidget {
  final League league;
  final Contest contest;
  final Function onPrizeStructure;
  final List<MySheet> myJoinedSheets;

  LivePrediction({
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
                          "Prediction",
                          style: TextStyle(color: Colors.black38),
                        ),
                        Text(
                          (_myBestSheet == null || _myBestSheet.name == null)
                              ? "-"
                              : _myBestSheet.name,
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
                          (_myBestSheet == null || _myBestSheet.name == null)
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
      ],
    );
  }
}
