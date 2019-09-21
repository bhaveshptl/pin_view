import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:playfantasy/createteam/sports.dart';
import 'package:playfantasy/createteam/teampreview.dart';
import 'dart:io';
import 'package:playfantasy/modal/l1.dart';
import 'package:playfantasy/appconfig.dart';
import 'package:playfantasy/modal/league.dart';
import 'package:playfantasy/modal/myteam.dart';
import 'package:playfantasy/utils/apiutil.dart';
import 'package:playfantasy/utils/httpmanager.dart';
import 'package:playfantasy/utils/stringtable.dart';
import 'package:playfantasy/commonwidgets/epoc.dart';
import 'package:playfantasy/utils/sharedprefhelper.dart';
import 'package:playfantasy/createteam/choosecaptain.dart';
import 'package:playfantasy/modal/createteamresponse.dart';
import 'package:playfantasy/commonwidgets/color_button.dart';
import 'package:playfantasy/commonwidgets/scaffoldpage.dart';
import 'package:playfantasy/createteam/playingstyletab.dart';
import 'package:playfantasy/redux/actions/loader_actions.dart';
import 'package:playfantasy/commonwidgets/fantasypageroute.dart';
import 'package:playfantasy/utils/analytics.dart';

class TeamCreationMode {
  static const int CREATE_TEAM = 1;
  static const int EDIT_TEAM = 2;
  static const int CLONE_TEAM = 3;
}

class CreateTeam extends StatefulWidget {
  final int mode;
  final L1 l1Data;
  final League league;
  final MyTeam selectedTeam;
 
  CreateTeam({this.league, this.l1Data, this.mode, this.selectedTeam});

  @override
  State<StatefulWidget> createState() => CreateTeamState();
}

class CreateTeamState extends State<CreateTeam>
    with SingleTickerProviderStateMixin {
  int _sportType = 1;
  double _usedCredits = 0.0;
  int _selectedPlayersCount = 0;
  final double TEAM_LOGO_HEIGHT = 48.0;
  final _scaffoldKey = new GlobalKey<ScaffoldState>();
  bool isIos = false;
  Player _captain;
  Player _vCaptain;
  String _sortedBy;
  bool bIsAscending = false;
  List<Player> allPlayers;
  Widget floatButtonWidget;
  String _avgCredits = "0";
  FanTeamRule _fanTeamRules;
  bool showNextButton = true;
  TabController tabController;
  List<Player> _selectedPlayers = [];
  Map<String, dynamic> _playerCountByStyle = {};
  Map<int, List<Player>> _selectedPlayersByStyleId = {};
  List<int> initialSquad =[];

  int teamAPlayerCount = 0;
  int teamBPlayerCount = 0;

  @override
  void initState() {
    super.initState();
    _addPlayerTeamId();
    _getSportsType();
    
    
     if(widget.l1Data.initialSquad !=null){
        initialSquad=widget.l1Data.initialSquad;
     }
    _selectedPlayers =
        widget.selectedTeam != null ? widget.selectedTeam.players : [];

    _fanTeamRules = widget.l1Data.league.fanTeamRules;
    _avgCredits = (widget.l1Data.league.fanTeamRules.credits /
            widget.l1Data.league.fanTeamRules.playersTotal)
        .toStringAsFixed(2);

    List<Player> teamAPlayers =
        widget.l1Data.league.rounds[0].matches[0].teamA.players;
    List<Player> teamBPlayers =
        widget.l1Data.league.rounds[0].matches[0].teamB.players;

    allPlayers = [];
    allPlayers.addAll(teamAPlayers);
    allPlayers.addAll(teamBPlayers);

    List<Player> _selectedTeamPlayers = [];
    allPlayers.forEach((Player player) {
      _selectedPlayers.forEach((Player selectedPlayer) {
        if (selectedPlayer.id == player.id) {
          _selectedTeamPlayers.add(player);
        }
      });
    });
    _selectedPlayers = _selectedTeamPlayers;

    if (widget.mode == TeamCreationMode.CLONE_TEAM ||
        widget.mode == TeamCreationMode.EDIT_TEAM) {
      _editOrCloneTeam();
    }

    onSort("CREDITS");

    tabController =
        TabController(length: _fanTeamRules.styles.length, vsync: this);
    tabController.addListener(() {
      bool bShowNext =
          tabController.index == tabController.length - 1 ? false : true;
      if (bShowNext != showNextButton) {
        setState(() {
          showNextButton = bShowNext;
        });
      }
    });
    floatButtonWidget = Icon(Icons.navigate_next);
    if (Platform.isIOS) {
      isIos = true;
    }
    webEngageCreateTeamInitiatedEvent();
  }

  _getSportsType() async {
    Future<dynamic> futureSportType =
        SharedPrefHelper.internal().getSportsType();
    await futureSportType.then((value) {
      if (value != null) {
        setState(() {
          _sportType = int.parse(value);
        });
      }
    });
  }

  showLoader(bool bShow) {
    AppConfig.of(context)
        .store
        .dispatch(bShow ? LoaderShowAction() : LoaderHideAction());
  }

  _addPlayerTeamId() {
    List<Player> teamAPlayers =
        widget.l1Data.league.rounds[0].matches[0].teamA.players;
    List<Player> teamBPlayers =
        widget.l1Data.league.rounds[0].matches[0].teamB.players;

    for (Player player in teamAPlayers) {
      player.teamId = widget.l1Data.league.rounds[0].matches[0].teamA.id;
      player.jerseyUrl =
          widget.l1Data.league.rounds[0].matches[0].teamA.jerseyUrl;
      if (widget.mode == TeamCreationMode.EDIT_TEAM ||
          widget.mode == TeamCreationMode.CLONE_TEAM) {
        if (widget.selectedTeam.viceCaptain == player.id) {
          _vCaptain = player;
        } else if (widget.selectedTeam.captain == player.id) {
          _captain = player;
        }
      }
    }

    for (Player player in teamBPlayers) {
      player.teamId = widget.l1Data.league.rounds[0].matches[0].teamB.id;
      player.jerseyUrl =
          widget.l1Data.league.rounds[0].matches[0].teamB.jerseyUrl;
      if (widget.mode == TeamCreationMode.EDIT_TEAM ||
          widget.mode == TeamCreationMode.CLONE_TEAM) {
        if (widget.selectedTeam.viceCaptain == player.id) {
          _vCaptain = player;
        } else if (widget.selectedTeam.captain == player.id) {
          _captain = player;
        }
      }
    }
  }

  ///
  /// Iterate selected players and calculate player credits
  /// to edit or clone team.
  ///
  _editOrCloneTeam() {
    setPlayerCount();
    _seperatePlayersByPlayingStyle();
    calculatePlayerCredits(_selectedPlayers);
  }

  setPlayerCount() {
    _selectedPlayers.forEach((player) {
      if (player.teamId == widget.league.teamA.id) {
        teamAPlayerCount++;
      } else {
        teamBPlayerCount++;
      }
    });
  }

  ///
  /// Iterate selected players and create map by [playingStyleId] -> List[players].
  ///
  _seperatePlayersByPlayingStyle() {
    _selectedPlayersByStyleId = {};
    for (Player player in _selectedPlayers) {
      if (_selectedPlayersByStyleId[player.playingStyleId] == null) {
        _selectedPlayersByStyleId[player.playingStyleId] = [];
      }
      _selectedPlayersByStyleId[player.playingStyleId].add(player);
    }
  }

  ///
  /// returns player index in selected player lisr.
  ///
  int _getPlayerIndex(Player player) {
    int selectedPlayerIndex = -1;
    int currentIndex = 0;
    for (Player selectedPlayer in _selectedPlayers) {
      if (player.id == selectedPlayer.id) {
        selectedPlayerIndex = currentIndex;
      }
      currentIndex++;
    }
    return selectedPlayerIndex;
  }

  ///
  /// Returns selected player count of give [style].
  ///
  _getSelectedPlayerCountForStyle(PlayingStyle style) {
    int _playerCount = 0;
    for (Player player in _selectedPlayers) {
      if (player.playingStyleId == style.id) {
        _playerCount++;
      }
    }
    return _playerCount;
  }

  ///
  /// It will toggle player selection after validating player selection
  /// and re-calculate player credits.
  /// It will also re-create tabs which is currently active.
  ///
  void _selectPlayer(PlayingStyle style, Player player) {
    final _selectedPlayerIndex = _getPlayerIndex(player);

    setState(() {
      if (_selectedPlayerIndex == -1) {
        if (!_isValidPlayerSelection(style, player)) {
          return;
        }
        _selectedPlayers.add(player);
        if (player.teamId == widget.league.teamA.id) {
          teamAPlayerCount++;
        } else {
          teamBPlayerCount++;
        }
      } else {
        _selectedPlayers.removeAt(_selectedPlayerIndex);
        if (_captain != null && player.id == _captain.id) {
          _captain = null;
        } else if (_vCaptain != null && player.id == _vCaptain.id) {
          _vCaptain = null;
        }
        if (player.teamId == widget.league.teamA.id) {
          teamAPlayerCount--;
        } else {
          teamBPlayerCount--;
        }
      }

      _seperatePlayersByPlayingStyle();
      calculatePlayerCredits(_selectedPlayers);
    });
  }

  ///
  /// It will check if player to be selected is according to team selection
  /// or not. it will return true if its valid else false and show message
  /// accordingly.
  ///
  /// [style] Playing style object of [player] to validate.
  ///
  bool _isValidPlayerSelection(PlayingStyle style, Player player) {
    final int _stylePlayerCount = _getSelectedPlayerCountForStyle(style);

    if (_selectedPlayers.length >= _fanTeamRules.playersTotal) {
      _showErrorMessage(
        strings.get("PLAYER_SELECTION_LIMIT").replaceAll(
              "\$limit",
              _fanTeamRules.playersTotal.toString(),
            ),
      );
      return false;
    }

    if ((_usedCredits + player.credit) > _fanTeamRules.credits) {
      _showErrorMessage(
        strings.get("PLAYER_CREDITS_LIMIT").replaceAll(
              "\$limit",
              _fanTeamRules.credits.toString(),
            ),
      );
      return false;
    }

    if (_stylePlayerCount >= style.rule[1]) {
      _showErrorMessage(
        strings
            .get("PLAYER_STYLE_LIMIT")
            .replaceAll(
              "\$limit",
              style.rule[1].toString(),
            )
            .replaceAll("\$label", style.label),
      );
      return false;
    }

    if (player.countryId !=
            widget.l1Data.league.rounds[0].matches[0].series.countryId &&
        _getForeignPlayerCount() >= _fanTeamRules.playersForeign) {
      _showErrorMessage(
        strings.get("PLAYER_CREDITS_LIMIT").replaceAll(
              "\$limit",
              _fanTeamRules.playersForeign.toString(),
            ),
      );
      return false;
    }

    if (_getPlayerCountPerTeam(player.teamId) >= _fanTeamRules.playersPerTeam) {
      _showErrorMessage(
        strings.get("SINGLE_TEAM_PLAYER_LIMIT").replaceAll(
              "\$limit",
              _fanTeamRules.playersPerTeam.toString(),
            ),
      );
      return false;
    }

    for (PlayingStyle style in _fanTeamRules.styles) {
      int playerCountForStyle = _selectedPlayersByStyleId[style.id] == null
          ? 0
          : _selectedPlayersByStyleId[style.id].length;
      if ((_fanTeamRules.playersTotal - (_selectedPlayersCount + 1) <
              style.rule[0] - playerCountForStyle) &&
          player.playingStyleId != style.id) {
        _showErrorMessage(
          strings
              .get("PLAYER_STYLE_MIN_LIMIT")
              .replaceAll(
                "\$limit",
                style.rule[0].toString(),
              )
              .replaceAll("\$label", style.label),
        );
        return false;
      }
    }

    return true;
  }

  ///
  /// It will return selected players count for team
  /// with given [teamId].
  ///
  _getPlayerCountPerTeam(int teamId) {
    int _playersPerTeamCount = 0;
    for (Player player in _selectedPlayers) {
      if (player.teamId == teamId) {
        _playersPerTeamCount++;
      }
    }
    return _playersPerTeamCount;
  }

  ///
  /// It will calculate selected team used credits, number of players selected,
  /// and average credits user can use for next playera selection.
  /// [selectedPlayers] is List of players selected for which calculations should
  /// done.
  ///
  void calculatePlayerCredits(List<Player> selectedPlayers) {
    double usedCredits = 0.0;
    _selectedPlayersCount = selectedPlayers.length;
    for (Player player in selectedPlayers) {
      usedCredits += player.credit;
      if (_playerCountByStyle[player.playingStyleId] == null) {
        _playerCountByStyle[player.playingStyleId.toString()] = 0;
      }
      _playerCountByStyle[player.playingStyleId.toString()]++;
    }
    _usedCredits = usedCredits;
    _avgCredits = _selectedPlayersCount != _fanTeamRules.playersTotal
        ? ((_fanTeamRules.credits - usedCredits) /
                (_fanTeamRules.playersTotal - _selectedPlayersCount))
            .toStringAsFixed(2)
        : "-";
  }

  ///
  /// Check for team validation based on team creation rules.
  /// Use this method when user click on choose captain/next.
  ///
  bool _isValidTeam() {
    if (_selectedPlayers.length != _fanTeamRules.playersTotal) {
      _showErrorMessage(
        strings.get("DREAM_TEAM_MSG").replaceAll(
              "\$count",
              (_fanTeamRules.playersTotal - _selectedPlayers.length).toString(),
            ),
      );
      return false;
    }
    if (!isPlayerStyleCriteriaMatch()) {
      return false;
    }
    if (_getForeignPlayerCount() > _fanTeamRules.playersForeign) {
      return false;
    }
    return true;
  }

  ///
  /// It will return foreign players count.
  ///
  _getForeignPlayerCount() {
    int _foreignPlayerCount = 0;
    for (Player player in _selectedPlayers) {
      if (player.countryId !=
          widget.l1Data.league.rounds[0].matches[0].series.countryId) {
        _foreignPlayerCount++;
      }
    }
    return _foreignPlayerCount;
  }

  ///
  /// It will check if all playing style player selection is matched
  /// according to team creation rules or not.
  ///
  bool isPlayerStyleCriteriaMatch() {
    for (PlayingStyle style in _fanTeamRules.styles) {
      int playingStyleCount = _getSelectedPlayerCountForStyle(style);
      if (!(playingStyleCount >= style.rule[0] &&
          playingStyleCount <= style.rule[1])) {
        if (playingStyleCount < style.rule[0]) {
          _showErrorMessage(
            strings
                .get("STYLE_MIN_COUNT")
                .replaceAll(
                  "\$count",
                  style.rule[0].toString(),
                )
                .replaceAll(
                  "\$style",
                  style.label.toLowerCase(),
                ),
          );
        } else if (playingStyleCount > style.rule[1]) {
          _showErrorMessage(
            strings
                .get("STYLE_MAX_COUNT")
                .replaceAll(
                  "\$count",
                  style.rule[1].toString(),
                )
                .replaceAll(
                  "\$style",
                  style.label.toLowerCase(),
                ),
          );
        }
        return false;
      }
    }
    return true;
  }

  ///
  /// It will show bottom panel popup for captain
  /// and vice captain selection.
  ///
  void _showChooseCaptain() {
    // _selectedPlayers.sort((a, b) {
    //   return a.playingStyleId - b.playingStyleId;
    // });
    var players = [];
    _fanTeamRules.styles.forEach((style) {
      _selectedPlayers.forEach((player) {
        if (style.id == player.playingStyleId) {
          players.add(player);
        }
      });
    });
    Navigator.of(context).push(
      FantasyPageRoute(
        pageBuilder: (context) => ChooseCaptain(
          captain: _captain,
          l1Data: widget.l1Data,
          league: widget.league,
          viceCaptain: _vCaptain,
          onSave: _onSaveCaptains,
          fanTeamRules: _fanTeamRules,
          mapSportLabel: sports.playingStyles,
          selectedPlayers: _selectedPlayers,
        ),
      ),
    );
  }

  ///
  /// Iterate playing style array get from team creation rules
  /// and create tabs for each playing style and returns tab
  /// object which includes tab icon and other UI.
  ///
  _createTabsBasedOnPlayingStyle() {
    final List<PlayingStyle> _playingStyles =
        _fanTeamRules != null ? _fanTeamRules.styles : [];
    List<Widget> tabs = [];
    for (PlayingStyle style in _playingStyles) {
      tabs.add(
        Tab(
          text: sports.playingStyles[style.id] +
              "(" +
              (_selectedPlayersByStyleId[style.id] == null
                  ? 0.toString()
                  : _selectedPlayersByStyleId[style.id].length.toString()) +
              ")",
        ),
      );
    }

    return Container(
      color: Colors.white,
      child: TabBar(
        tabs: tabs,
        indicatorWeight: 2.0,
        controller: tabController,
        unselectedLabelColor: Colors.black45,
        labelColor: Theme.of(context).primaryColor,
        indicatorColor: Theme.of(context).primaryColor,
        labelStyle: Theme.of(context).primaryTextTheme.subhead.copyWith(
              fontWeight: FontWeight.w600,
              fontSize: 18.0,
            ),
      ),
    );
  }

   onPlayerSquadePlayersChanged(List<int> modifiedList){
    // setState(() {
    //   initialSquad=modifiedList;
    // });
  }


  _getTabsBodyBasedOnPlayingStyle() {
    List<PlayingStyleTab> tabsBody = [];
    bool showSquadAnnouncedPlayersStatus =false;
    if(widget.l1Data.initialSquad !=null){
      showSquadAnnouncedPlayersStatus= widget.l1Data.initialSquad.isNotEmpty;
    }
    for (PlayingStyle style in _fanTeamRules.styles) {
      tabsBody.add(
        PlayingStyleTab(
          style: style,
          onSort: onSort,
          sortedBy: _sortedBy,
          league: widget.league,
          l1Data: widget.l1Data,
          allPlayers: allPlayers,
          isAscending: bIsAscending,
          onPlayerSelect: _selectPlayer,
          mapSportLabel: sports.playingStyles,
          selectedPlayers: _selectedPlayersByStyleId[style.id],
          showSquadAnnouncedPlayersStatus:showSquadAnnouncedPlayersStatus,
          initialSquad:initialSquad
        ),
      );
    }
    return tabsBody;
  }

  onSort(String type) {
    if (_sortedBy == type) {
      setState(() {
        bIsAscending = !bIsAscending;
        allPlayers = allPlayers.reversed.toList();
      });
    } else {
      switch (type) {
        case "NAME":
          bIsAscending = true;
          setState(() {
            allPlayers.sort((a, b) {
              return a.name.compareTo(b.name);
            });
          });
          break;
        case "SCORE":
          bIsAscending = false;
          setState(() {
            allPlayers.sort((a, b) {
              return ((b.seriesScore - a.seriesScore) * 100).toInt();
            });
          });
          break;
        case "CREDITS":
          bIsAscending = false;
          setState(() {
            allPlayers.sort((a, b) {
              return ((b.credit - a.credit) * 100).toInt();
            });
          });
          break;
      }
    }
    _sortedBy = type;
  }

  ///
  /// It will show [message] in bottom sheet.
  ///
  void _showErrorMessage(String message) {
    showModalBottomSheet<void>(
      context: context,
      builder: (BuildContext context) {
        return Container(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Theme.of(context).errorColor,
                fontSize: 24.0,
              ),
            ),
          ),
        );
      },
    );
  }

  _getTeamToSave() {
    webEngageCreatedTeamEvent();
    Map<String, dynamic> team = {
      "matchId": widget.league.matchId,
      "leagueId": widget.l1Data.league.id,
      "seriesId": widget.league.series.id,
      "captain": _captain == null ? -1 : _captain.id,
      "viceCaptain": _vCaptain == null ? -1 : _vCaptain.id,
      "players": _selectedPlayers,
      "name": "",
    };

    if (widget.l1Data.league.inningsId != null) {
      team["inningsId"] = widget.l1Data.league.inningsId;
    }

    if (widget.mode == TeamCreationMode.EDIT_TEAM) {
      team["fanTeamId"] = widget.selectedTeam.id;
      team["name"] = widget.selectedTeam.name;
    }

    return team;
  }

  webEngageCreateTeamInitiatedEvent() {
    DateTime now = new DateTime.now();
    DateTime date = new DateTime(now.year, now.month, now.day);
    Map<dynamic, dynamic> eventdata = new Map();
    Map<String, dynamic> webengageTeamData = new Map();
    webengageTeamData["MatchId"] = widget.league.matchId;
    webengageTeamData["LeagueId"] = widget.l1Data.league.id;
    webengageTeamData["SeriesId"] = widget.league.series.id;
    webengageTeamData["MatchDate"] =getReadableDateFromTimeStamp(widget.l1Data.league.rounds[0].matches[0].startTime.toString());
    webengageTeamData["MatchName"] = widget.l1Data.league.name;
    webengageTeamData["SportType"] = _sportType;
    webengageTeamData["Team1"] =
        widget.l1Data.league.rounds[0].matches[0].teamA.name;
    webengageTeamData["Team2"] =
        widget.l1Data.league.rounds[0].matches[0].teamB.name;
    webengageTeamData["SeriesTypeInfo"] = widget.league.series.seriesTypeInfo;
    webengageTeamData["SeriesStartDate"] =
        getReadableDateFromTimeStamp(widget.league.series.startDate.toString());
    webengageTeamData["SeriesEndDate"] =
        getReadableDateFromTimeStamp(widget.league.series.endDate.toString());
    eventdata["eventName"] = "CREATE_TEAM_INITIATED";
    webengageTeamData["Format"] = "";
    eventdata["data"] = webengageTeamData;
    AnalyticsManager.trackEventsWithAttributes(eventdata);
  }

  webEngageCreatedTeamEvent() {
    DateTime now = new DateTime.now();
    DateTime date = new DateTime(now.year, now.month, now.day);
    Map<String, dynamic> webengageTeamData = new Map();
    webengageTeamData["MatchId"] = widget.league.matchId;
    webengageTeamData["LeagueId"] = widget.l1Data.league.id;
    webengageTeamData["SeriesId"] = widget.league.series.id;
    webengageTeamData["MatchDate"] = getReadableDateFromTimeStamp(
        widget.l1Data.league.rounds[0].matches[0].startTime.toString());
    webengageTeamData["MatchName"] = widget.l1Data.league.name;
    webengageTeamData["SportType"] = _sportType;
    webengageTeamData["Team1"] =
        widget.l1Data.league.rounds[0].matches[0].teamA.name;
    webengageTeamData["Team2"] =
        widget.l1Data.league.rounds[0].matches[0].teamB.name;
    webengageTeamData["Format"] = "";
    webengageTeamData["SelectedCaptain"] = _captain.name;
    webengageTeamData["SeriesTypeInfo"] = widget.league.series.seriesTypeInfo;
    webengageTeamData["SeriesStartDate"] =
        getReadableDateFromTimeStamp(widget.league.series.startDate.toString());
    webengageTeamData["SeriesEndDate"] =
        getReadableDateFromTimeStamp(widget.league.series.endDate.toString());
    Map<dynamic, dynamic> eventdata = new Map();
    eventdata["eventName"] = "TEAM_CREATED";
    eventdata["data"] = webengageTeamData;
    AnalyticsManager.trackEventsWithAttributes(eventdata);
  }

  String getReadableDateFromTimeStamp(String timeStamp) {
    String convertedDate = "";
    if (timeStamp.length > 0) {
      DateTime date = DateTime.fromMillisecondsSinceEpoch(int.parse(timeStamp));
      convertedDate = date.day.toString() +
          "-" +
          date.month.toString() +
          "-" +
          date.year.toString();
    }
    return convertedDate;
  }

  void _onSaveCaptains(Player captain, Player viceCaptain) {
    _captain = captain;
    _vCaptain = viceCaptain;

    if (_captain == null) {
      _showErrorMessage(
        "Please select captain to make your dream team.",
      );
      return;
    }
    if (_vCaptain == null) {
      _showErrorMessage(
        "Please select vice captain to make your dream team.",
      );
      return;
    }

    Navigator.pop(context);
    if (widget.mode == TeamCreationMode.EDIT_TEAM) {
      _updateTeam(_getTeamToSave());
    } else {
      createTeam(_getTeamToSave());
    }
  }

  void createTeam(Map<String, dynamic> team) async {
    showLoader(true);
    http.Request req =
        http.Request("POST", Uri.parse(BaseUrl().apiUrl + ApiUtil.CREATE_TEAM));
    req.body = json.encode(team);
    return HttpManager(http.Client())
        .sendRequest(req)
        .then((http.Response res) {
      if (res.statusCode >= 200 && res.statusCode <= 300) {
        CreateTeamResponse response =
            CreateTeamResponse.fromJson(json.decode(res.body));
        Navigator.pop(context, response.message);
      } else {
        _showErrorMessage(
          strings.get("SAVE_TEAM_ERROR"),
        );
      }
    }).whenComplete(() {
      showLoader(false);
    });
  }

  void _updateTeam(Map<String, dynamic> team) async {
    String cookie;
    showLoader(true);
    Future<dynamic> futureCookie = SharedPrefHelper.internal().getCookie();
    await futureCookie.then((value) {
      cookie = value;
    });

    return new http.Client()
        .put(
      BaseUrl().apiUrl + ApiUtil.EDIT_TEAM + widget.selectedTeam.id.toString(),
      headers: {
        'Content-type': 'application/json',
        "cookie": cookie,
        "channelId": AppConfig.of(context).channelId
      },
      body: json.encoder.convert(team),
    )
        .then((http.Response res) {
      if (res.statusCode >= 200 && res.statusCode <= 300) {
        Map<String, dynamic> response = json.decode(res.body);
        Navigator.of(context).pop(response["message"]);
      } else {
        _showErrorMessage(
          strings.get("UPDATE_TEAM_ERROR"),
        );
      }
    }).whenComplete(() {
      showLoader(false);
    });
  }

  @override
  Widget build(BuildContext context) {
    Color colorA = Color.fromRGBO(133, 15, 15, 1);
    Color colorB = Color.fromRGBO(122, 11, 10, 1);

    return ScaffoldPage(
      scaffoldKey: _scaffoldKey,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(kToolbarHeight + 128.0),
        child: Row(
          children: <Widget>[
            Expanded(
              child: Stack(
                children: <Widget>[
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          colorA,
                          colorB,
                        ],
                        stops: [0.5, 0.5],
                        tileMode: TileMode.repeated,
                      ),
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.only(
                        left: MediaQuery.of(context).size.width * 0.1),
                    child: Transform(
                      transform: Matrix4.skewX(-0.2),
                      origin: Offset(0.0, 0.0),
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              colorA,
                              colorB,
                            ],
                            stops: [0.5, 0.5],
                            tileMode: TileMode.repeated,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Column(
                    children: <Widget>[
                      AppBar(
                        title: EPOC(
                          timeInMiliseconds: widget.league.matchStartTime,
                          style:
                              Theme.of(context).primaryTextTheme.body2.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                  ),
                        ),
                        elevation: 0.0,
                        centerTitle: true,
                        backgroundColor: Colors.transparent,
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          Text(
                            "Max " +
                                _fanTeamRules.playersPerTeam.toString() +
                                " players from a team",
                            style: Theme.of(context)
                                .primaryTextTheme
                                .subhead
                                .copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500,
                                ),
                          ),
                        ],
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: <Widget>[
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  strings.get("PLAYERS"),
                                  style: Theme.of(context)
                                      .primaryTextTheme
                                      .subhead
                                      .copyWith(
                                        color: Colors.white54,
                                      ),
                                ),
                                Text(
                                  _selectedPlayersCount.toString() +
                                      "/" +
                                      (widget.l1Data != null
                                          ? widget.l1Data.league.fanTeamRules
                                              .playersTotal
                                              .toString()
                                          : ""),
                                  style: TextStyle(
                                    fontSize: Theme.of(context)
                                        .primaryTextTheme
                                        .title
                                        .fontSize,
                                    color: Colors.white54,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                            Column(
                              children: <Widget>[
                                Padding(
                                  padding: EdgeInsets.only(top: 16.0),
                                  child: Row(
                                    children: <Widget>[
                                      Container(
                                        padding: EdgeInsets.all(2.0),
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: Colors.white,
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black12,
                                              blurRadius: 1.0,
                                              spreadRadius: 0.5,
                                              offset: Offset(0.0, 2.0),
                                            )
                                          ],
                                        ),
                                        child: ClipRRect(
                                          clipBehavior: Clip.hardEdge,
                                          borderRadius: BorderRadius.circular(
                                            TEAM_LOGO_HEIGHT,
                                          ),
                                          child: CachedNetworkImage(
                                            imageUrl: widget.league.teamA !=
                                                    null
                                                ? widget.league.teamA.logoUrl
                                                : "",
                                            fit: BoxFit.fitHeight,
                                            placeholder: (context, string) {
                                              return Container(
                                                padding: EdgeInsets.all(12.0),
                                                child:
                                                    CircularProgressIndicator(
                                                  strokeWidth: 2.0,
                                                ),
                                                width: TEAM_LOGO_HEIGHT,
                                                height: TEAM_LOGO_HEIGHT,
                                              );
                                            },
                                            height: TEAM_LOGO_HEIGHT,
                                            width: TEAM_LOGO_HEIGHT,
                                          ),
                                        ),
                                      ),
                                      Padding(
                                        padding: EdgeInsets.only(left: 8.0),
                                        child: Column(
                                          children: <Widget>[
                                            Text(
                                              widget.league.teamA != null
                                                  ? widget.league.teamA.name
                                                  : "",
                                              style: Theme.of(context)
                                                  .primaryTextTheme
                                                  .subhead
                                                  .copyWith(
                                                    color: Colors.white54,
                                                  ),
                                            ),
                                            Text(
                                              teamAPlayerCount.toString(),
                                              style: Theme.of(context)
                                                  .primaryTextTheme
                                                  .subhead
                                                  .copyWith(
                                                    color: Colors.white54,
                                                  ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            Column(
                              children: <Widget>[
                                Padding(
                                  padding: EdgeInsets.only(top: 16.0),
                                  child: Row(
                                    children: <Widget>[
                                      Padding(
                                        padding: EdgeInsets.only(right: 8.0),
                                        child: Column(
                                          children: <Widget>[
                                            Text(
                                              widget.league.teamB != null
                                                  ? widget.league.teamB.name
                                                  : "",
                                              style: Theme.of(context)
                                                  .primaryTextTheme
                                                  .subhead
                                                  .copyWith(
                                                    color: Colors.white54,
                                                  ),
                                            ),
                                            Text(
                                              teamBPlayerCount.toString(),
                                              style: Theme.of(context)
                                                  .primaryTextTheme
                                                  .subhead
                                                  .copyWith(
                                                    color: Colors.white54,
                                                  ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Container(
                                        padding: EdgeInsets.all(2.0),
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: Colors.white,
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black12,
                                              blurRadius: 1.0,
                                              spreadRadius: 0.5,
                                              offset: Offset(0.0, 2.0),
                                            )
                                          ],
                                        ),
                                        child: ClipRRect(
                                          clipBehavior: Clip.hardEdge,
                                          borderRadius: BorderRadius.circular(
                                            TEAM_LOGO_HEIGHT,
                                          ),
                                          child: CachedNetworkImage(
                                            imageUrl: widget.league.teamB !=
                                                    null
                                                ? widget.league.teamB.logoUrl
                                                : "",
                                            fit: BoxFit.fitHeight,
                                            placeholder: (context, string) {
                                              return Container(
                                                padding: EdgeInsets.all(12.0),
                                                child:
                                                    CircularProgressIndicator(
                                                  strokeWidth: 2.0,
                                                ),
                                                width: TEAM_LOGO_HEIGHT,
                                                height: TEAM_LOGO_HEIGHT,
                                              );
                                            },
                                            height: TEAM_LOGO_HEIGHT,
                                            width: TEAM_LOGO_HEIGHT,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: <Widget>[
                                Text(
                                  strings.get("CREDITS"),
                                  style: Theme.of(context)
                                      .primaryTextTheme
                                      .subhead
                                      .copyWith(
                                        color: Colors.white54,
                                      ),
                                ),
                                Text(
                                  (widget.l1Data.league.fanTeamRules.credits -
                                          _usedCredits)
                                      .toStringAsFixed(2),
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: Theme.of(context)
                                        .primaryTextTheme
                                        .title
                                        .fontSize,
                                    color: Colors.white70,
                                    fontWeight: FontWeight.w800,
                                  ),
                                )
                              ],
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding:
                            EdgeInsets.only(top: 8.0, left: 16.0, right: 16.0),
                        child: Row(
                          children: List.generate(_fanTeamRules.playersTotal,
                              (index) {
                            if (index < _selectedPlayersCount) {
                              return Padding(
                                padding: EdgeInsets.all(4.0),
                                child: Container(
                                  height: 16.0,
                                  alignment: Alignment.center,
                                  child: Text(
                                    (index + 1).toString(),
                                    style: Theme.of(context)
                                        .primaryTextTheme
                                        .caption
                                        .copyWith(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w800,
                                        ),
                                  ),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(2.0),
                                    color: Color.fromRGBO(70, 165, 12, 1),
                                  ),
                                  width: ((MediaQuery.of(context).size.width -
                                              32.0) /
                                          _fanTeamRules.playersTotal) -
                                      8.0,
                                ),
                              );
                            } else {
                              return Padding(
                                padding: EdgeInsets.all(4.0),
                                child: Container(
                                  height: 16.0,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(2.0),
                                    color: Colors.white,
                                  ),
                                  alignment: Alignment.center,
                                  child:
                                      (index + 1) == _fanTeamRules.playersTotal
                                          ? Text(
                                              (index + 1).toString(),
                                              style: Theme.of(context)
                                                  .primaryTextTheme
                                                  .caption
                                                  .copyWith(
                                                    color: Theme.of(context)
                                                        .primaryColor,
                                                    fontWeight: FontWeight.w800,
                                                  ),
                                            )
                                          : Container(),
                                  width: ((MediaQuery.of(context).size.width -
                                              32.0) /
                                          _fanTeamRules.playersTotal) -
                                      8.0,
                                ),
                              );
                            }
                          }),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: <Widget>[
          _createTabsBasedOnPlayingStyle(),
          Expanded(
            child: TabBarView(
              controller: tabController,
              children: _getTabsBodyBasedOnPlayingStyle(),
            ),
          ),
          Container(
            height: 64.0,
            padding: isIos ? EdgeInsets.only(bottom: 8.0) : null,
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  blurRadius: 10.0,
                  spreadRadius: 3.0,
                  color: Colors.black12,
                ),
              ],
            ),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(left: 40.0, right: 8.0),
                    child: Container(
                      height: 48.0,
                      child: ColorButton(
                        color: Colors.orange,
                        child: Text(
                          "Team Preview".toUpperCase(),
                          style: Theme.of(context)
                              .primaryTextTheme
                              .subhead
                              .copyWith(
                                color: Colors.white,
                                fontWeight:
                                    isIos ? FontWeight.w600 : FontWeight.w900,
                              ),
                        ),
                        onPressed: () {
                          Navigator.of(context).push(
                            FantasyPageRoute(
                              pageBuilder: (BuildContext context) =>
                                  TeamPreview(
                                league: widget.league,
                                l1Data: widget.l1Data,
                                allowEditTeam: false,
                                fanTeamRules: _fanTeamRules,
                                myTeam: MyTeam(
                                  players: _selectedPlayers,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(right: 40.0, left: 8.0),
                    child: Container(
                      height: 48.0,
                      child: ColorButton(
                        child: Text(
                          "Continue".toUpperCase(),
                          style: Theme.of(context)
                              .primaryTextTheme
                              .subhead
                              .copyWith(
                                color: Colors.white,
                                fontWeight:
                                    isIos ? FontWeight.w600 : FontWeight.w900,
                              ),
                        ),
                        onPressed: _selectedPlayers.length !=
                                _fanTeamRules.playersTotal
                            ? null
                            : () {
                                if (_isValidTeam()) {
                                  _showChooseCaptain();
                                }
                              },
                      ),
                    ),
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}
