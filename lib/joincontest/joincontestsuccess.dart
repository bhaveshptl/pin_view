import 'package:flutter/material.dart';
import 'package:playfantasy/commonwidgets/color_button.dart';

class JoinContestSuccess extends StatefulWidget {
  final String successMessage;
  final String launchPageSource;
  JoinContestSuccess({this.successMessage,this.launchPageSource});
  @override
  JoinContestSuccessState createState() => JoinContestSuccessState();
}

class JoinContestSuccessState extends State<JoinContestSuccess> {
  final _formKey = new GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
  }

  onGoToLobbyPressed() async {
    Map<String, dynamic> data = new Map();
    data["userOption"] = "joinContest";
    if(widget.launchPageSource=="l1"){
       Navigator.pop(context);
    }else{
       Navigator.of(context).pop(data);
    }
    
  }

  onCreateTeamPressed() async {
    Map<String, dynamic> data = new Map();
    data["userOption"] = "createTeam";
    Navigator.of(context).pop(data);
  }

  onClosePopup() {
    Map<String, dynamic> data = new Map();
    data["userOption"] = "onClosePressed";
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
        children: <Widget>[],
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
                        fontSize: 27),
                  )),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(vertical: 10.0),
              child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          ColorButton(
                            onPressed: () {
                              onCreateTeamPressed();
                            },
                            color: Colors.orange,
                            child: Padding(
                              padding: EdgeInsets.symmetric(
                                  vertical: 2.0, horizontal: 2.0),
                              child: Text(
                                "Create a new team".toUpperCase(),
                                style: Theme.of(context)
                                    .primaryTextTheme
                                    .subhead
                                    .copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w400,
                                        fontSize: 13),
                              ),
                            ),
                          )
                        ]),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Padding(
                            padding: EdgeInsets.only(
                                left: 15),
                            child: ColorButton(
                              onPressed: () {
                                onGoToLobbyPressed();
                              },
                              child: Padding(
                                padding: EdgeInsets.symmetric(
                                    vertical: 0.5, horizontal: 0.5),
                                child: Text(
                                  "Lobby".toUpperCase(),
                                  style: Theme.of(context)
                                      .primaryTextTheme
                                      .subhead
                                      .copyWith(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w400,
                                          fontSize: 13),
                                ),
                              ),
                            ))
                      ],
                    )
                  ]),
            ),
          ],
        ),
      ),
    );
  }
}
