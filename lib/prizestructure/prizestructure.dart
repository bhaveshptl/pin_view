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
    } else {
      for (dynamic _prize in widget.prizeStructure) {
        _prizeRows.add(
          Container(
            child: Padding(
              padding: const EdgeInsets.only(
                  left: 16.0, right: 16.0, top: 4.0, bottom: 4.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Text(
                    "RANK: " + _prize["rank"],
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
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
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.black38,
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
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Container(
          padding: EdgeInsets.symmetric(horizontal: 16.0),
          color: Theme.of(context).primaryColor,
          height: 40.0,
          child: Stack(
            alignment: Alignment.center,
            children: <Widget>[
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Text(
                    "Prize breakup".toUpperCase(),
                    style: Theme.of(context).primaryTextTheme.body2.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
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
        Container(
          constraints: BoxConstraints(
            maxHeight:
                (MediaQuery.of(context).size.height - kToolbarHeight) * 0.80,
          ),
          child: SingleChildScrollView(
            child: Column(
              children: <Widget>[
                Padding(
                  padding: EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 0.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Text(
                        "Prize Pool".toUpperCase(),
                        textAlign: TextAlign.center,
                        style:
                            Theme.of(context).primaryTextTheme.body2.copyWith(
                                  color: Colors.black38,
                                  fontWeight: FontWeight.w900,
                                ),
                      ),
                      Text(
                        "Winners".toUpperCase(),
                        textAlign: TextAlign.center,
                        style:
                            Theme.of(context).primaryTextTheme.body2.copyWith(
                                  color: Colors.black38,
                                  fontWeight: FontWeight.w900,
                                ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
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
                            formatCurrency.format(widget.contest.prizeDetails[0]
                                ["totalPrizeAmount"]),
                            textAlign: TextAlign.center,
                            style: Theme.of(context)
                                .primaryTextTheme
                                .body2
                                .copyWith(
                                  color: Colors.black,
                                  fontWeight: FontWeight.w900,
                                ),
                          ),
                        ],
                      ),
                      Text(
                        widget.contest.prizeDetails[0]["noOfPrizes"].toString(),
                        style:
                            Theme.of(context).primaryTextTheme.body2.copyWith(
                                  color: Colors.black,
                                  fontWeight: FontWeight.w900,
                                ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(top: 16.0, bottom: 32.0),
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
              ],
            ),
          ),
        ),
      ],
    );
  }
}
