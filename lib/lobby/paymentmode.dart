import 'package:flutter/material.dart';
import 'package:flutter_webview_plugin/flutter_webview_plugin.dart';

import 'package:playfantasy/lobby/initpay.dart';
import 'package:playfantasy/utils/apiutil.dart';
import 'package:playfantasy/utils/stringtable.dart';

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
      ApiUtil.COOKIE_PAGE,
      hidden: true,
    );
  }

  setPaymentModeList() {
    widget.paymentMode["choosePayment"]["paymentInfo"]["paymentTypes"]
        .forEach((type) {
      selectedPaymentMethod.add(
          widget.paymentMode["choosePayment"]["paymentInfo"][type["type"]][0]);
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
      int index = i;
      items.add(
        ExpansionPanel(
          isExpanded: _selectedItemIndex == i,
          headerBuilder: (context, isExpanded) {
            return Padding(
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
                      items: (widget.paymentMode["choosePayment"]["paymentInfo"]
                              [type["type"]] as List)
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
    });
    return items;
  }

  bool validateUserInfo() {
    if ((widget.paymentMode["first_name"] == null &&
            firstNameController.text == "") ||
        (widget.paymentMode["last_name"] == null &&
            lastNameController.text == "")) {
      showSnackbar("First name and Last name are required to proceed.");
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
      "channelId": 3,
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

    initPayment(ApiUtil.INIT_PAYMENT + querParamString);
  }

  initPayment(String url) async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => InitPay(
              url: url,
            ),
      ),
    );

    if (result != null) {
      Navigator.of(context).pop(result);
    }
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
                                        borderRadius: BorderRadius.all(
                                          Radius.circular(0.0),
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
                                        borderRadius: BorderRadius.all(
                                          Radius.circular(0.0),
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
                                        borderRadius: BorderRadius.all(
                                          Radius.circular(0.0),
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
                                        borderRadius: BorderRadius.all(
                                          Radius.circular(0.0),
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
