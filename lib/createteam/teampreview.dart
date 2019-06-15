import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
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
    bool bIsSmallDevice = MediaQuery.of(context).size.height < 640;
    bool bIsMediumDevice = MediaQuery.of(context).size.height < 840;
    myTeam.players.forEach((Player player) {
      if (player.playingStyleId == playingStyle.id ||
          player.playingStyleDesc.replaceAll(" ", "").toLowerCase() ==
              playingStyle.label.replaceAll(" ", "").toLowerCase()) {
        players.add(
          Column(
            children: <Widget>[
              Stack(
                children: <Widget>[
                  Stack(
                    alignment: Alignment.bottomRight,
                    children: <Widget>[
                      Padding(
                        padding: EdgeInsets.all(4.0),
                        child: Container(
                          width: bIsSmallDevice
                              ? 32.0
                              : (bIsMediumDevice ? 40.0 : 48.0),
                          height: bIsSmallDevice
                              ? 32.0
                              : (bIsMediumDevice ? 40.0 : 48.0),
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
                            imageUrl: player.jerseyUrl != null
                                ? player.jerseyUrl
                                : "",
                          ),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.only(bottom: 2.0),
                        child: Image.asset(
                          "images/style-" +
                              player.playingStyleId.toString() +
                              ".png",
                          height: 16.0,
                        ),
                      ),
                    ],
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
                  color: league.teamA.id == player.teamId
                      ? Colors.white
                      : Colors.grey.shade900,
                  borderRadius: BorderRadius.circular(2.0),
                ),
                child: Text(
                  player.name,
                  style: Theme.of(context).primaryTextTheme.caption.copyWith(
                        color: league.teamA.id == player.teamId
                            ? Colors.black
                            : Colors.white,
                        fontSize: 10.0,
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ),
              Container(
                child: Padding(
                  padding: EdgeInsets.only(top: 4.0),
                  child: Text(
                    league.status == LeagueStatus.UPCOMING
                        ? player.credit.toString() + " Cr"
                        : player.score.toString() + " Pts",
                    style: Theme.of(context).primaryTextTheme.button.copyWith(
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

  getPlayingStyleLabel(String label) {
    switch (label) {
      case "Batsman":
        return "batsmen".toUpperCase();
      case "Bowler":
        return "Bowlers".toUpperCase();
      case "All Rounder":
        return "All Rounders".toUpperCase();
      default:
        return label.toUpperCase();
    }
  }

  @override
  Widget build(BuildContext context) {
    bool bIsSmallDevice = MediaQuery.of(context).size.height < 720;
    bool bIsMediumDevice = MediaQuery.of(context).size.height < 1080;
    return Stack(
      children: <Widget>[
        ConstrainedBox(
          constraints: BoxConstraints.expand(),
          child: Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage("images/ground-image.png"),
                fit: BoxFit.fill,
              ),
            ),
          ),
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
          body: Column(
            children: <Widget>[
              Container(
                padding: EdgeInsets.only(
                    bottom:
                        bIsSmallDevice ? 4.0 : (bIsMediumDevice ? 8.0 : 12.0),
                    top: bIsSmallDevice ? 0.0 : (bIsMediumDevice ? 6.0 : 8.0)),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    SvgPicture.asset(
                      "images/logo_white.svg",
                      color: Colors.white30,
                      width: 32.0,
                      height: bIsSmallDevice ? 24.0 : 56.0,
                    ),
                    // Image.asset(
                    //   "images/logo_white.png",
                    //   color: Colors.white30,
                    //   height: bIsSmallDevice ? 24.0 : 56.0,
                    // ),
                    Padding(
                      padding: EdgeInsets.only(left: 8.0),
                      child: Image.asset(
                        "images/logo_name_white.png",
                        color: Colors.white30,
                        height: bIsSmallDevice ? 18.0 : 30.0,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    bottom: league.status == LeagueStatus.UPCOMING ? 32.0 : 0.0,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children:
                        fanTeamRules.styles.map((PlayingStyle playingStyle) {
                      return Padding(
                        padding: EdgeInsets.symmetric(vertical: 10.0),
                        child: Column(
                          children: <Widget>[
                            Row(
                              children: <Widget>[
                                Expanded(
                                  child: Text(
                                    getPlayingStyleLabel(playingStyle.label),
                                    style: Theme.of(context)
                                        .primaryTextTheme
                                        .subhead
                                        .copyWith(
                                          color: Colors.white54,
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
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children:
                                    getPlayersForStyle(playingStyle, context),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
              league.status == LeagueStatus.COMPLETED
                  ? Row(
                      children: <Widget>[
                        Expanded(
                          child: Container(
                            height: bIsMediumDevice
                                ? 56.0
                                : bIsSmallDevice ? 48.0 : 64.0,
                            color: Colors.grey.shade700,
                            padding: EdgeInsets.symmetric(horizontal: 16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: <Widget>[
                                Text(
                                  myTeam.score.toString(),
                                  style: Theme.of(context)
                                      .primaryTextTheme
                                      .headline
                                      .copyWith(
                                        color: Colors.white,
                                      ),
                                ),
                                Text(
                                  "Total Points".toUpperCase(),
                                  style: Theme.of(context)
                                      .primaryTextTheme
                                      .title
                                      .copyWith(
                                        color: Colors.grey.shade400,
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
