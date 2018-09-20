import 'package:flutter/material.dart';
import 'package:playfantasy/contestdetail/contestdetail.dart';

import 'package:playfantasy/modal/l1.dart';

class ContestCard extends StatelessWidget {
  final Contest _contest;
  final Function _onClick;

  ContestCard(this._contest, this._onClick);

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: _contest.id.toString() + " - " + _contest.name,
      child: Card(
        elevation: 3.0,
        clipBehavior: Clip.antiAliasWithSaveLayer,
        child: FlatButton(
          onPressed: () {
            _onClick(_contest);
          },
          padding: EdgeInsets.all(0.0),
          child: Column(
            children: <Widget>[
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Expanded(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Container(
                          color: Colors.black45,
                          child: Padding(
                            padding: EdgeInsets.fromLTRB(10.0, 5.0, 10.0, 5.0),
                            child: Text(
                              _contest.brand["info"],
                              style: TextStyle(color: Colors.white70),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Text(
                      _contest.name,
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(left: 10.0, right: 10.0),
                      child: Text(
                        "#" + _contest.id.toString(),
                        textAlign: TextAlign.right,
                        style: TextStyle(color: Colors.black12),
                      ),
                    ),
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
                              child: Text(
                                "₹" +
                                    _contest.prizeDetails[0]["totalPrizeAmount"]
                                        .toString(),
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    color: Theme.of(context).primaryColorDark,
                                    fontSize: Theme.of(context)
                                        .primaryTextTheme
                                        .headline
                                        .fontSize),
                              ),
                            ),
                            Container(
                              height: 20.0,
                              width: 1.0,
                              color: Colors.black12,
                            ),
                            Expanded(
                              child: Tooltip(
                                message: "Number of winners.",
                                child: FlatButton(
                                  padding: EdgeInsets.all(0.0),
                                  onPressed: () {},
                                  child: Column(
                                    children: <Widget>[
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: <Widget>[
                                          Padding(
                                            padding: const EdgeInsets.only(
                                                left: 16.0),
                                            child: Text(
                                              "WINNERS",
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
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: <Widget>[
                                          Text(_contest.prizeDetails[0]
                                                  ["noOfPrizes"]
                                              .toString())
                                        ],
                                      )
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        Container(
                          child: Padding(
                            padding: EdgeInsets.only(left: 10.0, bottom: 5.0),
                            child: Row(
                              children: <Widget>[
                                _contest.bonusAllowed > 0
                                    ? Tooltip(
                                        message: "You can use " +
                                            _contest.bonusAllowed.toString() +
                                            "% of entry fee amount from bonus.",
                                        child: Padding(
                                          padding:
                                              const EdgeInsets.only(right: 8.0),
                                          child: CircleAvatar(
                                            backgroundColor: Colors.redAccent,
                                            maxRadius: 10.0,
                                            child: Text(
                                              "B",
                                              style: TextStyle(
                                                  color: Colors.white70,
                                                  fontSize: Theme.of(context)
                                                      .primaryTextTheme
                                                      .caption
                                                      .fontSize),
                                            ),
                                          ),
                                        ),
                                      )
                                    : Container(),
                                _contest.teamsAllowed > 1
                                    ? Tooltip(
                                        message: "You can participate with " +
                                            _contest.teamsAllowed.toString() +
                                            " different teams.",
                                        child: CircleAvatar(
                                          backgroundColor: Colors.redAccent,
                                          maxRadius: 10.0,
                                          child: Text(
                                            "M",
                                            style: TextStyle(
                                                color: Colors.white70,
                                                fontSize: Theme.of(context)
                                                    .primaryTextTheme
                                                    .caption
                                                    .fontSize),
                                          ),
                                        ),
                                      )
                                    : Container(),
                                Expanded(
                                  child: Text(
                                    _contest.joined.toString() +
                                        "/" +
                                        _contest.size.toString() +
                                        " joined",
                                    textAlign: TextAlign.center,
                                  ),
                                )
                              ],
                            ),
                          ),
                        )
                      ],
                    ),
                  ),
                  Container(
                    height: 40.0,
                    width: 1.0,
                    color: Colors.black12,
                  ),
                  Expanded(
                    flex: 1,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: <Widget>[
                        Tooltip(
                          message: "Join contest with ₹" +
                              _contest.entryFee.toString() +
                              " entry fee.",
                          child: RaisedButton(
                            onPressed: () {},
                            color: Theme.of(context).primaryColorDark,
                            child: Text(
                              "₹" + _contest.entryFee.toString(),
                              style: TextStyle(color: Colors.white70),
                            ),
                          ),
                        ),
                      ],
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
