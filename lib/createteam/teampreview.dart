import 'package:flutter/material.dart';
import 'package:playfantasy/commonwidgets/scaffoldpage.dart';
import 'package:playfantasy/modal/l1.dart';

class TeamPreview extends StatelessWidget {
  final List<Player> selectedPlayers;
  final FanTeamRule fanTeamRules;

  TeamPreview({this.selectedPlayers, this.fanTeamRules});

  getPlayersForStyle(PlayingStyle playingStyle, BuildContext context) {
    List<Widget> players = [];
    bool bIsSmallDevice = MediaQuery.of(context).size.width < 320.0;
    selectedPlayers.forEach((Player player) {
      if (player.playingStyleId == playingStyle.id) {
        players.add(
          Column(
            children: <Widget>[
              Container(
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
    return ScaffoldPage(
      backgroundColor: Colors.green.shade700,
      appBar: AppBar(
        elevation: 0.0,
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
        title: Text(""),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.edit),
            onPressed: () {},
          ),
          IconButton(
            icon: Icon(Icons.share),
            onPressed: () {},
          ),
          IconButton(
            icon: Icon(Icons.close),
            onPressed: () {
              Navigator.pop(context);
            },
          )
        ],
      ),
      body: Column(
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
                        style:
                            Theme.of(context).primaryTextTheme.body1.copyWith(
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
    );
  }
}
