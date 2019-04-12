import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:playfantasy/modal/l1.dart';
import 'package:playfantasy/modal/league.dart';
import 'package:playfantasy/modal/myteam.dart';
import 'package:playfantasy/utils/stringtable.dart';

class ResultContest extends StatelessWidget {
  final League league;
  final Contest contest;
  final bool isMyContest;
  final Function onPrizeStructure;
  final List<MyTeam> myJoinedTeams;

  ResultContest({
    this.league,
    this.contest,
    this.myJoinedTeams,
    this.onPrizeStructure,
    this.isMyContest = false,
  });

  MyTeam _getMyBestTeam() {
    myJoinedTeams.sort((a, b) {
      int teamARank = a.rank == null ? 0 : a.rank;
      int teamBRank = b.rank == null ? 0 : b.rank;
      return teamARank - teamBRank;
    });
    return myJoinedTeams[0];
  }

  double _getTotalWinnings() {
    double winnings = 0.0;
    if (myJoinedTeams != null) {
      for (MyTeam team in myJoinedTeams) {
        if (team.contestId == contest.id) {
          winnings += team.prize;
        }
      }
    }
    return winnings;
  }

  @override
  Widget build(BuildContext context) {
    MyTeam _myBestTeam = myJoinedTeams == null ? null : _getMyBestTeam();
    double _totalWinnings = _getTotalWinnings();

    final formatCurrency = NumberFormat.currency(
      locale: "hi_IN",
      symbol: contest.prizeType == 1 ? "" : strings.rupee,
      decimalDigits: 0,
    );

    TextStyle bodyStyle = TextStyle(
      color: Theme.of(context).primaryColorDark,
      fontSize: Theme.of(context).primaryTextTheme.title.fontSize,
      fontWeight: FontWeight.w700,
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
                          _myBestTeam == null ? "-" : _myBestTeam.name,
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
                          _myBestTeam == null
                              ? "-"
                              : _myBestTeam.score.toString(),
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
                          _myBestTeam == null
                              ? "-"
                              : _myBestTeam.rank.toString(),
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
