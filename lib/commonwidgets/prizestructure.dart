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
  List<Widget> _getPrizeList() {
    final formatCurrency =
        NumberFormat.currency(locale: "hi_IN", symbol: "", decimalDigits: 0);

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
                    _prize["rank"],
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
                          : Text(strings.rupee),
                      Text(
                        formatCurrency
                            .format(double.parse(_prize["amount"].toString())),
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
    final formatCurrency =
        NumberFormat.currency(locale: "hi_IN", symbol: "", decimalDigits: 0);

    return AlertDialog(
      title: Text(strings.get("PRIZE_STRUCTURE")),
      contentPadding: EdgeInsets.fromLTRB(24.0, 20.0, 24.0, 0.0),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Row(
              children: <Widget>[
                Text(
                  "Winnings ",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: Theme.of(context).primaryColorDark,
                      fontSize:
                          Theme.of(context).primaryTextTheme.headline.fontSize),
                ),
                widget.contest.prizeType == 1
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
                            color: Theme.of(context).primaryColorDark,
                            fontSize: Theme.of(context)
                                .primaryTextTheme
                                .headline
                                .fontSize),
                      ),
                Text(
                  formatCurrency.format(
                      widget.contest.prizeDetails[0]["totalPrizeAmount"]),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: Theme.of(context).primaryColorDark,
                      fontSize:
                          Theme.of(context).primaryTextTheme.headline.fontSize),
                ),
              ],
            ),
            Divider(
              color: Colors.black12,
            ),
            Row(
              children: <Widget>[
                Expanded(
                  flex: 1,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 16.0),
                    child: Text(
                      strings.get("RANK").toUpperCase(),
                    ),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 16.0),
                    child: Text(
                      strings.get("PRIZE").toUpperCase(),
                      textAlign: TextAlign.right,
                    ),
                  ),
                )
              ],
            ),
            Divider(
              color: Colors.black12,
            ),
            Row(
              children: <Widget>[
                Expanded(
                  child: Column(
                    children: _getPrizeList(),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: Divider(
                color: Colors.black12,
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      strings.get("NOTES") +
                          ": " +
                          strings.get("PRIZE_STRUCTURE_TEXT_1") +
                          " " +
                          strings.get("PRIZE_STRUCTURE_TEXT_2") +
                          " " +
                          strings.get("PRIZE_STRUCTURE_TEXT_3"),
                      style: TextStyle(
                        fontSize:
                            Theme.of(context).primaryTextTheme.caption.fontSize,
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
      actions: <Widget>[
        FlatButton(
          child: Text(
            strings.get("CLOSE").toUpperCase(),
          ),
          onPressed: () {
            Navigator.of(context).pop();
          },
        )
      ],
    );
  }
}
