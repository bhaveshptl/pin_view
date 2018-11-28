import 'dart:io';
import 'dart:convert';
import 'package:path/path.dart';
import 'package:async/async.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';
import 'package:playfantasy/appconfig.dart';

import 'package:playfantasy/utils/apiutil.dart';
import 'package:playfantasy/modal/withdraw.dart';
import 'package:playfantasy/utils/httpmanager.dart';
import 'package:playfantasy/utils/stringtable.dart';
import 'package:playfantasy/lobby/withdrawhistory.dart';
import 'package:playfantasy/commonwidgets/statedob.dart';
import 'package:playfantasy/utils/joincontesterror.dart';
import 'package:playfantasy/utils/sharedprefhelper.dart';
import 'package:playfantasy/profilepages/verification.dart';

class Withdraw extends StatefulWidget {
  @override
  WithdrawState createState() => WithdrawState();
}

class WithdrawState extends State<Withdraw> {
  File _panImage;
  File _addressImage;
  List<dynamic> _addressList = [];

  String mobile;
  String cookie = "";
  Withhdraw _withdrawData;
  bool _bIsOTPSent = false;
  int _selectedItemIndex = -1;
  bool _bIsKYCVerified = false;
  List<Widget> _messageList = [];
  bool _bIsMobileVerified = false;
  String _mobileVerificationError;
  bool _bShowImageUploadError = false;

  String _docName;
  String _verificationStatus;
  String _panVerificationStatus;
  String _addressVerificationStatus;
  String _selectedAddressDocType = "";

  final _formKey = new GlobalKey<FormState>();
  final _paytmFormKey = new GlobalKey<FormState>();
  final _bankMobileFormKey = new GlobalKey<FormState>();
  final _paytmMobileFormKey = new GlobalKey<FormState>();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  TextEditingController amountController = TextEditingController();
  TextEditingController acIFSCCodeController = TextEditingController();
  TextEditingController paytmAmountController = TextEditingController();
  TextEditingController accountNameController = TextEditingController();
  TextEditingController accountNumberController = TextEditingController();
  final TextEditingController _otpController = new TextEditingController();
  final TextEditingController _mobileController = new TextEditingController();

  @override
  void initState() {
    super.initState();
    authenticateWithdraw();
  }

  _setAddressList() async {
    http.Request req = http.Request(
      "GET",
      Uri.parse(
        BaseUrl.apiUrl + ApiUtil.KYC_DOC_LIST,
      ),
    );
    return HttpManager(http.Client())
        .sendRequest(req)
        .then((http.Response res) {
      if (res.statusCode >= 200 && res.statusCode <= 299) {
        List<dynamic> response = json.decode(res.body);
        setState(() {
          _addressList = response;
          _selectedAddressDocType = _addressList[0]["name"];
        });
      }
    });
  }

  authenticateWithdraw() async {
    http.Request req = http.Request(
      "GET",
      Uri.parse(
        BaseUrl.apiUrl + ApiUtil.AUTH_WITHDRAW,
      ),
    );
    return HttpManager(http.Client()).sendRequest(req).then(
      (http.Response res) {
        if (res.statusCode >= 200 && res.statusCode <= 299) {
          Map<String, dynamic> response = json.decode(res.body);
          setState(() {
            _bIsKYCVerified = true;
            _bIsMobileVerified = true;
            _withdrawData = Withhdraw.fromJson(response);
            initFormInputs();
          });
        } else if (res.statusCode == 401) {
          Map<String, dynamic> response = json.decode(res.body);

          if (response["error"].length > 0) {
            JoinContestError error = JoinContestError(response["error"]);
            if (error.isBlockedUser()) {
            } else {
              int errorCode = error.getErrorCode();
              switch (errorCode) {
                case 3:
                  showDialog(
                    context: _scaffoldKey.currentContext,
                    builder: (BuildContext context) {
                      return StateDob(
                        onSuccess: (String msg) {
                          _scaffoldKey.currentState.showSnackBar(SnackBar(
                            content: Text(msg),
                          ));
                          authenticateWithdraw();
                        },
                      );
                    },
                  );
                  break;
                case 6:
                  _setAddressList();
                  _setVerificationStatus(Withhdraw.fromJson(response["data"]));
                  break;
              }
            }
          }
        }
      },
    );
  }

  _setVerificationStatus(Withhdraw withdrawData) async {
    setState(() {
      _withdrawData = withdrawData;
    });

    mobile = _withdrawData.mobile != null ? _withdrawData.mobile : "";

    _mobileController.text = mobile;
    _bIsMobileVerified = _withdrawData.mobileVerification;

    _panVerificationStatus = _withdrawData.panVerification;
    _addressVerificationStatus = _withdrawData.addressVerification;
    _bIsKYCVerified = _withdrawData.panVerification == "VERIFIED" &&
        _withdrawData.addressVerification == "VERIFIED";
    _setDocVerificationStatus();
  }

  _setDocVerificationStatus() {
    String kycStatus = _panVerificationStatus;
    String addressStatus = _addressVerificationStatus;

    if (kycStatus == addressStatus) {
      _verificationStatus = kycStatus;
    } else {
      if (kycStatus == "DOC_REJECTED" || addressStatus == "DOC_REJECTED") {
        _verificationStatus = "DOC_REJECTED";
      } else if (kycStatus == "UNDER_REVIEW" ||
          addressStatus == "UNDER_REVIEW") {
        _verificationStatus = "UNDER_REVIEW";
      } else if (kycStatus == "DOC_SUBMITTED" ||
          addressStatus == "DOC_SUBMITTED") {
        _verificationStatus = "DOC_SUBMITTED";
      } else {
        _verificationStatus = "DOC_NOT_SUBMITTED";
      }
    }

    if (kycStatus == "DOC_SUBMITTED" || addressStatus == "DOC_SUBMITTED") {
      _messageList
          .add(_getMessageWidget(DocVerificationMessages.DOC_SUBMITTED));
    }

    if (kycStatus == "UNDER_REVIEW") {
      _messageList.add(_getMessageWidget(PanVerificationMessages.UNDER_REVIEW));
    } else if (kycStatus == "DOC_REJECTED") {
      _messageList.add(_getMessageWidget(PanVerificationMessages.DOC_REJECTED));
    } else if (kycStatus == "VERIFIED") {
      _messageList.add(_getMessageWidget(PanVerificationMessages.VERIFIED));
    }

    if (addressStatus == "UNDER_REVIEW") {
      _messageList
          .add(_getMessageWidget(AddressVerificationMessages.UNDER_REVIEW));
    } else if (addressStatus == "DOC_REJECTED") {
      _messageList
          .add(_getMessageWidget(AddressVerificationMessages.DOC_REJECTED));
    } else if (addressStatus == "VERIFIED") {
      _messageList.add(_getMessageWidget(AddressVerificationMessages.VERIFIED));
    }

    if (kycStatus == "VERIFIED") {
      _messageList.add(_getMessageWidget(DocVerificationMessages.VERIFIED));
    }
  }

  _getMessageWidget(String msg) {
    return Row(
      children: <Widget>[
        Expanded(
          child: Text(
            msg,
            textAlign: TextAlign.left,
          ),
        ),
      ],
    );
  }

  ExpansionPanel getMobileVerificationWidget(
      BuildContext context, int withdrawType) {
    return ExpansionPanel(
      isExpanded: _selectedItemIndex == 0,
      headerBuilder: (context, isExpanded) {
        return FlatButton(
          onPressed: () {
            setState(() {
              if (_selectedItemIndex == 0) {
                _selectedItemIndex = -1;
              } else {
                _selectedItemIndex = 0;
              }
            });
          },
          child: Padding(
            padding: const EdgeInsets.only(left: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Text(
                  strings.get("MOBILE"),
                ),
                _bIsMobileVerified
                    ? Icon(Icons.check_circle_outline)
                    : Icon(Icons.remove_circle_outline),
              ],
            ),
          ),
        );
      },
      body: Column(
        children: <Widget>[
          Divider(
            height: 2.0,
            color: Colors.black12,
          ),
          Form(
            key: withdrawType == 1 ? _bankMobileFormKey : _paytmMobileFormKey,
            child: !_bIsMobileVerified
                ? Column(
                    children: <Widget>[
                      ListTile(
                        leading: TextFormField(
                          controller: _mobileController,
                          keyboardType: TextInputType.phone,
                          decoration: InputDecoration(
                              labelText: "Enter mobile number",
                              hintText: "9999999999",
                              prefix: Padding(
                                padding: const EdgeInsets.only(right: 4.0),
                                child: Text("+91"),
                              )),
                        ),
                      ),
                      _bIsOTPSent
                          ? ListTile(
                              leading: TextFormField(
                                validator: (value) {
                                  if (value.isEmpty) {
                                    return 'Please enter OTP.';
                                  }
                                },
                                controller: _otpController,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  labelText: "Enter OTP",
                                ),
                              ),
                            )
                          : Container(),
                      _mobileVerificationError == null
                          ? Container()
                          : Padding(
                              padding:
                                  EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 8.0),
                              child: Row(
                                children: <Widget>[
                                  Text(
                                    _mobileVerificationError,
                                    style: TextStyle(
                                      color: Theme.of(context).errorColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                      Padding(
                        padding: const EdgeInsets.only(
                          top: 8.0,
                          left: 16.0,
                          right: 16.0,
                        ),
                        child: Row(
                          children: <Widget>[
                            Expanded(
                              child: Text(
                                "You will receive an OTP on this number. Please do not share an OTP with anyone.",
                                style: TextStyle(color: Colors.black54),
                              ),
                            ),
                          ],
                        ),
                      ),
                      ListTile(
                        leading: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: <Widget>[
                            FlatButton(
                              onPressed: () {
                                if (_bIsOTPSent) {
                                  if (withdrawType == 1
                                      ? _bankMobileFormKey.currentState
                                          .validate()
                                      : _paytmMobileFormKey.currentState
                                          .validate()) {
                                    _verifyOTP();
                                  }
                                } else {
                                  _sendOTP();
                                }
                              },
                              child: Text(
                                !_bIsOTPSent
                                    ? strings.get("SEND_OTP").toUpperCase()
                                    : strings.get("VERIFY").toUpperCase(),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  )
                : Column(
                    children: <Widget>[
                      ListTile(
                        leading: Text(
                          mobile.toString(),
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  ExpansionPanel getKYCVerificationWidget(BuildContext context) {
    return ExpansionPanel(
      isExpanded: _selectedItemIndex == 1,
      headerBuilder: (context, isExpanded) {
        return FlatButton(
          onPressed: () {
            setState(() {
              if (_selectedItemIndex == 1) {
                _selectedItemIndex = -1;
              } else {
                _selectedItemIndex = 1;
              }
            });
          },
          child: Padding(
            padding: const EdgeInsets.only(left: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Text(
                  strings.get("KYC"),
                ),
                _verificationStatus == "VERIFIED"
                    ? Icon(Icons.check_circle_outline)
                    : _verificationStatus == "DOC_SUBMITTED"
                        ? Icon(Icons.check)
                        : Icon(Icons.remove_circle_outline)
              ],
            ),
          ),
        );
      },
      body: Column(
        children: <Widget>[
          Divider(
            height: 2.0,
            color: Colors.black12,
          ),
          (_verificationStatus == "VERIFIED" ||
                  _verificationStatus == "DOC_SUBMITTED")
              ? Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: _messageList,
                  ),
                )
              : Form(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 8.0),
                    child: Column(
                      children: <Widget>[
                        Row(
                          children: <Widget>[
                            OutlineButton(
                              borderSide: BorderSide(
                                  color: Theme.of(context).primaryColorDark),
                              onPressed: () {
                                getPanImage();
                              },
                              child: Row(
                                children: <Widget>[
                                  Icon(Icons.add),
                                  Padding(
                                    padding: const EdgeInsets.only(left: 8.0),
                                    child: Text("Pan card".toUpperCase()),
                                  ),
                                ],
                              ),
                            ),
                            _panImage == null
                                ? Container()
                                : Expanded(
                                    child: Padding(
                                      padding:
                                          const EdgeInsets.only(left: 16.0),
                                      child: Text(
                                        basename(_panImage.path),
                                        maxLines: 3,
                                      ),
                                    ),
                                  )
                          ],
                        ),
                        Divider(
                          color: Colors.black12,
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: <Widget>[
                            Text("Address type"),
                            Padding(
                              padding: const EdgeInsets.only(left: 16.0),
                              child: DropdownButton(
                                style: TextStyle(
                                    color: Colors.black45,
                                    fontSize: Theme.of(context)
                                        .primaryTextTheme
                                        .title
                                        .fontSize),
                                onChanged: (value) {
                                  setState(() {
                                    _selectedAddressDocType = value;
                                  });
                                },
                                value: _selectedAddressDocType,
                                items: _getAddressTypes(),
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: <Widget>[
                            OutlineButton(
                              borderSide: BorderSide(
                                  color: Theme.of(context).primaryColorDark),
                              onPressed: () {
                                getAddressImage();
                              },
                              child: Row(
                                children: <Widget>[
                                  Icon(Icons.add),
                                  Padding(
                                    padding: const EdgeInsets.only(left: 8.0),
                                    child: Text(_getDocValueFromName(
                                            _selectedAddressDocType)
                                        .toUpperCase()),
                                  )
                                ],
                              ),
                            ),
                            _addressImage == null
                                ? Container()
                                : Expanded(
                                    child: Padding(
                                      padding:
                                          const EdgeInsets.only(left: 16.0),
                                      child: Text(
                                        basename(_addressImage.path),
                                        maxLines: 3,
                                      ),
                                    ),
                                  )
                          ],
                        ),
                        _bShowImageUploadError
                            ? Padding(
                                padding: const EdgeInsets.only(
                                    top: 8.0, bottom: 8.0),
                                child: Row(
                                  children: <Widget>[
                                    Expanded(
                                      child: Text(
                                        "Please select pan card and address proof document both.",
                                        style: TextStyle(
                                            color:
                                                Theme.of(context).errorColor),
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : Container(),
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
                          child: Row(
                            children: <Widget>[
                              Expanded(
                                child: Text(
                                  "Upload both sides of aadhaar card or any other address proof where your name, date of birth & address is clearly visible.",
                                  style: TextStyle(
                                      color: Theme.of(context).indicatorColor),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: <Widget>[
                              FlatButton(
                                onPressed: () {
                                  _onUploadDocuments();
                                },
                                child: Text(
                                  strings.get("UPLOAD").toUpperCase(),
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

  List<DropdownMenuItem> _getAddressTypes() {
    List<DropdownMenuItem> _lstMenuItems = [];
    if (_addressList != null && _addressList.length > 0) {
      for (Map<String, dynamic> address in _addressList) {
        _lstMenuItems.add(DropdownMenuItem(
          child: Container(
              width: 140.0,
              child: Text(
                address["value"],
                overflow: TextOverflow.ellipsis,
              )),
          value: address["name"],
        ));
      }
    } else {
      _lstMenuItems.add(DropdownMenuItem(
        child: Container(
            width: 140.0,
            child: Text(
              "",
            )),
        value: "",
      ));
    }
    return _lstMenuItems;
  }

  Future getImage(Function callback) async {
    var image = await ImagePicker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      callback(image);
    }
  }

  Future getPanImage() async {
    getImage((File image) {
      setState(() {
        _panImage = image;
        _bShowImageUploadError = false;
      });
    });
  }

  Future getAddressImage() async {
    getImage((File image) {
      setState(() {
        _addressImage = image;
        _bShowImageUploadError = false;
      });
    });
  }

  _onUploadDocuments() async {
    if (_panImage == null || _addressImage == null) {
      setState(() {
        _bShowImageUploadError = true;
      });
    } else {
      if (cookie == null || cookie == "") {
        Future<dynamic> futureCookie = SharedPrefHelper.internal().getCookie();
        await futureCookie.then((value) {
          cookie = value;
        });
      }

      // string to uri
      var uri = Uri.parse(
          BaseUrl.apiUrl + ApiUtil.UPLOAD_DOC + _selectedAddressDocType);

      // get length for http post
      var panLength = await _panImage.length();
      // to byte stream
      var panStream =
          http.ByteStream(DelegatingStream.typed(_panImage.openRead()));

      // get length for http post
      var addressLength = await _addressImage.length();
      // to byte stream
      var addressStream =
          http.ByteStream(DelegatingStream.typed(_addressImage.openRead()));

      // new multipart request
      var request = http.MultipartRequest("POST", uri);

      // add multipart form to request
      request.files.add(http.MultipartFile('pan', panStream, panLength,
          filename: basename(_panImage.path),
          contentType: MediaType('image', 'jpg')));

      request.files.add(http.MultipartFile('kyc', addressStream, addressLength,
          filename: basename(_addressImage.path),
          contentType: MediaType('image', 'jpg')));

      request.headers["cookie"] = cookie;
      http.StreamedResponse response = await request.send().then((onValue) {
        return http.Response.fromStream(onValue);
      }).then(
        (http.Response res) {
          if (res.statusCode >= 200 && res.statusCode <= 299) {
            Map<String, dynamic> response = json.decode(res.body);
            setState(() {
              _panVerificationStatus = response["pan_verification"];
              _addressVerificationStatus = response["address_verification"];
              _setDocVerificationStatus();
            });
          }
        },
      );
    }
  }

  _getDocValueFromName(String name) {
    String _addressDocValue = "";
    for (Map<String, dynamic> address in _addressList) {
      if (address["name"] == _selectedAddressDocType) {
        _addressDocValue = address["value"];
      }
    }
    return _addressDocValue;
  }

  _sendOTP() async {
    setState(() {
      _mobileVerificationError = null;
    });

    http.Request req =
        http.Request("POST", Uri.parse(BaseUrl.apiUrl + ApiUtil.SEND_OTP));
    req.body = json.encode({
      "phone": _mobileController.text.toString(),
      "isChanged": mobile.toString() != _mobileController.text.toString(),
    });
    return HttpManager(http.Client())
        .sendRequest(req)
        .then((http.Response res) {
      if (res.statusCode >= 200 && res.statusCode <= 299) {
        setState(() {
          _bIsOTPSent = true;
        });
      } else {
        final response = json.decode(res.body);
        setState(() {
          _mobileVerificationError = response["error"]["erroMessage"];
        });
      }
    });
  }

  _verifyOTP() {
    http.Request req =
        http.Request("POST", Uri.parse(BaseUrl.apiUrl + ApiUtil.VERIFY_OTP));
    req.body = json.encode({
      "otp": _otpController.text.toString(),
    });
    return HttpManager(http.Client())
        .sendRequest(req)
        .then((http.Response res) {
      if (res.statusCode >= 200 && res.statusCode <= 299) {
        authenticateWithdraw();
        setState(() {
          _bIsMobileVerified = true;
        });
      }
    });
  }

  initFormInputs() {
    acIFSCCodeController.text =
        _withdrawData.ifscCode != null ? _withdrawData.ifscCode.toString() : "";
    accountNameController.text = _withdrawData.loginName != null
        ? _withdrawData.loginName.toString()
        : "";
    accountNumberController.text = _withdrawData.accountNumber != null
        ? _withdrawData.accountNumber.toString()
        : "";
  }

  confirmWithdrawRequest(BuildContext context) async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Alert"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                "You have already availed your " +
                    _withdrawData.numberOfFreeWithdraw.toString() +
                    " free withdrawl for this month. A processing fee of " +
                    strings.rupee +
                    _withdrawData.withdrawCost.toString() +
                    " will be deducted from your withdrawable balance for all subsequent withdrawls in this month. ",
                textAlign: TextAlign.justify,
              ),
              Padding(
                padding: EdgeInsets.only(top: 8.0),
                child:
                    Text("Would you still like to continue this withdrawal?"),
              ),
            ],
          ),
          actions: <Widget>[
            FlatButton(
              child: Text(strings.get("NO").toUpperCase()),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            FlatButton(
              child: Text(strings.get("YES").toUpperCase()),
              onPressed: () {
                if (_formKey.currentState.validate()) {
                  makeWithdrawRequest(context,
                      withdrawType: 1,
                      amount: int.parse(amountController.text));
                }
              },
            )
          ],
        );
      },
    );
  }

  makeWithdrawRequest(BuildContext context,
      {int withdrawType, int amount}) async {
    http.Request req =
        http.Request("POST", Uri.parse(BaseUrl.apiUrl + ApiUtil.WITHDRAW));
    req.body = json.encode({
      "amount": amount,
      "bankDetails": {
        "account_number": accountNumberController.text,
        "ifsc_code": acIFSCCodeController.text,
      },
      "hasBankDetails": (_withdrawData.accountNumber != null &&
          _withdrawData.accountNumber != null &&
          _withdrawData.ifscCode != null),
      "withdraw_type": 1,
    });
    await HttpManager(http.Client()).sendRequest(req).then(
      (http.Response res) {
        if (res.statusCode >= 200 && res.statusCode <= 299) {
          _scaffoldKey.currentState.showSnackBar(
            SnackBar(
              content: Text("Your withdraw request submitted successfully."),
            ),
          );
          openWithdrawHistory(context);
        }
      },
    );
  }

  openWithdrawHistory(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => WithdrawHistory(),
        fullscreenDialog: true,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        elevation: 0.0,
        title: Text("Withdraw"),
        actions: <Widget>[
          IconButton(
            icon: Icon(
              Icons.compare_arrows,
              size: Theme.of(context).primaryTextTheme.display1.fontSize,
            ),
            onPressed: () {
              openWithdrawHistory(context);
            },
          )
        ],
      ),
      body: DefaultTabController(
        length: 3,
        child: Column(
          children: <Widget>[
            Material(
              color: Theme.of(context).primaryColor,
              child: TabBar(
                tabs: [
                  Tab(
                    child: Text("PAYTM"),
                  ),
                  Tab(
                    child: Text("BANK"),
                  ),
                  Tab(
                    child: Text("UPI"),
                  )
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                children: <Widget>[
                  _withdrawData == null
                      ? Container()
                      : SingleChildScrollView(
                          child: Form(
                            key: _paytmFormKey,
                            child: !_bIsMobileVerified
                                ? Padding(
                                    padding: EdgeInsets.all(8.0),
                                    child: Column(
                                      children: <Widget>[
                                        Row(
                                          children: <Widget>[
                                            Expanded(
                                              child: ExpansionPanelList(
                                                expansionCallback: (int index,
                                                    bool isExpanded) {
                                                  setState(() {
                                                    if (_selectedItemIndex ==
                                                        index) {
                                                      _selectedItemIndex = -1;
                                                    } else {
                                                      _selectedItemIndex =
                                                          index;
                                                    }
                                                  });
                                                },
                                                children: [
                                                  getMobileVerificationWidget(
                                                      context, 4),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  )
                                : Column(
                                    children: <Widget>[
                                      Container(
                                        color: Colors.black12,
                                        padding:
                                            EdgeInsets.symmetric(vertical: 8.0),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: <Widget>[
                                            Text(
                                              "Withdrawable balance",
                                              style: TextStyle(
                                                color: Colors.black87,
                                                fontSize: Theme.of(context)
                                                    .primaryTextTheme
                                                    .subhead
                                                    .fontSize,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            Padding(
                                              padding:
                                                  EdgeInsets.only(left: 4.0),
                                              child: Text(
                                                strings.rupee +
                                                    (_withdrawData
                                                        .withdrawableAmount
                                                        .toStringAsFixed(2)),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Padding(
                                        padding: EdgeInsets.all(8.0),
                                        child: Card(
                                          elevation: 3.0,
                                          child: Container(
                                            padding: EdgeInsets.fromLTRB(
                                                8.0, 16.0, 8.0, 8.0),
                                            child: Column(
                                              children: <Widget>[
                                                Row(
                                                  children: <Widget>[
                                                    Expanded(
                                                      child: TextFormField(
                                                        controller:
                                                            paytmAmountController,
                                                        decoration:
                                                            InputDecoration(
                                                          labelText: "Amount",
                                                          prefix: Text(
                                                            strings.rupee,
                                                            style: TextStyle(
                                                                color: Colors
                                                                    .black87),
                                                          ),
                                                          hintText: _withdrawData
                                                              .paytmMinWithdraw
                                                              .toString(),
                                                          contentPadding:
                                                              EdgeInsets.all(
                                                                  8.0),
                                                          border:
                                                              OutlineInputBorder(
                                                            borderSide:
                                                                BorderSide(
                                                              color: Colors
                                                                  .black38,
                                                            ),
                                                          ),
                                                        ),
                                                        keyboardType:
                                                            TextInputType
                                                                .number,
                                                        style: TextStyle(
                                                          color: Colors.black87,
                                                        ),
                                                        validator: (value) {
                                                          if (value.isEmpty) {
                                                            return "Please enter amount to withdraw";
                                                          } else {
                                                            double amount =
                                                                double.parse(
                                                                    value);
                                                            if (amount <
                                                                _withdrawData
                                                                    .paytmMinWithdraw) {
                                                              return "You can not withdraw amount less than " +
                                                                  strings
                                                                      .rupee +
                                                                  _withdrawData
                                                                      .paytmMinWithdraw
                                                                      .toString();
                                                            } else if (amount >
                                                                _withdrawData
                                                                    .withdrawableAmount) {
                                                              return "You can not withdraw more than available withdraw amount(" +
                                                                  _withdrawData
                                                                      .withdrawableAmount
                                                                      .toString() +
                                                                  ")";
                                                            } else if (amount >
                                                                _withdrawData
                                                                    .paytmMaxWithdraw) {
                                                              return "You can not withdraw more than " +
                                                                  strings
                                                                      .rupee +
                                                                  _withdrawData
                                                                      .maxWithdraw
                                                                      .toString();
                                                            }
                                                          }
                                                        },
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                Padding(
                                                  padding: EdgeInsets.symmetric(
                                                    vertical: 16.0,
                                                    horizontal: 8.0,
                                                  ),
                                                  child: Row(
                                                    children: <Widget>[
                                                      Expanded(
                                                        child: RichText(
                                                          textAlign:
                                                              TextAlign.justify,
                                                          text: TextSpan(
                                                              style: TextStyle(
                                                                color: Colors
                                                                    .black54,
                                                                fontSize: Theme.of(
                                                                        context)
                                                                    .primaryTextTheme
                                                                    .caption
                                                                    .fontSize,
                                                              ),
                                                              children: [
                                                                TextSpan(
                                                                    text:
                                                                        "*Make sure your verified mobile number "),
                                                                TextSpan(
                                                                  text: _withdrawData
                                                                      .mobile,
                                                                  style:
                                                                      TextStyle(
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .bold,
                                                                  ),
                                                                ),
                                                                TextSpan(
                                                                  text:
                                                                      " is registered with PAYTM and it's KYC verification is completed on PAYTM.",
                                                                )
                                                              ]),
                                                        ),
                                                      )
                                                    ],
                                                  ),
                                                ),
                                                Padding(
                                                  padding:
                                                      EdgeInsets.only(top: 8.0),
                                                  child: Row(
                                                    children: <Widget>[
                                                      Expanded(
                                                        child: RaisedButton(
                                                          onPressed: () {
                                                            if (_paytmFormKey
                                                                .currentState
                                                                .validate()) {
                                                              makeWithdrawRequest(
                                                                context,
                                                                withdrawType: 4,
                                                                amount:
                                                                    int.parse(
                                                                  paytmAmountController
                                                                      .text,
                                                                ),
                                                              );
                                                            }
                                                          },
                                                          child: Text(
                                                              "REQUEST WITHDRAW"),
                                                          textColor:
                                                              Colors.white70,
                                                          color: Theme.of(
                                                                  context)
                                                              .primaryColorDark,
                                                        ),
                                                      )
                                                    ],
                                                  ),
                                                )
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                      Padding(
                                        padding: EdgeInsets.only(top: 16.0),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: <Widget>[
                                            Padding(
                                              padding:
                                                  EdgeInsets.only(right: 8.0),
                                              child: Text(
                                                "POWERED BY",
                                                style: TextStyle(
                                                  fontSize: Theme.of(context)
                                                      .primaryTextTheme
                                                      .subhead
                                                      .fontSize,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                            Container(
                                              height: 32.0,
                                              child: Image.asset(
                                                  "images/paytm.png"),
                                            ),
                                          ],
                                        ),
                                      )
                                    ],
                                  ),
                          ),
                        ),
                  _withdrawData == null
                      ? Container()
                      : SingleChildScrollView(
                          child: !_bIsMobileVerified || !_bIsKYCVerified
                              ? Padding(
                                  padding: EdgeInsets.all(8.0),
                                  child: Column(
                                    children: <Widget>[
                                      Row(
                                        children: <Widget>[
                                          Expanded(
                                            child: ExpansionPanelList(
                                              expansionCallback:
                                                  (int index, bool isExpanded) {
                                                setState(() {
                                                  if (_selectedItemIndex ==
                                                      index) {
                                                    _selectedItemIndex = -1;
                                                  } else {
                                                    _selectedItemIndex = index;
                                                  }
                                                });
                                              },
                                              children: [
                                                getMobileVerificationWidget(
                                                    context, 1),
                                                getKYCVerificationWidget(
                                                    context),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                )
                              : Padding(
                                  padding: EdgeInsets.only(bottom: 16.0),
                                  child: Form(
                                    key: _formKey,
                                    child: Column(
                                      children: <Widget>[
                                        Container(
                                          color: Colors.black12,
                                          padding: EdgeInsets.symmetric(
                                              vertical: 8.0),
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: <Widget>[
                                              Text(
                                                "Withdrawable balance",
                                                style: TextStyle(
                                                  color: Colors.black87,
                                                  fontSize: Theme.of(context)
                                                      .primaryTextTheme
                                                      .subhead
                                                      .fontSize,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              Padding(
                                                padding:
                                                    EdgeInsets.only(left: 4.0),
                                                child: Text(
                                                  strings.rupee +
                                                      (_withdrawData
                                                          .withdrawableAmount
                                                          .toStringAsFixed(2)),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Padding(
                                          padding: EdgeInsets.all(8.0),
                                          child: Card(
                                            elevation: 3.0,
                                            child: Container(
                                              padding: EdgeInsets.fromLTRB(
                                                  16.0, 8.0, 16.0, 8.0),
                                              child: Column(
                                                children: <Widget>[
                                                  Padding(
                                                    padding:
                                                        EdgeInsets.symmetric(
                                                            vertical: 8.0),
                                                    child: Row(
                                                      children: <Widget>[
                                                        Expanded(
                                                          child: TextFormField(
                                                            controller:
                                                                amountController,
                                                            decoration:
                                                                InputDecoration(
                                                              labelText:
                                                                  "Amount",
                                                              prefix: Text(
                                                                strings.rupee,
                                                                style: TextStyle(
                                                                    color: Colors
                                                                        .black87),
                                                              ),
                                                              hintText:
                                                                  _withdrawData
                                                                      .minWithdraw
                                                                      .toString(),
                                                              contentPadding:
                                                                  EdgeInsets
                                                                      .all(8.0),
                                                              border:
                                                                  OutlineInputBorder(
                                                                borderSide:
                                                                    BorderSide(
                                                                  color: Colors
                                                                      .black38,
                                                                ),
                                                              ),
                                                            ),
                                                            keyboardType:
                                                                TextInputType
                                                                    .number,
                                                            style: TextStyle(
                                                              color: Colors
                                                                  .black87,
                                                            ),
                                                            validator: (value) {
                                                              if (value
                                                                  .isEmpty) {
                                                                return "Please enter amount to withdraw";
                                                              } else {
                                                                double amount =
                                                                    double.parse(
                                                                        value);
                                                                if (amount <
                                                                    _withdrawData
                                                                        .minWithdraw) {
                                                                  return "You can not withdraw amount less than " +
                                                                      strings
                                                                          .rupee +
                                                                      _withdrawData
                                                                          .minWithdraw
                                                                          .toString();
                                                                } else if (amount >
                                                                    _withdrawData
                                                                        .withdrawableAmount) {
                                                                  return "You can not withdraw more than available withdraw amount(" +
                                                                      _withdrawData
                                                                          .withdrawableAmount
                                                                          .toString() +
                                                                      ")";
                                                                } else if (amount >
                                                                    _withdrawData
                                                                        .maxWithdraw) {
                                                                  return "You can not withdraw more than " +
                                                                      strings
                                                                          .rupee +
                                                                      _withdrawData
                                                                          .maxWithdraw
                                                                          .toString();
                                                                }
                                                              }
                                                            },
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  Padding(
                                                    padding:
                                                        EdgeInsets.symmetric(
                                                            vertical: 8.0),
                                                    child: Row(
                                                      children: <Widget>[
                                                        Expanded(
                                                          child: TextFormField(
                                                            enabled: _withdrawData
                                                                    .accountNumber ==
                                                                null,
                                                            controller:
                                                                accountNameController,
                                                            decoration:
                                                                InputDecoration(
                                                              labelText:
                                                                  "Account name",
                                                              contentPadding:
                                                                  EdgeInsets
                                                                      .all(8.0),
                                                              border:
                                                                  OutlineInputBorder(
                                                                borderSide:
                                                                    BorderSide(
                                                                  color: Colors
                                                                      .black38,
                                                                ),
                                                              ),
                                                            ),
                                                            keyboardType:
                                                                TextInputType
                                                                    .text,
                                                            style: TextStyle(
                                                              color: Colors
                                                                  .black45,
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  Padding(
                                                    padding:
                                                        EdgeInsets.symmetric(
                                                            vertical: 8.0),
                                                    child: Row(
                                                      children: <Widget>[
                                                        Expanded(
                                                          child: TextFormField(
                                                            controller:
                                                                accountNumberController,
                                                            enabled: _withdrawData
                                                                    .accountNumber ==
                                                                null,
                                                            decoration:
                                                                InputDecoration(
                                                              labelText:
                                                                  "Account number",
                                                              contentPadding:
                                                                  EdgeInsets
                                                                      .all(8.0),
                                                              border:
                                                                  OutlineInputBorder(
                                                                borderSide:
                                                                    BorderSide(
                                                                  color: Colors
                                                                      .black38,
                                                                ),
                                                              ),
                                                            ),
                                                            keyboardType:
                                                                TextInputType
                                                                    .number,
                                                            style: TextStyle(
                                                              color: Colors
                                                                  .black45,
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  Padding(
                                                    padding:
                                                        EdgeInsets.symmetric(
                                                            vertical: 8.0),
                                                    child: Row(
                                                      children: <Widget>[
                                                        Expanded(
                                                          child: TextFormField(
                                                            controller:
                                                                acIFSCCodeController,
                                                            enabled: _withdrawData
                                                                    .ifscCode ==
                                                                null,
                                                            decoration:
                                                                InputDecoration(
                                                              labelText:
                                                                  "IFSC code",
                                                              contentPadding:
                                                                  EdgeInsets
                                                                      .all(8.0),
                                                              border:
                                                                  OutlineInputBorder(
                                                                borderSide:
                                                                    BorderSide(
                                                                  color: Colors
                                                                      .black38,
                                                                ),
                                                              ),
                                                            ),
                                                            keyboardType:
                                                                TextInputType
                                                                    .text,
                                                            style: TextStyle(
                                                              color: Colors
                                                                  .black45,
                                                            ),
                                                            validator: (value) {
                                                              if (RegExp(r'^[A-Za-z]{4}\d{7}$')
                                                                      .allMatches(
                                                                          value)
                                                                      .length ==
                                                                  0) {
                                                                return "Please enter valid IFSC code";
                                                              }
                                                            },
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  Padding(
                                                    padding:
                                                        EdgeInsets.symmetric(
                                                            vertical: 16.0),
                                                    child: Row(
                                                      children: <Widget>[
                                                        Expanded(
                                                          child: Text(
                                                            "*Account name is auto-populated as per your KYC if it is not matching with the Name of your Bank Account, please send a mail to support@algorintechlabs.com",
                                                            textAlign: TextAlign
                                                                .justify,
                                                            style: TextStyle(
                                                              color: Colors
                                                                  .black54,
                                                              fontSize: Theme.of(
                                                                      context)
                                                                  .primaryTextTheme
                                                                  .caption
                                                                  .fontSize,
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  Row(
                                                    children: <Widget>[
                                                      Expanded(
                                                        child: Padding(
                                                          padding:
                                                              EdgeInsets.only(
                                                                  bottom: 8.0),
                                                          child: RaisedButton(
                                                            onPressed: () {
                                                              if (_withdrawData.withdrawCost !=
                                                                      null &&
                                                                  _withdrawData
                                                                          .withdrawCost >
                                                                      0 &&
                                                                  _withdrawData
                                                                          .numberOfFreeWithdraw <
                                                                      _withdrawData
                                                                          .totalWithdraw) {
                                                                confirmWithdrawRequest(
                                                                    context);
                                                              } else {
                                                                if (_formKey
                                                                    .currentState
                                                                    .validate()) {
                                                                  makeWithdrawRequest(
                                                                    context,
                                                                    withdrawType:
                                                                        1,
                                                                    amount: int
                                                                        .parse(
                                                                      amountController
                                                                          .text,
                                                                    ),
                                                                  );
                                                                }
                                                              }
                                                            },
                                                            child: Text(
                                                                "REQUEST WITHDRAW"),
                                                            textColor:
                                                                Colors.white70,
                                                            color: Theme.of(
                                                                    context)
                                                                .primaryColorDark,
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  )
                                                ],
                                              ),
                                            ),
                                          ),
                                        )
                                      ],
                                    ),
                                  ),
                                ),
                        ),
                  Center(
                    child: Text("COMING SOON!!"),
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
