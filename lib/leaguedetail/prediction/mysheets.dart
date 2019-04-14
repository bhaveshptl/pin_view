import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';

import 'package:playfantasy/appconfig.dart';
import 'package:playfantasy/leaguedetail/prediction/createsheet/createsheet.dart';
import 'package:playfantasy/leaguedetail/prediction/createsheet/predictionsummarywidget.dart';
import 'package:playfantasy/modal/league.dart';
import 'package:playfantasy/modal/mysheet.dart';
import 'package:playfantasy/modal/prediction.dart';
import 'package:playfantasy/lobby/tabs/leaguecard.dart';
import 'package:playfantasy/utils/fantasywebsocket.dart';
import 'package:playfantasy/commonwidgets/fantasypageroute.dart';

class MySheets extends StatefulWidget {
  final League league;
  final List<MySheet> mySheets;
  final Prediction predictionData;

  MySheets({this.league, this.mySheets, this.predictionData});

  @override
  MySheetsState createState() => MySheetsState();
}

class MySheetsState extends State<MySheets> {
  int _selectedItemIndex = -1;
  StreamSubscription _streamSubscription;

  @override
  initState() {
    super.initState();
    _streamSubscription =
        FantasyWebSocket().subscriber().stream.listen(_onWsMsg);
    widget.mySheets.sort((a, b) {
      return a.status - b.status;
    });
  }

  _onWsMsg(data) {
    if (data["iType"] == RequestType.MY_SHEET_ADDED &&
        data["bSuccessful"] == true) {
      MySheet sheetAdded = MySheet.fromJson(data["data"]);
      int existingIndex = -1;
      List<int>.generate(widget.mySheets.length, (index) {
        MySheet mySheet = widget.mySheets[index];
        if (mySheet.id == sheetAdded.id) {
          existingIndex = index;
        }
      });
      if (existingIndex == -1) {
        widget.mySheets.add(sheetAdded);
      } else {
        widget.mySheets[existingIndex] = sheetAdded;
      }
      setState(() {
        widget.mySheets.sort((a, b) {
          return a.status - b.status;
        });
      });
    }
  }

  Widget _createMySheetsWidget(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 72.0),
                  child: Container(
                    margin: const EdgeInsets.all(16.0),
                    child: ExpansionPanelList(
                      expansionCallback: (int index, bool isExpanded) {
                        setState(() {
                          if (index == _selectedItemIndex) {
                            _selectedItemIndex = -1;
                          } else {
                            _selectedItemIndex = index;
                          }
                        });
                      },
                      children: getExpansionPanel(context),
                    ),
                  ),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  List<ExpansionPanel> getExpansionPanel(BuildContext context) {
    int index = 0;
    List<ExpansionPanel> items = [];
    for (MySheet mySheet in widget.mySheets) {
      items.add(
        ExpansionPanel(
          isExpanded: index == _selectedItemIndex,
          headerBuilder: (context, isExpanded) {
            return FlatButton(
              onPressed: () {
                setState(() {
                  int curIndex = widget.mySheets.indexOf(mySheet);
                  if (curIndex == _selectedItemIndex) {
                    _selectedItemIndex = -1;
                  } else {
                    _selectedItemIndex = curIndex;
                  }
                });
              },
              child: Row(
                children: <Widget>[
                  getExpansionHeader(context, isExpanded, mySheet),
                ],
              ),
            );
          },
          body: _getExpansionBody(mySheet),
        ),
      );
      index++;
    }

    return items;
  }

  _getExpansionBody(MySheet mySheet) {
    Map<int, int> answers = {};
    List<int>.generate(mySheet.answers.length, (index) {
      answers[index] = mySheet.answers[index];
    });
    Map<int, int> flips = {};
    if (mySheet.boosterThree != null) {
      mySheet.boosterThree.forEach((f) {
        if (f["to"] < f["from"]) {
          flips[f["to"]] = f["from"];
        } else {
          flips[f["from"]] = f["to"];
        }
      });
    }

    return PredictionSummaryWidget(
      flips: flips,
      answers: answers,
      xBooster: mySheet.boosterOne,
      bPlusBooster: mySheet.boosterTwo,
      predictionData: widget.predictionData,
    );
  }

  void _onEditSheet(BuildContext context) async {
    final result = await Navigator.of(context).push(
      FantasyPageRoute(
        pageBuilder: (context) => CreateSheet(
              league: widget.league,
              predictionData: widget.predictionData,
              selectedSheet: widget.mySheets[_selectedItemIndex],
              mode: SheetCreationMode.EDIT_SHEET,
            ),
      ),
    );

    if (result != null) {
      Scaffold.of(context).showSnackBar(SnackBar(content: Text("$result")));
    }
    setState(() {
      _selectedItemIndex = -1;
    });
  }

  void _onCloneSheet(BuildContext context) async {
    final result = await Navigator.of(context).push(
      FantasyPageRoute(
        pageBuilder: (context) => CreateSheet(
              league: widget.league,
              predictionData: widget.predictionData,
              selectedSheet: MySheet.fromJson(
                json.decode(
                  json.encode(widget.mySheets[_selectedItemIndex]),
                ),
              ),
              mode: SheetCreationMode.CLONE_SHEET,
            ),
      ),
    );
    if (result != null) {
      Scaffold.of(context).showSnackBar(SnackBar(content: Text("$result")));
    }
    setState(() {
      _selectedItemIndex = -1;
    });
  }

  void _onCreateSheet(BuildContext context) async {
    final result = await Navigator.of(context).push(
      FantasyPageRoute(
        pageBuilder: (context) => CreateSheet(
              league: widget.league,
              mode: SheetCreationMode.CREATE_SHEET,
              predictionData: widget.predictionData,
            ),
      ),
    );
    if (result != null) {
      Scaffold.of(context).showSnackBar(SnackBar(content: Text("$result")));
    }
    setState(() {
      _selectedItemIndex = -1;
    });
  }

  Widget getExpansionHeader(
      BuildContext context, bool isExpanded, MySheet mySheet) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.only(left: 24.0),
        child: Column(
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Padding(
                      padding: EdgeInsets.only(right: 8.0),
                      child: Text(mySheet.name),
                    ),
                    mySheet.status == 0 ? Icon(Icons.drafts) : Container(),
                  ],
                ),
                isExpanded
                    ? Row(
                        mainAxisSize: MainAxisSize.max,
                        children: <Widget>[
                          IconButton(
                            padding: EdgeInsets.all(0.0),
                            onPressed: () {
                              _onEditSheet(context);
                            },
                            icon: Column(
                              children: <Widget>[
                                Icon(Icons.edit),
                                Padding(
                                  padding: EdgeInsets.only(top: 4.0),
                                  child: Text(
                                    "EDIT",
                                    style: Theme.of(context)
                                        .primaryTextTheme
                                        .caption
                                        .copyWith(color: Colors.black54),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            padding: EdgeInsets.all(0.0),
                            onPressed: () {
                              _onCloneSheet(context);
                            },
                            icon: Column(
                              children: <Widget>[
                                Icon(Icons.content_copy),
                                Padding(
                                  padding: EdgeInsets.only(top: 4.0),
                                  child: Text(
                                    "CLONE",
                                    style: Theme.of(context)
                                        .primaryTextTheme
                                        .caption
                                        .copyWith(color: Colors.black54),
                                  ),
                                ),
                              ],
                            ),
                          )
                        ],
                      )
                    : Container(),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _getEmptyMyTeamsWidget(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Text(
          "No sheets available for this match.",
          textAlign: TextAlign.center,
          style: TextStyle(
              color: Theme.of(context).errorColor,
              fontSize: Theme.of(context).primaryTextTheme.title.fontSize),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 16.0),
          child: Row(
            children: <Widget>[
              Expanded(
                child: Column(
                  children: <Widget>[
                    OutlineButton(
                      onPressed: () {
                        _onCreateSheet(context);
                      },
                      borderSide:
                          BorderSide(color: Theme.of(context).primaryColorDark),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Icon(Icons.add),
                          Text(
                            "CREATE SHEET",
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
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "My Sheets".toUpperCase(),
        ),
      ),
      body: Container(
        decoration: AppConfig.of(context).showBackground
            ? BoxDecoration(
                image: DecorationImage(
                    image: AssetImage("images/background.png"),
                    repeat: ImageRepeat.repeat),
              )
            : null,
        child: Column(
          children: <Widget>[
            LeagueCard(
              widget.league,
              clickable: false,
            ),
            Divider(
              height: 2.0,
            ),
            Expanded(
              child: widget.mySheets.length > 0
                  ? _createMySheetsWidget(context)
                  : _getEmptyMyTeamsWidget(context),
            )
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _onCreateSheet(context);
        },
        child: Icon(Icons.add),
      ),
    );
  }

  @override
  void dispose() {
    _streamSubscription.cancel();
    super.dispose();
  }
}
