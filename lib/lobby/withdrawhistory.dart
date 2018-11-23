import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:playfantasy/appconfig.dart';

import 'package:playfantasy/utils/apiutil.dart';
import 'package:playfantasy/utils/httpmanager.dart';
import 'package:playfantasy/utils/sharedprefhelper.dart';
import 'package:playfantasy/utils/stringtable.dart';

class WithdrawHistory extends StatefulWidget {
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
    if (cookie == null || cookie == "") {
      Future<dynamic> futureCookie = SharedPrefHelper.internal().getCookie();
      await futureCookie.then((value) {
        cookie = value;
      });
    }

    await http.Client().get(
      BaseUrl.apiUrl + ApiUtil.WITHDRAW_HISTORY,
      headers: {
        'Content-type': 'application/json',
        "cookie": cookie,
      },
    ).then(
      (http.Response res) {
        if (res.statusCode >= 200 && res.statusCode <= 299) {
          setState(() {
            recents = json.decode(res.body);
          });
        }
      },
    );
  }

  onCancelTransaction(Map<String, dynamic> transaction) async {
    http.Request req = http.Request(
        "POST",
        Uri.parse(BaseUrl.apiUrl +
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
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Recent withdraws"),
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
              trailing: recentWithdraw["status"] != "CANCELLED"
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
    );
  }
}
