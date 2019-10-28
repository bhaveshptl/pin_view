import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:playfantasy/action_utils/action_util.dart';
import 'package:playfantasy/commonwidgets/scaffoldpage.dart';

import 'package:playfantasy/utils/apiutil.dart';
import 'package:playfantasy/utils/httpmanager.dart';
import 'package:playfantasy/utils/stringtable.dart';

class WithdrawHistory extends StatefulWidget {
  final bool onBackPressedNavigateToLobby;
  WithdrawHistory(
    {
        this.onBackPressedNavigateToLobby
    }
  );
  @override
  WithdrawHistoryState createState() => WithdrawHistoryState();
}

class WithdrawHistoryState extends State<WithdrawHistory> {
  String cookie = "";
  List<dynamic> recents = [];

  @override
  void initState() {
    super.initState();
    getRecentWithdraws();
  }

  getRecentWithdraws() async {
    http.Request req = http.Request(
      "GET",
      Uri.parse(
        BaseUrl().apiUrl + ApiUtil.WITHDRAW_HISTORY,
      ),
    );
    return HttpManager(http.Client()).sendRequest(req).then(
      (http.Response res) {
        if (res.statusCode >= 200 && res.statusCode <= 299) {
          setState(() {
            recents = json.decode(res.body);
          });
        }
      },
    ).whenComplete(() {
      ActionUtil().showLoader(context, false);
    });
  }

  onCancelTransaction(Map<String, dynamic> transaction) async {
    http.Request req = http.Request(
        "POST",
        Uri.parse(BaseUrl().apiUrl +
            ApiUtil.CANCEL_WITHDRAW +
            transaction["id"].toString()));
    req.body = json.encode({});
    await HttpManager(http.Client()).sendRequest(req).then(
      (http.Response res) {
        if (res.statusCode >= 200 && res.statusCode <= 299) {
          Map<String, dynamic> cancelledTransaction = json.decode(res.body);
          recents.forEach((transaction) {
            if (transaction["id"] == cancelledTransaction["id"]) {
              setState(() {
                transaction["status"] = cancelledTransaction["status"];
              });
            }
          });
        }
      },
    ).whenComplete(() {
      ActionUtil().showLoader(context, false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: (){
        if(widget.onBackPressedNavigateToLobby){
          Navigator.of(context).popUntil((r) => r.isFirst);
          return Future.value(true);
        }else{
           Navigator.of(context).pop();  
        }
      },
      child: ScaffoldPage(
        appBar: AppBar(
          title: Text(
            "Recent withdrawals".toUpperCase(),
          ),
        ),
        body: ListView(
          children: recents.map((recentWithdraw) {
            return Padding(
              padding: EdgeInsets.symmetric(vertical: 8.0),
              child: ListTile(
                onTap: () {},
                leading: CircleAvatar(
                  maxRadius: 28.0,
                  backgroundColor: Colors.blue.shade100,
                  child: Text(
                    strings.rupee + recentWithdraw["amount"].toString(),
                    style: TextStyle(
                      color: Colors.blue.shade900.withOpacity(0.6),
                      // fontWeight: FontWeight.bold,
                      // fontSize: Theme.of(context).primaryTextTheme.subhead.fontSize,
                    ),
                  ),
                ),
                title: Text(recentWithdraw["status"]),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(recentWithdraw["createdDate"]),
                    Text("#" + recentWithdraw["id"].toString()),
                  ],
                ),
                trailing: recentWithdraw["status"] == "REQUESTED"
                    ? RaisedButton(
                        onPressed: () {
                          onCancelTransaction(recentWithdraw);
                        },
                        child: Text(
                          strings.get("CANCEL").toUpperCase(),
                        ),
                        textColor: Colors.white70,
                        color: Theme.of(context).primaryColorDark,
                      )
                    : Container(
                        width: 0.0,
                      ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
