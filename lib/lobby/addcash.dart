import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:playfantasy/appconfig.dart';
import 'package:playfantasy/lobby/initpay.dart';
import 'package:playfantasy/modal/analytics.dart';

import 'package:playfantasy/modal/deposit.dart';
import 'package:playfantasy/utils/analytics.dart';
import 'package:playfantasy/utils/apiutil.dart';
import 'package:playfantasy/lobby/paymentmode.dart';
import 'package:playfantasy/utils/httpmanager.dart';
import 'package:playfantasy/utils/stringtable.dart';

bool bShowAppBar = true;
Map<String, String> depositResponse;

class AddCash extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => AddCashState();
}

class AddCashState extends State<AddCash> {
  String cookie = "";
  Deposit depositData;
  int customAmountBonus = 0;
  bool bShowPromoInput = false;
  GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  TextEditingController promoController = TextEditingController();
  TextEditingController amountController = TextEditingController();
  TextEditingController customAmountController = TextEditingController();
  TextEditingController repeatAmountController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _getDepositInfo();
    AnalyticsManager().addEvent(Event());
    customAmountController.addListener(() {
      int customAmount = int.parse(customAmountController.text == ""
          ? "0"
          : customAmountController.text);
      setState(() {
        if (customAmount >= 100 && customAmount <= 1000) {
          customAmountBonus = customAmount;
        } else if (customAmount > 1000) {
          customAmountBonus = 1000;
        } else {
          customAmountBonus = 0;
        }
      });
    });
  }

  _getDepositInfo() async {
    http.Request req = http.Request(
      "GET",
      Uri.parse(
        BaseUrl.apiUrl + ApiUtil.DEPOSIT_INFO,
      ),
    );
    HttpManager(http.Client()).sendRequest(req).then(
      (http.Response res) {
        if (res.statusCode >= 200 && res.statusCode <= 299) {
          setState(() {
            depositData = Deposit.fromJson(json.decode(res.body));
            repeatAmountController.text =
                depositData.chooseAmountData.lastPaymentArray == null
                    ? ""
                    : (depositData.chooseAmountData.lastPaymentArray[0]
                            ["amount"])
                        .toString();
          });
        }
      },
    );
  }

  createChooseAmountUI() {
    if (depositData != null && depositData.chooseAmountData.isFirstDeposit) {
      return getAmountTiles();
    } else if (depositData != null) {
      return getRepeatDepositUI();
    } else {
      return [Container()];
    }
  }

  getAmountTiles() {
    List<Widget> tiles = [];
    depositData.chooseAmountData.amountTiles.forEach((amount) {
      tiles.add(
        Card(
          elevation: 1.0,
          clipBehavior: Clip.antiAliasWithSaveLayer,
          child: Container(
            height: 60.0,
            child: Stack(
              children: <Widget>[
                Banner(
                  message: amount >=
                              depositData.chooseAmountData.bonusArray[0]
                                  ["min"] &&
                          amount <=
                              depositData.chooseAmountData.bonusArray[0]["max"]
                      ? "BONUS " + strings.rupee + getBonusAmount(amount)
                      : "NO BONUS",
                  location: BannerLocation.topStart,
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Container(
                      padding: EdgeInsets.only(left: 50.0, right: 16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          Text(
                            strings.rupee + amount.toString(),
                            style: TextStyle(
                              fontSize: Theme.of(context)
                                  .primaryTextTheme
                                  .display1
                                  .fontSize,
                            ),
                          ),
                          OutlineButton(
                            borderSide: BorderSide(
                              color: Theme.of(context).primaryColorDark,
                            ),
                            textColor: Theme.of(context).primaryColorDark,
                            child: Text("Add now"),
                            onPressed: () {
                              onProceed(amount: amount);
                            },
                          )
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    });

    tiles.add(
      Card(
        elevation: 1.0,
        clipBehavior: Clip.antiAliasWithSaveLayer,
        child: Container(
          height: 60.0,
          child: Stack(
            children: <Widget>[
              Banner(
                message: customAmountBonus >=
                            depositData.chooseAmountData.bonusArray[0]["min"] &&
                        customAmountBonus <=
                            depositData.chooseAmountData.bonusArray[0]["max"]
                    ? "BONUS " +
                        strings.rupee +
                        getBonusAmount(customAmountBonus)
                    : "NO BONUS",
                location: BannerLocation.topStart,
              ),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Container(
                    padding: EdgeInsets.only(left: 50.0, right: 16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        Container(
                          width: 100.0,
                          child: TextFormField(
                            controller: customAmountController,
                            decoration: InputDecoration(
                              contentPadding: EdgeInsets.all(8.0),
                              border: OutlineInputBorder(
                                borderSide: BorderSide(
                                  color: Colors.black38,
                                ),
                              ),
                            ),
                            keyboardType: TextInputType.number,
                            style: TextStyle(
                              fontSize: Theme.of(context)
                                  .primaryTextTheme
                                  .title
                                  .fontSize,
                              color: Colors.black45,
                            ),
                          ),
                        ),
                        OutlineButton(
                          borderSide: BorderSide(
                            color: Theme.of(context).primaryColorDark,
                          ),
                          textColor: Theme.of(context).primaryColorDark,
                          child: Text("Add now"),
                          onPressed: () {
                            onCustomAddAmount();
                          },
                        )
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    return tiles;
  }

  getBonusAmount(int amount) {
    int minAmount = depositData.chooseAmountData.bonusArray[0]["min"];
    int maxAmount = depositData.chooseAmountData.bonusArray[0]["max"];
    int percentage = depositData.chooseAmountData.bonusArray[0]["percentage"];
    return (amount >= minAmount && amount <= maxAmount
            ? (amount * percentage ~/ 100)
            : 0)
        .toString();
  }

  getRepeatDepositUI() {
    List<Widget> rows = [
      Row(
        children: <Widget>[
          Expanded(
            child: Card(
              elevation: 3.0,
              child: Padding(
                padding: EdgeInsets.all(8.0),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: Column(
                        children: <Widget>[
                          Row(
                            children: <Widget>[
                              Text("Enter amount"),
                            ],
                          ),
                          Padding(
                            padding: EdgeInsets.symmetric(vertical: 16.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              mainAxisSize: MainAxisSize.max,
                              children: <Widget>[
                                Container(
                                  width: 150.0,
                                  child: TextFormField(
                                    controller: amountController,
                                    keyboardType: TextInputType.number,
                                    decoration: InputDecoration(
                                      labelText: strings.get("AMOUNT"),
                                      contentPadding: EdgeInsets.all(8.0),
                                      border: OutlineInputBorder(
                                        borderSide: BorderSide(
                                          color: Colors.black38,
                                        ),
                                      ),
                                      prefix: Padding(
                                        padding: EdgeInsets.only(top: 4.0),
                                        child: Text(
                                          strings.rupee,
                                        ),
                                      ),
                                    ),
                                  ),
                                )
                              ],
                            ),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: <Widget>[
                              RaisedButton(
                                onPressed: () {
                                  setDepositAmount(depositData
                                      .chooseAmountData.amountTiles[0]);
                                },
                                textColor: Colors.white70,
                                color: Theme.of(context).primaryColorDark,
                                child: Text(
                                  strings.rupee +
                                      depositData
                                          .chooseAmountData.amountTiles[0]
                                          .toString(),
                                ),
                              ),
                              RaisedButton(
                                onPressed: () {
                                  setDepositAmount(depositData
                                      .chooseAmountData.amountTiles[1]);
                                },
                                textColor: Colors.white70,
                                color: Theme.of(context).primaryColorDark,
                                child: Text(
                                  strings.rupee +
                                      depositData
                                          .chooseAmountData.amountTiles[1]
                                          .toString(),
                                ),
                              ),
                              RaisedButton(
                                onPressed: () {
                                  setDepositAmount(depositData
                                      .chooseAmountData.amountTiles[2]);
                                },
                                textColor: Colors.white70,
                                color: Theme.of(context).primaryColorDark,
                                child: Text(
                                  strings.rupee +
                                      depositData
                                          .chooseAmountData.amountTiles[2]
                                          .toString(),
                                ),
                              )
                            ],
                          ),
                          Row(
                            children: <Widget>[
                              Container(
                                height: 24.0,
                                child: FlatButton(
                                  padding: EdgeInsets.all(0.0),
                                  child: Text("Have a promocode?"),
                                  onPressed: () {
                                    setState(() {
                                      promoController.text = "";
                                      bShowPromoInput = !bShowPromoInput;
                                    });
                                  },
                                ),
                              )
                            ],
                          ),
                          bShowPromoInput
                              ? Padding(
                                  padding: EdgeInsets.only(bottom: 8.0),
                                  child: Row(
                                    children: <Widget>[
                                      Expanded(
                                        child: TextFormField(
                                          controller: promoController,
                                          keyboardType: TextInputType.text,
                                          decoration: InputDecoration(
                                            labelText: "Promocode",
                                            contentPadding: EdgeInsets.all(8.0),
                                            border: OutlineInputBorder(
                                              borderSide: BorderSide(
                                                color: Colors.black38,
                                              ),
                                            ),
                                          ),
                                        ),
                                      )
                                    ],
                                  ),
                                )
                              : Container(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      Row(
        children: <Widget>[
          Expanded(
            child: Card(
              elevation: 3.0,
              child: Padding(
                padding: EdgeInsets.all(8.0),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: Column(
                        children: <Widget>[
                          Row(
                            children: <Widget>[
                              Text("Last transaction"),
                            ],
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            mainAxisSize: MainAxisSize.max,
                            children: <Widget>[
                              Container(
                                width: 150.0,
                                child: TextFormField(
                                  controller: repeatAmountController,
                                  keyboardType: TextInputType.number,
                                  decoration: InputDecoration(
                                    labelText: strings.get("AMOUNT"),
                                    contentPadding: EdgeInsets.all(8.0),
                                    border: OutlineInputBorder(
                                      borderSide: BorderSide(
                                        color: Colors.black38,
                                      ),
                                    ),
                                    prefix: Padding(
                                      padding: EdgeInsets.only(top: 4.0),
                                      child: Text(
                                        strings.rupee,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              RaisedButton(
                                onPressed: () {
                                  initRepeatDeposit();
                                },
                                textColor: Colors.white54,
                                color: Theme.of(context).primaryColorDark,
                                child: Text("REPEAT"),
                              )
                            ],
                          ),
                          depositData.chooseAmountData.lastPaymentArray
                                      .length <=
                                  0
                              ? Container()
                              : Row(
                                  children: <Widget>[
                                    Text(
                                      (depositData.chooseAmountData
                                          .lastPaymentArray[0]["label"]
                                          .toString()
                                          .toUpperCase()),
                                    ),
                                  ],
                                )
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      Container(
        padding: EdgeInsets.fromLTRB(4.0, 16.0, 4.0, 8.0),
        child: Row(
          children: <Widget>[
            Expanded(
              child: Image.network(
                depositData.bannerImage,
              ),
            )
          ],
        ),
      ),
      Padding(
        padding: EdgeInsets.all(4.0),
        child: Row(
          children: <Widget>[
            Expanded(
              child: RaisedButton(
                onPressed: () {
                  onProceed();
                },
                textColor: Colors.white70,
                color: Theme.of(context).primaryColorDark,
                child: Text("PROCEED"),
              ),
            )
          ],
        ),
      ),
    ];

    return rows;
  }

  onProceed({int amount}) async {
    if ((depositData.chooseAmountData.isFirstDeposit && amount == 0) ||
        (!depositData.chooseAmountData.isFirstDeposit &&
            amountController.text == "")) {
      _scaffoldKey.currentState.showSnackBar(
        SnackBar(
          content: Text("Please enter valid amount to deposit."),
        ),
      );
    } else {
      amount = amount == null ? int.parse(amountController.text) : amount;
      if (amount < depositData.chooseAmountData.minAmount) {
        _scaffoldKey.currentState.showSnackBar(
          SnackBar(
            content: Text("Please enter more than " +
                depositData.chooseAmountData.minAmount.toString() +
                " to deposit."),
          ),
        );
      } else {
        validatePromo(amount);
      }
    }
  }

  validatePromo(int amount) async {
    http.Request req =
        http.Request("POST", Uri.parse(BaseUrl.apiUrl + ApiUtil.PAYMENT_MODE));
    req.body = json.encode({
      "amount": amount,
      "channelId": AppConfig.of(context).channelId,
      "promoCode": promoController.text,
      "transaction_amount_in_paise": amount * 100,
    });
    await HttpManager(http.Client()).sendRequest(req).then(
      (http.Response res) {
        if (res.statusCode >= 200 && res.statusCode <= 299) {
          initPayment(json.decode(res.body), amount);
        }
      },
    );
  }

  initPayment(Map<String, dynamic> paymentMode, int amount) async {
    if (paymentMode["error"] == true) {
      _scaffoldKey.currentState.showSnackBar(
        SnackBar(
          content: Text(paymentMode["msg"]),
        ),
      );
    } else {
      final result = await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => ChoosePaymentMode(
                amount: amount,
                paymentMode: paymentMode,
                promoCode: depositData.chooseAmountData.isFirstDeposit
                    ? depositData.chooseAmountData.bonusArray[0]["code"]
                    : promoController.text,
              ),
        ),
      );
      if (result != null) {
        Navigator.of(context).pop(result);
      }
    }
  }

  initRepeatDeposit() {
    if (repeatAmountController.text == "") {
      _scaffoldKey.currentState.showSnackBar(
        SnackBar(
          content: Text("Please enter amount to repeat deposit"),
        ),
      );
    } else {
      int amount = int.parse(repeatAmountController.text);
      paySecurely(amount);
    }
  }

  paySecurely(int amount) async {
    String querParamString = '';
    Map<String, dynamic> userDetails = depositData.refreshData;
    Map<String, dynamic> paymentModeDetails =
        depositData.chooseAmountData.lastPaymentArray[0];
    Map<String, dynamic> payload = {
      "channelId": AppConfig.of(context).channelId,
      "orderId": null,
      "promoCode": "",
      "depositAmount": amount,
      "paymentOption": paymentModeDetails["name"],
      "paymentType": paymentModeDetails["paymentType"],
      "gateway": paymentModeDetails["gateway"],
      "gatewayName": paymentModeDetails["gateway"],
      "gatewayId": paymentModeDetails["gatewayId"],
      "accessToken": paymentModeDetails["accessToken"],
      "requestType": paymentModeDetails["requestType"],
      "modeOptionId": paymentModeDetails["modeOptionId"],
      "bankCode": paymentModeDetails["processorBankCode"],
      "detailRequired": paymentModeDetails["detailRequired"],
      "processorBankCode": paymentModeDetails["processorBankCode"],
      "cvv": paymentModeDetails["cvv"],
      "label": paymentModeDetails["label"],
      "expireYear": paymentModeDetails["expireYear"],
      "expireMonth": paymentModeDetails["expireMonth"],
      "nameOnTheCard": paymentModeDetails["nameOnTheCard"],
      "saveCardDetails": paymentModeDetails["saveCardDetails"],
      "email": userDetails["email"],
      "phone": userDetails["mobile"],
      "last_name": userDetails["last_name"],
      "first_name": userDetails["first_name"],
      "updateEmail": false,
      "updateMobile": false,
      "updateName": false,
      "isFirstDeposit": false
    };

    int index = 0;
    payload.forEach((key, value) {
      if (index != 0) {
        querParamString += '&';
      }
      querParamString += key + '=' + value.toString();
      index++;
    });

    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => InitPay(
              url: BaseUrl.apiUrl + ApiUtil.INIT_PAYMENT + querParamString,
            ),
      ),
    );

    if (result != null) {
      Navigator.of(context).pop(result);
    }
  }

  setDepositAmount(int amount) {
    amountController.text = amount.toString();
  }

  onCustomAddAmount() {
    int customAmount = int.parse(
        customAmountController.text == "" ? "0" : customAmountController.text);
    if (customAmount > depositData.chooseAmountData.depositLimit) {
      _scaffoldKey.currentState.showSnackBar(SnackBar(
        content: Text("You can not deposit more than " +
            strings.rupee +
            depositData.chooseAmountData.depositLimit.toString() +
            " in single transaction."),
      ));
    } else if (customAmount < depositData.chooseAmountData.minAmount) {
      _scaffoldKey.currentState.showSnackBar(SnackBar(
        content: Text("Minimum  " +
            strings.rupee +
            depositData.chooseAmountData.minAmount.toString() +
            " should be deposit in a transaction."),
      ));
    } else {
      onProceed(amount: customAmount);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        key: _scaffoldKey,
        appBar: AppBar(
          title: Text(
            strings.get("ADD_CASH"),
          ),
        ),
        body: SingleChildScrollView(
          child: Column(
            children: <Widget>[
              Container(
                color: Colors.black12,
                padding: EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Text(
                      "Account balance",
                      style: TextStyle(
                        color: Colors.black87,
                        fontSize:
                            Theme.of(context).primaryTextTheme.subhead.fontSize,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.only(left: 4.0),
                      child: Text(
                        strings.rupee +
                            (depositData == null
                                ? "0.0"
                                : (depositData.chooseAmountData.balance
                                            .deposited +
                                        depositData.chooseAmountData.balance
                                            .nonWithdrawable +
                                        depositData.chooseAmountData.balance
                                            .withdrawable)
                                    .toStringAsFixed(2)),
                      ),
                    )
                  ],
                ),
              ),
              Column(
                children: createChooseAmountUI(),
              )
            ],
          ),
        ));
  }

  setAppBarVisibility(bool bShow) {
    setState(() {
      bShowAppBar = bShow;
    });
  }
}
