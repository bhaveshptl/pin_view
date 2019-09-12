import 'dart:convert';
import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_svg/svg.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_webview_plugin/flutter_webview_plugin.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'package:playfantasy/appconfig.dart';
import 'package:playfantasy/commonwidgets/color_button.dart';
import 'package:playfantasy/commonwidgets/routelauncher.dart';
import 'package:playfantasy/commonwidgets/scaffoldpage.dart';
import 'package:playfantasy/commonwidgets/textbox.dart';
// import 'package:playfantasy/commonwidgets/webview_scaffold.dart';
import 'package:playfantasy/deposit/initpay.dart';
import 'package:playfantasy/deposit/promo.dart';
import 'package:playfantasy/modal/analytics.dart';
import 'package:playfantasy/modal/deposit.dart';
import 'package:playfantasy/redux/actions/loader_actions.dart';
import 'package:playfantasy/utils/apiutil.dart';
import 'package:playfantasy/utils/httpmanager.dart';
import 'package:playfantasy/utils/stringtable.dart';
import 'package:playfantasy/deposit/paymentmode.dart';
import 'package:playfantasy/deposit/transactionfailed.dart';
import 'package:playfantasy/commonwidgets/fantasypageroute.dart';
import 'package:playfantasy/utils/analytics.dart';
import 'package:playfantasy/action_utils/action_util.dart';
import 'cardpayment.dart';

class AddCash extends StatefulWidget {
  final String source;
  final Deposit depositData;
  final double prefilledAmount;
  final String promoCode;

  AddCash(
      {this.depositData, this.source, this.prefilledAmount, this.promoCode});

  @override
  State<StatefulWidget> createState() => AddCashState();
}

class AddCashState extends State<AddCash> {
  int amount;
  String cookie = "";
  bool bShowPromoInput = false;
  bool bRepeatTransaction = true;
  bool bWaitForCookieset = true;
  bool expandPreferredMethod = false;
  bool isIos = false;
  TapGestureRecognizer termsGesture = TapGestureRecognizer();
  FlutterWebviewPlugin flutterWebviewPlugin = FlutterWebviewPlugin();
  GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  dynamic selectedPromo;
  int selectedTileindex = 0;
  bool bShowBonusDistribution = false;

  Map<String, dynamic> razorpayPayload;

  TextEditingController promoController = TextEditingController();
  TextEditingController amountController = TextEditingController();
  TextEditingController customAmountController = TextEditingController();

  FocusNode _customAmountFocusNode = FocusNode();

  bool selectedPromoExpanded = false;

  static const razorpay_platform =
      const MethodChannel('com.algorin.pf.razorpay');
  static const techprocess_platform =
      const MethodChannel('com.algorin.pf.techprocess');
  static const branch_io_platform =
      const MethodChannel('com.algorin.pf.branch');
  static const webengage_platform =
      const MethodChannel('com.algorin.pf.webengage');
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

    bShowBonusDistribution = widget.depositData.bshowBonusDistribution;

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

      setState(() {
        amount = customAmount;
      });
    });

    amountController.addListener(() {
      setState(() {
        amount = amountController.text != ""
            ? double.parse(amountController.text).round()
            : 0;
      });
    });

    razorpay_platform.setMethodCallHandler(myUtilsHandler);
    techprocess_platform.setMethodCallHandler(myUtilsHandler);
    if (Platform.isIOS) {
      initRazorpayNativePlugin();
      isIos = true;
    }
    webengageAddCashInitEvent();

    if (widget.depositData != null &&
        widget.depositData.chooseAmountData.isFirstDeposit) {
      amount = widget.depositData.chooseAmountData.amountTiles[0];
      customAmountController.text = amount.toString();
    }
  }

  webengageAddCashInitEvent() {
    Map<dynamic, dynamic> eventdata = new Map();
    eventdata["eventName"] = "ADDCASH_PAGE_VISITED";
    Map<String, dynamic> data = Map();
    data["isItARepeatTransaction"] = bRepeatTransaction;
    data["channelId"] = HttpManager.channelId;
    eventdata["data"] = data;
    AnalyticsManager.trackEventsWithAttributes(eventdata);
    /*Web engage Screen Data */
    Map<dynamic, dynamic> screendata = new Map();
    screendata["screenName"] = "ADDCASH";
    Map<String, dynamic> screenAttributedata = Map();
    screenAttributedata["screenname"] = "Add Cash";
    screendata["data"] = screenAttributedata;
    AnalyticsManager.webengageAddScreenData(screendata);
  }

  initWebview() {
    try {
      flutterWebviewPlugin.launch(
        BaseUrl().apiUrl + ApiUtil.COOKIE_PAGE,
        hidden: true,
      );
    } catch (e) {}
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
          appBar: AppBar(
            title: Text(
              title.toUpperCase(),
            ),
          ),
        ),
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

  Future<String> _openTechProcessNative(Map<String, dynamic> payload) async {
    Map<dynamic, dynamic> value = new Map();
    try {
      value = await techprocess_platform.invokeMethod(
          '_openTechProcessNative', payload);
      showLoader(false);
      print("((((((((((Tech Process Result)))))))))))");
      print(value);
      if (Platform.isIOS) {}
    } catch (e) {
      showLoader(false);
    }
    return "";
  }

  Future<String> initRazorpayNativePlugin() async {
    String value = "";
    try {
      value = await razorpay_platform.invokeMethod('initRazorpayNativePlugin');
    } catch (e) {}
    return "";
  }

  Future<dynamic> myUtilsHandler(MethodCall methodCall) async {
    switch (methodCall.method) {
      case 'onRazorPayPaymentFail':
      case 'onRazorPayPaymentSuccess':
        processSuccessResponse(json.decode(methodCall.arguments));
        break;
      case 'onTechProcessPaymentFail':
        Map<dynamic, dynamic> failedDataInfo =
            json.decode(methodCall.arguments);
        if (failedDataInfo["errorMessage"] != null) {
          if (failedDataInfo["errorMessage"].length > 2) {
            ActionUtil().showMsgOnTop(
                "Payment cancelled please retry transaction. In case your money has been deducted, please contact support team!", context);
          } else {
            ActionUtil().showMsgOnTop(
                "Payment cancelled please retry transaction. In case your money has been deducted, please contact customer support team!",
                context);
          }
        }
        break;

      case 'onTechProcessPaymentSuccess':
        onTechProcessSuccessResponse(json.decode(methodCall.arguments));
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
        Event event = Event(name: "pay_failed");
        event.setDepositAmount(amount);
        event.setModeOptionId(razorpayPayload["modeOptionId"]);
        event.setFirstDeposit(false);
        event.setGatewayId(int.parse(razorpayPayload["gatewayId"].toString()));
        event.setPromoCode(
            selectedPromo == null ? "" : selectedPromo["promoCode"]);
        event.setOrderId(response["orderId"] == null
            ? razorpayPayload["orderId"]
            : response["orderId"]);

        AnalyticsManager().addEvent(event);

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
          webengageEventTransactionFailed(response);
        }
      } else {
        Event event = Event(name: "pay_success");
        event.setDepositAmount(amount);
        event.setModeOptionId(response["modeOptionId"]);
        event.setFirstDeposit(false);
        event.setUserBalance(
          response["withdrawable"].toDouble() +
              response["nonWithdrawable"].toDouble() +
              response["depositBucket"].toDouble(),
        );
        event.setGatewayId(int.parse(response["gatewayId"].toString()));
        event.setPromoCode(
            selectedPromo == null ? "" : selectedPromo["promoCode"]);
        event.setOrderId(response["orderId"]);

        AnalyticsManager().addEvent(event);
        branchEventTransactionSuccess(response);
        webengageEventTransactionSuccess(response);
        Navigator.of(context).pop(res.body);
      }
    }).whenComplete(() {
      showLoader(false);
    });
  }

  onTechProcessSuccessResponse(Map<dynamic, dynamic> payload) {
    print("<<<<<<<<<<<<<<Tech Procees succes response>>>>>>>>>>>>");
    print(payload);
    showLoader(false);
    http.Request req = http.Request(
        "POST", Uri.parse(BaseUrl().apiUrl + ApiUtil.TECHPROCESS_SUCCESS_PAY));
    req.body = json.encode(payload);
    return HttpManager(http.Client())
        .sendRequest(req)
        .then((http.Response res) {
      Map<String, dynamic> response = json.decode(res.body);
      print("<<<<<<<<<<<<<<TEch Process success Response");
      print(response);
      if ((response["authStatus"] as String).toLowerCase() ==
              "Declined".toLowerCase() ||
          (response["authStatus"] as String).toLowerCase() ==
              "Failed".toLowerCase() ||
          (response["authStatus"] as String).toLowerCase() ==
              "Fail".toLowerCase()) {
        if (response["orderId"] == null) {
          ActionUtil().showMsgOnTop(
              "Payment cancelled please retry transaction. In case your money has been deducted, please contact customer support team!",
              context);
          // _scaffoldKey.currentState.showSnackBar(
          //   SnackBar(
          //     content: Text(
          //       "Payment cancelled please retry transaction. In case your money has been deducted, please contact customer support team!",
          //     ),
          //   ),
          // );
        } else {
          _showTransactionFailed(response);
          branchEventTransactionFailed(response);
          webengageEventTransactionFailed(response);
        }
      } else {
        branchEventTransactionSuccess(response);
        webengageEventTransactionSuccess(response);
        Navigator.of(context).pop(res.body);
      }
    }).whenComplete(() {
      showLoader(false);
    });
  }

  setDepositInfo() async {
    amountController.text =
        widget.depositData.chooseAmountData.lastPaymentArray == null ||
                widget.depositData.chooseAmountData.lastPaymentArray.length == 0
            ? ""
            : (widget.depositData.chooseAmountData.lastPaymentArray[0]
                    ["amount"])
                .toString();
    amount = amountController.text != ""
        ? double.parse(amountController.text).round()
        : 0;
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
    final formatCurrency = NumberFormat.currency(
      locale: "hi_IN",
      symbol: strings.rupee,
      decimalDigits: 0,
    );

    widget.depositData.chooseAmountData.amountTiles.forEach(
      (chooseAmount) {
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
                    Future.delayed(Duration(milliseconds: 100), () {
                      int selectedAmount = widget.depositData.chooseAmountData
                                  .amountTiles.length <=
                              curTileIndex
                          ? int.parse(
                              customAmountController.text,
                              onError: (e) => 0,
                            )
                          : widget.depositData.chooseAmountData
                              .amountTiles[curTileIndex];

                      Event event = Event(name: "deposit_tile");
                      event.setDepositAmount(selectedAmount);
                      event.setFirstDeposit(
                          widget.depositData.chooseAmountData.isFirstDeposit);
                      event.setPromoCode(selectedPromo == null
                          ? ""
                          : selectedPromo["promoCode"]);
                      addAnalyticsEvent(event: event);

                      customAmountController.text = selectedAmount.toString();
                      setState(() {
                        selectedTileindex = curTileIndex;
                        amount = selectedAmount;
                      });
                    });
                    FocusScope.of(context).requestFocus(FocusNode());
                  },
                  padding: EdgeInsets.only(
                      left: 16.0, right: 16.0, top: 16.0, bottom: 16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Expanded(
                        flex: 1,
                        child: Text(
                          strings.rupee + chooseAmount.toString(),
                          style: TextStyle(
                              fontSize: isIos
                                  ? Theme.of(context)
                                      .primaryTextTheme
                                      .subhead
                                      .fontSize
                                  : Theme.of(context)
                                      .primaryTextTheme
                                      .display1
                                      .fontSize),
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
            ],
          ),
        );
        i++;
      },
    );

    var bonusAmount = getFirstDepositBonusAmount(amount);

    tiles.add(
      Column(
        children: <Widget>[
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: SimpleTextBox(
              style: TextStyle(
                fontSize: Theme.of(context).primaryTextTheme.display1.fontSize,
                color: Colors.grey.shade900,
              ),
              labelText: "Enter Amount",
              labelStyle: TextStyle(
                fontSize: Theme.of(context).primaryTextTheme.title.fontSize,
              ),
              focusedBorderColor: Colors.green,
              suffixIcon: !bShowBonusDistribution
                  ? (customAmountController.text != "" &&
                          bonusAmount > 0 &&
                          _customAmountFocusNode.hasFocus
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
                                    bonusAmount.toStringAsFixed(0) +
                                    " Bonus",
                                style: Theme.of(context)
                                    .primaryTextTheme
                                    .title
                                    .copyWith(
                                      color: Colors.green,
                                    ),
                              ),
                            )
                          ],
                        )
                      : null)
                  : FlatButton(
                      child: Text(
                        "Have a Promocode?",
                        style: TextStyle(
                          color: Colors.blue,
                          decorationStyle: TextDecorationStyle.solid,
                        ),
                      ),
                      onPressed: () {
                        launchPromoSelector();
                      },
                    ),
              focusNode: _customAmountFocusNode,
              controller: customAmountController,
              keyboardType: isIos ? TextInputType.text : TextInputType.number,
              inputFormatters: <TextInputFormatter>[
                WhitelistingTextInputFormatter.digitsOnly
              ],
              contentPadding: EdgeInsets.all(12.0),
            ),
          ),
          Row(
            children: <Widget>[
              Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text(
                    "(Minimum Deposit Amount: ${formatCurrency.format(widget.depositData.chooseAmountData.minAmount)})",
                  ),
                ),
              )
            ],
          )
        ],
      ),
    );

    if (selectedPromo != null && bShowBonusDistribution) {
      tiles.add(Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
        child: getSelectedPromoWidget(),
      ));
    }
    return tiles;
  }

  addAnalyticsEvent({Event event}) {
    AnalyticsManager().addEvent(event);
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
    } else {
      dynamic paymentDetails =
          widget.depositData.chooseAmountData.lastPaymentArray[0];

      Event event = Event(name: "repeat_transaction");
      event.setDepositAmount(amount);
      event.setModeOptionId(paymentDetails["modeOptionId"]);
      event.setFirstDeposit(false);
      event.setGatewayId(int.parse(paymentDetails["gatewayId"].toString()));
      event.setPromoCode(
          selectedPromo != null ? selectedPromo["promoCode"] : "");

      addAnalyticsEvent(event: event);

      if (selectedPromo == null) {
        initRepeatDeposit();
      } else {
        final result = await validatePromo(amount);
        if (result != null) {
          Map<String, dynamic> paymentMode = json.decode(result);
          selectedPromo = paymentMode["details"];
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
  }

  getSelectedPromoBonusAmount() {
    if (selectedPromo != null) {
      double bonusAmount = amount * selectedPromo["percentage"] / 100;
      if (amount < selectedPromo["minimum"]) {
        bonusAmount = 0;
      } else if (bonusAmount > selectedPromo["maximum"]) {
        bonusAmount = (selectedPromo["maximum"]).toDouble();
      }
      return bonusAmount;
    } else {
      return 0.0;
    }
  }

  getFirstDepositBonusAmount(int amount) {
    int minAmount = selectedPromo == null ? 0 : selectedPromo["minimum"];
    int maxAmount = selectedPromo == null ? 0 : selectedPromo["maximum"];
    int percentage = selectedPromo == null ? 0 : selectedPromo["percentage"];
    double bonusAmount = amount * percentage / 100;
    if (amount < minAmount) {
      bonusAmount = 0;
    } else if (bonusAmount > maxAmount) {
      bonusAmount = maxAmount.toDouble();
    }
    return bonusAmount;
  }

  launchPromoSelector() async {
    if (bShowBonusDistribution) {
      showLoader(true);
      List<dynamic> promoCodes = await routeLauncher
          .getPromoCodes(widget.depositData.chooseAmountData.isFirstDeposit);
      promoCodes.sort((a, b) {
        return a["minimum"] - b["minimum"];
      });
      showLoader(false);
      final result = await showDialog(
        context: context,
        builder: (BuildContext context) {
          return PromoInput(
            amount: amount,
            isFirstDeposit: widget.depositData.chooseAmountData.isFirstDeposit,
            promoCodes: promoCodes,
            selectedPromo: selectedPromo,
          );
        },
        barrierDismissible: false,
      );

      if (result != null) {
        setState(() {
          selectedPromo = result;
        });
        showLoader(true);
        final promoResult = await validatePromo(amount);
        showLoader(false);
        if (promoResult != null) {
          Map<String, dynamic> paymentMode = json.decode(promoResult);
          if (paymentMode["error"] == true) {
            Event event = Event(name: "apply_promo_error");
            event.setDepositAmount(amount);
            event.setFirstDeposit(
                widget.depositData.chooseAmountData.isFirstDeposit);
            event.setPromoCode(
                selectedPromo != null ? selectedPromo["promoCode"] : "");
            event.setErrorMessage(paymentMode["msg"]);

            AnalyticsManager().addEvent(event);

            _scaffoldKey.currentState.showSnackBar(
              SnackBar(
                content: Text(paymentMode["msg"]),
              ),
            );
          } else {
            selectedPromo = paymentMode["details"];
            Event event = Event(name: "apply_promo_sucess");
            event.setDepositAmount(amount);
            event.setFirstDeposit(
                widget.depositData.chooseAmountData.isFirstDeposit);
            event.setPromoCode(
                selectedPromo != null ? selectedPromo["promoCode"] : "");
            event.setErrorMessage(paymentMode["message"]);

            AnalyticsManager().addEvent(event);

            _scaffoldKey.currentState.showSnackBar(
              SnackBar(
                content: Text(paymentMode["message"]),
                duration: Duration(seconds: 2),
              ),
            );
          }
        }
      }
    } else {
      setState(() {
        bShowPromoInput = !bShowPromoInput;
      });
    }
  }

  int getTotalWagerAmount() {
    return ((getSelectedPromoBonusAmount() *
                selectedPromo["nonPlayablePercentage"]) /
            (selectedPromo['wagerPercentage'] * selectedPromo["chunks"]))
        .floor();
  }

  int getWagerReleaseAmount() {
    return ((getSelectedPromoBonusAmount() *
                (selectedPromo["nonPlayablePercentage"] / 100)) /
            selectedPromo["chunks"])
        .floor();
  }

  Widget getBonusDistribution() {
    int totalWagerAmount = getTotalWagerAmount();
    int wagerReleaseAmount = getWagerReleaseAmount();
    return Row(
      children: <Widget>[
        Expanded(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 8.0),
            child: Column(
              children: <Widget>[
                selectedPromo["percentage"] == 0
                    ? Container()
                    : Container(
                        padding: EdgeInsets.symmetric(
                          vertical: 8.0,
                        ),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: Colors.grey.shade300,
                            ),
                          ),
                        ),
                        child: Row(
                          children: <Widget>[
                            Expanded(
                              child: Text(
                                "Total Benefits",
                                style: Theme.of(context)
                                    .primaryTextTheme
                                    .body1
                                    .copyWith(
                                      color: Colors.black,
                                    ),
                              ),
                            ),
                            Expanded(
                              child: Row(
                                children: <Widget>[
                                  Text(
                                    getSelectedPromoBonusAmount().toString(),
                                    style: Theme.of(context)
                                        .primaryTextTheme
                                        .body1
                                        .copyWith(
                                          color: Colors.black,
                                          fontWeight: FontWeight.bold,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                Container(
                  padding: EdgeInsets.symmetric(
                    vertical: 8.0,
                  ),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: Colors.grey.shade300,
                      ),
                    ),
                  ),
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          "Playable Bonus",
                          style:
                              Theme.of(context).primaryTextTheme.body1.copyWith(
                                    color: Colors.black,
                                  ),
                        ),
                      ),
                      Expanded(
                        child: Row(
                          children: <Widget>[
                            Text(
                              strings.rupee +
                                  (getSelectedPromoBonusAmount() *
                                          selectedPromo["playablePercentage"] /
                                          100)
                                      .toString(),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.only(left: 8.0),
                              child: Text("(Expires in " +
                                  ((selectedPromo["playableBonusExp"] / 24)
                                          as double)
                                      .ceil()
                                      .toString() +
                                  " days)"),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                // Container(
                //   padding: EdgeInsets.symmetric(
                //     vertical: 8.0,
                //   ),
                //   decoration: BoxDecoration(
                //     border: Border(
                //       bottom: BorderSide(
                //         color: Colors.grey.shade300,
                //       ),
                //     ),
                //   ),
                //   child: Row(
                //     children: <Widget>[
                //       Expanded(
                //         child: Text(
                //           "Max Benefits",
                //           style:
                //               Theme.of(context).primaryTextTheme.body1.copyWith(
                //                     color: Colors.black,
                //                   ),
                //         ),
                //       ),
                //       Expanded(
                //         child: Text(
                //           strings.rupee + selectedPromo["maximum"].toString(),
                //           style:
                //               Theme.of(context).primaryTextTheme.body1.copyWith(
                //                     color: Colors.black,
                //                     fontWeight: FontWeight.bold,
                //                   ),
                //         ),
                //       ),
                //     ],
                //   ),
                // ),
                selectedPromo["nonPlayablePercentage"] == 0
                    ? Container()
                    : Container(
                        padding: EdgeInsets.symmetric(
                          vertical: 8.0,
                        ),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: Colors.grey.shade300,
                            ),
                          ),
                        ),
                        child: Row(
                          children: <Widget>[
                            Expanded(
                              child: Text(
                                "Locked Bonus",
                                style: Theme.of(context)
                                    .primaryTextTheme
                                    .body1
                                    .copyWith(
                                      color: Colors.black,
                                    ),
                              ),
                            ),
                            Expanded(
                              child: Row(
                                children: <Widget>[
                                  Text(
                                    strings.rupee +
                                        (getSelectedPromoBonusAmount() *
                                                selectedPromo[
                                                    "nonPlayablePercentage"] /
                                                100)
                                            .toString(),
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Padding(
                                    padding: EdgeInsets.only(left: 8.0),
                                    child: Text("(Expires in " +
                                        ((selectedPromo["nonPlayableBonusExp"] /
                                                24) as double)
                                            .ceil()
                                            .toString() +
                                        " days)"),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                selectedPromo["instantCashPercentage"] == 0
                    ? Container()
                    : Container(
                        padding: EdgeInsets.symmetric(
                          vertical: 8.0,
                        ),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: Colors.grey.shade300,
                            ),
                          ),
                        ),
                        child: Row(
                          children: <Widget>[
                            Expanded(
                              child: Text(
                                "Instant Cash",
                                style: Theme.of(context)
                                    .primaryTextTheme
                                    .body1
                                    .copyWith(
                                      color: Colors.black,
                                    ),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                strings.rupee +
                                    (getSelectedPromoBonusAmount() *
                                            selectedPromo[
                                                "instantCashPercentage"] /
                                            100)
                                        .toString(),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                getSelectedPromoBonusAmount() == 0 ||
                        !(totalWagerAmount > 0 && wagerReleaseAmount > 0)
                    ? Container()
                    : Container(
                        padding: EdgeInsets.symmetric(
                          vertical: 8.0,
                        ),
                        child: Row(
                          children: <Widget>[
                            Expanded(
                              child: Text(
                                "Each time you play for ${strings.rupee}${totalWagerAmount.toString()} you get ${strings.rupee}${wagerReleaseAmount.toString()} to playable bonus from locked bonus",
                                style: Theme.of(context)
                                    .primaryTextTheme
                                    .caption
                                    .copyWith(
                                      color: Colors.black,
                                    ),
                              ),
                            ),
                          ],
                        ),
                      )
              ],
            ),
          ),
        )
      ],
    );
  }

  getSelectedPromoWidget() {
    return Padding(
      padding: EdgeInsets.fromLTRB(0.0, 8.0, 0.0, 16.0),
      child: InkWell(
        onTap: () {
          setState(() {
            selectedPromoExpanded = !selectedPromoExpanded;
          });
        },
        child: Row(
          children: <Widget>[
            Expanded(
              child: DottedBorder(
                padding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 6.0),
                color: Colors.green,
                child: Column(
                  children: <Widget>[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: <Widget>[
                            Padding(
                              padding: EdgeInsets.only(right: 8.0),
                              child: Container(
                                height: 20.0,
                                width: 20.0,
                                child: Container(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Color.fromRGBO(70, 165, 12, 1),
                                      width: 1.0,
                                    ),
                                  ),
                                  padding: EdgeInsets.all(2.0),
                                  child: CircleAvatar(
                                    radius: 6.0,
                                    backgroundColor: Colors.white,
                                    child: CircleAvatar(
                                      radius: 6.0,
                                      backgroundColor:
                                          Color.fromRGBO(70, 165, 12, 1),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Text(
                              selectedPromo["promoCode"],
                              style: TextStyle(
                                color: Color.fromRGBO(70, 165, 12, 1),
                                fontWeight: FontWeight.bold,
                              ),
                            )
                          ],
                        ),
                        Row(
                          children: <Widget>[
                            InkWell(
                              child: Padding(
                                padding: EdgeInsets.all(8.0),
                                child: Text(
                                  "REMOVE",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              onTap: () {
                                Event event = Event(name: "remove_promo_code");
                                event.setDepositAmount(amount);
                                event.setFirstDeposit(widget.depositData
                                    .chooseAmountData.isFirstDeposit);
                                event.setPromoCode(selectedPromo == null
                                    ? ""
                                    : selectedPromo["promoCode"]);

                                AnalyticsManager().addEvent(event);

                                setState(() {
                                  selectedPromo = null;
                                });
                              },
                            ),
                            Icon(
                              Icons.expand_more,
                              color: Colors.green,
                            ),
                          ],
                        ),
                      ],
                    ),
                    selectedPromoExpanded ? getBonusDistribution() : Container()
                  ],
                ),
              ),
            )
          ],
        ),
      ),
    );
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
          Event event = Event(name: "proceed_validation_error");
          event.setDepositAmount(amount);
          event.setFirstDeposit(
              widget.depositData.chooseAmountData.isFirstDeposit);
          event.setPromoCode(
              selectedPromo != null ? selectedPromo["promoCode"] : "");
          event.setErrorMessage(paymentMode["msg"]);

          addAnalyticsEvent(event: event);

          _scaffoldKey.currentState.showSnackBar(
            SnackBar(
              content: Text(paymentMode["msg"]),
            ),
          );
        } else {
          selectedPromo = paymentMode["details"];
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
                                    keyboardType: isIos
                                        ? TextInputType.text
                                        : TextInputType.number,
                                    inputFormatters: <TextInputFormatter>[
                                      WhitelistingTextInputFormatter.digitsOnly
                                    ],
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
                                InkWell(
                                  onTap: () async {
                                    launchPromoSelector();
                                  },
                                  child: Padding(
                                    padding: EdgeInsets.all(8.0),
                                    child: Text(
                                      "Have a Promocode?",
                                      style: TextStyle(
                                        color: Colors.blue,
                                        decoration: TextDecoration.underline,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          !bShowBonusDistribution || selectedPromo == null
                              ? Container()
                              : getSelectedPromoWidget(),
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
                                                dynamic paymentDetails = widget
                                                    .depositData
                                                    .chooseAmountData
                                                    .lastPaymentArray[0];

                                                Event event =
                                                    Event(name: "repeat");
                                                event.setDepositAmount(amount);
                                                event.setModeOptionId(
                                                    paymentDetails[
                                                        "modeOptionId"]);
                                                event.setFirstDeposit(false);
                                                event.setPaymentRepeatChecked(
                                                    checked);
                                                event.setGatewayId(
                                                    paymentDetails[
                                                        "gatewayId"]);
                                                event.setPromoCode(
                                                    selectedPromo != null
                                                        ? selectedPromo[
                                                            "promoCode"]
                                                        : "");

                                                addAnalyticsEvent(event: event);

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
    ];

    return rows;
  }

  onProceed({int amount}) async {
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
          Event event = Event(name: "proceed_req");
          event.setDepositAmount(amount);
          event.setFirstDeposit(
              widget.depositData.chooseAmountData.isFirstDeposit);
          event.setPromoCode(
              selectedPromo != null ? selectedPromo["promoCode"] : "");

          addAnalyticsEvent(event: event);

          final result = await proceedToPaymentMode(amount);
          if (result != null) {
            initPayment(json.decode(result), amount);
          }
        }
      }
    }
  }

  proceedToPaymentMode(int amount) async {
    Map<dynamic, dynamic> eventdata = new Map();
    Map<dynamic, dynamic> addcashPageData = new Map();
    addcashPageData["user_selected_amount"] = amount.toString();
    addcashPageData["promoCode"] =
        selectedPromo == null ? "" : selectedPromo["promoCode"];
    addcashPageData["channelId"] = AppConfig.of(context).channelId;
    addcashPageData["Repeat_Transaction"] = bRepeatTransaction;
    eventdata["eventName"] = "PROCEED_TO_PAYMENTMODE";
    eventdata["data"] = addcashPageData;
    AnalyticsManager.trackEventsWithAttributes(eventdata);

    showLoader(true);

    http.Request req = http.Request(
        "POST", Uri.parse(BaseUrl().apiUrl + ApiUtil.PAYMENT_MODE));
    req.body = json.encode({
      "amount": amount,
      "channelId": AppConfig.of(context).channelId,
      "promoCode": selectedPromo == null ? "" : selectedPromo["promoCode"],
      "transaction_amount_in_paise": amount * 100,
    });
    return HttpManager(http.Client()).sendRequest(req).then(
      (http.Response res) {
        showLoader(false);
        bool bSuccess = res.statusCode >= 200 && res.statusCode <= 299;

        Event event = Event(name: "proceed_res");
        event.setDepositAmount(amount);
        event.setFirstDeposit(
            widget.depositData.chooseAmountData.isFirstDeposit);
        event.setPaymentSuccess(bSuccess);

        addAnalyticsEvent(event: event);

        if (bSuccess) {
          return res.body;
        } else {
          return null;
        }
      },
    ).whenComplete(() {
      showLoader(false);
    });
  }

  validatePromo(int amount) async {
    http.Request req = http.Request(
        "POST",
        Uri.parse(BaseUrl().apiUrl +
            (bShowBonusDistribution
                ? ApiUtil.VALIDATE_PROMO_V2
                : ApiUtil.VALIDATE_PROMO)));
    req.body = json.encode({
      "amount": amount,
      "channelId": AppConfig.of(context).channelId,
      "promoCode": !bShowBonusDistribution
          ? promoController.text
          : selectedPromo == null ? "" : selectedPromo["promoCode"],
      "transaction_amount_in_paise": amount * 100,
    });
    return HttpManager(http.Client()).sendRequest(req).then(
      (http.Response res) {
        if (res.statusCode >= 200 && res.statusCode <= 299) {
          return res.body;
        }
      },
    ).whenComplete(() {
      showLoader(false);
    });
  }

  initPayment(Map<String, dynamic> paymentMode, int amount) async {
    if (paymentMode["error"] == true) {
      Event event = Event(name: "proceed_validation_error");
      event.setDepositAmount(amount);
      event.setFirstDeposit(widget.depositData.chooseAmountData.isFirstDeposit);
      event.setPromoCode(
          selectedPromo != null ? selectedPromo["promoCode"] : "");
      event.setErrorMessage(paymentMode["msg"]);

      addAnalyticsEvent(event: event);

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
            expandPreferredMethod: expandPreferredMethod,
            paymentMode: paymentMode,
            bonusAmount: widget.depositData.chooseAmountData.isFirstDeposit
                ? getFirstDepositBonusAmount(amount)
                : getSelectedPromoBonusAmount(),
            promoCode: selectedPromo == null ? "" : selectedPromo["promoCode"],
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

  Future<Map<String, dynamic>> openCardForm() async {
    Map<String, dynamic> cardPaymentFormresult = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return CardPaymentForm();
      },
    );
    if (cardPaymentFormresult != null) {
      return cardPaymentFormresult;
    } else {
      return null;
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
      "promoCode": selectedPromo == null ? "" : selectedPromo["promoCode"],
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

    Event event = Event(name: "pay_securely");
    event.setDepositAmount(amount);
    event.setModeOptionId(payload["modeOptionId"]);
    event.setFirstDeposit(false);
    event.setGatewayId(int.parse(payload["gatewayId"].toString()));
    event.setFLEM(2222);
    event.setPromoCode(selectedPromo == null ? "" : selectedPromo["promoCode"]);

    AnalyticsManager().addEvent(event);
    showLoader(true);

    try {
      /*Web Engage  Event*/
      Map<dynamic, dynamic> eventdata = new Map();
      eventdata["eventName"] = "PROCEED_TO_REPEAT_TRANSACTION";
      Map<String, dynamic> wePayloadData = payload;
      wePayloadData.removeWhere((key, value) => value == null);
      eventdata["data"] = wePayloadData;
      AnalyticsManager.trackEventsWithAttributes(eventdata);
    } catch (e) {
      print("Error for PROCEED_TO_REPEAT_TRANSACTION event " + e.toString());
    }
    if (paymentModeDetails["gateway"] == "TECHPROCESS_SEAMLESS" &&
        paymentModeDetails["isSeamless"]) {
      var dateNow = new DateTime.now();
      var formatter = new DateFormat('dd-MM-yyyy');
      String formattedDate = formatter.format(dateNow);
      String method = (payload["paymentType"] as String).indexOf("CARD") == -1
          ? payload["paymentType"].toLowerCase()
          : "card";
      String cformCVV = "";
      String cformNameOnTheCard = "";
      String cformCardNumber = "";
      String cformExpMonth = "";
      String cformExpYear = "";

      http.Request req = http.Request(
          "GET",
          Uri.parse(BaseUrl().apiUrl +
              ApiUtil.INIT_PAYMENT_TECHPROCESS +
              querParamString));
      return HttpManager(http.Client())
          .sendRequest(req)
          .then((http.Response res) {
        Map<String, dynamic> response = json.decode(res.body);
        if (res.statusCode >= 200 && res.statusCode <= 299) {
          _openTechProcessNative({
            "name": AppConfig.of(context).appName,
            "email": payload["email"],
            "phone": payload["phone"],
            "amount": payload["depositAmount"].toString(),
            "orderId": response["action"]["value"],
            "method": (payload["paymentType"] as String).indexOf("CARD") == -1
                ? payload["paymentType"].toLowerCase()
                : "card",
            "userId": paymentModeDetails["userId"].toString(),
            "date": formattedDate,
            "extra_public_key": "1234-6666-6789-56",
            "tp_nameOnTheCard": cformNameOnTheCard,
            "tp_expireYear": cformExpYear,
            "tp_expireMonth": cformExpMonth,
            "tp_cvv": cformCVV,
            "tp_cardNumber": cformCardNumber,
            "tp_instrumentToken": "",
            "cardDataCapturingRequired": false
          });
        } else {
          ActionUtil().showMsgOnTop("Opps!! Try again later.", context);
        }
      }).whenComplete(() {
        showLoader(false);
      });
    } else if (paymentModeDetails["isSeamless"]) {
      http.Request req = http.Request(
          "GET",
          Uri.parse(BaseUrl().apiUrl +
              ApiUtil.INIT_PAYMENT_SEAMLESS +
              querParamString));
      return HttpManager(http.Client())
          .sendRequest(req)
          .then((http.Response res) {
        Map<String, dynamic> response = json.decode(res.body);
        razorpayPayload = payload;
        razorpayPayload["orderId"] = response["action"]["value"];

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
                  : "https://d2cbroser6kssl.cloudfront.net/images/howzat/logo/howzat-logo-red-bg-v1.png")
        });
      }).whenComplete(() {
        showLoader(false);
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
          waitForCookieset: bWaitForCookieset,
        ),
      ),
    );

    showLoader(false);
    bWaitForCookieset = false;

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
          webengageEventTransactionFailed(response);

          try {
            Event event = Event(name: "pay_failed");
            event.setDepositAmount(amount);
            event.setModeOptionId(response["modeOptionId"]);
            event.setFirstDeposit(false);
            event.setGatewayId(int.parse(response["gatewayId"].toString()));
            event.setPromoCode(
                selectedPromo == null ? "" : selectedPromo["promoCode"]);
            event.setOrderId(response["orderId"]);

            AnalyticsManager().addEvent(event);
          } catch (e) {
            print(e);
          }
        }
      } else {
        try {
          Event event = Event(name: "pay_success");
          event.setDepositAmount(amount);
          event.setModeOptionId(response["modeOptionId"]);
          event.setFirstDeposit(false);
          event.setUserBalance(
            double.parse(response["withdrawable"]) +
                double.parse(response["nonWithdrawable"]) +
                double.parse(response["depositBucket"]),
          );
          event.setGatewayId(int.parse(response["gatewayId"].toString()));
          event.setPromoCode(
              selectedPromo == null ? "" : selectedPromo["promoCode"]);
          event.setOrderId(response["orderId"]);

          AnalyticsManager().addEvent(event);
        } catch (e) {
          print(e);
        }

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

  Future<String> webengageEventTransactionFailed(
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
      String trackStatus = await webengage_platform.invokeMethod(
          'webEngageTransactionFailed', trackdata);
    } catch (e) {}
    return trackStatus;
  }

  Future<String> webengageEventTransactionSuccess(
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
      String trackStatus = await webengage_platform.invokeMethod(
          'webEngageTransactionSuccess', trackdata);
    } catch (e) {}
    return trackStatus;
  }

  _showTransactionFailed(Map<String, dynamic> transactionResult) async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return TransactionFailed(transactionResult, () {
          Event event = Event(name: "pay_failed_retry");
          event.setDepositAmount(amount);
          event.setModeOptionId(transactionResult["modeOptionId"]);
          event.setFirstDeposit(transactionResult["firstDepositor"] != "false");
          event.setPromoCode(
              selectedPromo == null ? "" : selectedPromo["promoCode"]);
          event.setOrderId(transactionResult["orderId"]);

          Navigator.of(context).pop();
        }, () {
          Event event = Event(name: "pay_failed_cancel");
          event.setDepositAmount(amount);
          event.setModeOptionId(transactionResult["modeOptionId"]);
          event.setFirstDeposit(transactionResult["firstDepositor"] != "false");
          event.setPromoCode(
              selectedPromo == null ? "" : selectedPromo["promoCode"]);
          event.setOrderId(transactionResult["orderId"]);

          AnalyticsManager().addEvent(event);

          Navigator.of(context).pop();
          Navigator.of(context).pop(json.encode(transactionResult));
        });
      },
    );
  }

  setDepositAmount(int amount) {
    Event event = Event(name: "deposit_tile");
    event.setDepositAmount(amount);
    event.setFirstDeposit(widget.depositData.chooseAmountData.isFirstDeposit);
    event.setPromoCode(selectedPromo == null ? "" : selectedPromo["promoCode"]);

    addAnalyticsEvent(event: event);

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
            Expanded(
              child: SingleChildScrollView(
                child: createChooseAmountUI(),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          widget.depositData != null &&
                  widget.depositData.chooseAmountData.isFirstDeposit
              ? Padding(
                  padding:
                      EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
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
                              onProceed(amount: amount);
                            },
                          ),
                        ),
                      )
                    ],
                  ),
                )
              : Padding(
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
          Container(
            height: 72.0,
            decoration: BoxDecoration(
              color: Color.fromRGBO(242, 242, 242, 1),
              border: Border.fromBorderSide(
                BorderSide(
                  color: Colors.grey.shade300,
                  width: 1.0,
                ),
              ),
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
                        style:
                            Theme.of(context).primaryTextTheme.caption.copyWith(
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
    );
  }
}
