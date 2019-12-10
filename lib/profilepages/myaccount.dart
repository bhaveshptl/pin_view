import 'package:flutter/material.dart';
import 'package:playfantasy/appconfig.dart';
import 'package:playfantasy/commonwidgets/color_button.dart';
import 'package:playfantasy/commonwidgets/leadingbutton.dart';
import 'package:playfantasy/commonwidgets/routelauncher.dart';
import 'package:playfantasy/commonwidgets/scaffoldpage.dart';
import 'package:playfantasy/modal/account.dart';
import 'package:playfantasy/redux/actions/loader_actions.dart';
import 'package:playfantasy/profilepages/verification.dart';
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
  GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    accountDetails = Account.fromJson(widget.accountData);
  }

  _launchAddCash(
      {String source, String promoCode, double prefilledAmount}) async {
    showLoader(true);
    routeLauncher.launchAddCash(
      context,
      source: source,
      promoCode: promoCode,
      prefilledAmount: prefilledAmount,
      onComplete: () {
        showLoader(false);
      },
    );
  }

  getAbsoluteAmount(double amount) {
    String amountInString = amount.toStringAsFixed(2);
    try {
      var decimalAmount = amountInString.split('.');
      if (decimalAmount[1] == "00") {
        amountInString = amount.toStringAsFixed(0);
      }
    } catch (e) {}
    return amountInString;
  }

  showLoader(bool bShow) {
    AppConfig.of(scaffoldKey.currentContext)
        .store
        .dispatch(bShow ? LoaderShowAction() : LoaderHideAction());
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldPage(
      scaffoldKey: scaffoldKey,
      appBar: AppBar(
        leading: LeadingButton(),
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
                      getAbsoluteAmount(accountDetails.totalBalance),
                  style: TextStyle(
                      fontSize:
                          Theme.of(context).primaryTextTheme.display2.fontSize,
                      fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.all(16.0),
            color: Colors.white,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Expanded(
                    child: Column(
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
                          getAbsoluteAmount(accountDetails.depositAmount),
                      style: TextStyle(
                          fontSize: Theme.of(context)
                              .primaryTextTheme
                              .subhead
                              .fontSize,
                          fontWeight: FontWeight.bold),
                    ),
                    InkWell(
                      child: Container(
                        padding: EdgeInsets.all(12),
                        margin: EdgeInsets.all(8),
                        color: Colors.green,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            Padding(
                              padding: EdgeInsets.only(right: 0.0),
                              child: Text(
                                "Add Cash",
                                style: Theme.of(context)
                                    .primaryTextTheme
                                    .subhead
                                    .copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w400,
                                    ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      onTap: () {
                        _launchAddCash(
                            source: "transaction_history", promoCode: "");
                      },
                    ),
                  ],
                )),
                Expanded(
                    child: Column(
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
                          getAbsoluteAmount(accountDetails.winningAmount),
                      style: TextStyle(
                          fontSize: Theme.of(context)
                              .primaryTextTheme
                              .subhead
                              .fontSize,
                          fontWeight: FontWeight.bold),
                    ),
                    InkWell(
                      child: Container(
                        padding: EdgeInsets.all(12),
                        margin: EdgeInsets.all(8),
                        color: Color.fromRGBO(245, 131, 18, 1),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            Padding(
                              padding: EdgeInsets.only(right: 0.0),
                              child: Text(
                                "Withdraw",
                                style: Theme.of(context)
                                    .primaryTextTheme
                                    .subhead
                                    .copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w400,
                                    ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      //elevation: 0.0,
                      onTap: () {
                        routeLauncher.launchWithdraw(scaffoldKey,
                            onComplete: () {
                          showLoader(false);
                        });
                      },
                    ),
                  ],
                )),
                Expanded(
                    child: Column(
                  children: <Widget>[
                    Column(
                      children: <Widget>[
                        Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: <Widget>[
                              Column(
                                crossAxisAlignment:
                                    accountDetails.unreleasedBonus >= 0
                                        ? CrossAxisAlignment.center
                                        : CrossAxisAlignment.end,
                                children: <Widget>[
                                  Text(
                                    "Bonus",
                                    style: TextStyle(
                                      fontSize: Theme.of(context)
                                          .primaryTextTheme
                                          .body1
                                          .fontSize,
                                    ),
                                  ),
                                  Text(
                                    strings.rupee +
                                        getAbsoluteAmount(
                                            accountDetails.bonusAmount),
                                    style: TextStyle(
                                      fontSize: Theme.of(context)
                                          .primaryTextTheme
                                          .subhead
                                          .fontSize,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              accountDetails.unreleasedBonus >= 0
                                  ? Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: <Widget>[
                                        Text(
                                          "Locked",
                                          style: TextStyle(
                                            fontSize: Theme.of(context)
                                                .primaryTextTheme
                                                .body1
                                                .fontSize,
                                          ),
                                        ),
                                        Text(
                                          strings.rupee +
                                              getAbsoluteAmount(accountDetails
                                                  .unreleasedBonus),
                                          style: TextStyle(
                                            fontSize: Theme.of(context)
                                                .primaryTextTheme
                                                .subhead
                                                .fontSize,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    )
                                  : Container(),
                            ]),
                      ],
                    ),
                    InkWell(
                      child: Container(
                        padding: EdgeInsets.all(12),
                        margin: EdgeInsets.all(8),
                        color: Color.fromRGBO(40, 74, 171, 1),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            Padding(
                              padding: EdgeInsets.only(right: 0.0),
                              child: Text(
                                "Refer",
                                style: Theme.of(context)
                                    .primaryTextTheme
                                    .subhead
                                    .copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w400,
                                    ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      onTap: () {
                        routeLauncher.launchEarnCash(scaffoldKey,
                            onComplete: () {
                          showLoader(false);
                        });
                      },
                    ),
                  ],
                )),
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
                  "TRANSACTION HISTORY",
                  style: TextStyle(
                    fontSize: Theme.of(context).primaryTextTheme.title.fontSize,
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
