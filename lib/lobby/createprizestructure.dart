import 'dart:convert';
import 'package:flutter/material.dart';

import 'package:playfantasy/utils/stringtable.dart';
import 'package:playfantasy/modal/prizestructure.dart';

class CreatePrizeStructure extends StatefulWidget {
  final Function onClose;
  final double totalPrize;
  final GlobalKey<ScaffoldState> scaffoldKey;
  final List<PrizeStructure> suggestedPrizes;

  CreatePrizeStructure(
      {this.suggestedPrizes, this.totalPrize, this.onClose, this.scaffoldKey});

  @override
  State<StatefulWidget> createState() => CreatePrizeStructureState();
}

class CreatePrizeStructureState extends State<CreatePrizeStructure> {
  List<PrizeStructure> _suggestedPrizes;
  List<TextEditingController> _winningsController = [];
  GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  TextEditingController _numberOfPrizeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _suggestedPrizes =
        (json.decode(json.encode(widget.suggestedPrizes)) as List)
            .map((i) => PrizeStructure.fromJson(i))
            .toList();

    _suggestedPrizes.forEach((PrizeStructure prizeStructure) {
      _winningsController.add(TextEditingController(
          text: (prizeStructure.amount / widget.totalPrize * 100)
              .toStringAsFixed(2)));
    });

    _numberOfPrizeController.text = _suggestedPrizes.length.toString();
  }

  getTotalPrizeAmount(List<PrizeStructure> _suggestedPrizes) {
    double _totalPrize = 0.0;
    _suggestedPrizes.forEach((PrizeStructure prizeStructure) {
      _totalPrize += prizeStructure.amount;
    });

    return _totalPrize;
  }

  String validatePrizeDistribution() {
    double totalDistribution = 0.0;
    _winningsController.forEach((TextEditingController _textController) {
      totalDistribution += double.parse(_textController.text);
    });
    if (!(totalDistribution > 99.90 && totalDistribution <= 100.0)) {
      return strings.get("AMOUNT_SHOULD_DISTRIBUTED");
    }
    return "";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomPadding: false,
      key: _scaffoldKey,
      body: Container(
        child: Column(
          children: <Widget>[
            Container(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.only(left: 8.0),
                    child: OutlineButton(
                      padding: EdgeInsets.all(0.0),
                      onPressed: () {
                        Navigator.of(context).pop();
                        widget.onClose(widget.suggestedPrizes);
                      },
                      child: Text(
                        strings.get("CANCEL").toUpperCase(),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: RaisedButton(
                      color: Colors.teal,
                      textColor: Colors.white70,
                      padding: EdgeInsets.all(0.0),
                      onPressed: () {
                        String error = validatePrizeDistribution();
                        if (widget.onClose != null && error == "") {
                          Navigator.of(context).pop();
                          widget.onClose(_suggestedPrizes);
                        } else if (error != "") {
                          _scaffoldKey.currentState.showSnackBar(SnackBar(
                            content: Text(error),
                          ));
                        }
                      },
                      child: Text(
                        strings.get("SAVE").toUpperCase(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Divider(
              height: 6.0,
              color: Colors.black45,
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Text(
                    strings.get("NUMBER_OF_PRIZE"),
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Container(
                    width: 80.0,
                    child: TextField(
                      decoration: InputDecoration(
                        contentPadding: EdgeInsets.fromLTRB(8.0, 4.0, 8.0, 4.0),
                        border: OutlineInputBorder(
                          borderSide:
                              BorderSide(width: 1.0, color: Colors.black26),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                              width: 1.0,
                              color: Theme.of(context).primaryColorDark),
                        ),
                      ),
                      style: TextStyle(
                        height: 1.0,
                        color: Colors.black87,
                      ),
                      keyboardType: TextInputType.number,
                      controller: _numberOfPrizeController,
                      onChanged: (String value) {
                        setState(() {
                          int numberOfPrize = int.parse(
                              _numberOfPrizeController.text == ""
                                  ? "0"
                                  : _numberOfPrizeController.text);
                          _suggestedPrizes = [];
                          _winningsController = [];

                          for (int i = 0; i < numberOfPrize; i++) {
                            _winningsController
                                .add(TextEditingController(text: ""));
                            _suggestedPrizes
                                .add(PrizeStructure(rank: i + 1, amount: 0.0));
                          }

                          _winningsController
                              .forEach((TextEditingController _textController) {
                            _textController.text = "";
                          });
                        });
                      },
                    ),
                  ),
                ],
              ),
            ),
            Divider(
              height: 8.0,
              color: Colors.black12,
            ),
            Expanded(
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: ListView.builder(
                      itemCount: _suggestedPrizes.length + 1,
                      itemBuilder: (context, index) {
                        int curIndex = index - 1;

                        if (index == 0) {
                          return Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Row(
                              children: <Widget>[
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    strings.get("RANK"),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                                Expanded(
                                  flex: 1,
                                  child: Text(
                                    strings.get("WINNING_PERCENT"),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    strings.get("AMOUNT"),
                                    textAlign: TextAlign.center,
                                  ),
                                )
                              ],
                            ),
                          );
                        }
                        return Padding(
                          padding: const EdgeInsets.all(4.0),
                          child: Row(
                            children: <Widget>[
                              Expanded(
                                flex: 2,
                                child: Text(
                                  _suggestedPrizes
                                      .elementAt(curIndex)
                                      .rank
                                      .toString(),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              Expanded(
                                flex: 1,
                                child: TextField(
                                  decoration: InputDecoration(
                                    contentPadding:
                                        EdgeInsets.fromLTRB(8.0, 4.0, 8.0, 4.0),
                                    border: OutlineInputBorder(
                                      borderSide: BorderSide(
                                        width: 1.0,
                                        color: Colors.black26,
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderSide: BorderSide(
                                          width: 1.0,
                                          color: Theme.of(context)
                                              .primaryColorDark),
                                    ),
                                  ),
                                  style: TextStyle(
                                    color: Colors.black87,
                                  ),
                                  keyboardType: TextInputType.number,
                                  controller: _winningsController[curIndex],
                                  onChanged: (String value) {
                                    double winningPercent = double.parse(
                                        value == "" ? "0.0" : value);
                                    setState(() {
                                      _suggestedPrizes[curIndex].amount =
                                          widget.totalPrize *
                                              (winningPercent / 100);
                                    });
                                  },
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(
                                  _suggestedPrizes
                                      .elementAt(curIndex)
                                      .amount
                                      .toStringAsFixed(2),
                                  textAlign: TextAlign.center,
                                ),
                              )
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
