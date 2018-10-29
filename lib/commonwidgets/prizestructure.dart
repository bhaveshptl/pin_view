import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'package:playfantasy/modal/l1.dart';
import 'package:playfantasy/utils/apiutil.dart';
import 'package:playfantasy/utils/stringtable.dart';
import 'package:playfantasy/utils/sharedprefhelper.dart';

class PrizeStructure extends StatefulWidget {
  final Contest contest;

  PrizeStructure({this.contest});

  @override
  PrizeStructureState createState() => PrizeStructureState();
}

class PrizeStructureState extends State<PrizeStructure> {
  String cookie;
  List<dynamic> _prizeStructure = [];

  @override
  void initState() {
    super.initState();
    _getPrizeStructure();
  }

  _getPrizeStructure() async {
    if (cookie == null) {
      Future<dynamic> futureCookie = SharedPrefHelper.internal().getCookie();
      await futureCookie.then((value) {
        cookie = value;
      });
    }

    return new http.Client().get(
      ApiUtil.GET_PRIZESTRUCTURE +
          widget.contest.id.toString() +
          "/prizestructure",
      headers: {'Content-type': 'application/json', "cookie": cookie},
    ).then(
      (http.Response res) {
        if (res.statusCode >= 200 && res.statusCode <= 299) {
          setState(() {
            _prizeStructure = json.decode(res.body);
          });
        }
      },
    );
  }

  List<Widget> _getPrizeList() {
    List<Widget> _prizeRows = [];
    if (_prizeStructure.length == 0) {
      _prizeRows.add(Container());
    } else {
      for (dynamic _prize in _prizeStructure) {
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
                  Text(
                    strings.rupee + _prize["amount"].toStringAsFixed(2),
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
    return AlertDialog(
      title: Text(strings.get("PRIZE_STRUCTURE")),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Row(
            children: <Widget>[
              Padding(
                padding: EdgeInsets.fromLTRB(0.0, 0.0, 0.0, 10.0),
                child: Text(
                  strings.get("TOTAL_WINNINGS") +
                      " " +
                      strings.rupee +
                      widget.contest.prizeDetails[0]["totalPrizeAmount"]
                          .toString(),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: Theme.of(context).primaryColorDark,
                      fontSize:
                          Theme.of(context).primaryTextTheme.headline.fontSize),
                ),
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
