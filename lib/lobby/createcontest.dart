import 'package:flutter/material.dart';
import 'package:playfantasy/lobby/createprizestructure.dart';
import 'package:playfantasy/lobby/tabs/leaguecard.dart';
import 'package:playfantasy/modal/league.dart';

class CreateContest extends StatefulWidget {
  final League _league;

  CreateContest(this._league);

  @override
  State<StatefulWidget> createState() => CreateContestState();
}

class CreateContestState extends State<CreateContest> {
  int _totalPrize = 0;
  int _numberOfPrize = 0;
  bool _bIsMultyEntry = false;
  final _customPrizeStructure = [];
  final _suggestedPrizeStructure = [];
  final _formKey = GlobalKey<FormState>();
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  _onSearchContest() {
    if (_formKey.currentState.validate()) {
      _showComingsoonDialog();
    }
  }

  _onCustomPrizeStructure(final prizeStructure) {}

  _onEditPrize() {
    _scaffoldKey.currentState.showBottomSheet((context) {
      return Container(
        decoration: new BoxDecoration(
          color: Colors.white,
          boxShadow: [
            new BoxShadow(
              color: Colors.black,
              blurRadius: 20.0,
            ),
          ],
        ),
        // color: Colors.blueGrey,
        height: 550.0,
        child: CreatePrizeStructure(
          customPrizes: _customPrizeStructure,
          suggestedPrizes: _suggestedPrizeStructure,
          onSave: (prizeStructure) {
            _onCustomPrizeStructure(prizeStructure);
          },
        ),
      );
    });
  }

  _showComingsoonDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Create contest"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Padding(
                    padding: EdgeInsets.fromLTRB(0.0, 0.0, 0.0, 10.0),
                    child: Text(
                      "Coming Soon!",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 24.0),
                    ),
                  ),
                ],
              ),
              Text(
                  "We are currently working on this feature and will launch soon.")
            ],
          ),
          actions: <Widget>[
            FlatButton(
              child: Text("OK"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            )
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text("Create contest"),
      ),
      body: Column(
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: LeagueCard(
                    widget._league,
                    clickable: false,
                  ),
                ),
              ),
            ],
          ),
          Divider(
            height: 2.0,
            color: Colors.black12,
          ),
          Expanded(
            child: Form(
              key: _formKey,
              child: ListView(
                children: <Widget>[
                  ListTile(
                    leading: TextFormField(
                      decoration: InputDecoration(
                        labelText: 'Contest name',
                      ),
                      validator: (value) {},
                      onEditingComplete: () {
                        _onSearchContest();
                      },
                      textInputAction: TextInputAction.next,
                    ),
                  ),
                  ListTile(
                    leading: Row(
                      children: <Widget>[
                        Expanded(
                          flex: 1,
                          child: Text(
                            "Type",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        Expanded(
                          flex: 4,
                          child: ContestTypeRadio(
                            defaultValue: 0,
                            onValueChanged: (int value) {},
                          ),
                        ),
                      ],
                    ),
                  ),
                  ListTile(
                    leading: TextFormField(
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: "Entry fee",
                        hintText: '1 - 10,000',
                        prefix: Padding(
                          padding: const EdgeInsets.only(left: 2.0, right: 4.0),
                          child: Text('₹'),
                        ),
                      ),
                      validator: (value) {
                        final int entryFee = int.parse(value);
                        if (value.isEmpty ||
                            entryFee <= 0 ||
                            entryFee > 10000) {
                          return 'Entry fee should be between 1 to 10,000';
                        }
                      },
                      onEditingComplete: () {
                        _onSearchContest();
                      },
                      textInputAction: TextInputAction.next,
                    ),
                  ),
                  ListTile(
                    leading: TextFormField(
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: "Participants",
                        hintText: '2-100',
                      ),
                      validator: (value) {
                        final int noOfParticipants = int.parse(value);
                        if (value.isEmpty ||
                            noOfParticipants <= 1 ||
                            noOfParticipants > 100) {
                          return 'Participants should be between 2 to 100.';
                        }
                      },
                      onEditingComplete: () {
                        _onSearchContest();
                      },
                      textInputAction: TextInputAction.next,
                    ),
                  ),
                  ListTile(
                    leading: Row(
                      children: <Widget>[
                        Text(
                          "Multi entry",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Switch(
                          onChanged: (bool value) {},
                          value: _bIsMultyEntry,
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 16.0, bottom: 16.0),
                    child: ListTile(
                      leading: Row(
                        children: <Widget>[
                          Expanded(
                            flex: 1,
                            child: Container(
                              decoration: BoxDecoration(
                                border: Border.all(
                                    width: 1.0, color: Colors.black26),
                              ),
                              child: Column(
                                children: <Widget>[
                                  Container(
                                    color: Theme.of(context).primaryColor,
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: <Widget>[
                                        Padding(
                                          padding: const EdgeInsets.all(8.0),
                                          child: Text(
                                            "Total prize",
                                            style: TextStyle(
                                                color: Colors.white70,
                                                fontSize: Theme.of(context)
                                                    .primaryTextTheme
                                                    .subhead
                                                    .fontSize),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: <Widget>[
                                      Container(
                                        height: 48.0,
                                        child: Align(
                                          alignment: Alignment.center,
                                          child: Padding(
                                            padding: const EdgeInsets.all(8.0),
                                            child: Text(
                                                "₹ " + _totalPrize.toString()),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 1,
                            child: Container(
                              decoration: BoxDecoration(
                                border: Border.all(
                                    width: 1.0, color: Colors.black26),
                              ),
                              child: Column(
                                children: <Widget>[
                                  Container(
                                    color: Theme.of(context).primaryColor,
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: <Widget>[
                                        Stack(
                                          children: <Widget>[
                                            Padding(
                                              padding:
                                                  const EdgeInsets.all(8.0),
                                              child: Text(
                                                "Number of prizes",
                                                style: TextStyle(
                                                    color: Colors.white70,
                                                    fontSize: Theme.of(context)
                                                        .primaryTextTheme
                                                        .subhead
                                                        .fontSize),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: <Widget>[
                                      Container(
                                        child: Padding(
                                          padding: const EdgeInsets.all(8.0),
                                          child: Text(
                                            _numberOfPrize.toString(),
                                          ),
                                        ),
                                      ),
                                      Container(
                                        height: 48.0,
                                        child: IconButton(
                                          padding: EdgeInsets.all(0.0),
                                          icon: Icon(Icons.edit),
                                          onPressed: () {
                                            _onEditPrize();
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          )
                        ],
                      ),
                    ),
                  ),
                  ListTile(
                    leading: Tooltip(
                      message:
                          "Ceate private contest and play with your friends.",
                      child: Padding(
                        padding: const EdgeInsets.only(top: 32.0),
                        child: RaisedButton(
                          color: Theme.of(context).primaryColorDark,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: <Widget>[
                              Icon(
                                Icons.add,
                                color: Colors.white70,
                              ),
                              Padding(
                                padding: const EdgeInsets.only(left: 8.0),
                                child: Text(
                                  "CREATE",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: Colors.white70),
                                ),
                              ),
                            ],
                          ),
                          onPressed: () {
                            _onSearchContest();
                          },
                        ),
                      ),
                    ),
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ContestTypeRadio extends StatefulWidget {
  final Function onValueChanged;
  final int defaultValue;
  ContestTypeRadio({this.defaultValue, this.onValueChanged});

  @override
  State<StatefulWidget> createState() => ContestTypeRadioState();
}

class ContestTypeRadioState extends State<ContestTypeRadio> {
  int _radioValue;

  @override
  void initState() {
    super.initState();
    _radioValue = widget.defaultValue == null ? 0 : widget.defaultValue;
  }

  _handleRadioValueChange(value) {
    setState(() {
      _radioValue = value;
      widget.onValueChanged(value);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Expanded(
          child: Row(
            children: <Widget>[
              Radio(
                value: 0,
                groupValue: _radioValue,
                onChanged: (int value) {
                  _handleRadioValueChange(value);
                },
              ),
              Text("Cash"),
            ],
          ),
        ),
        Expanded(
          child: Row(
            children: <Widget>[
              Radio(
                value: 1,
                groupValue: _radioValue,
                onChanged: (int value) {
                  _handleRadioValueChange(value);
                },
              ),
              Text("Practise"),
            ],
          ),
        )
      ],
    );
  }
}
