import 'dart:convert';
import 'package:flutter_svg/svg.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_webview_plugin/flutter_webview_plugin.dart';

import 'package:playfantasy/appconfig.dart';
import 'package:playfantasy/commonwidgets/scaffoldpage.dart';
import 'package:playfantasy/deposit/initpay.dart';
import 'package:playfantasy/modal/deposit.dart';
import 'package:playfantasy/redux/actions/loader_actions.dart';
import 'package:playfantasy/utils/apiutil.dart';
import 'package:playfantasy/utils/httpmanager.dart';
import 'package:playfantasy/utils/stringtable.dart';
import 'package:playfantasy/deposit/paymentmode.dart';
import 'package:playfantasy/deposit/transactionfailed.dart';
import 'package:playfantasy/commonwidgets/fantasypageroute.dart';

class AddCash extends StatefulWidget {
  final String source;
  final Deposit depositData;
  final double prefilledAmount;

  AddCash({this.depositData, this.source, this.prefilledAmount});

  @override
  State<StatefulWidget> createState() => AddCashState();
}

class AddCashState extends State<AddCash> {
  int amount;
  String cookie = "";
  bool bShowPromoInput = false;
  double customAmountBonus = 0.0;
  Map<String, dynamic> bonusInfo;
  bool bRepeatTransaction = true;
  FlutterWebviewPlugin flutterWebviewPlugin = FlutterWebviewPlugin();
  GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  TextEditingController promoController = TextEditingController();
  TextEditingController amountController = TextEditingController();
  TextEditingController customAmountController = TextEditingController();

  static const razorpay_platform =
      const MethodChannel('com.algorin.pf.razorpay');
  static const _kFontFam = 'MyFlutterApp';
  IconData gift_1 = const IconData(0xe800, fontFamily: _kFontFam);

  @override
  void initState() {
    super.initState();
    initWebview();
    if (!widget.depositData.bAllowRepeatDeposit ||
        widget.depositData.chooseAmountData.lastPaymentArray == null ||
        widget.depositData.chooseAmountData.lastPaymentArray.length == 0) {
      bRepeatTransaction = false;
    }

    setDepositInfo();

    if (widget.prefilledAmount != null && widget.depositData != null) {
      final double amount = widget.prefilledAmount <
              widget.depositData.chooseAmountData.minAmount.toDouble()
          ? widget.depositData.chooseAmountData.minAmount.toDouble()
          : widget.prefilledAmount;
      widget.depositData.chooseAmountData.minAmount.toDouble();
      amountController.text = amount.ceil().toString();
      customAmountController.text = amount.ceil().toString();
    }

    customAmountController.addListener(() {
      int customAmount = int.parse(customAmountController.text == ""
          ? "0"
          : customAmountController.text);

      if (bonusInfo != null) {
        customAmountBonus = customAmount * bonusInfo["percentage"] / 100;
        setState(() {
          if (customAmount < bonusInfo["min"]) {
            customAmountBonus = 0.0;
          } else if (customAmountBonus > bonusInfo["max"]) {
            customAmountBonus = (bonusInfo["max"]).toDouble();
          }
        });
      }
    });

    amountController.addListener(() {
      setState(() {
        amount = amountController.text != ""
            ? double.parse(amountController.text).round()
            : 0;
      });
    });

    razorpay_platform.setMethodCallHandler(myUtilsHandler);
  }

  initWebview() {
    flutterWebviewPlugin.launch(
      BaseUrl().apiUrl + ApiUtil.COOKIE_PAGE,
      hidden: true,
    );
  }

  Future<String> _openRazorpayNative(Map<String, dynamic> payload) async {
    String value;
    try {
      value =
          await razorpay_platform.invokeMethod('_openRazorpayNative', payload);
    } catch (e) {}
    return value;
  }

  Future<dynamic> myUtilsHandler(MethodCall methodCall) async {
    switch (methodCall.method) {
      case 'onRazorPayPaymentFail':
      case 'onRazorPayPaymentSuccess':
        processSuccessResponse(json.decode(methodCall.arguments));
        break;
      default:
    }
  }

  showLoader(bool bShow) {
    AppConfig.of(context).store.dispatch(
          bShow ? LoaderShowAction() : LoaderHideAction(),
        );
  }

  processSuccessResponse(Map<String, dynamic> payload) {
    showLoader(false);
    http.Request req =
        http.Request("POST", Uri.parse(BaseUrl().apiUrl + ApiUtil.SUCCESS_PAY));
    req.body = json.encode(payload);
    return HttpManager(http.Client())
        .sendRequest(req)
        .then((http.Response res) {
      Map<String, dynamic> response = json.decode(res.body);
      if ((response["authStatus"] as String).toLowerCase() ==
              "Declined".toLowerCase() ||
          (response["authStatus"] as String).toLowerCase() ==
              "Failed".toLowerCase() ||
          (response["authStatus"] as String).toLowerCase() ==
              "Fail".toLowerCase()) {
        if (response["orderId"] == null) {
          _scaffoldKey.currentState.showSnackBar(
            SnackBar(
              content: Text(
                "Payment cancelled please retry transaction. In case your money has been deducted, please contact customer support team!",
              ),
            ),
          );
        } else {
          _showTransactionFailed(response);
        }
      } else {
        Navigator.of(context).pop(res.body);
      }
    });
  }

  setDepositInfo() async {
    // depositData = widget.depositData;
    amountController.text =
        widget.depositData.chooseAmountData.lastPaymentArray == null
            ? ""
            : (widget.depositData.chooseAmountData.lastPaymentArray[0]
                    ["amount"])
                .toString();
    amount = amountController.text != ""
        ? double.parse(amountController.text).round()
        : 0;
    bonusInfo = widget.depositData.chooseAmountData.bonusArray != null
        ? widget.depositData.chooseAmountData.bonusArray[0]
        : null;
  }

  createChooseAmountUI() {
    if (widget.depositData != null &&
        widget.depositData.chooseAmountData.isFirstDeposit) {
      return getAmountTiles();
    } else if (widget.depositData != null) {
      return getRepeatDepositUI();
    } else {
      return [Container()];
    }
  }

  getAmountTiles() {
    List<Widget> tiles = [];
    widget.depositData.chooseAmountData.amountTiles.forEach((amount) {
      tiles.add(
        Card(
          elevation: 1.0,
          clipBehavior: Clip.antiAliasWithSaveLayer,
          child: Container(
            height: 64.0,
            child: Stack(
              children: <Widget>[
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Container(
                      padding: EdgeInsets.only(left: 16.0, right: 16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          Expanded(
                            child: Row(
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
                                Row(
                                  children: <Widget>[
                                    Padding(
                                      padding: EdgeInsets.only(
                                          right: 8.0, left: 8.0),
                                      child: Icon(
                                        gift_1,
                                        color: (amount >=
                                                    widget
                                                        .depositData
                                                        .chooseAmountData
                                                        .bonusArray[0]["min"] &&
                                                amount <=
                                                    widget
                                                        .depositData
                                                        .chooseAmountData
                                                        .bonusArray[0]["max"])
                                            ? Colors.teal
                                            : Colors.red,
                                        size: 18.0,
                                      ),
                                    ),
                                    Text(
                                      (amount >=
                                                  widget
                                                      .depositData
                                                      .chooseAmountData
                                                      .bonusArray[0]["min"] &&
                                              amount <=
                                                  widget
                                                      .depositData
                                                      .chooseAmountData
                                                      .bonusArray[0]["max"]
                                          ? ("+ " +
                                              strings.rupee +
                                              getFirstDepositBonusAmount(
                                                  amount))
                                          : "No Bonus"),
                                      style: TextStyle(
                                        color: (amount >=
                                                    widget
                                                        .depositData
                                                        .chooseAmountData
                                                        .bonusArray[0]["min"] &&
                                                amount <=
                                                    widget
                                                        .depositData
                                                        .chooseAmountData
                                                        .bonusArray[0]["max"])
                                            ? Colors.teal
                                            : Colors.red,
                                      ),
                                    )
                                  ],
                                )
                              ],
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
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Container(
                    padding: EdgeInsets.only(left: 16.0, right: 16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        Expanded(
                          child: Row(
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
                              customAmountController.text != ""
                                  ? Row(
                                      children: <Widget>[
                                        Padding(
                                          padding: EdgeInsets.only(
                                              right: 8.0, left: 8.0),
                                          child: Icon(
                                            gift_1,
                                            color: customAmountBonus > 0
                                                ? Colors.teal
                                                : Colors.red,
                                            size: 18.0,
                                          ),
                                        ),
                                        Text(
                                          (customAmountBonus > 0
                                              ? ("+ " +
                                                  strings.rupee +
                                                  customAmountBonus.toString())
                                              : "No Bonus"),
                                          style: TextStyle(
                                            color: customAmountBonus > 0
                                                ? Colors.teal
                                                : Colors.red,
                                          ),
                                        )
                                      ],
                                    )
                                  : Container(),
                            ],
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

  onApplyPromo() async {
    int amount =
        amountController.text != "" ? int.parse(amountController.text) : 0;
    if (amountController.text == "") {
      _scaffoldKey.currentState.showSnackBar(
        SnackBar(
          content: Text("Please enter amount to apply promo."),
        ),
      );
    } else if (promoController.text == "") {
      _scaffoldKey.currentState.showSnackBar(
        SnackBar(
          content: Text("Please enter promo code to apply."),
        ),
      );
    } else {
      final result = await validatePromo(amount);
      if (result != null) {
        Map<String, dynamic> paymentMode = json.decode(result);
        if (paymentMode["error"] == true) {
          _scaffoldKey.currentState.showSnackBar(
            SnackBar(
              content: Text(paymentMode["msg"]),
            ),
          );
        } else {
          setState(() {
            bonusInfo = paymentMode["details"];
          });
          _scaffoldKey.currentState.showSnackBar(
            SnackBar(
              content: Text(paymentMode["message"]),
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    }
  }

  onRepeatTransaction() async {
    int amount =
        amountController.text != "" ? int.parse(amountController.text) : 0;

    if (amount < widget.depositData.chooseAmountData.minAmount ||
        amount > widget.depositData.chooseAmountData.depositLimit) {
      _scaffoldKey.currentState.showSnackBar(
        SnackBar(
          content: Text("Enter amount between Min " +
              strings.rupee +
              widget.depositData.chooseAmountData.minAmount.toString() +
              " and Max " +
              strings.rupee +
              widget.depositData.chooseAmountData.depositLimit.toString()),
        ),
      );
    } else if (promoController.text == "") {
      initRepeatDeposit();
    } else {
      final result = await validatePromo(amount);
      if (result != null) {
        Map<String, dynamic> paymentMode = json.decode(result);
        if (paymentMode["error"] == true) {
          _scaffoldKey.currentState.showSnackBar(
            SnackBar(
              content: Text(paymentMode["msg"]),
            ),
          );
        } else {
          initRepeatDeposit();
        }
      }
    }
  }

  getBonusAmount() {
    double bonusAmount = amount * bonusInfo["percentage"] / 100;
    if (amount < bonusInfo["minimum"]) {
      bonusAmount = 0;
    } else if (bonusAmount > bonusInfo["maximum"]) {
      bonusAmount = (bonusInfo["maximum"]).toDouble();
    }
    return bonusAmount;
  }

  getFirstDepositBonusAmount(int amount) {
    int minAmount = widget.depositData.chooseAmountData.bonusArray[0]["min"];
    int maxAmount = widget.depositData.chooseAmountData.bonusArray[0]["max"];
    int percentage =
        widget.depositData.chooseAmountData.bonusArray[0]["percentage"];
    double bonusAmount = amount * percentage / 100;
    if (amount < minAmount) {
      bonusAmount = 0;
    } else if (bonusAmount > maxAmount) {
      bonusAmount = maxAmount.toDouble();
    }
    return bonusAmount.toString();
  }

  getRepeatDepositUI() {
    List<Widget> rows = [
      Padding(
        padding: EdgeInsets.fromLTRB(4.0, 16.0, 4.0, 8.0),
        child: ClipRRect(
          clipBehavior: Clip.hardEdge,
          borderRadius: BorderRadius.all(Radius.circular(5.0)),
          child: Container(
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Image.network(
                    widget.depositData.bannerImage,
                  ),
                )
              ],
            ),
          ),
        ),
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
                              Text("Enter amount"),
                            ],
                          ),
                          Padding(
                            padding: EdgeInsets.symmetric(vertical: 16.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.start,
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
                                ),
                                bonusInfo == null
                                    ? Container()
                                    : Row(
                                        children: <Widget>[
                                          Padding(
                                            padding: EdgeInsets.only(
                                                left: 16.0, right: 2.0),
                                            child: Icon(
                                              gift_1,
                                              color: Colors.teal,
                                            ),
                                          ),
                                          Padding(
                                            padding: EdgeInsets.symmetric(
                                                horizontal: 2.0),
                                            child: Text(
                                              strings.rupee +
                                                  getBonusAmount()
                                                      .toStringAsFixed(2),
                                              style: TextStyle(
                                                  color: Colors.teal,
                                                  fontSize: Theme.of(context)
                                                      .primaryTextTheme
                                                      .subhead
                                                      .fontSize),
                                            ),
                                          )
                                        ],
                                      )
                              ],
                            ),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: <Widget>[
                              OutlineButton(
                                onPressed: () {
                                  setDepositAmount(widget.depositData
                                      .chooseAmountData.amountTiles[0]);
                                },
                                textColor: Theme.of(context).primaryColorDark,
                                borderSide: BorderSide(
                                  color: Theme.of(context).primaryColorDark,
                                ),
                                highlightedBorderColor:
                                    Theme.of(context).primaryColor,
                                child: Text(
                                  strings.rupee +
                                      widget.depositData.chooseAmountData
                                          .amountTiles[0]
                                          .toString(),
                                ),
                              ),
                              OutlineButton(
                                onPressed: () {
                                  setDepositAmount(widget.depositData
                                      .chooseAmountData.amountTiles[1]);
                                },
                                textColor: Theme.of(context).primaryColorDark,
                                borderSide: BorderSide(
                                  color: Theme.of(context).primaryColorDark,
                                ),
                                highlightedBorderColor:
                                    Theme.of(context).primaryColor,
                                child: Text(
                                  strings.rupee +
                                      widget.depositData.chooseAmountData
                                          .amountTiles[1]
                                          .toString(),
                                ),
                              ),
                              OutlineButton(
                                onPressed: () {
                                  setDepositAmount(widget.depositData
                                      .chooseAmountData.amountTiles[2]);
                                },
                                textColor: Theme.of(context).primaryColorDark,
                                borderSide: BorderSide(
                                  color: Theme.of(context).primaryColorDark,
                                ),
                                highlightedBorderColor:
                                    Theme.of(context).primaryColor,
                                child: Text(
                                  strings.rupee +
                                      widget.depositData.chooseAmountData
                                          .amountTiles[2]
                                          .toString(),
                                ),
                              )
                            ],
                          ),
                          Padding(
                            padding: EdgeInsets.symmetric(vertical: 4.0),
                            child: Row(
                              children: <Widget>[
                                Text("Have a promocode?"),
                                Padding(
                                  padding: EdgeInsets.only(left: 8.0),
                                  child: InkWell(
                                    customBorder: Border(
                                        bottom: BorderSide(
                                      color: Colors.black,
                                      width: 1.0,
                                    )),
                                    child: Padding(
                                      padding: EdgeInsets.all(4.0),
                                      child: Text(
                                        "Apply Now",
                                        style: Theme.of(context)
                                            .primaryTextTheme
                                            .button
                                            .copyWith(
                                              color: Colors.black87,
                                              decoration:
                                                  TextDecoration.underline,
                                              decorationColor: Colors.black,
                                            ),
                                      ),
                                    ),
                                    onTap: () {
                                      // AnalyticsManager().addEvent(
                                      //   Event(
                                      //     name: "have_promo_code",
                                      //     v1: widget
                                      //             .depositData
                                      //             .chooseAmountData
                                      //             .isFirstDeposit
                                      //         ? 1
                                      //         : 0,
                                      //     v2: amount,
                                      //     v5: !bShowPromoInput ? 0 : 1,
                                      //     s1: promoController.text,
                                      //   ),
                                      // );
                                      setState(() {
                                        promoController.text = "";
                                        bShowPromoInput = !bShowPromoInput;
                                      });
                                    },
                                  ),
                                )
                              ],
                            ),
                          ),
                          bShowPromoInput
                              ? Padding(
                                  padding:
                                      EdgeInsets.only(bottom: 8.0, top: 8.0),
                                  child: Row(
                                    children: <Widget>[
                                      Expanded(
                                        child: TextFormField(
                                          textCapitalization:
                                              TextCapitalization.characters,
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
                                            suffixIcon: FlatButton(
                                              child:
                                                  Text("Apply".toUpperCase()),
                                              onPressed: () {
                                                onApplyPromo();
                                              },
                                            ),
                                          ),
                                        ),
                                      )
                                    ],
                                  ),
                                )
                              : Container(),
                          widget.depositData.chooseAmountData
                                          .lastPaymentArray !=
                                      null &&
                                  widget.depositData.chooseAmountData
                                          .lastPaymentArray.length >
                                      0
                              ? InkWell(
                                  onTap: widget.depositData.bAllowRepeatDeposit
                                      ? () {
                                          setState(() {
                                            bRepeatTransaction =
                                                !bRepeatTransaction;
                                          });
                                        }
                                      : null,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    children: <Widget>[
                                      Checkbox(
                                        value: bRepeatTransaction,
                                        onChanged: widget
                                                .depositData.bAllowRepeatDeposit
                                            ? (bool checked) {
                                                setState(() {
                                                  bRepeatTransaction = checked;
                                                });
                                              }
                                            : null,
                                      ),
                                      Text(
                                        "Proceed with ",
                                      ),
                                      Text(
                                        widget.depositData.chooseAmountData
                                            .lastPaymentArray[0]["label"]
                                            .toString(),
                                      ),
                                      Padding(
                                        padding: EdgeInsets.only(left: 8.0),
                                        child: SvgPicture.network(
                                          widget.depositData.chooseAmountData
                                              .lastPaymentArray[0]["logoUrl"],
                                          width: 24.0,
                                        ),
                                      ),
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
      Padding(
        padding: EdgeInsets.fromLTRB(4.0, 16.0, 4.0, 4.0),
        child: Row(
          children: <Widget>[
            Expanded(
              child: RaisedButton(
                onPressed: () {
                  if (bRepeatTransaction) {
                    onRepeatTransaction();
                  } else {
                    onProceed();
                  }
                },
                textColor: Colors.white70,
                color: Theme.of(context).primaryColorDark,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Text("DEPOSIT "),
                    amountController.text != ""
                        ? Padding(
                            padding: EdgeInsets.only(left: 4.0),
                            child: Text(
                              strings.rupee + amount.toString(),
                              style: TextStyle(color: Colors.white),
                            ),
                          )
                        : Container(),
                  ],
                ),
              ),
            )
          ],
        ),
      ),
      Padding(
        padding: EdgeInsets.only(top: 16.0),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: <Widget>[
              Container(
                child: Image.asset("images/pci.png"),
                height: 48.0,
              ),
              Container(
                child: Image.asset("images/paytm.png"),
                height: 48.0,
              ),
              Container(
                child: Image.asset("images/visa.png"),
                height: 48.0,
              ),
              Container(
                child: Image.asset("images/master.png"),
                height: 48.0,
              ),
              Container(
                child: Image.asset("images/amex.png"),
                height: 48.0,
              ),
              Container(
                child: Image.asset("images/cashfree.png"),
                height: 48.0,
              ),
            ],
          ),
        ),
      )
    ];

    return rows;
  }

  onProceed({int amount}) async {
    // AnalyticsManager().addEvent(
    //   Event(
    //     name: "deposit_tile",
    //     v1: widget.depositData.chooseAmountData.isFirstDeposit ? 1 : 0,
    //     v2: amount,
    //     s1: promoController.text,
    //   ),
    // );
    if ((widget.depositData.chooseAmountData.isFirstDeposit && amount == 0) ||
        (!widget.depositData.chooseAmountData.isFirstDeposit &&
            amountController.text == "")) {
      _scaffoldKey.currentState.showSnackBar(
        SnackBar(
          content: Text("Please enter valid amount to deposit."),
        ),
      );
    } else {
      if (amountController.text.indexOf(".") != -1) {
        _scaffoldKey.currentState.showSnackBar(
          SnackBar(
            content: Text("Please enter amount without decimal point"),
          ),
        );
      } else {
        amount = amount == null ? int.parse(amountController.text) : amount;
        if (amount < widget.depositData.chooseAmountData.minAmount ||
            amount > widget.depositData.chooseAmountData.depositLimit) {
          _scaffoldKey.currentState.showSnackBar(
            SnackBar(
              content: Text("Enter amount between Min " +
                  strings.rupee +
                  widget.depositData.chooseAmountData.minAmount.toString() +
                  " and Max " +
                  strings.rupee +
                  widget.depositData.chooseAmountData.depositLimit.toString()),
            ),
          );
        } else {
          final result = await proceedToPaymentMode(amount);
          if (result != null) {
            initPayment(json.decode(result), amount);
          }
        }
      }
    }
  }

  proceedToPaymentMode(int amount) async {
    showLoader(true);

    http.Request req = http.Request(
        "POST", Uri.parse(BaseUrl().apiUrl + ApiUtil.PAYMENT_MODE));
    req.body = json.encode({
      "amount": amount,
      "channelId": AppConfig.of(context).channelId,
      "promoCode": promoController.text,
      "transaction_amount_in_paise": amount * 100,
    });
    return HttpManager(http.Client()).sendRequest(req).then(
      (http.Response res) {
        showLoader(false);
        if (res.statusCode >= 200 && res.statusCode <= 299) {
          return res.body;
        }
      },
    );
  }

  validatePromo(int amount) async {
    http.Request req = http.Request(
        "POST", Uri.parse(BaseUrl().apiUrl + ApiUtil.VALIDATE_PROMO));
    req.body = json.encode({
      "amount": amount,
      "channelId": AppConfig.of(context).channelId,
      "promoCode": promoController.text,
      "transaction_amount_in_paise": amount * 100,
    });
    return HttpManager(http.Client()).sendRequest(req).then(
      (http.Response res) {
        if (res.statusCode >= 200 && res.statusCode <= 299) {
          return res.body;
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
      flutterWebviewPlugin.close();
      final result = await Navigator.of(context).push(
        FantasyPageRoute(
          pageBuilder: (context) => ChoosePaymentMode(
                amount: amount,
                paymentMode: paymentMode,
                promoCode: widget.depositData.chooseAmountData.isFirstDeposit
                    ? widget.depositData.chooseAmountData.bonusArray[0]["code"]
                    : promoController.text,
              ),
        ),
      );
      if (result != null) {
        Navigator.of(context).pop(result);
      } else {
        initWebview();
        razorpay_platform.setMethodCallHandler(myUtilsHandler);
      }
    }
  }

  initRepeatDeposit() {
    if (amountController.text == "") {
      _scaffoldKey.currentState.showSnackBar(
        SnackBar(
          content: Text("Please enter amount to repeat deposit"),
        ),
      );
    } else {
      int amount = int.parse(amountController.text);
      paySecurely(amount);
    }
  }

  paySecurely(int amount) async {
    String querParamString = '';
    Map<String, dynamic> userDetails = widget.depositData.refreshData;
    Map<String, dynamic> paymentModeDetails =
        widget.depositData.chooseAmountData.lastPaymentArray[0];
    Map<String, dynamic> payload = {
      "channelId": AppConfig.of(context).channelId,
      "orderId": null,
      "promoCode": promoController.text,
      "depositAmount": amount,
      "paymentOption": paymentModeDetails["paymentOption"],
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
      "isFirstDeposit": false,
      "native": true,
    };

    int index = 0;
    payload.forEach((key, value) {
      if (index != 0) {
        querParamString += '&';
      }
      querParamString += key + '=' + value.toString();
      index++;
    });

    showLoader(true);

    if (paymentModeDetails["isSeamless"]) {
      http.Request req = http.Request(
          "GET",
          Uri.parse(BaseUrl().apiUrl +
              ApiUtil.INIT_PAYMENT_SEAMLESS +
              querParamString));
      return HttpManager(http.Client())
          .sendRequest(req)
          .then((http.Response res) {
        Map<String, dynamic> response = json.decode(res.body);
        _openRazorpayNative({
          "name": AppConfig.of(context).appName,
          "email": payload["email"],
          "phone": payload["phone"],
          "amount": (payload["depositAmount"] * 100).toString(),
          "orderId": response["action"]["value"],
          "method": (payload["paymentType"] as String).indexOf("CARD") == -1
              ? payload["paymentType"].toLowerCase()
              : "card",
          "image": AppConfig.of(context).channelId == '3'
              ? "https://dyrnmb8cbz1ud.cloudfront.net/images/logo.png"
              : (AppConfig.of(context).channelId == '9'
                  ? "https://dyrnmb8cbz1ud.cloudfront.net/images/icons/smart11_logo.png"
                  : "https://dyrnmb8cbz1ud.cloudfront.net/images/icons/howzat_logo.png")
        });
      });
    } else {
      startInitPayment(
          BaseUrl().apiUrl + ApiUtil.INIT_PAYMENT + querParamString);
    }
  }

  startInitPayment(String url) async {
    final result = await Navigator.of(context).push(
      FantasyPageRoute(
        pageBuilder: (context) => InitPay(
              url: url,
            ),
      ),
    );

    showLoader(false);

    if (result != null) {
      Map<String, dynamic> response = json.decode(result);
      if ((response["authStatus"] as String).toLowerCase() ==
              "Declined".toLowerCase() ||
          (response["authStatus"] as String).toLowerCase() ==
              "Failed".toLowerCase() ||
          (response["authStatus"] as String).toLowerCase() ==
              "Fail".toLowerCase()) {
        if (response["orderId"] == null) {
          _scaffoldKey.currentState.showSnackBar(
            SnackBar(
              content: Text(
                "Payment cancelled please retry transaction. In case your money has been deducted, please contact customer support team!",
              ),
            ),
          );
        } else {
          _showTransactionFailed(response);
        }
      } else {
        Navigator.of(context).pop(result);
      }
    }
  }

  _showTransactionFailed(Map<String, dynamic> transactionResult) async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return TransactionFailed(transactionResult, () {
          Navigator.of(context).pop();
        }, () {
          Navigator.of(context).pop();
          Navigator.of(context).pop(json.encode(transactionResult));
        });
      },
    );
  }

  setDepositAmount(int amount) {
    amountController.text = amount.toString();
  }

  onCustomAddAmount() {
    if (customAmountController.text.indexOf(".") != -1) {
      _scaffoldKey.currentState.showSnackBar(
        SnackBar(
          content: Text("Please enter amount without decimal point"),
        ),
      );
    } else {
      int customAmount = int.parse(customAmountController.text == ""
          ? "0"
          : customAmountController.text);

      onProceed(amount: customAmount);
    }
  }

  @override
  void dispose() {
    if (flutterWebviewPlugin != null) {
      flutterWebviewPlugin.close();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldPage(
      scaffoldKey: _scaffoldKey,
      appBar: AppBar(
        title: Text(
          strings.get("ADD_CASH").toUpperCase(),
        ),
      ),
      body: Container(
        decoration: AppConfig.of(context).showBackground
            ? BoxDecoration(
                image: DecorationImage(
                  image: AssetImage("images/background.png"),
                  repeat: ImageRepeat.repeat,
                ),
              )
            : null,
        child: SingleChildScrollView(
          child: Column(
            children: <Widget>[
              Container(
                color: Colors.black26,
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
                            (widget.depositData == null
                                ? "0.0"
                                : (widget.depositData.chooseAmountData.balance
                                            .deposited +
                                        widget.depositData.chooseAmountData
                                            .balance.nonWithdrawable +
                                        widget.depositData.chooseAmountData
                                            .balance.withdrawable)
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
        ),
      ),
    );
  }
}
