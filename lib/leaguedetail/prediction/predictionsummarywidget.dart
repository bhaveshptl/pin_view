import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:playfantasy/modal/prediction.dart';

class PredictionSummaryWidget extends StatelessWidget {
  final int xBooster;
  final int bPlusBooster;
  final String language = "1";
  final Map<int, int> answers;
  final Prediction predictionData;

  PredictionSummaryWidget({
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
      children: List<Widget>.generate(
          predictionData.quizSet.quiz["0"].questions.length, (index) {
        Question question = predictionData.quizSet.quiz["0"].questions[index];
        if (answers[index] != null &&
            answers[index] != -1 &&
            answers[index] < question.options.length) {
          var answer = question.options[answers[index]];
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
                                      xBooster == index
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
                                      bPlusBooster == index
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
                            child: Row(
                              children: <Widget>[
                                Text(
                                  "+" + answer["positive"].toString(),
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
                                    answer["negative"].toString(),
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
                            ),
                          )
                        ],
                      ),
                    )
                    // Container(
                    //   padding:
                    //       EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
                    //   child: Column(
                    //     children: <Widget>[

                    //       )
                    //     ],
                    //   ),
                    // ),
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
