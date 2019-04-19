import 'dart:convert';
import 'package:flutter_svg/svg.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'package:playfantasy/appconfig.dart';
import 'package:playfantasy/modal/league.dart';
import 'package:playfantasy/modal/mysheet.dart';
import 'package:playfantasy/utils/apiutil.dart';
import 'package:playfantasy/modal/prediction.dart';
import 'package:playfantasy/utils/httpmanager.dart';
import 'package:playfantasy/commonwidgets/scaffoldpage.dart';
import 'package:playfantasy/redux/actions/loader_actions.dart';
import 'package:playfantasy/commonwidgets/fantasypageroute.dart';
import 'package:playfantasy/leaguedetail/prediction/createsheet/predictionsummary.dart';

class SheetCreationMode {
  static const int CREATE_SHEET = 1;
  static const int EDIT_SHEET = 2;
  static const int CLONE_SHEET = 3;
}

class CreateSheet extends StatefulWidget {
  final int mode;
  final League league;
  final MySheet selectedSheet;
  final Prediction predictionData;
  CreateSheet({
    this.predictionData,
    this.league,
    this.mode,
    this.selectedSheet,
  });

  @override
  CreateSheetState createState() => CreateSheetState();
}

class CreateSheetState extends State<CreateSheet>
    with SingleTickerProviderStateMixin {
  int maxQuestionRules;
  int minQuestionCount;
  List<dynamic> xBoosterRules;
  List<dynamic> bPlusBoosterRules;

  int xBoosterLeft;
  int bPlusBoosterLeft;

  int lastFlippedQuestionIndex;

  int xBooster = -1;
  int curFlipIndex;
  int sheetStatus = 0;
  int activeIndex = 0;
  int bPlusBooster = -1;
  int answerSheetId = 0;
  String language = "1";
  int totalQuestinCount = 0;
  Map<int, int> answers = {};
  TabController tabController;

  int flipBalance = 0;
  int totalFlipBalance = 0;
  Map<int, int> usedFlips = {};
  Map<int, int> tmpBooster = {};
  Map<int, int> flipBooster = {};
  List<int> remainFlipQuestionIndex = [];

  final _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    setRules();
    initSheet();
    getFlipBalance();

    Quiz quiz = widget.predictionData.quizSet.quiz["0"];
    List<int>.generate(quiz.questions.length - maxQuestionRules, (index) {
      remainFlipQuestionIndex.add(maxQuestionRules + index);
    });

    tabController = TabController(
      vsync: this,
      length: maxQuestionRules,
    );

    tabController.addListener(() {
      if (!tabController.indexIsChanging) {
        setState(() {
          activeIndex = tabController.index;
        });
      }
    });

    getFlips();
  }

  showLoader(bool bShow) {
    AppConfig.of(context).store.dispatch(
          bShow ? LoaderShowAction() : LoaderHideAction(),
        );
  }

  getFlipBalance() {
    http.Request req = http.Request(
        "GET",
        Uri.parse(BaseUrl().apiUrl +
            ApiUtil.GET_FLIP_BALANCE +
            widget.league.leagueId.toString()));
    return HttpManager(http.Client())
        .sendRequest(req)
        .then((http.Response res) {
      if (res.statusCode >= 200 && res.statusCode <= 299) {
        Map<String, dynamic> response = json.decode(res.body);
        setState(() {
          flipBalance = response["usable"];
          totalFlipBalance = response["total"];
        });
      }
    });
  }

  getFlips() async {
    http.Request req = http.Request(
        "GET",
        Uri.parse(BaseUrl().apiUrl +
            ApiUtil.GET_LEAGUE_FLIPS +
            widget.league.leagueId.toString()));
    await HttpManager(http.Client()).sendRequest(req).then((http.Response res) {
      if (res.statusCode >= 200 && res.statusCode <= 299) {
        List<dynamic> response = json.decode(res.body);
        response.forEach((flip) {
          usedFlips[flip["from"]] = flip["to"];
          int toIndex = remainFlipQuestionIndex.indexOf(flip["to"]);
          if (toIndex >= 0) {
            remainFlipQuestionIndex.removeAt(toIndex);
          }

          int fromIndex = remainFlipQuestionIndex.indexOf(flip["from"]);
          if (fromIndex >= 0) {
            remainFlipQuestionIndex.removeAt(fromIndex);
          }
        });
      }
    });
  }

  setRules() {
    Quiz quiz = widget.predictionData.quizSet.quiz["0"];
    minQuestionCount =
        quiz.questions.length < widget.predictionData.rules["0"]["minQ"]
            ? quiz.questions.length
            : widget.predictionData.rules["0"]["minQ"];
    maxQuestionRules =
        quiz.questions.length < widget.predictionData.rules["0"]["qcount"]
            ? quiz.questions.length
            : widget.predictionData.rules["0"]["qcount"];
    curFlipIndex = maxQuestionRules;
    xBoosterRules = widget.predictionData.rules["0"]["booster"]["b1"]["rule"];
    bPlusBoosterRules =
        widget.predictionData.rules["0"]["booster"]["b1"]["rule"];
    totalQuestinCount = quiz.questions.length;
    xBoosterLeft = xBoosterRules[1];
    bPlusBoosterLeft = bPlusBoosterRules[1];
  }

  initSheet() {
    if (widget.mode != SheetCreationMode.CREATE_SHEET) {
      if (widget.mode == SheetCreationMode.EDIT_SHEET) {
        answerSheetId = widget.selectedSheet.id;
        if (widget.selectedSheet.boosterThree != null) {
          widget.selectedSheet.boosterThree.forEach((flip) {
            flipBooster[flip["from"]] = flip["to"];
          });
        }
        List<int>.generate(widget.selectedSheet.answers.length, (index) {
          if (widget.selectedSheet.answers[index] != -1) {
            answers[index] = widget.selectedSheet.answers[index];
          }
        });
        xBooster = widget.selectedSheet.boosterOne;
        bPlusBooster = widget.selectedSheet.boosterTwo;
      } else {
        List<int>.generate(maxQuestionRules, (index) {
          if (widget.selectedSheet.answers[index] != -1) {
            answers[index] = widget.selectedSheet.answers[index];
          }
        });
        xBooster = (widget.selectedSheet.boosterOne != null &&
                widget.selectedSheet.boosterOne < maxQuestionRules)
            ? widget.selectedSheet.boosterOne
            : -1;
        bPlusBooster = (widget.selectedSheet.boosterTwo != null &&
                widget.selectedSheet.boosterTwo < maxQuestionRules)
            ? widget.selectedSheet.boosterTwo
            : -1;
      }
      xBoosterLeft = xBooster == -1 ? xBoosterLeft : 0;
      bPlusBoosterLeft = bPlusBooster == -1 ? bPlusBoosterLeft : 0;
    }
  }

  getFlippedQuestion(int index) {
    int flippedIndex;
    flipBooster.keys.forEach((int key) {
      if (key == index) {
        flippedIndex = flipBooster[key];
      } else if (flipBooster[key] == index) {
        flippedIndex = key;
      }
    });
    return flippedIndex;
  }

  setAnswer({int index, int oldIndex, int optionsIndex}) {
    if (index != null && optionsIndex != null) {
      if (answers[index] != null && answers[index] == optionsIndex) {
        setState(() {
          answers.remove(index);
        });
      } else {
        if (isQuestionFlipped(index)) {
          int flippedIndex = getFlippedQuestion(index);
          answers.remove(index);
          answers.remove(flippedIndex);
        }
        if (answers[index] != null) {
          setState(() {
            if (answers[index] != optionsIndex) {
              answers[index] = optionsIndex;
            }
            resetBoostersFor(index);
          });
        } else {
          setState(() {
            answers[index] = optionsIndex;
          });
        }
      }
    }
  }

  saveAnswer() {
    if (answers.keys.length >= minQuestionCount ||
        (flipBooster.keys.length + tmpBooster.keys.length) > 0) {
      List<int> lstAnswers = [];
      List<int>.generate(
          widget.predictionData.quizSet.quiz["0"].questions.length, (curIndex) {
        answers[curIndex] == null || answers[flipBooster[curIndex]] != null
            ? lstAnswers.add(-1)
            : lstAnswers.add(answers[curIndex]);
      });
      var mapObj = {
        "inningsId": 0,
        "name": "",
        "score": 0,
        "id": answerSheetId,
        "status": sheetStatus,
        "answers": lstAnswers,
        "boosterOne": xBooster == -1 ? null : xBooster,
        "boosterTwo": bPlusBooster == -1 ? null : bPlusBooster,
        "answerSheetId": answerSheetId,
        "boosterThree": getFlipObject(),
        "leagueId": widget.predictionData.league.id,
        "channelId": AppConfig.of(context).channelId,
      };
      createAnswerSheet(mapObj);
    } else {
      showLoader(false);
    }
  }

  getFlipObject() {
    List<dynamic> flips = [];
    tmpBooster.keys.forEach((k) {
      flips.add({
        "from": k,
        "to": tmpBooster[k],
      });
    });
    return flips;
  }

  createAnswerSheet(Map<String, dynamic> payload) async {
    http.Request req =
        http.Request("POST", Uri.parse(BaseUrl().apiUrl + ApiUtil.SAVE_SHEET));
    req.body = json.encode(payload);
    await HttpManager(http.Client()).sendRequest(req).then((http.Response res) {
      if (res.statusCode >= 200 && res.statusCode <= 299) {
        Map<String, dynamic> response = json.decode(res.body);
        answerSheetId = response["answerSheetId"];
        sheetStatus = response["answerSheet"]["status"];
        showFlipResponse(response["flipResponse"]);
        if (response["flipResponse"]["status"] == "IGNORE") {
          (payload["boosterThree"] as List).forEach((flip) {
            usedFlips[flip["to"]] = flip["from"];
          });
        }
      } else {
        if (lastFlippedQuestionIndex != null) {
          if (usedFlips[tmpBooster[lastFlippedQuestionIndex]] == null) {
            remainFlipQuestionIndex.insert(
                0, tmpBooster[lastFlippedQuestionIndex]);
          }
        }
      }
    }).whenComplete(() {
      showLoader(false);
    });
  }

  showFlipResponse(Map<String, dynamic> response) {
    if (response["status"] == "SUCCESS" || response["status"] == "ERROR") {
      if (response["status"] == "ERROR") {
        setState(() {
          flipBooster.remove(lastFlippedQuestionIndex);
          bPlusBooster =
              bPlusBooster == lastFlippedQuestionIndex ? -1 : bPlusBooster;
          xBooster = xBooster == lastFlippedQuestionIndex ? -1 : xBooster;
        });
      } else {
        setState(() {
          tmpBooster.keys.forEach((k) {
            resetBoostersFor(k);
            flipBooster[k] = tmpBooster[k];
          });
        });
      }
      getFlipBalance();
      tmpBooster = {};
      lastFlippedQuestionIndex = null;
      _scaffoldKey.currentState.showSnackBar(SnackBar(
        content: Text(response["message"]),
      ));
    }
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

  getFlippedQuestionIndex(int index) {
    return totalQuestinCount - flipBalance;
  }

  resetBoostersFor(int index) {
    if (xBooster == index) {
      setState(() {
        xBooster = -1;
        xBoosterLeft++;
      });
    }
    if (bPlusBooster == index) {
      setState(() {
        bPlusBooster = -1;
        bPlusBoosterLeft++;
      });
    }
  }

  flipQuestion(int index, Question question) {
    if (!isQuestionFlipped(index)) {
      int flippedQuestionIndex = getFlippedQuestionIndex(index);
      if (flipBalance <= 0) {
        _scaffoldKey.currentState.showSnackBar(SnackBar(
          content:
              Text("You have already used the maximum flips for this league."),
        ));
      } else if (flippedQuestionIndex == null) {
        _scaffoldKey.currentState.showSnackBar(SnackBar(
          content:
              Text("You have used maximum flip or not enough flip balance."),
        ));
        return null;
      } else {
        tmpBooster[index] = flippedQuestionIndex;
      }
      lastFlippedQuestionIndex = index;
    } else {
      if (flipBooster[index] == null) {
        int flippedQuestionIndex;
        flipBooster.keys.forEach((k) {
          if (flipBooster[k] == index) {
            flippedQuestionIndex = k;
          }
        });
        flipBooster[index] = flippedQuestionIndex;
        flipBooster.remove(flippedQuestionIndex);
        tmpBooster[index] = flippedQuestionIndex;
      } else {
        flipBooster[flipBooster[index]] = index;
        flipBooster[index] = null;
      }
    }
    showLoader(true);
    saveAnswer();
  }

  bool isQuestionFlipped(int questionIndex) {
    bool bIsFlipped = false;
    flipBooster.keys.forEach((k) {
      if (questionIndex == k || questionIndex == flipBooster[k]) {
        bIsFlipped = true;
      }
    });
    return bIsFlipped;
  }

  List<Widget> getTriviaList(Question question) {
    List<Widget> lstTrivia = [];
    List<String> trivias = question.trivia[language].toString().split("</br>");
    trivias.forEach((trivia) {
      lstTrivia.add(Padding(
        padding: EdgeInsets.only(bottom: 4.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Container(
              height: 20.0,
              padding: EdgeInsets.only(right: 8.0),
              child: CircleAvatar(
                backgroundColor: Colors.black87,
                radius: 4.0,
              ),
            ),
            Expanded(
              child: Text(
                trivia,
                textAlign: TextAlign.left,
                style: Theme.of(context).primaryTextTheme.subhead.copyWith(
                      color: Colors.black54,
                    ),
              ),
            ),
          ],
        ),
      ));
    });
    return lstTrivia;
  }

  apply2XBooster(int curIndex) {
    if (answers[curIndex] != null) {
      setState(() {
        xBooster = xBooster == curIndex ? -1 : curIndex;

        xBoosterLeft = xBooster == -1
            ? xBoosterLeft + 1
            : (xBoosterLeft == 0 ? 0 : xBoosterLeft - 1);
      });
    } else {
      _scaffoldKey.currentState.showSnackBar(SnackBar(
        content: Text("Booster can not applied on unanswered question."),
      ));
    }
  }

  applyBPlusBooster(int curIndex) {
    if (answers[curIndex] != null) {
      setState(() {
        bPlusBooster = bPlusBooster == curIndex ? -1 : curIndex;
        bPlusBoosterLeft = bPlusBooster == -1
            ? bPlusBoosterLeft + 1
            : (bPlusBoosterLeft == 0 ? 0 : bPlusBoosterLeft - 1);
      });
    } else {
      _scaffoldKey.currentState.showSnackBar(SnackBar(
        content: Text("Booster can not applied on unanswered question."),
      ));
    }
  }

  Widget getQuestionTab(int index) {
    List<Question> questions =
        widget.predictionData.quizSet.quiz["0"].questions;
    Question question = questions[index];
    int curIndex = index;
    bool bIsQuestionFlipped = false;
    if (isQuestionFlipped(index)) {
      bIsQuestionFlipped = true;
      if (flipBooster[index] != null) {
        question = questions[flipBooster[index]];
        curIndex = flipBooster[index];
      }
    }
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        Expanded(
          child: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                children: <Widget>[
                  Card(
                    elevation: 3.0,
                    margin: EdgeInsets.all(16.0),
                    child: Column(
                      children: <Widget>[
                        Padding(
                          padding: EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 0.0),
                          child: Row(
                            children: <Widget>[
                              Expanded(
                                child: Text(
                                  question.text[language],
                                  style: Theme.of(context)
                                      .primaryTextTheme
                                      .title
                                      .copyWith(
                                        color: Theme.of(context).primaryColor,
                                      ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.fromLTRB(16.0, 16.0, 8.0, 16.0),
                          child: Column(
                            children: getTriviaList(question),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24.0),
                    child: Column(
                      children: List<Widget>.generate(question.options.length,
                          (optionsIndex) {
                        dynamic option = question.options[optionsIndex];
                        bool bIsSelected = answers[curIndex] == optionsIndex;
                        return Card(
                          elevation: 3.0,
                          clipBehavior: Clip.hardEdge,
                          child: Container(
                            color: bIsSelected
                                ? Theme.of(context).primaryColor
                                : Colors.transparent,
                            child: FlatButton(
                              onPressed: () {
                                setAnswer(
                                  index: curIndex,
                                  oldIndex: index,
                                  optionsIndex: optionsIndex,
                                );
                              },
                              padding: EdgeInsets.all(0.0),
                              child: Column(
                                children: <Widget>[
                                  Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: <Widget>[
                                        Text(
                                          option["negative"].toString(),
                                          style: Theme.of(context)
                                              .primaryTextTheme
                                              .title
                                              .copyWith(
                                                color: bIsSelected
                                                    ? Colors.redAccent
                                                    : Colors.red.shade800,
                                                fontWeight: FontWeight.bold,
                                              ),
                                        ),
                                        Expanded(
                                          child: Text(
                                            option["label"][language]
                                                .toString(),
                                            textAlign: TextAlign.center,
                                            style: Theme.of(context)
                                                .primaryTextTheme
                                                .subhead
                                                .copyWith(
                                                  color: bIsSelected
                                                      ? Colors.white70
                                                      : Colors.black87,
                                                  fontWeight: bIsSelected
                                                      ? FontWeight.bold
                                                      : FontWeight.normal,
                                                ),
                                          ),
                                        ),
                                        Text(
                                          "+" + option["positive"].toString(),
                                          style: Theme.of(context)
                                              .primaryTextTheme
                                              .title
                                              .copyWith(
                                                color: bIsSelected
                                                    ? Colors.greenAccent
                                                    : Colors.green.shade800,
                                                fontWeight: FontWeight.bold,
                                              ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  )
                ],
              ),
            ),
          ),
        ),
        Container(
            height: 56.0,
            child: Container(
              color: Colors.blue.withAlpha(50),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Container(
                    width: 48.0,
                    child: Stack(
                      children: <Widget>[
                        IconButton(
                          // padding: EdgeInsets.all(8.0),
                          onPressed: () {
                            apply2XBooster(curIndex);
                          },
                          icon: SvgPicture.asset(
                            curIndex == xBooster
                                ? "images/2x_selected.svg"
                                : "images/2x.svg",
                          ),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: <Widget>[
                            Container(
                              decoration: BoxDecoration(
                                boxShadow: [
                                  BoxShadow(
                                    blurRadius: 2.0,
                                    spreadRadius: 2.0,
                                    color: Colors.black38,
                                  )
                                ],
                                shape: BoxShape.circle,
                              ),
                              child: CircleAvatar(
                                radius: 8.0,
                                backgroundColor: Colors.red,
                                child: Text(
                                  xBoosterLeft.toString(),
                                  style: TextStyle(
                                    fontSize: 8.0,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 48.0,
                    child: Stack(
                      children: <Widget>[
                        IconButton(
                          onPressed: () {
                            applyBPlusBooster(curIndex);
                          },
                          icon: SvgPicture.asset(
                            curIndex == bPlusBooster
                                ? "images/bpos_selected.svg"
                                : "images/bpos.svg",
                          ),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: <Widget>[
                            Container(
                              decoration: BoxDecoration(
                                boxShadow: [
                                  BoxShadow(
                                    blurRadius: 2.0,
                                    spreadRadius: 2.0,
                                    color: Colors.black38,
                                  )
                                ],
                                shape: BoxShape.circle,
                              ),
                              child: CircleAvatar(
                                radius: 8.0,
                                backgroundColor: Colors.red,
                                child: Text(
                                  bPlusBoosterLeft.toString(),
                                  style: TextStyle(
                                    fontSize: 8.0,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 48.0,
                    child: Stack(
                      children: <Widget>[
                        IconButton(
                          onPressed: () {
                            setState(() {
                              flipQuestion(curIndex, question);
                            });
                          },
                          icon: SvgPicture.asset(
                            bIsQuestionFlipped
                                ? "images/flip_selected.svg"
                                : "images/flip.svg",
                          ),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: <Widget>[
                            Container(
                              decoration: BoxDecoration(
                                boxShadow: [
                                  BoxShadow(
                                    blurRadius: 2.0,
                                    spreadRadius: 2.0,
                                    color: Colors.black38,
                                  )
                                ],
                                shape: BoxShape.circle,
                              ),
                              child: CircleAvatar(
                                radius: 8.0,
                                backgroundColor: Colors.red,
                                child: Text(
                                  flipBalance.toString(),
                                  style: TextStyle(
                                    fontSize: 8.0,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ))
      ],
    );
  }

  launchPredictionSummary() async {
    if (answers.keys.length < minQuestionCount) {
      _scaffoldKey.currentState.showSnackBar(SnackBar(
        content: Text("Please answer atleast " +
            minQuestionCount.toString() +
            " questions."),
      ));
      return;
    } else if (xBoosterRules[0] == 1 && xBooster == -1) {
      _scaffoldKey.currentState.showSnackBar(SnackBar(
        content: Text("Please choose 2X booster question."),
      ));
      return;
    } else if (bPlusBoosterRules[0] == 1 && bPlusBooster == -1) {
      _scaffoldKey.currentState.showSnackBar(SnackBar(
        content: Text("Please choose B+ booster question."),
      ));
      return;
    }
    final result = await Navigator.of(context).push(
      FantasyPageRoute(
        pageBuilder: (context) => PredictionSummary(
              answers: answers,
              xBooster: xBooster,
              league: widget.league,
              flipBooster: flipBooster,
              bPlusBooster: bPlusBooster,
              answerSheetId: answerSheetId,
              predictionData: widget.predictionData,
            ),
      ),
    );

    if (result != null) {
      var response = json.decode(result);
      if (response["edit"] != null && response["edit"]) {
        setState(() {
          tabController.index = 0;
        });
      } else if (response["finish"] != null && response["finish"]) {
        if (widget.mode == SheetCreationMode.EDIT_SHEET) {
          Navigator.of(context).pop("Sheet updated successfully!!");
        } else {
          Navigator.of(context).pop("Sheet created successfully!!");
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldPage(
      scaffoldKey: _scaffoldKey,
      appBar: AppBar(
        title: Text(
          widget.league.teamA.name.toString() +
              " vs " +
              widget.league.teamB.name.toString(),
        ),
      ),
      body: Stack(
        children: <Widget>[
          Container(
            decoration: AppConfig.of(context).showBackground
                ? BoxDecoration(
                    image: DecorationImage(
                        image: AssetImage("images/background.png"),
                        repeat: ImageRepeat.repeat),
                  )
                : null,
            child: TabBarView(
              controller: tabController,
              children: List<Widget>.generate(maxQuestionRules, (index) {
                return getQuestionTab(index);
              }).toList(),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(8.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Row(
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    CircleAvatar(
                      radius: 16.0,
                      backgroundColor: activeIndex == 0 ? Colors.black45 : null,
                      child: IconButton(
                        padding: EdgeInsets.all(0.0),
                        onPressed: activeIndex == 0
                            ? null
                            : () {
                                tabController.index--;
                              },
                        icon: Icon(Icons.chevron_left),
                      ),
                    ),
                    CircleAvatar(
                      radius: 16.0,
                      backgroundColor: activeIndex == tabController.length - 1
                          ? Colors.black45
                          : null,
                      child: IconButton(
                        padding: EdgeInsets.all(0.0),
                        onPressed: activeIndex == tabController.length - 1
                            ? null
                            : () {
                                tabController.index++;
                              },
                        icon: Icon(Icons.chevron_right),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          )
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          launchPredictionSummary();
        },
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(Icons.speaker_notes),
            Text(
              "SAVE",
              style: Theme.of(context).primaryTextTheme.overline.copyWith(
                    letterSpacing: 0.6,
                  ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        height: 48.0,
        color: Theme.of(context).primaryColor,
        child: TabBar(
          isScrollable: true,
          controller: tabController,
          indicatorColor: Colors.transparent,
          labelPadding: EdgeInsets.symmetric(horizontal: 4.0),
          tabs: List<Widget>.generate(maxQuestionRules, (index) {
            String text = (index + 1).toString();
            return CircleAvatar(
              radius: 15.0,
              backgroundColor:
                  activeIndex == index ? Colors.white24 : Colors.transparent,
              child: Text(
                text,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white70,
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
