import 'package:flutter/material.dart';

class SearchContest extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => SearchContestState();
}

class SearchContestState extends State<SearchContest> {
  final _formKey = GlobalKey<FormState>();

  _onSearchContest() {
    if (_formKey.currentState.validate()) {
      _showComingsoonDialog();
    }
  }

  _showComingsoonDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Search contest"),
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
      appBar: AppBar(
        title: Text("Search contest"),
      ),
      body: Form(
        key: _formKey,
        child: Row(
          children: <Widget>[
            Expanded(
              child: Column(
                children: <Widget>[
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Expanded(
                        child: Padding(
                          padding:
                              const EdgeInsets.fromLTRB(8.0, 24.0, 8.0, 8.0),
                          child: TextFormField(
                            decoration: InputDecoration(
                                hintText: 'Contest code to search.'),
                            validator: (value) {
                              if (value.isEmpty) {
                                return 'Contest code is required to search contest.';
                              }
                            },
                            onEditingComplete: () {
                              _onSearchContest();
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Expanded(
                        child: Padding(
                          padding:
                              const EdgeInsets.fromLTRB(8.0, 24.0, 8.0, 8.0),
                          child: Tooltip(
                            message: "Search contest using contest code.",
                            child: RaisedButton(
                              color: Theme.of(context).primaryColorDark,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: <Widget>[
                                  Icon(
                                    Icons.search,
                                    color: Colors.white70,
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.only(left: 8.0),
                                    child: Text(
                                      "SEARCH",
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
                      ),
                    ],
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
