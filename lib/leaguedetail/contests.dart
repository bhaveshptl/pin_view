import 'package:flutter/material.dart';
import 'package:playfantasy/contestdetail/contestdetail.dart';

import 'package:playfantasy/modal/l1.dart';
import 'package:playfantasy/modal/league.dart';
import 'package:playfantasy/lobby/tabs/leaguecard.dart';
import 'package:playfantasy/leaguedetail/contestcard.dart';

class Contests extends StatefulWidget {
  final L1 _l1Data;
  final League _league;

  Contests(this._league, this._l1Data);

  @override
  State<StatefulWidget> createState() => ContestsState();
}

class ContestsState extends State<Contests> {
  List<Contest> _contests = [];
  @override
  void initState() {
    super.initState();
    _contests = widget._l1Data.contests;
  }

  _onContestClick(Contest contest) {
    Navigator.of(context).push(new MaterialPageRoute(
        builder: (context) =>
            ContestDetail(widget._league, widget._l1Data, contest)));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: LeagueCard(
                widget._league,
                clickable: false,
              ),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.only(bottom:4.0),
          child: Divider(
            height: 2.0,
            color: Colors.black12,
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: _contests.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.all(0.0),
                child: ContestCard(_contests[index], _onContestClick),
              );
            },
          ),
        ),
      ],
    );
  }
}
