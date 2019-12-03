import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_svg/flutter_svg.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:flutter_webview_plugin/flutter_webview_plugin.dart';
import 'package:intl/intl.dart';
import 'package:playfantasy/action_utils/action_util.dart';
import 'package:playfantasy/appconfig.dart';
import 'package:playfantasy/commonwidgets/color_button.dart';
// import 'package:playfantasy/commonwidgets/webview_scaffold.dart';
import 'package:playfantasy/deposit/initpay.dart';
import 'package:playfantasy/modal/analytics.dart';
import 'package:playfantasy/utils/apiutil.dart';
import 'package:playfantasy/utils/httpmanager.dart';
import 'package:playfantasy/utils/stringtable.dart';
import 'package:playfantasy/deposit/transactionfailed.dart';
import 'package:playfantasy/commonwidgets/scaffoldpage.dart';
import 'package:playfantasy/redux/actions/loader_actions.dart';
import 'package:playfantasy/commonwidgets/fantasypageroute.dart';
import 'package:playfantasy/utils/analytics.dart';
import 'package:playfantasy/utils/maskedTextController.dart';
import 'package:playfantasy/utils/MaskedTextInputFormatter.dart';
import 'cardpayment.dart';

class ChoosePaymentMode extends StatefulWidget {
  final int amount;
  final String url;
  final String promoCode;
  final double bonusAmount;
  final bool expandPreferredMethod;
  final Map<String, dynamic> paymentMode;

  ChoosePaymentMode(
      {this.amount,
      this.bonusAmount,
      this.promoCode,
      this.url,
      this.paymentMode,
      this.expandPreferredMethod});

  @override
  ChoosePaymentModeState createState() => ChoosePaymentModeState();
}

class ChoosePaymentModeState extends State<ChoosePaymentMode> {
  String cookie;
  String _selectedPaymentModeType = "";
  List<dynamic> paymentModesListData;

  bool bWaitForCookieset = true;
  bool lastPaymentExpanded = false;
  final flutterWebviewPlugin = FlutterWebviewPlugin();
  static const razorpay_platform =
      const MethodChannel('com.algorin.pf.razorpay');
  static const techprocess_platform =
      const MethodChannel('com.algorin.pf.techprocess');
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

  TapGestureRecognizer termsGesture = TapGestureRecognizer();
  GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  Map<String, dynamic> razorpayPayload;
  Map<String, dynamic> techProcessPayload;
  Map<String, dynamic> initPayPayload;
  Map<String, dynamic> paymentPayload;
  /* Card payment UI */
  final _formKey = new GlobalKey<FormState>();
  TextEditingController cformNameOnCardController = TextEditingController();
  TextEditingController cformCVVController = TextEditingController();
  TextEditingController cformCardNumberController = TextEditingController();
  TextEditingController cformExpDateController = TextEditingController();
  String cformNameOnTheCard = "";
  String cformCVV = "";
  String cformCardNumber = "";
  String cformExpMonth = "";
  String cformExpYear = "";
  String cformExpDate = "";
  bool cFormIsValidDateEntered = false;
  String cformCardImagePath = " ";
  bool cformSaveCardDetails = false;
  bool cformObscureCVV = true;
  FocusNode cformCVVFocusnode = FocusNode();
  FocusNode cformExpDateFocusnode = FocusNode();
  FocusNode cformNameFocusnode = FocusNode();
  FocusNode cformCardNumberFocusnode = FocusNode();
  final paymentCardWidgetDataKey = new GlobalKey();

  @override
  void initState() {
    super.initState();
    setPaymentModeList();
    lastPaymentExpanded = widget.expandPreferredMethod;
    cformControllerListener();
    try {
      flutterWebviewPlugin.launch(
        BaseUrl().apiUrl + ApiUtil.COOKIE_PAGE,
        hidden: true,
      );
    } catch (e) {}

    razorpay_platform.setMethodCallHandler(myUtilsHandler);
    techprocess_platform.setMethodCallHandler(myUtilsHandler);
    if (Platform.isIOS) {
      initRazorpayNativePlugin();
    }

    termsGesture.onTap = () {
      _launchStaticPage("T&C");
    };

    webengagePaymentModeInitEvent();
    Event event = Event(name: "payment_mode_screen");
    event.setDepositAmount(widget.amount);
    event.setFirstDeposit(widget.paymentMode["isFirstDeposit"]);
    event.setFLEM(getFLEM());
    event.setPromoCode(widget.promoCode);

    AnalyticsManager().addEvent(event);
  }

  int getFLEM() {
    return (firstNameController.text == "" ? 1000 : 2000) +
        (lastNameController.text == "" ? 100 : 200) +
        (widget.paymentMode["email"] == "" ||
                widget.paymentMode["email"] == null ||
                widget.paymentMode["email"].toString().endsWith("@howzat.com")
            ? (emailController.text == "" ? 10 : 20)
            : 20) +
        (widget.paymentMode["mobile"] == "" ||
                widget.paymentMode["mobile"] == null ||
                widget.paymentMode["mobile"] == "9876543210"
            ? (phoneController.text == "" ? 1 : 2)
            : 2);
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
    Map<String, dynamic> screenAttributedata = Map();
    screenAttributedata["depositAmount"] = widget.amount;
    screendata["data"] = screenAttributedata;
    AnalyticsManager.webengageAddScreenData(screendata);
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
                "Payment cancelled please retry transaction. In case your money has been deducted, please contact support team!",
                context);
          } else {
            ActionUtil().showMsgOnTop(
                "Payment cancelled please retry transaction. In case your money has been deducted, please contact customer support team!",
                context);
          }
        }
        break;
      case 'onTechProcessPaymentSuccess':
        onTechProcessSuccessResponse(methodCall.arguments);
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
        event.setDepositAmount(widget.amount);
        event.setModeOptionId(response["modeOptionId"]);
        event.setFirstDeposit(razorpayPayload["isFirstDeposit"]);
        event.setGatewayId(int.parse(razorpayPayload["gatewayId"].toString()));
        event.setPromoCode(widget.promoCode);
        event.setOrderId(response["orderId"] == null
            ? razorpayPayload["orderId"]
            : response["orderId"]);

        AnalyticsManager().addEvent(event);

        if (response["orderId"] == null) {
          ActionUtil().showMsgOnTop(
              "Payment cancelled please retry transaction. In case your money has been deducted, please contact customer support team!",
              context);
        } else {
          _showTransactionFailed(response);
          branchEventTransactionFailed(response);
          webengageEventTransactionFailed(response);
        }
      } else {
        Event event = Event(name: "pay_success");
        event.setDepositAmount(widget.amount);
        event.setModeOptionId(response["modeOptionId"]);
        event.setFirstDeposit(razorpayPayload["isFirstDeposit"]);
        event.setGatewayId(int.parse(response["gatewayId"].toString()));
        event.setPromoCode(widget.promoCode);
        event.setOrderId(response["orderId"]);
        event.setUserBalance(
          response["withdrawable"].toDouble() +
              response["nonWithdrawable"].toDouble() +
              response["depositBucket"].toDouble(),
        );

        AnalyticsManager().addEvent(event);

        branchEventTransactionSuccess(response);
        webengageEventTransactionSuccess(response);
        Navigator.of(context).pop(res.body);
      }
    }).whenComplete(() {
      showLoader(false);
    });
  }

  onTechProcessSuccessResponse(String payload) {
    showLoader(false);
    http.Request req = http.Request(
        "POST", Uri.parse(BaseUrl().apiUrl + ApiUtil.TECHPROCESS_SUCCESS_PAY));
    req.body = payload;
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
        event.setDepositAmount(widget.amount);
        event.setModeOptionId(response["modeOptionId"]);
        event.setFirstDeposit(techProcessPayload["isFirstDeposit"]);
        event.setGatewayId(
            int.parse(techProcessPayload["gatewayId"].toString()));
        event.setPromoCode(widget.promoCode);
        event.setOrderId(response["orderId"] == null
            ? techProcessPayload["orderId"]
            : response["orderId"]);

        AnalyticsManager().addEvent(event);
        if (response["orderId"] == null) {
          ActionUtil().showMsgOnTop(
              "Payment cancelled please retry transaction. In case your money has been deducted, please contact customer support team!",
              context);
        } else {
          _showTransactionFailed(response);
          branchEventTransactionFailed(response);
          webengageEventTransactionFailed(response);
        }
      } else {
        Event event = Event(name: "pay_success");
        event.setDepositAmount(widget.amount);
        event.setModeOptionId(response["modeOptionId"]);
        event.setFirstDeposit(techProcessPayload["isFirstDeposit"]);
        event.setGatewayId(int.parse(response["gatewayId"].toString()));
        event.setPromoCode(widget.promoCode);
        event.setOrderId(response["orderId"]);
        event.setUserBalance(
          response["withdrawable"].toDouble() +
              response["nonWithdrawable"].toDouble() +
              response["depositBucket"].toDouble(),
        );

        AnalyticsManager().addEvent(event);
        branchEventTransactionSuccess(response);
        webengageEventTransactionSuccess(response);
        Navigator.of(context).pop(res.body);
      }
    }).whenComplete(() {
      showLoader(false);
    });
  }

  setPaymentModeList() {
    paymentModesListData =
        widget.paymentMode["choosePayment"]["paymentInfo"]["paymentTypes"];
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
          int i = 0;
          (widget.paymentMode["choosePayment"]["paymentInfo"][type["type"]]
                  as List)
              .forEach((infoType) {
            if (infoType["name"] == lastPaymentArray["paymentOption"]) {
              selectedPaymentMethod[type["type"]] = widget
                  .paymentMode["choosePayment"]["paymentInfo"][type["type"]][i];
              lastPaymentMethod = infoType;
              bLastTransactionFound = true;
            }
            i++;
          });
          if (!bLastTransactionFound) {
            selectedPaymentMethod[type["type"]] = widget
                .paymentMode["choosePayment"]["paymentInfo"][type["type"]][0];
          }
        } else {
          selectedPaymentMethod[type["type"]] = widget
              .paymentMode["choosePayment"]["paymentInfo"][type["type"]][0];
        }
      } else {
        selectedPaymentMethod[type["type"]] =
            widget.paymentMode["choosePayment"]["paymentInfo"][type["type"]][0];
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

  /** Card Payment UI*/
  validateTheExpireDate(String date) {
    String value = date.toString();
    var mnthlst = new List(12);
    mnthlst = [
      "01",
      "02",
      "03",
      "04",
      "05",
      "06",
      "07",
      "08",
      "09",
      "10",
      "11",
      "12"
    ];
    if (value.isEmpty) {
      return "Enter a valid date";
    } else {
      if (!mnthlst.contains(cformExpMonth)) {
        return "Enter  a valid month";
      } else {
        String userEnteredYear = cformExpYear.toString();
        if (userEnteredYear.length == 4 &&
            !userEnteredYear.contains(".") &&
            !userEnteredYear.contains(",") &&
            !userEnteredYear.contains("-")) {
          userEnteredYear.replaceAll(new RegExp(r'[^\w\s]+'), '');
          userEnteredYear.split(" ").join("");
          String patttern = r'[0-9]*$';
          RegExp regExp = new RegExp(patttern);
          if (regExp.hasMatch(userEnteredYear)) {
            cFormIsValidDateEntered = true;
            return null;
          } else {
            return "Enter a valid year";
          }
        } else {
          return "Enter a valid year";
        }
      }
    }
  }

  bool isNumeric(String s) {
    if (s == null) {
      return false;
    }
    return double.parse(s) != null;
  }

  cformControllerListener() {
    cformExpDateController.addListener(() {
      setState(() {
        cformExpDate = cformExpDateController.text;
        cformExpMonth = cformExpDate.split("/")[0];
        cformExpYear = cformExpDate.split("/")[1];
        cformExpYear = "20" + cformExpYear;
      });
    });
    cformNameOnCardController.addListener(() {
      setState(() {
        cformNameOnTheCard = cformNameOnCardController.text;
      });
    });
    cformCVVController.addListener(() {
      setState(() {
        cformCVV = cformCVVController.text;
      });
    });
    cformNameOnCardController.addListener(() {
      setState(() {
        cformExpDate = cformNameOnCardController.text;
      });
    });
    cformCardNumberController.addListener(() {
      List<String> visa = ["4"];
      List<String> americanExpress = ["34", "37"];
      List<String> discover = [
        "6011",
        "622126",
        "622925",
        "644",
        "645",
        "648" "649",
        "65"
      ];
      List<String> mastercard = [
        "51",
        "55",
        "54",
        "52",
        "2221",
        "2229",
        "223",
        "229",
        "23",
        "26",
        "270",
        "271",
        "2720"
      ];
      setState(() {
        cformCardNumber = cformCardNumberController.text
            .replaceAll(new RegExp(r"\s\b|\b\s"), "");
      });
      if (cformCardNumber.length > 0) {
        setState(() {
          cformCardImagePath =
              "https://d2cbroser6kssl.cloudfront.net/images/howzat/imgs/othercards.png";
        });
      }
      if (cformCardNumber.length < 1) {
        setState(() {
          cformCardImagePath = " ";
        });
      }

      if (cformCardNumber.startsWith("4")) {
        /*Visa Card*/
        setState(() {
          cformCardImagePath =
              "https://d2cbroser6kssl.cloudfront.net/images/howzat/imgs/visa.png";
        });
      }
      if (cformCardNumber.startsWith("34") ||
          cformCardNumber.startsWith("37")) {
        setState(() {
          cformCardImagePath =
              "https://d2cbroser6kssl.cloudfront.net/images/howzat/imgs/amex.png";
        });
      }
      for (var c in mastercard) {
        if (cformCardNumber.startsWith(c)) {
          setState(() {
            cformCardImagePath =
                "https://d2cbroser6kssl.cloudfront.net/images/howzat/imgs/mastercad.png";
          });
        }
      }

      for (var c in discover) {
        if (cformCardNumber.startsWith(c)) {
          setState(() {
            cformCardImagePath =
                "https://d2cbroser6kssl.cloudfront.net/images/howzat/imgs/discovery.png";
          });
        }
      }
    });
  }

  getCardFormErrorMessages(String value, String fieldType) {
    bool isValidDateEntered = false;
    switch (fieldType) {
      case "card":
        if (value.isEmpty) {
          return "Enter a valid card number";
        } else {
          return null;
        }
        break;
      case "date":
        if (cformCardNumber.isEmpty) {
          return null;
        } else {
          return validateTheExpireDate(value);
        }
        break;
      case "cvv":
        if (cformCardNumber.isEmpty ||
            cformExpDate.isEmpty ||
            !cFormIsValidDateEntered) {
          return null;
        } else {
          if (cformCVV.isEmpty) {
            return "Enter a valid CVV";
          } else {
            return null;
          }
        }
        break;
      case "name":
        if (cformCardNumber.isEmpty ||
            cformExpDate.isEmpty ||
            cformCVV.isEmpty) {
          return null;
        } else {
          if (cformNameOnTheCard.isEmpty) {
            return "Enter the  name on the card";
          } else {
            return null;
          }
        }
        break;
    }
  }

  bool validateUserInfo(String paymentType) {
    if (widget.paymentMode["isFirstDeposit"]) {
      Event event = Event(name: "pay_securely_validation");
      event.setDepositAmount(widget.amount);
      event.setModeOptionId(
          selectedPaymentMethod[paymentType]["info"]["modeOptionId"]);
      event.setFirstDeposit(widget.paymentMode["isFirstDeposit"]);
      event.setGatewayId(int.parse(
          selectedPaymentMethod[paymentType]["info"]["gatewayId"].toString()));
      event.setFLEM(getFLEM());
      event.setPromoCode(widget.promoCode);

      AnalyticsManager().addEvent(event);

      return true;
    } else if ((widget.paymentMode["first_name"] == null &&
        firstNameController.text == "")) {
      Event event = Event(name: "pay_securely_validation");
      event.setDepositAmount(widget.amount);
      event.setModeOptionId(
          selectedPaymentMethod[paymentType]["info"]["modeOptionId"]);
      event.setFirstDeposit(widget.paymentMode["isFirstDeposit"]);
      event.setGatewayId(int.parse(
          selectedPaymentMethod[paymentType]["info"]["gatewayId"].toString()));
      event.setFLEM(getFLEM());
      event.setErrorMessage("First name is required to proceed.");
      event.setPromoCode(widget.promoCode);

      AnalyticsManager().addEvent(event);

      ActionUtil().showMsgOnTop("First name is required to proceed.", context);
      return false;
    } else if (widget.paymentMode["mobile"] == null &&
        phoneController.text == "") {
      Event event = Event(name: "pay_securely_validation");
      event.setDepositAmount(widget.amount);
      event.setModeOptionId(
          selectedPaymentMethod[paymentType]["info"]["modeOptionId"]);
      event.setFirstDeposit(widget.paymentMode["isFirstDeposit"]);
      event.setGatewayId(int.parse(
          selectedPaymentMethod[paymentType]["info"]["gatewayId"].toString()));
      event.setFLEM(getFLEM());
      event.setErrorMessage("Mobile number is required to proceed.");
      event.setPromoCode(widget.promoCode);

      AnalyticsManager().addEvent(event);

      ActionUtil()
          .showMsgOnTop("Mobile number is required to proceed.", context);
      return false;
    } else if (widget.paymentMode["email"] == null &&
        emailController.text == "") {
      Event event = Event(name: "pay_securely_validation");
      event.setDepositAmount(widget.amount);
      event.setModeOptionId(
          selectedPaymentMethod[paymentType]["info"]["modeOptionId"]);
      event.setFirstDeposit(widget.paymentMode["isFirstDeposit"]);
      event.setGatewayId(int.parse(
          selectedPaymentMethod[paymentType]["info"]["gatewayId"].toString()));
      event.setFLEM(getFLEM());
      event.setErrorMessage("Email id is required to proceed.");
      event.setPromoCode(widget.promoCode);

      AnalyticsManager().addEvent(event);

      ActionUtil().showMsgOnTop("Email id is required to proceed.", context);
      return false;
    } else {
      Event event = Event(name: "pay_securely_validation");
      event.setDepositAmount(widget.amount);
      event.setModeOptionId(
          selectedPaymentMethod[paymentType]["info"]["modeOptionId"]);
      event.setFirstDeposit(widget.paymentMode["isFirstDeposit"]);
      event.setGatewayId(int.parse(
          selectedPaymentMethod[paymentType]["info"]["gatewayId"].toString()));
      event.setFLEM(getFLEM());
      event.setPromoCode(widget.promoCode);

      AnalyticsManager().addEvent(event);

      return true;
    }
  }

  clearCardPlaceholderDetails() {
    cformNameOnTheCard = "";
    cformCVV = null;
    cformCardNumber = "";
    cformExpMonth = "";
    cformExpYear = "";
    cformExpDate = "";
    cFormIsValidDateEntered = false;
    cformCardImagePath = " ";
    cformSaveCardDetails = false;
    cformNameOnCardController.text = " ";
    cformCVVController.text = '';
    cformCardNumberController.text = " ";
    cformExpDateController.text = " ";
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
          ? emailController.text == ""
              ? "${widget.paymentMode["mobile"]}@howzat.com"
              : emailController.text
          : widget.paymentMode["email"],
      "phone": widget.paymentMode["mobile"] == null
          ? phoneController.text == "" ? "9876543210" : phoneController.text
          : widget.paymentMode["mobile"],
      "last_name": widget.paymentMode["last_name"] == null
          ? lastNameController.text == "" ? "User" : lastNameController.text
          : widget.paymentMode["last_name"],
      "first_name": widget.paymentMode["first_name"] == null
          ? firstNameController.text == "" ? "Howzat" : firstNameController.text
          : widget.paymentMode["first_name"],
      "updateEmail": widget.paymentMode["email"] == null,
      "updateMobile": widget.paymentMode["mobile"] == null,
      "updateName": widget.paymentMode["firstName"] == null ||
          widget.paymentMode["lastName"] == null,
      "isFirstDeposit": widget.paymentMode["isFirstDeposit"],
      "native": true,
    };

    paymentPayload = payload;

    Event event = Event(name: "pay_securely");
    event.setDepositAmount(widget.amount);
    event.setModeOptionId(payload["modeOptionId"]);
    event.setFirstDeposit(widget.paymentMode["isFirstDeposit"]);
    event.setGatewayId(int.parse(payload["gatewayId"].toString()));
    event.setFLEM(getFLEM());
    event.setPromoCode(widget.promoCode);

    AnalyticsManager().addEvent(event);

    if (payload["first_name"] == "Howzat" ||
        payload["last_name"] == "User" ||
        payload["phone"] == "9876543210" ||
        payload["email"] == "${widget.paymentMode["mobile"]}@howzat.com") {
      payload["updateEmail"] = false;
      payload["updateMobile"] = false;
      payload["updateName"] = false;
    }
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
    if (paymentModeDetails["info"]["gateway"] == "TECHPROCESS_SEAMLESS" &&
        paymentModeDetails["info"]["isSeamless"]) {
      var dateNow = new DateTime.now();
      var formatter = new DateFormat('dd-MM-yyyy');
      String formattedDate = formatter.format(dateNow);
      techProcessPayload = payload;
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
            "userId": widget.paymentMode["user_id"].toString(),
            "date": formattedDate,
            "merchantIdentifier": response["merchantIdentifier"],
            "extra_public_key": response["tpExtraPublicKey"],
            "tp_nameOnTheCard": cformNameOnTheCard,
            "tp_expireYear": cformExpYear,
            "tp_expireMonth": cformExpMonth,
            "tp_cvv": cformCVV,
            "tp_cardNumber": cformCardNumber,
            "tp_instrumentToken": "",
            "cardDataCapturingRequired": true
          });
        } else {
          ActionUtil().showMsgOnTop("Opps!! Try again later.", context);
        }
      }).whenComplete(() {
        showLoader(false);
      });
    } else if (paymentModeDetails["info"]["isSeamless"]) {
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
        } else {}
      }).whenComplete(() {
        showLoader(false);
      });
    } else {
      initPayPayload = payload;
      initPayment(
          BaseUrl().apiUrl + ApiUtil.INIT_PAYMENT + querParamString, payload);
    }
  }

  webEngagePaymentInitEvent(Map<String, dynamic> paymentModeDetails) {
    Map<dynamic, dynamic> eventdata = new Map();
    eventdata["eventName"] = "PAYMENT_INIT_FROM_PAYMENTMODEPAGE";
    eventdata["data"] = paymentModeDetails;
    AnalyticsManager.trackEventsWithAttributes(eventdata);
  }

  initPayment(String url, Map<String, dynamic> payload) async {
    final result = await Navigator.of(context).push(
      FantasyPageRoute(
        routeSettings: RouteSettings(name: "InitPay"),
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
          "Declined".toLowerCase()) {
        _showTransactionFailed(response);
        branchEventTransactionFailed(response);
        webengageEventTransactionFailed(response);

        try {
          Event event = Event(name: "pay_failed");
          event.setDepositAmount(widget.amount);
          event.setModeOptionId(response["modeOptionId"]);
          event.setFirstDeposit(response["firstDepositor"] != "false");
          event.setGatewayId(int.parse(payload["gatewayId"].toString()));
          event.setPromoCode(widget.promoCode);
          event.setOrderId(response["orderId"]);

          AnalyticsManager().addEvent(event);
        } catch (e) {
          print(e);
        }
      } else {
        try {
          Event event = Event(name: "pay_success");
          event.setDepositAmount(widget.amount);
          event.setModeOptionId(response["modeOptionId"]);
          event.setFirstDeposit(response["firstDepositor"] != "false");
          event.setUserBalance(
            double.parse(response["withdrawable"]) +
                double.parse(response["nonWithdrawable"]) +
                double.parse(response["depositBucket"]),
          );
          event.setGatewayId(int.parse(payload["gatewayId"].toString()));
          event.setPromoCode(widget.promoCode);
          event.setOrderId(response["orderId"]);

          AnalyticsManager().addEvent(event);
        } catch (e) {
          print(e);
        }
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
          Event event = Event(name: "pay_failed_retry");
          event.setDepositAmount(widget.amount);
          event.setModeOptionId(paymentPayload["modeOptionId"]);
          event.setFirstDeposit(transactionResult["firstDepositor"] != "false");
          event.setPromoCode(widget.promoCode);
          event.setOrderId(transactionResult["orderId"]);

          AnalyticsManager().addEvent(event);

          Navigator.of(context).pop();
        }, () {
          Event event = Event(name: "pay_failed_cancel");
          event.setDepositAmount(widget.amount);
          event.setModeOptionId(paymentPayload["modeOptionId"]);
          event.setFirstDeposit(transactionResult["firstDepositor"] != "false");
          event.setPromoCode(widget.promoCode);
          event.setOrderId(transactionResult["orderId"]);

          AnalyticsManager().addEvent(event);

          Navigator.of(context).pop();
          Navigator.of(context).pop(json.encode(transactionResult));
        });
      },
    );
  }

  Form getCardPaymentFormWidget(String paymentType) {
    return Form(
        key: _formKey,
        child: Column(
          children: <Widget>[
            Padding(
              padding: EdgeInsets.only(top: 1.5, bottom: 5.0),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Container(
                        height: 54.0,
                        child: TextFormField(
                            controller: cformCardNumberController,
                            focusNode: cformCardNumberFocusnode,
                            inputFormatters: [
                              MaskedTextInputFormatter(
                                mask: 'xxxx xxxx xxxx xxxx xxxx',
                                separator: ' ',
                              ),
                            ],
                            onFieldSubmitted: (value) {
                              cformCardNumberFocusnode.unfocus();
                              FocusScope.of(context)
                                  .requestFocus(cformExpDateFocusnode);
                            },
                            decoration: InputDecoration(
                              labelText: 'Card Number',
                              counterText: "",
                              helperText: ' ',
                              suffixIcon: Padding(
                                padding:
                                    const EdgeInsetsDirectional.only(end: 8.0),
                                child: Image.network(cformCardImagePath,
                                    height: 1, width: 1),
                              ),
                              contentPadding: EdgeInsets.all(13.0),
                              border: OutlineInputBorder(
                                borderSide: BorderSide(
                                  color: Colors.black38,
                                ),
                              ),
                            ),
                            validator: (String value) {
                              return getCardFormErrorMessages(value, "card");
                            },
                            keyboardType: TextInputType.number,
                            maxLength: 23)),
                  )
                ],
              ),
            ),
            Padding(
                padding: EdgeInsets.only(top: 5.0, bottom: 5.0),
                child: Row(
                  children: <Widget>[
                    Expanded(
                        flex: 8,
                        child: Container(
                            height: 54.0,
                            child: TextFormField(
                              controller: cformExpDateController,
                              focusNode: cformExpDateFocusnode,
                              inputFormatters: [
                                MaskedTextInputFormatter(
                                  mask: 'xx/xx',
                                  separator: '/',
                                ),
                              ],
                              onFieldSubmitted: (value) {
                                cformExpDateFocusnode.unfocus();
                                FocusScope.of(context)
                                    .requestFocus(cformCVVFocusnode);
                              },
                              decoration: const InputDecoration(
                                labelText: 'Expiry Date',
                                hintText: "MM/YY",
                                helperText: ' ',
                                counterText: "",
                                contentPadding: EdgeInsets.all(13.0),
                                border: OutlineInputBorder(
                                  borderSide: BorderSide(
                                    color: Colors.black38,
                                  ),
                                ),
                              ),
                              validator: (String value) {
                                return getCardFormErrorMessages(value, "date");
                              },
                              keyboardType: TextInputType.number,
                              maxLength: 6,
                            ))),
                    Expanded(
                      flex: 1,
                      child: Container(),
                    ),
                    Expanded(
                      flex: 8,
                      child: Container(
                          height: 54.0,
                          child: TextFormField(
                              controller: cformCVVController,
                              focusNode: cformCVVFocusnode,
                              inputFormatters: <TextInputFormatter>[
                                WhitelistingTextInputFormatter.digitsOnly
                              ],
                              onFieldSubmitted: (value) {
                                cformCVVFocusnode.unfocus();
                                FocusScope.of(context)
                                    .requestFocus(cformNameFocusnode);
                              },
                              decoration: const InputDecoration(
                                labelText: 'CVV',
                                counterText: "",
                                helperText: ' ',
                                contentPadding: EdgeInsets.all(13.0),
                                fillColor: Colors.blue,
                                border: OutlineInputBorder(
                                  borderSide: BorderSide(
                                    color: Colors.black38,
                                  ),
                                ),
                              ),
                              validator: (String value) {
                                return getCardFormErrorMessages(value, "cvv");
                              },
                              maxLength: 4,
                              obscureText: cformObscureCVV,
                              keyboardType: TextInputType.number)),
                    )
                  ],
                )),
            Padding(
              padding: EdgeInsets.only(top: 5.0, bottom: 5.0),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Container(
                        height: 54.0,
                        child: TextFormField(
                          controller: cformNameOnCardController,
                          focusNode: cformNameFocusnode,
                          maxLength: 38,
                          onFieldSubmitted: (value) {
                            cformCVVFocusnode.unfocus();
                          },
                          decoration: const InputDecoration(
                            labelText: "Card Holder's Name",
                            counterText: "",
                            helperText: ' ',
                            contentPadding: EdgeInsets.all(13.0),
                            border: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: Colors.black38,
                              ),
                            ),
                          ),
                          validator: (String value) {
                            return getCardFormErrorMessages(value, "name");
                          },
                        )),
                  )
                ],
              ),
            ),
            // Padding(
            //     padding: EdgeInsets.only(top: 16.0),
            //     child: Row(children: <Widget>[
            //       Checkbox(
            //         value: cformSaveCardDetails,
            //         onChanged: (bool value) {
            //           setState(() {
            //             cformSaveCardDetails = value;
            //           });
            //         },
            //       ),
            //       Text("Securely  save this  card")
            //     ])),
            Padding(
              padding: EdgeInsets.only(top: 8.0),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Container(
                      height: 48.0,
                      child: ColorButton(
                        onPressed: () {
                          if (_formKey.currentState.validate()) {
                            if (validateUserInfo(paymentType)) {
                              onPaySecurely(selectedPaymentMethod[paymentType],
                                  paymentType);
                            }
                          }
                        },
                        child: Text(
                          strings.get("PAY_SECURELY").toUpperCase(),
                          style:
                              Theme.of(context).primaryTextTheme.title.copyWith(
                                    color: Colors.white,
                                  ),
                        ),
                      ),
                    ),
                  )
                ],
              ),
            ),
          ],
        ));
  }

  getLastPaymentWidget() {
    /*This is for last payment method-Both expandable and non expandable*/
    List<Widget> items = [];
    int i = 0;
    Map<String, dynamic> lastPaymentArray = widget.paymentMode["choosePayment"]
                ["userInfo"]["lastPaymentArray"] !=
            null
        ? widget.paymentMode["choosePayment"]["userInfo"]["lastPaymentArray"][0]
        : {};

    widget.paymentMode["choosePayment"]["paymentInfo"]["paymentTypes"]
        .forEach((type) {
      /* Check for detailRequired is true any one of bank */
      bool showCardDetailsUI = false;
      (widget.paymentMode["choosePayment"]["paymentInfo"][type["type"]])
          .forEach((bankType) {
        if (bankType["info"]["detailRequired"]) {
          showCardDetailsUI = true;
        }
      });
      if (widget.paymentMode["choosePayment"]["paymentInfo"][type["type"]]
                  .length ==
              1 &&
          lastPaymentArray["paymentType"] == type["type"] &&
          !showCardDetailsUI) {
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
                    if (validateUserInfo(type["type"])) {
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
          lastPaymentArray["paymentType"] == type["type"] &&
          !showCardDetailsUI) {
        items.add(
          ExpansionPanelList(
            expansionCallback: (int index, bool isExpanded) {
              Event event = Event(name: "pay_mode_select");
              event.setDepositAmount(widget.amount);
              event.setFirstDeposit(widget.paymentMode["isFirstDeposit"]);
              event.setFLEM(getFLEM());
              event.setPayModeExpanded(isExpanded);
              event.setPaymentType(type["type"]);
              event.setPromoCode(widget.promoCode);

              AnalyticsManager().addEvent(event);

              setState(() {
                lastPaymentExpanded = !lastPaymentExpanded;
                _selectedPaymentModeType = " ";
              });

              FocusScope.of(context).requestFocus(new FocusNode());
            },
            children: [
              ExpansionPanel(
                isExpanded: lastPaymentExpanded,
                canTapOnHeader: true,
                headerBuilder: (context, isExpanded) {
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Padding(
                            padding: EdgeInsets.only(left: 16.0),
                            child: SvgPicture.network(
                              type["logo"],
                              width: 24.0,
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.only(left: 8.0),
                            child: Text(type["label"]),
                          ),
                        ],
                      )
                    ],
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
                              Event event = Event(name: "pay_option_select");
                              event.setDepositAmount(widget.amount);
                              event.setModeOptionId(
                                  value["info"]["modeOptionId"]);
                              event.setGatewayId(int.parse(
                                  value["info"]["gatewayId"].toString()));
                              event.setFirstDeposit(
                                  widget.paymentMode["isFirstDeposit"]);
                              event.setFLEM(getFLEM());
                              event.setPaymentOptionType(value["name"]);
                              event.setPromoCode(widget.promoCode);

                              AnalyticsManager().addEvent(event);

                              setState(() {
                                lastPaymentMethod = value;
                                selectedPaymentMethod[type["type"]] = value;
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
                                    if (validateUserInfo(type["type"])) {
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
      } else if (lastPaymentArray["paymentType"] == type["type"] &&
          showCardDetailsUI) {
        items.add(
          ExpansionPanelList(
            expansionCallback: (int index, bool isExpanded) {
              Event event = Event(name: "pay_mode_select");
              event.setDepositAmount(widget.amount);
              event.setFirstDeposit(widget.paymentMode["isFirstDeposit"]);
              event.setFLEM(getFLEM());
              event.setPayModeExpanded(isExpanded);
              event.setPaymentType(type["type"]);
              event.setPromoCode(widget.promoCode);

              AnalyticsManager().addEvent(event);
              clearCardPlaceholderDetails();
              setState(() {
                lastPaymentExpanded = !lastPaymentExpanded;
                _selectedPaymentModeType = " ";
              });
              FocusScope.of(context).requestFocus(new FocusNode());
            },
            children: [
              ExpansionPanel(
                isExpanded: lastPaymentExpanded,
                canTapOnHeader: true,
                headerBuilder: (context, isExpanded) {
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Padding(
                            padding: EdgeInsets.only(left: 16.0),
                            child: SvgPicture.network(
                              type["logo"],
                              width: 24.0,
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.only(left: 8.0),
                            child: Text(type["label"]),
                          ),
                        ],
                      )
                    ],
                  );
                },
                body: Padding(
                    padding:
                        EdgeInsets.only(left: 16.0, bottom: 16.0, right: 16.0),
                    child: lastPaymentExpanded
                        ? getCardPaymentFormWidget(type["type"])
                        : Container()),
              ),
            ],
          ),
        );
      }
    });
    return items;
  }

  getExpandablePaymentModeBody(dynamic paymentType) {
    return Padding(
      padding: EdgeInsets.only(left: 16.0, bottom: 16.0, right: 16.0),
      child: Column(
        children: <Widget>[
          Row(
            children: <Widget>[
              DropdownButton(
                onChanged: (value) {
                  Event event = Event(name: "pay_option_select");
                  event.setDepositAmount(widget.amount);
                  event.setModeOptionId(value["info"]["modeOptionId"]);
                  event.setGatewayId(
                      int.parse(value["info"]["gatewayId"].toString()));
                  event.setFirstDeposit(widget.paymentMode["isFirstDeposit"]);
                  event.setFLEM(getFLEM());
                  event.setPaymentOptionType(value["name"]);
                  event.setPromoCode(widget.promoCode);

                  AnalyticsManager().addEvent(event);

                  setState(() {
                    selectedPaymentMethod[paymentType["type"]] = value;
                  });
                },
                value: selectedPaymentMethod[paymentType["type"]],
                items: (widget.paymentMode["choosePayment"]["paymentInfo"]
                        [paymentType["type"]] as List)
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
                        if (validateUserInfo(paymentType["type"])) {
                          onPaySecurely(
                              selectedPaymentMethod[paymentType["type"]],
                              paymentType["type"]);
                        }
                      },
                      child: Text(
                        strings.get("PAY_SECURELY").toUpperCase(),
                        style:
                            Theme.of(context).primaryTextTheme.title.copyWith(
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
    );
  }

  getExpandablePaymentWidgetHeader(
      dynamic paymentTypeData, dynamic selectedPaymentData) {
    return Container(
        child: Column(
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: FlatButton(
                padding: EdgeInsets.all(0.0),
                onPressed: () {
                  const twentyMillis = const Duration(milliseconds: 50);
                  new Timer(twentyMillis,
                      () => Scrollable.ensureVisible(paymentCardWidgetDataKey.currentContext));
                  if (paymentTypeData != null) {
                    Event event = Event(name: "pay_mode_select");
                    event.setDepositAmount(widget.amount);
                    event.setFirstDeposit(widget.paymentMode["isFirstDeposit"]);
                    event.setFLEM(getFLEM());
                    event.setPayModeExpanded(
                        _selectedPaymentModeType == paymentTypeData["type"]);
                    event.setPaymentType(paymentTypeData["type"]);
                    event.setPromoCode(widget.promoCode);

                    AnalyticsManager().addEvent(event);
                    setState(() {
                      lastPaymentExpanded = false;
                      clearCardPlaceholderDetails();
                    });
                    if (_selectedPaymentModeType == paymentTypeData["type"]) {
                      setState(() {
                        _selectedPaymentModeType = " ";
                      });
                    } else {
                      setState(() {
                        _selectedPaymentModeType = paymentTypeData["type"];
                        paymentModesListData.remove(selectedPaymentData);
                        paymentModesListData.insert(0, selectedPaymentData);
                      });
                    }
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
                              paymentTypeData["logo"],
                              width: 24.0,
                            ),
                            Padding(
                              padding: EdgeInsets.only(left: 8.0),
                              child: Text(
                                paymentTypeData["label"],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.expand_more,
                        color: Colors.black26,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        _selectedPaymentModeType == paymentTypeData["type"]
            ? getExpandablePaymentModeBody(paymentTypeData)
            : Container()
      ],
    ));
  }

  getExpandableCardPaymentWidgetHeader(
      dynamic paymentTypeData, dynamic selectedPaymentData) {
    return Container(
        child: Column(
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: FlatButton(
                padding: EdgeInsets.all(0.0),
                onPressed: () {
                   const twentyMillis = const Duration(milliseconds: 50);
                  new Timer(twentyMillis,
                      () => Scrollable.ensureVisible(paymentCardWidgetDataKey.currentContext));
                  if (paymentTypeData != null) {
                    Event event = Event(name: "pay_mode_select");
                    event.setDepositAmount(widget.amount);
                    event.setFirstDeposit(widget.paymentMode["isFirstDeposit"]);
                    event.setFLEM(getFLEM());
                    event.setPayModeExpanded(
                        _selectedPaymentModeType == paymentTypeData["type"]);
                    event.setPaymentType(paymentTypeData["type"]);
                    event.setPromoCode(widget.promoCode);
                    AnalyticsManager().addEvent(event);
                    setState(() {
                      lastPaymentExpanded = false;
                      clearCardPlaceholderDetails();
                    });
                    if (_selectedPaymentModeType == paymentTypeData["type"]) {
                      setState(() {
                        _selectedPaymentModeType = " ";
                      });
                    } else {
                      setState(() {
                        _selectedPaymentModeType = paymentTypeData["type"];
                        paymentModesListData.remove(selectedPaymentData);
                        paymentModesListData.insert(0, selectedPaymentData);
                      });
                    }
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
                              paymentTypeData["logo"],
                              width: 24.0,
                            ),
                            Padding(
                              padding: EdgeInsets.only(left: 8.0),
                              child: Text(
                                paymentTypeData["label"],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.expand_more,
                        color: Colors.black26,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        _selectedPaymentModeType == paymentTypeData["type"]
            ? Padding(
                padding: EdgeInsets.only(left: 16.0, bottom: 16.0, right: 16.0),
                child: Container(
                    child: getCardPaymentFormWidget(paymentTypeData["type"])))
            : Container()
      ],
    ));
  }

  getNonExpandableHeaderPaymentWidget(
      dynamic paymentTypeData, dynamic selectedPaymentData) {
    return Container(
      child: Row(
        children: <Widget>[
          Expanded(
            child: FlatButton(
              padding: EdgeInsets.all(0.0),
              onPressed: () {
                Event event = Event(name: "pay_mode_select");
                event.setDepositAmount(widget.amount);
                event.setFirstDeposit(widget.paymentMode["isFirstDeposit"]);
                event.setFLEM(getFLEM());
                event.setPayModeExpanded(
                    _selectedPaymentModeType == paymentTypeData["type"]);
                event.setPaymentType(paymentTypeData["type"]);
                event.setPromoCode(widget.promoCode);

                AnalyticsManager().addEvent(event);

                if (validateUserInfo(paymentTypeData["type"])) {
                  setState(() {
                    _selectedPaymentModeType = paymentTypeData["type"];
                    paymentModesListData.remove(selectedPaymentData);
                    paymentModesListData.insert(0, selectedPaymentData);
                  });
                  onPaySecurely(
                      widget.paymentMode["choosePayment"]["paymentInfo"]
                          [paymentTypeData["type"]][0],
                      paymentTypeData["type"]);
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
                            paymentTypeData["logo"],
                            width: 24.0,
                          ),
                          Padding(
                            padding: EdgeInsets.only(left: 8.0),
                            child: Text(
                              paymentTypeData["label"],
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
  }

  getAllExpandablePaymentModeWidgetList() {
    List<Widget> paymentModeWidgetItems = [];
    int i = 0;
    Map<String, dynamic> lastPaymentArray = widget.paymentMode["choosePayment"]
                ["userInfo"]["lastPaymentArray"] !=
            null
        ? widget.paymentMode["choosePayment"]["userInfo"]["lastPaymentArray"][0]
        : {};
    (paymentModesListData).forEach((type) {
      /* Check for detailRequired is true any one of bank */
      bool showCardDetailsUI = false;
      (widget.paymentMode["choosePayment"]["paymentInfo"][type["type"]])
          .forEach((bankType) {
        if (bankType["info"]["detailRequired"]) {
          showCardDetailsUI = true;
        }
      });
      bool isLastPaymentType = lastPaymentArray["paymentType"] == type["type"];
      int paymentBanksLength = widget
          .paymentMode["choosePayment"]["paymentInfo"][type["type"]].length;
      if (!isLastPaymentType) {
        if (i != 0) {
          paymentModeWidgetItems.add(
            Divider(height: 2.0),
          );
        }
        if (showCardDetailsUI && !isLastPaymentType) {
          paymentModeWidgetItems.add(getExpandableCardPaymentWidgetHeader(
              type, paymentModesListData[i]));
        }
        if (paymentBanksLength > 1 &&
            !isLastPaymentType &&
            !showCardDetailsUI) {
          paymentModeWidgetItems.add(
              getExpandablePaymentWidgetHeader(type, paymentModesListData[i]));
        }
        if (paymentBanksLength == 1 &&
            !showCardDetailsUI &&
            !isLastPaymentType) {
          paymentModeWidgetItems.add(getNonExpandableHeaderPaymentWidget(
              type, paymentModesListData[i]));
        }
      }
      i++;
    });
    return paymentModeWidgetItems;
  }

  getAllPayMentModeWidgets() {
    return Container(
      child: Card(
        elevation: 3.0,
        key: paymentCardWidgetDataKey,
        child: Column(
          children: getAllExpandablePaymentModeWidgetList(),
        ),
      ),
    );
  }

  getDepositeInfoCardWidget() {
    final formatCurrency = NumberFormat.currency(
      locale: "hi_IN",
      symbol: strings.rupee,
      decimalDigits: 0,
    );
    return Card(
      child: Container(
        padding: EdgeInsets.all(16.0),
        child: (widget.promoCode != null && widget.promoCode.length > 0) &&
                widget.bonusAmount > 0
            ? Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Text("Deposit Amount"),
                        ],
                      ),
                      Padding(
                        padding: EdgeInsets.only(top: 4.0),
                        child: Row(
                          children: <Widget>[
                            Text(
                              formatCurrency.format(widget.amount),
                              style: Theme.of(context)
                                  .primaryTextTheme
                                  .display1
                                  .copyWith(
                                    color: Colors.black,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ],
                        ),
                      )
                    ],
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Column(
                            children: <Widget>[
                              Row(
                                children: <Widget>[
                                  Text("Bonus Code"),
                                ],
                              ),
                              Padding(
                                padding: EdgeInsets.only(top: 4.0),
                                child: DottedBorder(
                                  gap: 2,
                                  strokeWidth: 1,
                                  color: Colors.green,
                                  child: Container(
                                    // padding:
                                    //     EdgeInsets.symmetric(
                                    //   horizontal: 4.0,
                                    // ),
                                    child: Text(
                                      widget.promoCode,
                                      style: Theme.of(context)
                                          .primaryTextTheme
                                          .subtitle
                                          .copyWith(
                                            color: Colors.green,
                                          ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      )
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Column(
                            children: <Widget>[
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: <Widget>[
                                  Text("Total Benefits"),
                                ],
                              ),
                              Padding(
                                padding: EdgeInsets.only(top: 4.0),
                                child: DottedBorder(
                                  gap: 2,
                                  strokeWidth: 1,
                                  color: Colors.green,
                                  child: Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 20.0,
                                    ),
                                    child: Text(
                                      formatCurrency.format(widget.bonusAmount),
                                      style: Theme.of(context)
                                          .primaryTextTheme
                                          .subtitle
                                          .copyWith(
                                            color: Colors.green,
                                          ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      )
                    ],
                  ),
                ],
              )
            : Column(
                children: <Widget>[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Text("Deposit amount"),
                    ],
                  ),
                  Padding(
                    padding: EdgeInsets.only(top: 4.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Text(
                          formatCurrency.format(widget.amount),
                          style: Theme.of(context)
                              .primaryTextTheme
                              .display1
                              .copyWith(
                                color: Colors.black,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ],
                    ),
                  )
                ],
              ),
      ),
    );
  }

  getFLMEWidget() {
    return (!widget.paymentMode["isFirstDeposit"]) &&
            (widget.paymentMode["first_name"] == null ||
                widget.paymentMode["last_name"] == null ||
                widget.paymentMode["email"] == null ||
                widget.paymentMode["mobile"] == null)
        ? Card(
            elevation: 3.0,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
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
                ],
              ),
            ),
          )
        : Container();
  }

  getBottomNavigationBarWidget() {
    return Container(
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
                  style: Theme.of(context).primaryTextTheme.caption.copyWith(
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
                    style: Theme.of(context).primaryTextTheme.caption.copyWith(
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
    );
  }

  @override
  void dispose() {
    flutterWebviewPlugin.close();
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
      body: new GestureDetector(
        onTap: () {
          FocusScope.of(context).requestFocus(new FocusNode());
        },
        child: widget.paymentMode != null
            ? SingleChildScrollView(
                child: Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Column(
                    children: <Widget>[
                      getDepositeInfoCardWidget(),
                      getFLMEWidget(),
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
                      getAllPayMentModeWidgets()
                    ],
                  ),
                ),
              )
            : Container(),
      ),
      bottomNavigationBar: getBottomNavigationBarWidget(),
    );
  }
}
