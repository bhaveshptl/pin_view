import 'package:flutter/material.dart';
import 'package:playfantasy/commonwidgets/scaffoldpage.dart';
import 'package:playfantasy/modal/account.dart';

import 'package:playfantasy/utils/stringtable.dart';

class MyAccount extends StatefulWidget {
  final Map<String, dynamic> accountData;

  MyAccount({this.accountData});

  @override
  MyAccountState createState() => MyAccountState();
}

class MyAccountState extends State<MyAccount> {
  String cookie = "";
  Account accountDetails = Account();

  @override
  void initState() {
    super.initState();
    accountDetails = Account.fromJson(widget.accountData);
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldPage(
      appBar: AppBar(
        title: Text(
          "My account".toUpperCase(),
        ),
      ),
      body: Column(
        children: <Widget>[
          Padding(
            padding: EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 0.0),
            child: Row(
              children: <Widget>[
                Text(
                  "Total balance",
                  style: TextStyle(
                    fontSize:
                        Theme.of(context).primaryTextTheme.caption.fontSize,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: <Widget>[
                Text(
                  strings.rupee +
                      " " +
                      accountDetails.totalBalance.toStringAsFixed(2),
                  style: TextStyle(
                      fontSize:
                          Theme.of(context).primaryTextTheme.display2.fontSize,
                      fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      "Deposits",
                      style: TextStyle(
                        fontSize:
                            Theme.of(context).primaryTextTheme.body1.fontSize,
                      ),
                    ),
                    Text(
                      strings.rupee +
                          " " +
                          accountDetails.depositAmount.toStringAsFixed(2),
                      style: TextStyle(
                          fontSize:
                              Theme.of(context).primaryTextTheme.title.fontSize,
                          fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    Text(
                      "Winnings",
                      style: TextStyle(
                        fontSize:
                            Theme.of(context).primaryTextTheme.body1.fontSize,
                      ),
                    ),
                    Text(
                      strings.rupee +
                          " " +
                          accountDetails.winningAmount.toStringAsFixed(2),
                      style: TextStyle(
                          fontSize:
                              Theme.of(context).primaryTextTheme.title.fontSize,
                          fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: accountDetails.unreleasedBonus >= 0
                      ? CrossAxisAlignment.center
                      : CrossAxisAlignment.end,
                  children: <Widget>[
                    Text(
                      "Bonus",
                      style: TextStyle(
                        fontSize:
                            Theme.of(context).primaryTextTheme.body1.fontSize,
                      ),
                    ),
                    Text(
                      strings.rupee +
                          " " +
                          accountDetails.bonusAmount.toStringAsFixed(2),
                      style: TextStyle(
                        fontSize:
                            Theme.of(context).primaryTextTheme.title.fontSize,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                accountDetails.unreleasedBonus >= 0
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: <Widget>[
                          Text(
                            "Locked Bonus",
                            style: TextStyle(
                              fontSize: Theme.of(context)
                                  .primaryTextTheme
                                  .body1
                                  .fontSize,
                            ),
                          ),
                          Text(
                            strings.rupee +
                                " " +
                                accountDetails.unreleasedBonus
                                    .toStringAsFixed(2),
                            style: TextStyle(
                              fontSize: Theme.of(context)
                                  .primaryTextTheme
                                  .title
                                  .fontSize,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      )
                    : Container(),
              ],
            ),
          ),
          Divider(
            height: 2.0,
            color: Colors.black54,
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 0.0),
            child: Row(
              children: <Widget>[
                Text(
                  "Recents",
                  style: TextStyle(
                    fontSize:
                        Theme.of(context).primaryTextTheme.display1.fontSize,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Row(
              children: <Widget>[
                Expanded(
                  child: ListView.builder(
                    itemCount: accountDetails.recentTransactions == null
                        ? 0
                        : accountDetails.recentTransactions.length,
                    itemBuilder: (context, index) {
                      return ListTile(
                        leading: Container(
                          width: 32.0,
                          height: 32.0,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16.0),
                            color:
                                accountDetails.recentTransactions[index].debit
                                    ? Colors.redAccent
                                    : Colors.greenAccent,
                          ),
                          child: Center(
                            child: Text(
                              accountDetails.recentTransactions[index].debit
                                  ? "-"
                                  : "+",
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: Theme.of(context)
                                    .primaryTextTheme
                                    .title
                                    .fontSize,
                              ),
                            ),
                          ),
                        ),
                        title: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: <Widget>[
                            Text(
                              accountDetails.recentTransactions[index].type
                                  .toString(),
                            ),
                            Text((accountDetails.recentTransactions[index].debit
                                    ? "-"
                                    : "+") +
                                " " +
                                strings.rupee +
                                accountDetails.recentTransactions[index].amount
                                    .toStringAsFixed(2))
                          ],
                        ),
                        subtitle:
                            Text(accountDetails.recentTransactions[index].date),
                      );
                    },
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
