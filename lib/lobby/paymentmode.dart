import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import 'package:platform/platform.dart';
import 'package:flutter_webview_plugin/flutter_webview_plugin.dart';

import 'package:playfantasy/appconfig.dart';
import 'package:playfantasy/lobby/initpay.dart';
import 'package:playfantasy/utils/apiutil.dart';
import 'package:playfantasy/utils/httpmanager.dart';
import 'package:playfantasy/utils/stringtable.dart';
import 'package:playfantasy/commonwidgets/transactionfailed.dart';

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
  final flutterWebviewPlugin = FlutterWebviewPlugin();
  static const razorpay_platform =
      const MethodChannel('com.algorin.pf.razorpay');
  List<Map<String, dynamic>> selectedPaymentMethod = [];
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
      BaseUrl.apiUrl + ApiUtil.COOKIE_PAGE,
      hidden: true,
    );
   
   razorpay_platform.setMethodCallHandler(myUtilsHandler);
  }

  Future<String> _openRazorpayNative() async {
    String value;
    var paymentDetails=<String,dynamic>{
       'email':'subbu@algorintechlabs.com',
       'phone':'9494475165',
       'amount':'100'
    };
    try {
      value = await razorpay_platform.invokeMethod('_openRazorpayNative',paymentDetails);
      print("<<<<<<<<<<<<<<<<<<<RAZo>>>>>>>>>>>>>>");
      print(value);
    } catch (e) {
      print(e);
    }
    return value;
  }




   Future<dynamic> myUtilsHandler(MethodCall methodCall) async {
    switch (methodCall.method) {
      case 'onRazorPayPaymentFail':
       print("<<<<<<<<<<<<<<<<<<<<<<<<<<<payment succes>>>>>>>>>>>>>>>>>>>>>>>>");
       showSnackbar("payment Failed");
      print("payment Failed");
        return 'some string';
      case 'onRazorPayPaymentSuccess':
       showSnackbar("payment Success");
        return 123.0;
      default:
        // todo - throw not implemented
    }
  }

  initRazorpayPaymentMode(){
     _openRazorpayNative();
  }

  setPaymentModeList() {
    int i = 0;
    widget.paymentMode["choosePayment"]["paymentInfo"]["paymentTypes"]
        .forEach((type) {
      if (widget.paymentMode["choosePayment"]["paymentInfo"][type["type"]]
              .length >
          0) {
        Map<String, dynamic> lastPaymentArray = widget
            .paymentMode["choosePayment"]["userInfo"]["lastPaymentArray"][0];
        if (lastPaymentArray != null &&
            lastPaymentArray["paymentType"] == type["type"]) {
          bool bLastTransactionFound = false;
          (widget.paymentMode["choosePayment"]["paymentInfo"][type["type"]]
                  as List)
              .forEach((type) {
            if (type["name"] == lastPaymentArray["paymentOption"]) {
              selectedPaymentMethod.add(type);
              bLastTransactionFound = true;
            }
          });
          if (!bLastTransactionFound) {
            selectedPaymentMethod.add(widget.paymentMode["choosePayment"]
                ["paymentInfo"][type["type"]][0]);
          }
          _selectedItemIndex = i;
        } else {
          selectedPaymentMethod.add(widget.paymentMode["choosePayment"]
              ["paymentInfo"][type["type"]][0]);
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

  getPaymentModeWidgetList() {
    List<ExpansionPanel> items = [];
    int i = 0;
    (widget.paymentMode["choosePayment"]["paymentInfo"]["paymentTypes"])
        .forEach((type) {
      if (widget.paymentMode["choosePayment"]["paymentInfo"][type["type"]]
              .length >
          0) {
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
                        Text(type["label"]),
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
                            selectedPaymentMethod[index] = value;
                          });
                        },
                        value: selectedPaymentMethod[i],
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
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: RaisedButton(
                          onPressed: () {
                            if (validateUserInfo()) {
                              onPaySecurely(
                                  selectedPaymentMethod[index], type["type"]);
                            }
                          },
                          child: Text(
                            strings.get("PAY_SECURELY").toUpperCase(),
                          ),
                          textColor: Colors.white70,
                          color: Theme.of(context).primaryColorDark,
                        ),
                      )
                    ],
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
      "isFirstDeposit": widget.paymentMode["isFirstDeposit"]
    };

    int index = 0;
    payload.forEach((key, value) {
      if (index != 0) {
        querParamString += '&';
      }
      querParamString += key + '=' + value.toString();
      index++;
    });

    if (paymentModeDetails["info"]["isSeamless"]) {
      http.Request req = http.Request(
          "GET",
          Uri.parse(BaseUrl.apiUrl +
              ApiUtil.INIT_PAYMENT_SEAMLESS +
              querParamString));
      return HttpManager(http.Client())
          .sendRequest(req)
          .then((http.Response res) {
        print(res.body);
      });
    } else {
      initPayment(BaseUrl.apiUrl + ApiUtil.INIT_PAYMENT + querParamString);
    }
  }

  initPayment(String url) async {
    final result = await Navigator.of(context).push(
      CupertinoPageRoute(
        builder: (context) => InitPay(
              url: url,
            ),
      ),
    );

    if (result != null) {
      Map<String, dynamic> response = json.decode(result);
      if ((response["authStatus"] as String).toLowerCase() ==
          "Declined".toLowerCase()) {
        _showTransactionFailed(response);
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

  @override
  void dispose() {
    flutterWebviewPlugin.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text(
          strings.get("CHOOSE_PAYMENT_MODE"),
        ),
      ),
      body: widget.paymentMode != null
          ? SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.all(8.0),
                child: Column(
                  children: <Widget>[
                    RaisedButton(
                      onPressed: () {
                        initRazorpayPaymentMode();
                      },
                      color: Theme.of(context).primaryColorDark,
                      textColor: Colors.white70,
                      child: Text("RAZORPAY TEST"),
                    ),
                    Container(
                      padding: EdgeInsets.all(8.0),
                      child: widget.paymentMode["first_name"] == null ||
                              widget.paymentMode["last_name"] == null
                          ? Row(
                              children: <Widget>[
                                Expanded(
                                  flex: 8,
                                  child: TextFormField(
                                    controller: firstNameController,
                                    decoration: InputDecoration(
                                      labelText: strings.get("FIRST_NAME"),
                                      contentPadding: EdgeInsets.all(12.0),
                                      border: OutlineInputBorder(
                                        borderSide: BorderSide(
                                          color: Colors.black38,
                                        ),
                                      ),
                                    ),
                                    keyboardType: TextInputType.text,
                                    style: TextStyle(
                                        fontSize: Theme.of(context)
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
                                    controller: lastNameController,
                                    decoration: InputDecoration(
                                      labelText: strings.get("LAST_NAME"),
                                      contentPadding: EdgeInsets.all(12.0),
                                      border: OutlineInputBorder(
                                        borderSide: BorderSide(
                                          color: Colors.black38,
                                        ),
                                      ),
                                    ),
                                    keyboardType: TextInputType.text,
                                    style: TextStyle(
                                        fontSize: Theme.of(context)
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
                                      labelText: strings.get("EMAIL"),
                                      contentPadding: EdgeInsets.all(12.0),
                                      border: OutlineInputBorder(
                                        borderSide: BorderSide(
                                          color: Colors.black38,
                                        ),
                                      ),
                                    ),
                                    keyboardType: TextInputType.emailAddress,
                                    style: TextStyle(
                                        fontSize: Theme.of(context)
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
                                      labelText: strings.get("MOBILE"),
                                      contentPadding: EdgeInsets.all(12.0),
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
                                            .subhead
                                            .fontSize,
                                        color: Colors.black45),
                                  ),
                                ),
                              ],
                            ),
                          )
                        : Container(),
                    Padding(
                      padding: EdgeInsets.only(top: 16.0),
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
                  ],
                ),
              ),
            )
          : Container(),
    );
  }
}
