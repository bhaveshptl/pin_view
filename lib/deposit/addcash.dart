import 'dart:convert';
import 'package:flutter/gestures.dart';
import 'package:flutter_svg/svg.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_webview_plugin/flutter_webview_plugin.dart';
import 'dart:io';
import 'package:playfantasy/appconfig.dart';
import 'package:playfantasy/commonwidgets/color_button.dart';
import 'package:playfantasy/commonwidgets/scaffoldpage.dart';
import 'package:playfantasy/commonwidgets/textbox.dart';
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
  TapGestureRecognizer termsGesture = TapGestureRecognizer();
  FlutterWebviewPlugin flutterWebviewPlugin = FlutterWebviewPlugin();
  GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  int selectedTileindex = 0;

  TextEditingController promoController = TextEditingController();
  TextEditingController amountController = TextEditingController();
  TextEditingController customAmountController = TextEditingController();

  FocusNode _customAmountFocusNode = FocusNode();

  static const razorpay_platform =
      const MethodChannel('com.algorin.pf.razorpay');
  static const branch_io_platform =
      const MethodChannel('com.algorin.pf.branch');
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
    termsGesture.onTap = () {
      _launchStaticPage("T&C");
    };

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

    _customAmountFocusNode.addListener(() {
      if (_customAmountFocusNode.hasFocus) {
        if (selectedTileindex !=
            widget.depositData.chooseAmountData.amountTiles.length) {
          setState(() {
            selectedTileindex =
                widget.depositData.chooseAmountData.amountTiles.length;
          });
        }
      }
    });

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
    if (Platform.isIOS) {
        initRazorpayNativePlugin();  
    }
  }

  initWebview() {
    flutterWebviewPlugin.launch(
      BaseUrl().apiUrl + ApiUtil.COOKIE_PAGE,
      hidden: true,
    );
  }

  _launchStaticPage(String name) {
    String url = "";
    String title = "";
    switch (name.toUpperCase()) {
      case "T&C":
        title = "TERMS AND CONDITIONS";
        url = BaseUrl().staticPageUrls["TERMS"];
        break;
    }
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => WebviewScaffold(
              url: url,
              clearCache: true,
              appBar: AppBar(
                title: Text(
                  title.toUpperCase(),
                ),
              ),
            ),
        fullscreenDialog: true,
      ),
    );
  }

  Future<String> _openRazorpayNative(Map<String, dynamic> payload) async {
    
    Map<dynamic, dynamic> value = new Map();
    try {
      value =
          await razorpay_platform.invokeMethod('_openRazorpayNative', payload);
          showLoader(false);
      if (Platform.isIOS) {
        processSuccessResponse(value);  
      }    
    } catch (e) {
      showLoader(false);
    }
    return "";
  }

  Future<String> initRazorpayNativePlugin() async {
      String value = "";
    try {
      value =
          await razorpay_platform.invokeMethod('initRazorpayNativePlugin');
          
    } catch (e) {}
    return "";
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

  processSuccessResponse(Map<dynamic, dynamic> payload) {
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
          branchEventTransactionFailed(response);
        }
      } else {
        branchEventTransactionSuccess(response);
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
      return Column(
        children: <Widget>[
          Card(
            elevation: 0.0,
            margin: EdgeInsets.all(16.0),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(1.0),
              side: BorderSide(
                color: Colors.grey.shade300,
                width: 1.0,
              ),
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 12.0),
              child: Column(
                children: getAmountTiles(),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Container(
                    height: 56.0,
                    child: ColorButton(
                      child: Text(
                        "Add Cash".toUpperCase(),
                        style: Theme.of(context)
                            .primaryTextTheme
                            .headline
                            .copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      onPressed: () {
                        int amount = widget.depositData.chooseAmountData
                                    .amountTiles.length <=
                                selectedTileindex
                            ? int.parse(
                                customAmountController.text,
                                onError: (e) => 0,
                              )
                            : widget.depositData.chooseAmountData
                                .amountTiles[selectedTileindex];
                        onProceed(amount: amount);
                      },
                    ),
                  ),
                )
              ],
            ),
          ),
        ],
      );
    } else if (widget.depositData != null) {
      return Column(
        children: getRepeatDepositUI(),
      );
    } else {
      return Container();
    }
  }

  getAmountTiles() {
    List<Widget> tiles = [];
    int i = 0;
    widget.depositData.chooseAmountData.amountTiles.forEach(
      (amount) {
        int curTileIndex = i;
        tiles.add(
          Stack(
            alignment: Alignment.centerLeft,
            children: <Widget>[
              Card(
                elevation: 0.0,
                margin: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(1.0),
                  side: BorderSide(
                    color: Colors.grey.shade300,
                    width: 1.0,
                  ),
                ),
                child: FlatButton(
                  onPressed: () {
                    setState(() {
                      selectedTileindex = curTileIndex;
                    });
                    FocusScope.of(context).requestFocus(FocusNode());
                  },
                  padding: EdgeInsets.only(
                      left: 16.0, right: 16.0, top: 16.0, bottom: 16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Expanded(
                        flex: 2,
                        child: Container(),
                      ),
                      Expanded(
                        flex: 1,
                        child: Text(
                          strings.rupee + amount.toString(),
                          style: TextStyle(
                            fontSize: Theme.of(context)
                                .primaryTextTheme
                                .display1
                                .fontSize,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 1,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: <Widget>[
                            Container(
                              width: 20.0,
                              height: 20.0,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white,
                                border: Border.all(
                                  color: i == selectedTileindex
                                      ? Colors.green
                                      : Colors.grey.shade400,
                                  width: 2.0,
                                ),
                              ),
                              padding: EdgeInsets.all(2.0),
                              child: i == selectedTileindex
                                  ? Container(
                                      width: 16.0,
                                      height: 16.0,
                                      decoration: BoxDecoration(
                                        color: Colors.green,
                                        shape: BoxShape.circle,
                                      ),
                                    )
                                  : null,
                            ),
                          ],
                        ),
                      )
                    ],
                  ),
                ),
              ),
              IgnorePointer(
                child: Row(
                  children: <Widget>[
                    Expanded(
                      flex: 2,
                      child: Container(
                        height: 50.0,
                        decoration: BoxDecoration(
                          image: DecorationImage(
                            image: ExactAssetImage("images/Ribbon.png"),
                          ),
                        ),
                        margin: EdgeInsets.only(left: 10.0, right: 32.0),
                        padding: EdgeInsets.only(left: 8.0),
                        child: Row(
                          children: <Widget>[
                            Image.asset(
                              "images/Bonus-gift.png",
                              height: 20.0,
                            ),
                            Padding(
                              padding: EdgeInsets.only(left: 8.0),
                              child: Text(
                                (amount >=
                                            widget.depositData.chooseAmountData
                                                .bonusArray[0]["min"] &&
                                        amount <=
                                            widget.depositData.chooseAmountData
                                                .bonusArray[0]["max"]
                                    ? (strings.rupee +
                                        getFirstDepositBonusAmount(amount) +
                                        " Bonus")
                                    : "No Bonus"),
                                style: Theme.of(context)
                                    .primaryTextTheme
                                    .subhead
                                    .copyWith(
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
                                          ? Theme.of(context).primaryColor
                                          : Colors.red,
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                            )
                          ],
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Container(),
                    )
                  ],
                ),
              ),
            ],
          ),
        );
        i++;
      },
    );

    tiles.add(
      Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: SimpleTextBox(
          style: TextStyle(
            fontSize: Theme.of(context).primaryTextTheme.display1.fontSize,
            color: Colors.grey.shade900,
          ),
          focusedBorderColor: Colors.green,
          suffixIcon: customAmountController.text != "" && customAmountBonus > 0
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Padding(
                      padding: EdgeInsets.only(right: 8.0),
                      child: Icon(
                        gift_1,
                        size: 20.0,
                        color: Colors.green,
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.only(right: 8.0),
                      child: Text(
                        strings.rupee +
                            customAmountBonus.toStringAsFixed(0) +
                            " Bonus",
                        style:
                            Theme.of(context).primaryTextTheme.title.copyWith(
                                  color: Colors.green,
                                ),
                      ),
                    )
                  ],
                )
              : null,
          focusNode: _customAmountFocusNode,
          controller: customAmountController,
          keyboardType: TextInputType.number,
          contentPadding: EdgeInsets.all(12.0),
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
    return bonusAmount.toStringAsFixed(0);
  }

  getRepeatDepositUI() {
    List<Widget> rows = [
      Padding(
        padding: EdgeInsets.all(16.0),
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
              margin: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
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
                                        activeColor: Colors.green,
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
        padding: EdgeInsets.all(16.0),
        child: Row(
          children: <Widget>[
            Expanded(
              child: Container(
                height: 48.0,
                child: ColorButton(
                  onPressed: () {
                    if (bRepeatTransaction) {
                      onRepeatTransaction();
                    } else {
                      onProceed();
                    }
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Text(
                        "DEPOSIT " +
                            (amountController.text != ""
                                ? strings.rupee + amount.toString()
                                : ""),
                        style: Theme.of(context)
                            .primaryTextTheme
                            .headline
                            .copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
                  ),
                ),
              ),
            )
          ],
        ),
      ),
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
              ? "https://d2cbroser6kssl.cloudfront.net/images/logo.png"
              : (AppConfig.of(context).channelId == '9'
                  ? "https://d2cbroser6kssl.cloudfront.net/images/icons/smart11_logo.png"
                  : "https://d2cbroser6kssl.cloudfront.net/images/icons/howzat_logo.png")
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
          branchEventTransactionFailed(response);
        }
      } else {
        branchEventTransactionSuccess(response);
        Navigator.of(context).pop(result);
      }
    }
  }

  Future<String> branchEventTransactionFailed(
      Map<String, dynamic> transactionData) async {
    Map<dynamic, dynamic> trackdata = new Map();
    DateTime date = DateTime.fromMillisecondsSinceEpoch(
        int.parse(transactionData["date"].toString()));
    String dateinString = date.day.toString() +
        "-" +
        date.month.toString() +
        "-" +
        date.year.toString();
    String timeinString = date.hour.toString() +
        ":" +
        date.minute.toString() +
        ":" +
        date.second.toString();
    trackdata["txnDate"] = dateinString;
    trackdata["txnTime"] = timeinString;
    trackdata["txnId"] = transactionData["txnId"];
    trackdata["appPage"] = "AddCashPage";
    trackdata["data"] = transactionData;
    trackdata["firstDepositor"] = transactionData["firstDepositor"];
    String trackStatus;
    try {
      String trackStatus = await branch_io_platform.invokeMethod(
          'branchEventTransactionFailed', trackdata);
    } catch (e) {}
    return trackStatus;
  }

  Future<String> branchEventTransactionSuccess(
      Map<String, dynamic> transactionData) async {
    Map<dynamic, dynamic> trackdata = new Map();
    DateTime date = DateTime.fromMillisecondsSinceEpoch(
        int.parse(transactionData["date"].toString()));
    String dateinString = date.day.toString() +
        "-" +
        date.month.toString() +
        "-" +
        date.year.toString();
    String timeinString = date.hour.toString() +
        ":" +
        date.minute.toString() +
        ":" +
        date.second.toString();
    trackdata["txnDate"] = dateinString;
    trackdata["txnTime"] = timeinString;
    trackdata["appPage"] = "AddCashPage";
    trackdata["data"] = transactionData;
    trackdata["firstDepositor"] = transactionData["firstDepositor"];
    String trackStatus;
    try {
      String trackStatus = await branch_io_platform.invokeMethod(
          'branchEventTransactionSuccess', trackdata);
    } catch (e) {}
    return trackStatus;
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
          "Payment".toUpperCase(),
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
        child: Column(
          children: <Widget>[
            // Container(
            //   color: Colors.black26,
            //   padding: EdgeInsets.symmetric(vertical: 8.0),
            //   child: Row(
            //     mainAxisAlignment: MainAxisAlignment.center,
            //     children: <Widget>[
            //       Text(
            //         "Account balance",
            //         style: TextStyle(
            //           color: Colors.black87,
            //           fontSize:
            //               Theme.of(context).primaryTextTheme.subhead.fontSize,
            //           fontWeight: FontWeight.bold,
            //         ),
            //       ),
            //       Padding(
            //         padding: EdgeInsets.only(left: 4.0),
            //         child: Text(
            //           strings.rupee +
            //               (widget.depositData == null
            //                   ? "0.0"
            //                   : (widget.depositData.chooseAmountData.balance
            //                               .deposited +
            //                           widget.depositData.chooseAmountData
            //                               .balance.nonWithdrawable +
            //                           widget.depositData.chooseAmountData
            //                               .balance.withdrawable)
            //                       .toStringAsFixed(2)),
            //         ),
            //       )
            //     ],
            //   ),
            // ),
            Expanded(
              child: SingleChildScrollView(
                child: createChooseAmountUI(),
              ),
            ),
            Container(
              height: 72.0,
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    blurRadius: 3.0,
                    spreadRadius: 1.0,
                    color: Colors.black12,
                  ),
                ],
              ),
              child: Column(
                children: <Widget>[
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Image.asset(
                          "images/payment-footer-strip.png",
                          height: 28.0,
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          "We do not accept deposits from the states of Assam, Odisha and Telangana",
                          textAlign: TextAlign.center,
                          style: Theme.of(context)
                              .primaryTextTheme
                              .caption
                              .copyWith(
                                color: Colors.grey.shade500,
                              ),
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: RichText(
                          textAlign: TextAlign.center,
                          text: TextSpan(
                            style: Theme.of(context)
                                .primaryTextTheme
                                .caption
                                .copyWith(
                                  color: Colors.grey.shade500,
                                  fontSize: 10.0,
                                ),
                            children: [
                              TextSpan(
                                text: "Bonus credit is subject to ",
                              ),
                              TextSpan(
                                recognizer: termsGesture,
                                text: "Terms and Conditions*",
                                style: TextStyle(
                                  color: Colors.blue,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
