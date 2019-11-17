import 'package:flutter/material.dart';
import 'package:playfantasy/appconfig.dart';
import 'package:playfantasy/commonwidgets/fantasypageroute.dart';
import 'package:http/http.dart' as http;
import 'package:playfantasy/modal/account.dart';
import 'package:playfantasy/utils/apiutil.dart';
import 'package:playfantasy/utils/httpmanager.dart';
import 'dart:convert';
import 'package:playfantasy/modal/league.dart';
import 'package:playfantasy/redux/actions/loader_actions.dart';
import 'package:playfantasy/utils/stringtable.dart';
import 'package:playfantasy/lobby/tabs/leaguecard.dart';
import 'package:playfantasy/leaguedetail/leaguedetail.dart';

class StatusTab extends StatelessWidget {
  final int sportType;
  final int leagueStatus;
  final Function onSportChange;
  final List<League> allLeagues;
  final List<League> statusLeagues;
  final Map<String, int> mapSportTypes;
  final Function onLeagueStatusChanged;

  StatusTab({
    this.sportType,
    this.allLeagues,
    this.leagueStatus,
    this.statusLeagues,
    this.onSportChange,
    this.mapSportTypes,
    this.onLeagueStatusChanged,
  });

  showLoader(bool bShow, BuildContext context) {
    AppConfig.of(context)
        .store
        .dispatch(bShow ? LoaderShowAction() : LoaderHideAction());
  }

  onLeagueSelect(BuildContext context, League league) async {
    showLoader(true, context);
    Map<String, dynamic> accountData = await getUserAccountsData();
    Account accountDetails = Account();
    accountDetails = Account.fromJson(accountData);
    if(accountData !=null){
      Navigator.of(context).push(
      FantasyPageRoute(
        pageBuilder: (context) => LeagueDetail(
              league,
              leagues: allLeagues,
              sportType: sportType,
              onSportChange: onSportChange,
              mapSportTypes: mapSportTypes,
              accountDetails: accountDetails,
            ),
      ),
    );
    } 
  }

  getUserAccountsData() async{
    http.Request req = http.Request(
      "GET",
      Uri.parse(
        BaseUrl().apiUrl + ApiUtil.GET_ACCOUNT_DETAILS,
      ),
    );
    return HttpManager(http.Client()).sendRequest(req).then(
      (http.Response res) {
        if (res.statusCode >= 200 && res.statusCode <= 299) {
           
             return json.decode(res.body);
           
        } else if (res.statusCode >= 400 &&
            res.statusCode <= 499 
            ) {
              return null;
                  }
      },
    );
  }


  @override
  Widget build(BuildContext context) {
    final noLeaguesMsg = leagueStatus == LeagueStatus.COMPLETED
        ? strings.get("NO_COMPLETED_MATCHES")
        : leagueStatus == LeagueStatus.LIVE
            ? strings.get("NO_RUNNING_MATCHES")
            : strings.get("NO_UPCOMING_MATCHES");

    if (statusLeagues.length > 0) {
      return ListView.builder(
        physics: ClampingScrollPhysics(),
        shrinkWrap: true,
        itemCount: statusLeagues.length,
        itemBuilder: (context, index) {
          return Container(
            child: LeagueCard(
              statusLeagues[index],
              onTimeComplete: onLeagueStatusChanged,
              onClick: (league) {
                onLeagueSelect(context, league);
              },
            ),
          );
        },
      );
    } else {
      return Container(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              noLeaguesMsg,
              textAlign: TextAlign.center,
              style: Theme.of(context).primaryTextTheme.title.copyWith(
                    color: Theme.of(context).errorColor,
                  ),
            ),
          ],
        ),
      );
    }
  }
}
