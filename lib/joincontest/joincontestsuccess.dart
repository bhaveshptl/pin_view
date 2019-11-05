import 'package:flutter/material.dart';
import 'package:playfantasy/commonwidgets/color_button.dart';

class JoinContestSuccess extends StatefulWidget {
  final String successMessage;
  JoinContestSuccess({this.successMessage});
  @override
  JoinContestSuccessState createState() => JoinContestSuccessState();
}

class JoinContestSuccessState extends State<JoinContestSuccess> {
  final _formKey = new GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
  }

  onJoinAnotherContestPressed() async {
    Map<String, dynamic> data = new Map();
    data["userOption"] = "joinContest";
    print(data);
    Navigator.of(context).pop(data);
  }

  onCreateTeamPressed() async {
    Map<String, dynamic> data = new Map();
    data["userOption"] = "createTeam";
    print(data);
    Navigator.of(context).pop(data);
  }

  onClosePopup() {
    Map<String, dynamic> data = new Map();
    data["userOption"] = "joinContest";
    print(data);
    Navigator.of(context).pop(data);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(5.0),
      ),
      elevation: 0.0,
      title: Row(
        mainAxisSize: MainAxisSize.max,
        children: <Widget>[
          Expanded(
            child: Container(
              //width: MediaQuery.of(context).size.width,
              alignment: Alignment.topRight,
              child: InkWell(
                child: Padding(
                  padding: EdgeInsets.all(0.0),
                  child: Icon(
                    Icons.close,
                  ),
                ),
                onTap: () {
                  onClosePopup();
                },
              ),
            ),
          ),
        ],
      ),
      contentPadding: EdgeInsets.all(0.0),
      content: Container(
        width: MediaQuery.of(context).size.width,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.only(
                  top: 24.0, left: 24.0, right: 24.0, bottom: 25),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Expanded(
                      child: Text(
                    widget.successMessage,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).primaryTextTheme.title.copyWith(
                          fontWeight: FontWeight.w400,
                          color: Colors.black,
                        ),
                  )),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(vertical: 10.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  ColorButton(
                    onPressed: () {
                      onCreateTeamPressed();
                    },
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                          vertical: 12.0, horizontal: 20.0),
                      child: Text(
                        "Create a new team".toUpperCase(),
                        style: Theme.of(context)
                            .primaryTextTheme
                            .title
                            .copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w600),
                      ),
                    ),
                  )
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.only(
                  top: 10.0, left: 10.0, right: 10.0, bottom: 25),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  ColorButton(
                    onPressed: () {
                      onJoinAnotherContestPressed();
                    },
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                          vertical: 12.0, horizontal: 20.0),
                      child: Text(
                        "Join another contest".toUpperCase(),
                        style: Theme.of(context)
                            .primaryTextTheme
                            .title
                            .copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w600),
                      ),
                    ),
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
