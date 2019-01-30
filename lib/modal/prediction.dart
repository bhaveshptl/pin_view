import 'package:playfantasy/modal/l1.dart';

class Prediction {
  QuizSet quizSet;
  List<Contest> contests;
  PredictionLeague league;
  Map<String, dynamic> rules;

  Prediction({
    this.rules,
    this.league,
    this.quizSet,
    this.contests,
  });

  factory Prediction.fromJson(Map<String, dynamic> json) {
    return Prediction(
      rules: json["rules"],
      league: PredictionLeague.fromJson(json['league']),
      quizSet: QuizSet.fromJson(json["quizSet"]),
      contests:
          (json["contests"] as List).map((i) => Contest.fromJson(i)).toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        "rules": this.rules,
        "league": this.league.toJson(),
        "quizSet": this.quizSet.toJson(),
        "contests": this.contests.map((f) => f.toJson()).toList(),
      };
}

class PredictionLeague {
  int id;
  int status;
  String name;
  int endTime;
  double vcMult;
  int startTime;
  int inningsId;
  int captainMult;
  int qfVisibility;
  List<Rounds> rounds;

  PredictionLeague({
    this.id,
    this.name,
    this.status,
    this.rounds,
    this.vcMult,
    this.endTime,
    this.startTime,
    this.inningsId,
    this.captainMult,
    this.qfVisibility,
  });

  factory PredictionLeague.fromJson(Map<String, dynamic> json) {
    return PredictionLeague(
      id: json["id"],
      name: json["name"],
      status: json["status"],
      endTime: json["endTime"],
      startTime: json["startTime"],
      inningsId: json["inningsId"],
      captainMult: json["captainMult"],
      vcMult: json["vcMult"].toDouble(),
      qfVisibility: json["qfVisibility"] == null ? 0 : json["qfVisibility"],
      rounds: (json["rounds"] as List).map((i) => Rounds.fromJson(i)).toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        "id": this.id,
        "name": this.name,
        "status": this.status,
        "vcMult": this.vcMult,
        "endTime": this.endTime,
        "startTime": this.startTime,
        "inningsId": this.inningsId,
        "captainMult": this.captainMult,
        "qfVisibility": this.qfVisibility,
        "rounds": this.rounds.map((f) => f.toJson()).toList(),
      };
}

class Rounds {
  List<Match> matches;

  Rounds({this.matches});

  factory Rounds.fromJson(Map<String, dynamic> json) {
    return Rounds(
      matches: (json["matches"] as List).map((i) => Match.fromJson(i)).toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        "matches": this.matches.map((f) => f.toJson()).toList(),
      };
}

class Match {
  int id;
  int squad;
  int status;
  String name;
  int endTime;
  String sportDesc;
  Series series;
  int startTime;
  int sportType;

  Match({
    this.id,
    this.name,
    this.squad,
    this.status,
    this.series,
    this.endTime,
    this.sportDesc,
    this.startTime,
    this.sportType,
  });

  factory Match.fromJson(Map<String, dynamic> json) {
    return Match(
      id: json["id"],
      name: json["name"],
      squad: json["squad"],
      status: json["status"],
      endTime: json["endTime"],
      sportDesc: json["sportDesc"],
      startTime: json["startTime"],
      sportType: json["sportType"],
      series: Series.fromJson(json["series"]),
    );
  }

  Map<String, dynamic> toJson() => {
        "id": this.id,
        "name": this.name,
        "squad": this.squad,
        "status": this.status,
        "endTime": this.endTime,
        "sportDesc": this.sportDesc,
        "startTime": this.startTime,
        "sportType": this.sportType,
        "series": this.series.toJson(),
      };
}

class Series {
  int id;
  String info;
  String name;
  int endDate;
  int startDate;
  int countryId;
  int seriesTypeId;

  Series({
    this.id,
    this.info,
    this.name,
    this.endDate,
    this.startDate,
    this.countryId,
    this.seriesTypeId,
  });

  factory Series.fromJson(Map<String, dynamic> json) {
    return Series(
      id: json["id"],
      info: json["info"],
      name: json["name"],
      endDate: json["endDate"],
      startDate: json["startDate"],
      countryId: json["countryId"],
      seriesTypeId: json["seriesTypeId"],
    );
  }

  Map<String, dynamic> toJson() => {
        "id": this.id,
        "info": this.info,
        "name": this.name,
        "endDate": this.endDate,
        "startDate": this.startDate,
        "countryId": this.countryId,
        "seriesTypeId": this.seriesTypeId,
      };
}

class QuizSet {
  int matchId;
  int brandId;
  int leagueId;
  Map<String, Quiz> quiz;

  QuizSet({
    this.quiz,
    this.matchId,
    this.brandId,
    this.leagueId,
  });

  factory QuizSet.fromJson(Map<String, dynamic> json) {
    Map<String, Quiz> quiz = {};
    (json["quiz"] as Map<String, dynamic>).keys.forEach((k) {
      quiz[k] = Quiz.fromJson(json["quiz"][k]);
    });
    return QuizSet(
      quiz: quiz, //json["quiz"],
      matchId: json["matchId"],
      brandId: json["brandId"],
      leagueId: json["leagueId"],
    );
  }

  Map<String, dynamic> toJson() {
    Map<String, dynamic> quiz = {};
    this.quiz.keys.forEach((k) {
      quiz[k] = this.quiz[k].toJson();
    });
    return {
      "quiz": quiz,
      "matchId": this.matchId,
      "brandId": this.brandId,
      "leagueId": this.leagueId
    };
  }
}

class Quiz {
  int status;
  int brandId;
  int priority;
  int questionSetId;
  List<Question> questions;

  Quiz({
    this.status,
    this.brandId,
    this.priority,
    this.questions,
    this.questionSetId,
  });

  factory Quiz.fromJson(Map<String, dynamic> json) {
    return Quiz(
      status: json["status"],
      brandId: json["brandId"],
      priority: json["priority"],
      questions:
          (json["questions"] as List).map((i) => Question.fromJson(i)).toList(),
      questionSetId: json["questionSetId"],
    );
  }

  Map<String, dynamic> toJson() => {
        "status": this.status,
        "brandId": this.brandId,
        "priority": this.priority,
        "questions": this.questions.map((f) => f.toJson()).toList(),
        "questionSetId": this.questionSetId,
      };
}

class Question {
  int id;
  int answer;
  List<dynamic> options;
  Map<String, dynamic> text;
  Map<String, dynamic> trivia;

  Question({
    this.id,
    this.answer,
    this.options,
    this.text,
    this.trivia,
  });

  factory Question.fromJson(Map<String, dynamic> json) {
    return Question(
      id: json["id"],
      answer: json["answer"],
      options: json["options"],
      text: json["text"],
      trivia: json["trivia"],
    );
  }

  Map<String, dynamic> toJson() => {
        "id": this.id,
        "answer": this.answer,
        "options": this.options,
        "text": this.text,
        "trivia": this.trivia,
      };
}
