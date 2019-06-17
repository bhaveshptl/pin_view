import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_webview_plugin/flutter_webview_plugin.dart';
import 'dart:io';
import 'package:playfantasy/appconfig.dart';
import 'package:playfantasy/commonwidgets/color_button.dart';
import 'package:playfantasy/deposit/initpay.dart';
import 'package:playfantasy/utils/apiutil.dart';
import 'package:playfantasy/utils/httpmanager.dart';
import 'package:playfantasy/utils/stringtable.dart';
import 'package:playfantasy/deposit/transactionfailed.dart';
import 'package:playfantasy/commonwidgets/scaffoldpage.dart';
import 'package:playfantasy/redux/actions/loader_actions.dart';
import 'package:playfantasy/commonwidgets/fantasypageroute.dart';
import 'package:playfantasy/utils/analytics.dart';

class ChoosePaymentMode extends StatefulWidget {
  final int amount;
  final String url;
  final String promoCode;
  final Map<String, dynamic> paymentMode;

  ChoosePaymentMode({this.amount, this.promoCode, this.url, this.paymentMode});

  @override
  ChoosePaymentModeState createState() => ChoosePaymentModeState();
}

class ChoosePaymentModeState extends State<ChoosePaymentMode> {
  String cookie;
  int _selectedItemIndex = -1;
  bool lastPaymentExpanded = false;
  final flutterWebviewPlugin = FlutterWebviewPlugin();
  static const razorpay_platform =
      const MethodChannel('com.algorin.pf.razorpay');
  static const branch_io_platform =
      const MethodChannel('com.algorin.pf.branch');
  static const webengage_platform =
      const MethodChannel('com.algorin.pf.webengage');
  Map<String, dynamic> lastPaymentMethod;
  Map<String, Map<String, dynamic>> selectedPaymentMethod = {};
  TextEditingController phoneController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController lastNameController = TextEditingController();
  TextEditingController firstNameController = TextEditingController();

  GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    setPaymentModeList();
    flutterWebviewPlugin.launch(
      BaseUrl().apiUrl + ApiUtil.COOKIE_PAGE,
      hidden: true,
    );

    razorpay_platform.setMethodCallHandler(myUtilsHandler);
    if (Platform.isIOS) {
      initRazorpayNativePlugin();
    }

    webengagePaymentModeInitEvent();
  }

  webengagePaymentModeInitEvent() {
    Map<dynamic, dynamic> eventdata = new Map();
    eventdata["eventName"] = "PAYMENTMODE_PAGE_VISITED";
    Map<String, dynamic> data = Map();
    data["promoCode"] = widget.promoCode;
    data["depositAmount"] = widget.amount;
    data["channelId"] = HttpManager.channelId;
    eventdata["data"] = data;
    AnalyticsManager.trackEventsWithAttributes(eventdata);

    /*Web engage Screen Data */
    Map<dynamic, dynamic> screendata = new Map();
    screendata["screenName"] = "PAYMENTMODE";
    Map<String,dynamic> screenAttributedata =Map();
    screenAttributedata["depositAmount"]=widget.amount;
    screendata["data"] = screenAttributedata;
    AnalyticsManager.webengageAddScreenData(screendata);
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
      default:
    }
  }

  showLoader(bool bShow) {
    AppConfig.of(context)
        .store
        .dispatch(bShow ? LoaderShowAction() : LoaderHideAction());
  }

  processSuccessResponse(Map<dynamic, dynamic> payload) {
    print("<<<<<<<<<<<<<<Procees succes response>>>>>>>>>>>>");
    print(payload);
    showLoader(false);
    http.Request req =
        http.Request("POST", Uri.parse(BaseUrl().apiUrl + ApiUtil.SUCCESS_PAY));
    req.body = json.encode(payload);
    return HttpManager(http.Client())
        .sendRequest(req)
        .then((http.Response res) {
      Map<String, dynamic> response = json.decode(res.body);
      print("Response");
      print(response);
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

  setPaymentModeList() {
    int i = 0;
    widget.paymentMode["choosePayment"]["paymentInfo"]["paymentTypes"]
        .forEach((type) {
      if (widget.paymentMode["choosePayment"]["paymentInfo"][type["type"]]
              .length >
          1) {
        Map<String, dynamic> lastPaymentArray =
            widget.paymentMode["choosePayment"]["userInfo"]
                        ["lastPaymentArray"] !=
                    null
                ? widget.paymentMode["choosePayment"]["userInfo"]
                    ["lastPaymentArray"][0]
                : {};
        if (lastPaymentArray != null &&
            lastPaymentArray["paymentType"] == type["type"]) {
          bool bLastTransactionFound = false;
          (widget.paymentMode["choosePayment"]["paymentInfo"][type["type"]]
                  as List)
              .forEach((type) {
            if (type["name"] == lastPaymentArray["paymentOption"]) {
              selectedPaymentMethod[type["type"]] = type;
              lastPaymentMethod = type;
              bLastTransactionFound = true;
            }
          });
          if (!bLastTransactionFound) {
            selectedPaymentMethod[type["type"]] = widget
                .paymentMode["choosePayment"]["paymentInfo"][type["type"]][0];
          }
          _selectedItemIndex = i;
        } else {
          selectedPaymentMethod[type["type"]] = widget
              .paymentMode["choosePayment"]["paymentInfo"][type["type"]][0];
        }
      }
      i++;
    });
    lastNameController.text = widget.paymentMode["last_name"] == null
        ? ""
        : widget.paymentMode["last_name"];
    firstNameController.text = widget.paymentMode["first_name"] == null
        ? ""
        : widget.paymentMode["first_name"];
  }

  getPaymentModeWidgetButtons() {
    List<Widget> items = [];
    int i = 0;
    Map<String, dynamic> lastPaymentArray = widget.paymentMode["choosePayment"]
                ["userInfo"]["lastPaymentArray"] !=
            null
        ? widget.paymentMode["choosePayment"]["userInfo"]["lastPaymentArray"][0]
        : {};
    (widget.paymentMode["choosePayment"]["paymentInfo"]["paymentTypes"])
        .forEach((type) {
      if (widget.paymentMode["choosePayment"]["paymentInfo"][type["type"]]
                  .length ==
              1 &&
          lastPaymentArray["paymentType"] != type["type"]) {
        if (i != 0) {
          items.add(
            Divider(height: 2.0),
          );
        }
        items.add(
          Row(
            children: <Widget>[
              Expanded(
                child: FlatButton(
                  padding: EdgeInsets.all(0.0),
                  onPressed: () {
                    if (validateUserInfo()) {
                      onPaySecurely(
                          widget.paymentMode["choosePayment"]["paymentInfo"]
                              [type["type"]][0],
                          type["type"]);
                    }
                  },
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        Expanded(
                          child: Row(
                            children: <Widget>[
                              SvgPicture.network(
                                type["logo"],
                                width: 24.0,
                              ),
                              Padding(
                                padding: EdgeInsets.only(left: 8.0),
                                child: Text(
                                  type["label"],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.chevron_right,
                          color: Colors.black26,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
        i++;
      }
    });
    return items;
  }

  getLastPaymentWidget() {
    List<Widget> items = [];
    int i = 0;
    Map<String, dynamic> lastPaymentArray = widget.paymentMode["choosePayment"]
                ["userInfo"]["lastPaymentArray"] !=
            null
        ? widget.paymentMode["choosePayment"]["userInfo"]["lastPaymentArray"][0]
        : {};

    widget.paymentMode["choosePayment"]["paymentInfo"]["paymentTypes"]
        .forEach((type) {
      if (widget.paymentMode["choosePayment"]["paymentInfo"][type["type"]]
                  .length ==
              1 &&
          lastPaymentArray["paymentType"] == type["type"]) {
        if (i != 0) {
          items.add(
            Divider(height: 2.0),
          );
        }
        items.add(
          Row(
            children: <Widget>[
              Expanded(
                child: FlatButton(
                  padding: EdgeInsets.all(0.0),
                  onPressed: () {
                    if (validateUserInfo()) {
                      onPaySecurely(
                          widget.paymentMode["choosePayment"]["paymentInfo"]
                              [type["type"]][0],
                          type["type"]);
                    }
                  },
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        Expanded(
                          child: Row(
                            children: <Widget>[
                              SvgPicture.network(
                                type["logo"],
                                width: 24.0,
                              ),
                              Padding(
                                padding: EdgeInsets.only(left: 8.0),
                                child: Text(
                                  type["label"],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.chevron_right,
                          color: Colors.black26,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
        i++;
      } else if (widget
                  .paymentMode["choosePayment"]["paymentInfo"][type["type"]]
                  .length >
              1 &&
          lastPaymentArray["paymentType"] == type["type"]) {
        items.add(
          ExpansionPanelList(
            expansionCallback: (int index, bool isExpanded) {
              setState(() {
                lastPaymentExpanded = !lastPaymentExpanded;
              });
            },
            children: [
              ExpansionPanel(
                isExpanded: lastPaymentExpanded,
                headerBuilder: (context, isExpanded) {
                  return FlatButton(
                    onPressed: () {
                      setState(() {
                        lastPaymentExpanded = !lastPaymentExpanded;
                      });
                    },
                    padding: EdgeInsets.only(left: 16.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Row(
                          children: <Widget>[
                            SvgPicture.network(
                              type["logo"],
                              width: 24.0,
                            ),
                            Padding(
                              padding: EdgeInsets.only(left: 8.0),
                              child: Text(type["label"]),
                            ),
                          ],
                        )
                      ],
                    ),
                  );
                },
                body: Padding(
                  padding:
                      EdgeInsets.only(left: 16.0, bottom: 16.0, right: 16.0),
                  child: Column(
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          DropdownButton(
                            onChanged: (value) {
                              setState(() {
                                lastPaymentMethod = value;
                              });
                            },
                            value: lastPaymentMethod,
                            items: (widget.paymentMode["choosePayment"]
                                    ["paymentInfo"][type["type"]] as List)
                                .map((item) {
                              return DropdownMenuItem(
                                child: Text(item["info"]["label"]),
                                value: item,
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                      Padding(
                        padding: EdgeInsets.only(top: 8.0),
                        child: Row(
                          children: <Widget>[
                            Expanded(
                              child: Container(
                                height: 48.0,
                                child: ColorButton(
                                  onPressed: () {
                                    if (validateUserInfo()) {
                                      onPaySecurely(
                                        lastPaymentMethod,
                                        type["type"],
                                      );
                                    }
                                  },
                                  child: Text(
                                    strings.get("PAY_SECURELY").toUpperCase(),
                                    style: Theme.of(context)
                                        .primaryTextTheme
                                        .title
                                        .copyWith(
                                          color: Colors.white,
                                        ),
                                  ),
                                ),
                              ),
                            )
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
      }
    });
    return items;
  }

  getPaymentModeWidgetList() {
    List<ExpansionPanel> items = [];
    int i = 0;
    Map<String, dynamic> lastPaymentArray = widget.paymentMode["choosePayment"]
                ["userInfo"]["lastPaymentArray"] !=
            null
        ? widget.paymentMode["choosePayment"]["userInfo"]["lastPaymentArray"][0]
        : {};
    (widget.paymentMode["choosePayment"]["paymentInfo"]["paymentTypes"])
        .forEach((type) {
      if (widget.paymentMode["choosePayment"]["paymentInfo"][type["type"]]
                  .length >
              1 &&
          lastPaymentArray["paymentType"] != type["type"]) {
        int index = i;
        items.add(
          ExpansionPanel(
            isExpanded: _selectedItemIndex == i,
            headerBuilder: (context, isExpanded) {
              return FlatButton(
                onPressed: () {
                  setState(() {
                    if (_selectedItemIndex == index) {
                      _selectedItemIndex = -1;
                    } else {
                      _selectedItemIndex = index;
                    }
                  });
                },
                padding: EdgeInsets.only(left: 16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        SvgPicture.network(
                          type["logo"],
                          width: 24.0,
                        ),
                        Padding(
                          padding: EdgeInsets.only(left: 8.0),
                          child: Text(type["label"]),
                        ),
                      ],
                    )
                  ],
                ),
              );
            },
            body: Padding(
              padding: EdgeInsets.only(left: 16.0, bottom: 16.0, right: 16.0),
              child: Column(
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      DropdownButton(
                        onChanged: (value) {
                          setState(() {
                            selectedPaymentMethod[type["type"]] = value;
                          });
                        },
                        value: selectedPaymentMethod[type["type"]],
                        items: (widget.paymentMode["choosePayment"]
                                ["paymentInfo"][type["type"]] as List)
                            .map((item) {
                          return DropdownMenuItem(
                            child: Text(item["info"]["label"]),
                            value: item,
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                  Padding(
                    padding: EdgeInsets.only(top: 8.0),
                    child: Row(
                      children: <Widget>[
                        Expanded(
                          child: Container(
                            height: 48.0,
                            child: ColorButton(
                              onPressed: () {
                                if (validateUserInfo()) {
                                  onPaySecurely(
                                      selectedPaymentMethod[type["type"]],
                                      type["type"]);
                                }
                              },
                              child: Text(
                                strings.get("PAY_SECURELY").toUpperCase(),
                                style: Theme.of(context)
                                    .primaryTextTheme
                                    .title
                                    .copyWith(
                                      color: Colors.white,
                                    ),
                              ),
                            ),
                          ),
                        )
                      ],
                    ),
                  )
                ],
              ),
            ),
          ),
        );
        i++;
      }
    });
    return items;
  }

  bool validateUserInfo() {
    if ((widget.paymentMode["first_name"] == null &&
        firstNameController.text == "")) {
      showSnackbar("First name is required to proceed.");
      return false;
    } else if (widget.paymentMode["mobile"] == null &&
        phoneController.text == "") {
      showSnackbar("Mobile number is required to proceed.");
      return false;
    } else if (widget.paymentMode["email"] == null &&
        emailController.text == "") {
      showSnackbar("Email id is required to proceed.");
      return false;
    } else {
      return true;
    }
  }

  showSnackbar(String msg) {
    _scaffoldKey.currentState.showSnackBar(
      SnackBar(
        content: Text(msg),
      ),
    );
  }

  onPaySecurely(Map<String, dynamic> paymentModeDetails, String type) async {
    String querParamString = '';
    Map<String, dynamic> payload = {
      "channelId": AppConfig.of(context).channelId,
      "orderId": null,
      "paymentType": type,
      "promoCode": widget.promoCode,
      "depositAmount": widget.amount,
      "paymentOption": paymentModeDetails["name"],
      "gateway": paymentModeDetails["info"]["gateway"],
      "gatewayName": paymentModeDetails["info"]["gateway"],
      "gatewayId": paymentModeDetails["info"]["gatewayId"],
      "accessToken": paymentModeDetails["info"]["accessToken"],
      "requestType": paymentModeDetails["info"]["requestType"],
      "modeOptionId": paymentModeDetails["info"]["modeOptionId"],
      "bankCode": paymentModeDetails["info"]["processorBankCode"],
      "detailRequired": paymentModeDetails["info"]["detailRequired"],
      "processorBankCode": paymentModeDetails["info"]["processorBankCode"],
      "cvv": paymentModeDetails["cvv"],
      "label": paymentModeDetails["label"],
      "expireYear": paymentModeDetails["expireYear"],
      "expireMonth": paymentModeDetails["expireMonth"],
      "nameOnTheCard": paymentModeDetails["nameOnTheCard"],
      "saveCardDetails": paymentModeDetails["saveCardDetails"],
      "email": widget.paymentMode["email"] == null
          ? emailController.text
          : widget.paymentMode["email"],
      "phone": widget.paymentMode["mobile"] == null
          ? phoneController.text
          : widget.paymentMode["mobile"],
      "last_name": widget.paymentMode["last_name"] == null
          ? lastNameController.text
          : widget.paymentMode["last_name"],
      "first_name": widget.paymentMode["first_name"] == null
          ? firstNameController.text
          : widget.paymentMode["first_name"],
      "updateEmail": widget.paymentMode["email"] == null,
      "updateMobile": widget.paymentMode["mobile"] == null,
      "updateName": widget.paymentMode["firstName"] == null ||
          widget.paymentMode["lastName"] == null,
      "isFirstDeposit": widget.paymentMode["isFirstDeposit"],
      "native": true,
    };
    webEngagePaymentInitEvent(paymentModeDetails);
    int index = 0;
    payload.forEach((key, value) {
      if (index != 0) {
        querParamString += '&';
      }
      querParamString += key + '=' + value.toString();
      index++;
    });

    showLoader(true);

    if (paymentModeDetails["info"]["isSeamless"]) {
      http.Request req = http.Request(
          "GET",
          Uri.parse(BaseUrl().apiUrl +
              ApiUtil.INIT_PAYMENT_SEAMLESS +
              querParamString));
      return HttpManager(http.Client())
          .sendRequest(req)
          .then((http.Response res) {
        Map<String, dynamic> response = json.decode(res.body);
        if (res.statusCode >= 200 && res.statusCode <= 299) {
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
        } else {
          _scaffoldKey.currentState.showSnackBar(
            SnackBar(
              content: Text("Opps!! Try again later."),
            ),
          );
        }
      }).whenComplete(() {
        showLoader(false);
      });
    } else {
      initPayment(BaseUrl().apiUrl + ApiUtil.INIT_PAYMENT + querParamString);
    }
  }

  webEngagePaymentInitEvent(Map<String, dynamic> paymentModeDetails) {
    Map<dynamic, dynamic> eventdata = new Map();
    eventdata["eventName"] = "PAYMENT_INIT_FROM_PAYMENTMODEPAGE";
    eventdata["data"] = paymentModeDetails;
    AnalyticsManager.trackEventsWithAttributes(eventdata);
  }

  initPayment(String url) async {
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
          "Declined".toLowerCase()) {
        _showTransactionFailed(response);
        branchEventTransactionFailed(response);
        webengageEventTransactionFailed(response);
      } else {
        Navigator.of(context).pop(result);
        branchEventTransactionSuccess(response);
        webengageEventTransactionSuccess(response); 
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
    trackdata["appPage"] = "PaymentModePage";
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
    trackdata["appPage"] = "PaymentModePage";
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
          Navigator.of(context).pop();
        }, () {
          Navigator.of(context).pop();
          Navigator.of(context).pop(json.encode(transactionResult));
        });
      },
    );
  }

  @override
  void dispose() {
    flutterWebviewPlugin.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Map<String, dynamic> lastPaymentArray = widget.paymentMode["choosePayment"]
                ["userInfo"]["lastPaymentArray"] !=
            null
        ? widget.paymentMode["choosePayment"]["userInfo"]["lastPaymentArray"][0]
        : {};
    return ScaffoldPage(
      scaffoldKey: _scaffoldKey,
      appBar: AppBar(
        title: Text(
          "Payment".toUpperCase(),
        ),
      ),
      body: widget.paymentMode != null
          ? SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.all(8.0),
                child: Column(
                  children: <Widget>[
                    widget.paymentMode["first_name"] == null ||
                            widget.paymentMode["last_name"] == null ||
                            widget.paymentMode["email"] == null ||
                            widget.paymentMode["mobile"] == null
                        ? Card(
                            elevation: 3.0,
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Column(
                                children: <Widget>[
                                  Container(
                                    padding: EdgeInsets.all(8.0),
                                    child: widget.paymentMode["first_name"] ==
                                                null ||
                                            widget.paymentMode["last_name"] ==
                                                null
                                        ? Row(
                                            children: <Widget>[
                                              Expanded(
                                                flex: 8,
                                                child: TextFormField(
                                                  controller:
                                                      firstNameController,
                                                  decoration: InputDecoration(
                                                    labelText: strings
                                                        .get("FIRST_NAME"),
                                                    contentPadding:
                                                        EdgeInsets.all(12.0),
                                                    border: OutlineInputBorder(
                                                      borderSide: BorderSide(
                                                        color: Colors.black38,
                                                      ),
                                                    ),
                                                  ),
                                                  keyboardType:
                                                      TextInputType.text,
                                                  style: TextStyle(
                                                      fontSize:
                                                          Theme.of(context)
                                                              .primaryTextTheme
                                                              .subhead
                                                              .fontSize,
                                                      color: Colors.black45),
                                                ),
                                              ),
                                              Expanded(
                                                flex: 1,
                                                child: Container(),
                                              ),
                                              Expanded(
                                                flex: 8,
                                                child: TextFormField(
                                                  controller:
                                                      lastNameController,
                                                  decoration: InputDecoration(
                                                    labelText: strings
                                                        .get("LAST_NAME"),
                                                    contentPadding:
                                                        EdgeInsets.all(12.0),
                                                    border: OutlineInputBorder(
                                                      borderSide: BorderSide(
                                                        color: Colors.black38,
                                                      ),
                                                    ),
                                                  ),
                                                  keyboardType:
                                                      TextInputType.text,
                                                  style: TextStyle(
                                                      fontSize:
                                                          Theme.of(context)
                                                              .primaryTextTheme
                                                              .subhead
                                                              .fontSize,
                                                      color: Colors.black45),
                                                ),
                                              )
                                            ],
                                          )
                                        : Container(),
                                  ),
                                  widget.paymentMode["email"] == null
                                      ? Container(
                                          padding: EdgeInsets.all(8.0),
                                          child: Row(
                                            children: <Widget>[
                                              Expanded(
                                                child: TextFormField(
                                                  controller: emailController,
                                                  decoration: InputDecoration(
                                                    labelText:
                                                        strings.get("EMAIL"),
                                                    contentPadding:
                                                        EdgeInsets.all(12.0),
                                                    border: OutlineInputBorder(
                                                      borderSide: BorderSide(
                                                        color: Colors.black38,
                                                      ),
                                                    ),
                                                  ),
                                                  keyboardType: TextInputType
                                                      .emailAddress,
                                                  style: TextStyle(
                                                      fontSize:
                                                          Theme.of(context)
                                                              .primaryTextTheme
                                                              .subhead
                                                              .fontSize,
                                                      color: Colors.black45),
                                                ),
                                              ),
                                            ],
                                          ),
                                        )
                                      : Container(),
                                  widget.paymentMode["mobile"] == null
                                      ? Container(
                                          padding: EdgeInsets.all(8.0),
                                          child: Row(
                                            children: <Widget>[
                                              Expanded(
                                                child: TextFormField(
                                                  controller: phoneController,
                                                  decoration: InputDecoration(
                                                    labelText:
                                                        strings.get("MOBILE"),
                                                    contentPadding:
                                                        EdgeInsets.all(12.0),
                                                    border: OutlineInputBorder(
                                                      borderSide: BorderSide(
                                                        color: Colors.black38,
                                                      ),
                                                    ),
                                                  ),
                                                  keyboardType:
                                                      TextInputType.number,
                                                  style: TextStyle(
                                                      fontSize:
                                                          Theme.of(context)
                                                              .primaryTextTheme
                                                              .subhead
                                                              .fontSize,
                                                      color: Colors.black45),
                                                ),
                                              ),
                                            ],
                                          ),
                                        )
                                      : Container(),
                                ],
                              ),
                            ),
                          )
                        : Container(),
                    getLastPaymentWidget().length > 0
                        ? Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Row(
                              children: <Widget>[
                                Text(
                                  "Preferred method",
                                  style: Theme.of(context)
                                      .primaryTextTheme
                                      .subhead
                                      .copyWith(
                                        color: Colors.black54,
                                        fontWeight: FontWeight.bold,
                                      ),
                                )
                              ],
                            ))
                        : Container(),
                    getLastPaymentWidget().length > 0
                        ? Card(
                            elevation: 3.0,
                            child: Column(
                              children: getLastPaymentWidget(),
                            ),
                          )
                        : Container(),
                    Padding(
                      padding: EdgeInsets.fromLTRB(8.0, 32.0, 8.0, 8.0),
                      child: Row(
                        children: <Widget>[
                          Text(
                            "Other payment options",
                            style: Theme.of(context)
                                .primaryTextTheme
                                .subhead
                                .copyWith(
                                  color: Colors.black54,
                                  fontWeight: FontWeight.bold,
                                ),
                          )
                        ],
                      ),
                    ),
                    Card(
                      elevation: 3.0,
                      child: Column(
                        children: getPaymentModeWidgetButtons(),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.only(
                        top: 16.0,
                        left: 4.0,
                        right: 4.0,
                      ),
                      child: Row(
                        children: <Widget>[
                          Expanded(
                            child: widget.paymentMode == null
                                ? Container()
                                : ExpansionPanelList(
                                    expansionCallback:
                                        (int index, bool isExpanded) {
                                      setState(() {
                                        if (_selectedItemIndex == index) {
                                          _selectedItemIndex = -1;
                                        } else {
                                          _selectedItemIndex = index;
                                        }
                                      });
                                    },
                                    children: getPaymentModeWidgetList(),
                                  ),
                          ),
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
                  ],
                ),
              ),
            )
          : Container(),
    );
  }
}
