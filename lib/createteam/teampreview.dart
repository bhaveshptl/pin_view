import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:playfantasy/commonwidgets/fantasypageroute.dart';
import 'package:playfantasy/commonwidgets/scaffoldpage.dart';
import 'package:playfantasy/createteam/createteam.dart';
import 'package:playfantasy/modal/l1.dart';
import 'package:playfantasy/modal/league.dart';
import 'package:playfantasy/modal/myteam.dart';

class TeamPreview extends StatelessWidget {
  final L1 l1Data;
  final League league;
  final MyTeam myTeam;
  final bool allowEditTeam;
  final FanTeamRule fanTeamRules;

  TeamPreview({
    this.l1Data,
    this.league,
    this.myTeam,
    this.fanTeamRules,
    this.allowEditTeam = false,
  });

  void _onEditTeam(BuildContext context) async {
    final result = await Navigator.of(context).push(
      FantasyPageRoute(
        pageBuilder: (context) => CreateTeam(
              league: league,
              l1Data: l1Data,
              selectedTeam: myTeam,
              mode: TeamCreationMode.EDIT_TEAM,
            ),
      ),
    );

    if (result != null) {
      Scaffold.of(context).showSnackBar(SnackBar(content: Text("$result")));
    }
  }

  getPlayersForStyle(PlayingStyle playingStyle, BuildContext context) {
    List<Widget> players = [];
    bool bIsSmallDevice = MediaQuery.of(context).size.width < 320.0;
    myTeam.players.forEach((Player player) {
      if (player.playingStyleId == playingStyle.id ||
          player.playingStyleDesc.replaceAll(" ", "").toLowerCase() ==
              playingStyle.label.replaceAll(" ", "").toLowerCase()) {
        players.add(
          Column(
            children: <Widget>[
              Stack(
                children: <Widget>[
                  Padding(
                    padding: EdgeInsets.all(4.0),
                    child: Container(
                      width: bIsSmallDevice ? 40.0 : 56.0,
                      height: bIsSmallDevice ? 40.0 : 56.0,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            blurRadius: 1.0,
                            spreadRadius: 1.0,
                            color: Colors.black38,
                            offset: Offset(1, 2),
                          ),
                        ],
                        color: Colors.grey.shade300,
                      ),
                      child: CachedNetworkImage(
                        imageUrl:
                            player.jerseyUrl != null ? player.jerseyUrl : "",
                      ),
                    ),
                  ),
                  myTeam.captain == player.id
                      ? Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.orange,
                          ),
                          padding: EdgeInsets.all(6.0),
                          child: Text(
                            "C",
                            style: Theme.of(context)
                                .primaryTextTheme
                                .body2
                                .copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                ),
                          ),
                        )
                      : Container(),
                  myTeam.viceCaptain == player.id
                      ? Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.blueAccent.shade400,
                          ),
                          padding: EdgeInsets.all(4.0),
                          child: Text(
                            "VC",
                            style: Theme.of(context)
                                .primaryTextTheme
                                .body2
                                .copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                ),
                          ),
                        )
                      : Container(),
                ],
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 4.0, vertical: 2.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(2.0),
                ),
                child: Text(
                  player.name,
                  style: Theme.of(context).primaryTextTheme.caption.copyWith(
                        color: Colors.black,
                        fontSize: 10.0,
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ),
              Container(
                child: Padding(
                  padding: EdgeInsets.only(top: 4.0),
                  child: Text(
                    player.score.toString() + " Pts",
                    style: Theme.of(context).primaryTextTheme.caption.copyWith(
                          color: Colors.white,
                        ),
                  ),
                ),
              )
            ],
          ),
        );
      }
    });
    return players;
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        Column(
          children: <Widget>[
            Expanded(
              child: Image.asset(
                "images/ground-image.png",
                fit: BoxFit.cover,
              ),
            ),
          ],
        ),
        ScaffoldPage(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            elevation: 0.0,
            automaticallyImplyLeading: false,
            backgroundColor: Colors.transparent,
            title:
                Text(myTeam == null || myTeam.name == null ? "" : myTeam.name),
            actions: <Widget>[
              allowEditTeam && league.status == LeagueStatus.UPCOMING
                  ? IconButton(
                      icon: Icon(Icons.edit),
                      onPressed: () {
                        _onEditTeam(context);
                      },
                    )
                  : Container(),
              IconButton(
                icon: Icon(Icons.close),
                onPressed: () {
                  Navigator.pop(context);
                },
              )
            ],
          ),
          body: Stack(
            alignment: Alignment.bottomLeft,
            children: <Widget>[
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: fanTeamRules.styles.map((PlayingStyle playingStyle) {
                  return Padding(
                    padding: EdgeInsets.symmetric(vertical: 10.0),
                    child: Column(
                      children: <Widget>[
                        Row(
                          children: <Widget>[
                            Expanded(
                              child: Text(
                                playingStyle.label.toUpperCase(),
                                style: Theme.of(context)
                                    .primaryTextTheme
                                    .body1
                                    .copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                    ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                        Padding(
                          padding: EdgeInsets.only(top: 8.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: getPlayersForStyle(playingStyle, context),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
              league.status == LeagueStatus.COMPLETED
                  ? Row(
                      children: <Widget>[
                        Expanded(
                          child: Container(
                            height: 56.0,
                            color: Colors.black45,
                            padding: EdgeInsets.symmetric(horizontal: 16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: <Widget>[
                                Text(
                                  "Score",
                                  style: Theme.of(context)
                                      .primaryTextTheme
                                      .title
                                      .copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700,
                                      ),
                                ),
                                Text(
                                  myTeam.score.toString(),
                                  style: Theme.of(context)
                                      .primaryTextTheme
                                      .headline
                                      .copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w800,
                                      ),
                                ),
                              ],
                            ),
                          ),
                        )
                      ],
                    )
                  : Container(),
            ],
          ),
        ),
      ],
    );
  }
}
