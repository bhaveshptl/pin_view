import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:playfantasy/appconfig.dart';
import 'package:playfantasy/commonwidgets/loader.dart';
import 'package:playfantasy/modal/league.dart';
import 'package:playfantasy/utils/apiutil.dart';
import 'package:playfantasy/modal/prediction.dart';
import 'package:playfantasy/utils/httpmanager.dart';
import 'package:playfantasy/leaguedetail/prediction/predictionsummarywidget.dart';

class PredictionSummary extends StatefulWidget {
  final int xBooster;
  final League league;
  final int bPlusBooster;
  final int answerSheetId;
  final Map<int, int> answers;
  final Prediction predictionData;
  final Map<int, int> flipBooster;

  PredictionSummary({
    this.league,
    this.answers,
    this.xBooster,
    this.flipBooster,
    this.bPlusBooster,
    this.answerSheetId,
    this.predictionData,
  });

  @override
  PredictionSummaryState createState() {
    return new PredictionSummaryState();
  }
}

class PredictionSummaryState extends State<PredictionSummary> {
  bool bShowLoader = false;
  final String language = "1";

  onEdit(BuildContext context) {
    Navigator.of(context).pop(json.encode({"edit": true}));
  }

  onFinish(BuildContext context) {
    saveAnswer(context);
  }

  showLoader(bool bShow) {
    setState(() {
      bShowLoader = bShow;
    });
  }

  getQuestionIndex(int id) {
    int curIndex;
    List<int>.generate(widget.predictionData.quizSet.quiz["0"].questions.length,
        (index) {
      if (widget.predictionData.quizSet.quiz["0"].questions[index].id == id) {
        curIndex = index;
      }
    });
    return curIndex;
  }

  saveAnswer(BuildContext context) {
    showLoader(true);
    List<int> lstAnswers = [];
    List<int>.generate(widget.predictionData.quizSet.quiz["0"].questions.length,
        (curIndex) {
      widget.answers[curIndex] == null
          ? lstAnswers.add(-1)
          : lstAnswers.add(widget.answers[curIndex]);
    });
    var mapObj = {
      "inningsId": 0,
      "name": "",
      "score": 0,
      "status": 0,
      "id": widget.answerSheetId,
      "answers": lstAnswers,
      "boosterOne": widget.xBooster,
      "boosterTwo": widget.bPlusBooster,
      "answerSheetId": widget.answerSheetId,
      "boosterThree": getFlipObject(),
      "leagueId": widget.predictionData.league.id,
      "channelId": AppConfig.of(context).channelId,
    };
    createAnswerSheet(mapObj, context);
  }

  getFlipObject() {
    List<dynamic> flips = [];
    widget.flipBooster.keys.forEach((k) {
      flips.add({
        "from": k,
        "to": widget.flipBooster[k],
      });
    });
    return flips;
  }

  createAnswerSheet(Map<String, dynamic> payload, BuildContext context) async {
    http.Request req =
        http.Request("POST", Uri.parse(BaseUrl.apiUrl + ApiUtil.SAVE_SHEET));
    req.body = json.encode(payload);
    await HttpManager(http.Client()).sendRequest(req).then((http.Response res) {
      if (res.statusCode >= 200 && res.statusCode <= 299) {
        Map<String, dynamic> response = json.decode(res.body);
        Navigator.of(context).pop(json.encode({"finish": true}));
      }
    }).whenComplete(() {
      showLoader(false);
    });
  }

  @override
  Widget build(BuildContext context) {
    Quiz quiz = widget.predictionData.quizSet.quiz["0"];
    int maxQuestionRules =
        quiz.questions.length < widget.predictionData.rules["0"]["qcount"]
            ? quiz.questions.length
            : widget.predictionData.rules["0"]["qcount"];
    return Stack(
      children: <Widget>[
        Scaffold(
          appBar: AppBar(
            title: Text(
              widget.league.teamA.name.toString() +
                  " vs " +
                  widget.league.teamB.name.toString(),
            ),
          ),
          body: Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                  image: AssetImage("images/norwegian_rose.png"),
                  repeat: ImageRepeat.repeat),
            ),
            constraints: BoxConstraints.expand(),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Card(
                    elevation: 3.0,
                    margin: EdgeInsets.all(16.0),
                    child: Column(
                      children: <Widget>[
                        Container(
                          color: Colors.black.withAlpha(10),
                          padding: EdgeInsets.all(16.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: <Widget>[
                              Text(
                                "Prediction Summary",
                                style: Theme.of(context)
                                    .primaryTextTheme
                                    .subhead
                                    .copyWith(
                                      color: Colors.black54,
                                    ),
                              ),
                              Text(
                                widget.answers.keys.length.toString() +
                                    "/" +
                                    maxQuestionRules.toString(),
                                style: Theme.of(context)
                                    .primaryTextTheme
                                    .subhead
                                    .copyWith(
                                      color: Colors.black54,
                                    ),
                              )
                            ],
                          ),
                        ),
                        PredictionSummaryWidget(
                          answers: widget.answers,
                          xBooster: widget.xBooster,
                          bPlusBooster: widget.bPlusBooster,
                          predictionData: widget.predictionData,
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.only(bottom: 8.0),
                    color: Colors.transparent,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: <Widget>[
                            RaisedButton(
                              onPressed: () {
                                onEdit(context);
                              },
                              color: Theme.of(context).primaryColor,
                              child: Text(
                                "EDIT",
                                style: Theme.of(context)
                                    .primaryTextTheme
                                    .button
                                    .copyWith(
                                      color: Colors.white70,
                                    ),
                              ),
                            ),
                            RaisedButton(
                              onPressed: () {
                                onFinish(context);
                              },
                              color: Theme.of(context).primaryColor,
                              child: Text(
                                "FINISH",
                                style: Theme.of(context)
                                    .primaryTextTheme
                                    .button
                                    .copyWith(
                                      color: Colors.white70,
                                    ),
                              ),
                            )
                          ],
                        )
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          // bottomNavigationBar: Container(
          //   color: Colors.transparent,
          //   child: Column(
          //     mainAxisSize: MainAxisSize.min,
          //     children: <Widget>[
          //       Row(
          //         mainAxisAlignment: MainAxisAlignment.spaceAround,
          //         children: <Widget>[
          //           RaisedButton(
          //             onPressed: () {},
          //             color: Theme.of(context).primaryColor,
          //             child: Text(
          //               "EDIT",
          //               style: Theme.of(context).primaryTextTheme.button.copyWith(
          //                     color: Colors.white70,
          //                   ),
          //             ),
          //           ),
          //           RaisedButton(
          //             onPressed: () {},
          //             color: Theme.of(context).primaryColor,
          //             child: Text(
          //               "FINISH",
          //               style: Theme.of(context).primaryTextTheme.button.copyWith(
          //                     color: Colors.white70,
          //                   ),
          //             ),
          //           )
          //         ],
          //       )
          //     ],
          //   ),
          // ),
        ),
        bShowLoader ? Loader() : Container(),
      ],
    );
  }
}
