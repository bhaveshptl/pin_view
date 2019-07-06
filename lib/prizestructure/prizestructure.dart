import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:playfantasy/modal/l1.dart';
import 'package:playfantasy/utils/stringtable.dart';

class PrizeStructure extends StatefulWidget {
  final Contest contest;
  final List<dynamic> prizeStructure;

  PrizeStructure({
    this.contest,
    this.prizeStructure,
  });

  @override
  PrizeStructureState createState() => PrizeStructureState();
}

class PrizeStructureState extends State<PrizeStructure> {
  String winners = "";
  NumberFormat formatCurrency;

  @override
  void initState() {
    formatCurrency = NumberFormat.currency(
      locale: "hi_IN",
      symbol: widget.contest.prizeType == 1 ? "" : strings.rupee,
      decimalDigits: 2,
    );
    super.initState();
  }

  List<Widget> _getPrizeList() {
    List<Widget> _prizeRows = [];
    if (widget.prizeStructure.length == 0) {
      _prizeRows.add(Container());
    } else if (widget.contest.multiplier) {
      int i = 0;
      int prevIndex = 0;
      List<Map<String, dynamic>> updatePrizeStructure = [];
      for (dynamic _prize in widget.prizeStructure) {
        if (prevIndex != i) {
          if ((widget.prizeStructure[i]["amount"] !=
                  widget.prizeStructure[prevIndex]["amount"]) ||
              i == widget.prizeStructure.length - 1) {
            updatePrizeStructure.add({
              "rank": (prevIndex + 1).toString() + "-" + (i + 1).toString(),
              "amount": widget.prizeStructure[prevIndex]["amount"]
            });
            prevIndex = i;
          }
        }
        i++;
      }
      for (Map<String, dynamic> _prize in updatePrizeStructure) {
        _prizeRows.add(
          Container(
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: Colors.grey.shade200,
                ),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.only(
                  left: 16.0, right: 16.0, top: 12.0, bottom: 12.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Text(
                    "RANK: " + _prize["rank"],
                    style: Theme.of(context).primaryTextTheme.subhead.copyWith(
                          color: Colors.grey.shade800,
                        ),
                  ),
                  Row(
                    children: <Widget>[
                      widget.contest.prizeType == 1
                          ? Image.asset(
                              strings.chips,
                              width: 16.0,
                              height: 12.0,
                              fit: BoxFit.contain,
                            )
                          : Container(),
                      Text(
                        formatCurrency.format(
                          double.parse(_prize["amount"].toString()),
                        ),
                        style:
                            Theme.of(context).primaryTextTheme.subhead.copyWith(
                                  color: Colors.grey.shade600,
                                ),
                      )
                    ],
                  )
                ],
              ),
            ),
          ),
        );
      }
    } else {
      for (dynamic _prize in widget.prizeStructure) {
        _prizeRows.add(
          Container(
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: Colors.grey.shade200,
                ),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.only(
                  left: 16.0, right: 16.0, top: 12.0, bottom: 12.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Text(
                    "RANK: " + _prize["rank"],
                    style: Theme.of(context).primaryTextTheme.subhead.copyWith(
                          color: Colors.grey.shade800,
                        ),
                  ),
                  Row(
                    children: <Widget>[
                      widget.contest.prizeType == 1
                          ? Image.asset(
                              strings.chips,
                              width: 16.0,
                              height: 12.0,
                              fit: BoxFit.contain,
                            )
                          : Container(),
                      Text(
                        formatCurrency.format(
                          double.parse(_prize["amount"].toString()),
                        ),
                        style:
                            Theme.of(context).primaryTextTheme.subhead.copyWith(
                                  color: Colors.grey.shade600,
                                ),
                      )
                    ],
                  )
                ],
              ),
            ),
          ),
        );
      }
    }

    return _prizeRows;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: (MediaQuery.of(context).size.height - kToolbarHeight) * 0.80,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            color: Theme.of(context).primaryColor,
            height: 48.0,
            child: Stack(
              alignment: Alignment.center,
              children: <Widget>[
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Text(
                      "Prize breakup".toUpperCase(),
                      style: Theme.of(context).primaryTextTheme.title.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: <Widget>[
                    IconButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      icon: Icon(
                        Icons.close,
                        color: Colors.white54,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: <Widget>[
                  Padding(
                    padding: EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 0.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        Text(
                          "Prize Pool".toUpperCase(),
                          textAlign: TextAlign.center,
                          style: Theme.of(context)
                              .primaryTextTheme
                              .subtitle
                              .copyWith(
                                color: Colors.grey.shade500,
                              ),
                        ),
                        Text(
                          "Winners".toUpperCase(),
                          textAlign: TextAlign.center,
                          style: Theme.of(context)
                              .primaryTextTheme
                              .subtitle
                              .copyWith(
                                color: Colors.grey.shade500,
                              ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding:
                        EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        widget.contest.multiplier
                            ? Row(
                                children: <Widget>[
                                  Text(
                                    widget.contest.topPrecent.toString(),
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontSize: 20.0,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  Text(
                                    "%",
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontSize: 12.0,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  Text(
                                    " win ",
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontSize: 20.0,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  Text(
                                    formatCurrency.format(
                                      widget.contest.entryFee *
                                          widget.contest.winningsMultiplier,
                                    ),
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontSize: 24.0,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              )
                            : Row(
                                children: <Widget>[
                                  widget.contest.prizeType == 1
                                      ? Image.asset(
                                          strings.chips,
                                          width: 16.0,
                                          height: 12.0,
                                          fit: BoxFit.contain,
                                        )
                                      : Container(),
                                  Text(
                                    formatCurrency.format(widget.contest
                                        .prizeDetails[0]["totalPrizeAmount"]),
                                    textAlign: TextAlign.center,
                                    style: Theme.of(context)
                                        .primaryTextTheme
                                        .title
                                        .copyWith(
                                          color: Colors.black,
                                          fontWeight: FontWeight.w700,
                                        ),
                                  ),
                                ],
                              ),
                        Text(
                          widget.contest.prizeDetails[0]["noOfPrizes"]
                              .toString(),
                          style:
                              Theme.of(context).primaryTextTheme.title.copyWith(
                                    color: Colors.black,
                                    fontWeight: FontWeight.w700,
                                  ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.only(bottom: 32.0),
                    child: Row(
                      children: <Widget>[
                        Expanded(
                          child: Column(
                            children: _getPrizeList(),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(
                        bottom: 8.0, left: 8.0, right: 8.0),
                    child: Row(
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            strings.get("PRIZE_STRUCTURE_TEXT_1") +
                                " " +
                                strings.get("PRIZE_STRUCTURE_TEXT_2") +
                                " " +
                                strings.get("PRIZE_STRUCTURE_TEXT_3"),
                            style: TextStyle(
                              fontSize: Theme.of(context)
                                  .primaryTextTheme
                                  .caption
                                  .fontSize,
                              color: Colors.black54,
                            ),
                            textAlign: TextAlign.justify,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
