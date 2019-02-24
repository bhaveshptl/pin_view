import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:playfantasy/modal/prediction.dart';

class PredictionSummaryWidget extends StatelessWidget {
  final int xBooster;
  final int bPlusBooster;
  final Map<int, int> flips;
  final String language = "1";
  final Map<int, int> answers;
  final Prediction predictionData;

  PredictionSummaryWidget({
    this.flips,
    this.answers,
    this.xBooster,
    this.bPlusBooster,
    this.predictionData,
  });

  getQuestionIndex(int id) {
    int curIndex = -1;
    List<int>.generate(predictionData.quizSet.quiz["0"].questions.length,
        (index) {
      if (predictionData.quizSet.quiz["0"].questions[index].id == id) {
        curIndex = index;
      }
    });
    return curIndex;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children:
          List<Widget>.generate(predictionData.rules["0"]["qcount"], (index) {
        int curIndex = index;
        Question question =
            predictionData.quizSet.quiz["0"].questions[curIndex];
        if ((answers[curIndex] == null || answers[curIndex] == -1) &&
            (flips[curIndex] != null && flips[curIndex] != -1)) {
          curIndex = flips[curIndex];
          question = predictionData.quizSet.quiz["0"].questions[curIndex];
        }
        if (answers[curIndex] != null &&
            answers[curIndex] != -1 &&
            answers[curIndex] < question.options.length) {
          var answer = question.options[answers[curIndex]];
          var positiveScore = curIndex == xBooster
              ? answer["positive"] * 2
              : answer["positive"];
          var negativeScore = curIndex == xBooster
              ? answer["negative"] * 2
              : answer["negative"];
          negativeScore = curIndex == bPlusBooster ? 0 : negativeScore;

          return Row(
            children: <Widget>[
              Expanded(
                child: Column(
                  children: <Widget>[
                    Divider(
                      height: 2.0,
                      color: Colors.black12,
                    ),
                    Padding(
                      padding:
                          EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
                      child: Row(
                        children: <Widget>[
                          Expanded(
                            child: Column(
                              children: <Widget>[
                                Row(
                                  children: <Widget>[
                                    Expanded(
                                      child: Column(
                                        children: <Widget>[
                                          Row(
                                            children: <Widget>[
                                              Expanded(
                                                child: Text(
                                                  question.text[language],
                                                  style: Theme.of(context)
                                                      .primaryTextTheme
                                                      .subtitle
                                                      .copyWith(
                                                        color: Colors.black45,
                                                      ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    )
                                  ],
                                ),
                                Padding(
                                  padding: EdgeInsets.only(top: 3.0),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: <Widget>[
                                      Expanded(
                                        child: Text(
                                          answer["label"][language],
                                          style: Theme.of(context)
                                              .primaryTextTheme
                                              .subtitle
                                              .copyWith(
                                                color: Colors.black54,
                                                fontWeight: FontWeight.w900,
                                              ),
                                        ),
                                      ),
                                      xBooster == curIndex
                                          ? RotationTransition(
                                              turns: AlwaysStoppedAnimation(
                                                  -15 / 360),
                                              child: Container(
                                                padding:
                                                    EdgeInsets.only(right: 8.0),
                                                child: SvgPicture.asset(
                                                  "images/2x_selected.svg",
                                                  height: 24.0,
                                                ),
                                              ),
                                            )
                                          : Container(),
                                      bPlusBooster == curIndex
                                          ? RotationTransition(
                                              turns: AlwaysStoppedAnimation(
                                                  -15 / 360),
                                              child: Container(
                                                padding:
                                                    EdgeInsets.only(right: 8.0),
                                                child: SvgPicture.asset(
                                                  "images/bpos_selected.svg",
                                                  height: 24.0,
                                                ),
                                              ),
                                            )
                                          : Container(),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            child: predictionData.league.status == 1 ||
                                    question.answer == -1
                                ? Row(
                                    children: <Widget>[
                                      Text(
                                        "+" + positiveScore.toString(),
                                        style: Theme.of(context)
                                            .primaryTextTheme
                                            .subtitle
                                            .copyWith(
                                              color: Colors.green.shade800,
                                              fontWeight: FontWeight.bold,
                                            ),
                                      ),
                                      Padding(
                                        padding: EdgeInsets.only(left: 16.0),
                                        child: Text(
                                          negativeScore.toString(),
                                          style: Theme.of(context)
                                              .primaryTextTheme
                                              .subtitle
                                              .copyWith(
                                                color: Colors.red.shade800,
                                                fontWeight: FontWeight.bold,
                                              ),
                                        ),
                                      ),
                                    ],
                                  )
                                : Row(
                                    children: <Widget>[
                                      question.answer == answers[curIndex]
                                          ? Text(
                                              "+" + positiveScore.toString(),
                                              style: Theme.of(context)
                                                  .primaryTextTheme
                                                  .subtitle
                                                  .copyWith(
                                                    color:
                                                        Colors.green.shade800,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                            )
                                          : Padding(
                                              padding:
                                                  EdgeInsets.only(left: 16.0),
                                              child: Text(
                                                negativeScore.toString(),
                                                style: Theme.of(context)
                                                    .primaryTextTheme
                                                    .subtitle
                                                    .copyWith(
                                                      color:
                                                          Colors.red.shade800,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                              ),
                                            ),
                                    ],
                                  ),
                          )
                        ],
                      ),
                    )
                  ],
                ),
              ),
            ],
          );
        } else {
          return Container();
        }
      }),
    );
  }
}
