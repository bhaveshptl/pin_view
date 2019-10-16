import 'dart:io';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:path/path.dart';
import 'package:async/async.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';
import 'package:playfantasy/action_utils/action_util.dart';
import 'package:playfantasy/appconfig.dart';
import 'package:playfantasy/commonwidgets/color_button.dart';
import 'package:playfantasy/commonwidgets/scaffoldpage.dart';
import 'package:playfantasy/commonwidgets/textbox.dart';

import 'package:playfantasy/utils/apiutil.dart';
import 'package:playfantasy/modal/withdraw.dart';
import 'package:playfantasy/utils/httpmanager.dart';
import 'package:playfantasy/utils/joincontesterror.dart';
import 'package:playfantasy/utils/stringtable.dart';
import 'package:playfantasy/utils/sharedprefhelper.dart';
import 'package:playfantasy/profilepages/verification.dart';
import 'package:playfantasy/commonwidgets/fantasypageroute.dart';
import 'package:playfantasy/withdraw/withdrawhistory.dart';
import 'package:playfantasy/withdraw/withdrawsuccess.dart';

class Withdraw extends StatefulWidget {
  final Map<String, dynamic> data;

  Withdraw({this.data});

  @override
  WithdrawState createState() => WithdrawState();
}

class WithdrawState extends State<Withdraw>
    with SingleTickerProviderStateMixin {
  File _panImage;
  File _addressImage;
  File _addressBackCopyImage;
  int allowdDocSizeInMB = 10;
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

  String _verificationStatus;
  String _panVerificationStatus;
  String _addressVerificationStatus;
  String _selectedAddressDocType = "";

  Map<String, dynamic> _withdrawModes;

  final _formKey = new GlobalKey<FormState>();
  final _paytmFormKey = new GlobalKey<FormState>();
  final _bankMobileFormKey = new GlobalKey<FormState>();
  final _paytmMobileFormKey = new GlobalKey<FormState>();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  TextEditingController amountController = TextEditingController();
  TextEditingController otpController = new TextEditingController();
  TextEditingController lastNameController = TextEditingController();
  TextEditingController firstNameController = TextEditingController();
  TextEditingController acIFSCCodeController = TextEditingController();
  TextEditingController mobileController = new TextEditingController();
  TextEditingController paytmAmountController = TextEditingController();
  TextEditingController accountNumberController = TextEditingController();
  TextEditingController accountLastNameController = TextEditingController();
  TextEditingController accountFirstNameController = TextEditingController();

  TabController _tabController;

  @override
  void initState() {
    super.initState();
    _setAddressList();
    _withdrawData = Withhdraw.fromJson(widget.data);

    _setVerificationStatus(_withdrawData);
    _withdrawModes = widget.data["withdrawModes"];
    _tabController = TabController(
      length: _withdrawModes.keys.length,
      vsync: this,
    );
    initFormInputs();
    setAllowedDocSizeInMB();
  }

  updateWithdrawData() {
    http.Request req = http.Request(
      "GET",
      Uri.parse(
        BaseUrl().apiUrl + ApiUtil.AUTH_WITHDRAW,
      ),
    );
    HttpManager(http.Client()).sendRequest(req).then((http.Response res) {
      Map<String, dynamic> response = json.decode(res.body);
      if (res.statusCode >= 200 && res.statusCode <= 299) {
        _withdrawData = Withhdraw.fromJson(response);
      } else {
        JoinContestError error = JoinContestError(response["error"]);
        int errorCode = error.getErrorCode();
        if (errorCode == 6 || errorCode == -1) {
          setState(() {
            _withdrawData = Withhdraw.fromJson(response["data"]);
          });
        }
      }
    }).whenComplete(() {
      ActionUtil().showLoader(_scaffoldKey.currentContext, false);
    });
  }

  _setAddressList() async {
    http.Request req = http.Request(
      "GET",
      Uri.parse(
        BaseUrl().apiUrl + ApiUtil.KYC_DOC_LIST,
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
    }).whenComplete(() {
      ActionUtil().showLoader(_scaffoldKey.currentContext, false);
    });
  }

  _setVerificationStatus(Withhdraw withdrawData) async {
    setState(() {
      _withdrawData = withdrawData;
    });

    mobile = _withdrawData.mobile != null ? _withdrawData.mobile : "";

    mobileController.text = mobile;
    _bIsMobileVerified = _withdrawData.mobileVerification;

    _panVerificationStatus = _withdrawData.panVerification;
    _addressVerificationStatus = _withdrawData.addressVerification;
    _bIsKYCVerified = _withdrawData.panVerification == "VERIFIED";
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
      } else if (kycStatus == "DOC_SUBMITTED" &&
          addressStatus == "DOC_SUBMITTED") {
        _verificationStatus = "DOC_SUBMITTED";
      } else {
        _verificationStatus = "DOC_NOT_SUBMITTED";
      }
    }

    if (kycStatus == "DOC_SUBMITTED" && addressStatus == "DOC_SUBMITTED") {
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

    if (kycStatus == "VERIFIED" && addressStatus == "VERIFIED") {
      _messageList.add(_getMessageWidget(DocVerificationMessages.VERIFIED));
    }
  }

  setAllowedDocSizeInMB() {
    http.Request req = http.Request(
      "GET",
      Uri.parse(
        BaseUrl().apiUrl + ApiUtil.GET_ALLOWED_DOC_SIZE_IN_MB,
      ),
    );
    return HttpManager(http.Client())
        .sendRequest(req)
        .then((http.Response res) {
      if (res.statusCode >= 200 && res.statusCode <= 299) {
        Map<String, dynamic> response = json.decode(res.body);
        allowdDocSizeInMB = response["allowedDocSizeInMB"];
        print("allowdDocSizeInMB>>>>>>>>");
        print(allowdDocSizeInMB);
      }
    }).whenComplete(() {
      ActionUtil().showLoader(_scaffoldKey.currentContext, false);
    });
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
                        leading: SimpleTextBox(
                          controller: mobileController,
                          keyboardType: TextInputType.phone,
                          inputFormatters: [
                            LengthLimitingTextInputFormatter(
                              10,
                            )
                          ],
                          labelText: "Enter mobile number",
                        ),
                      ),
                      _bIsOTPSent
                          ? ListTile(
                              leading: SimpleTextBox(
                                validator: (value) {
                                  if (value.isEmpty) {
                                    return 'Please enter OTP.';
                                  }
                                },
                                controller: otpController,
                                keyboardType: TextInputType.number,
                                labelText: "Enter OTP",
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
                Column(
                  children: <Widget>[
                    Text(
                      "KYC Verification",
                    ),
                    Text(
                      "(ID and Address)",
                    ),
                  ],
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
                  _verificationStatus == "DOC_SUBMITTED" ||
                  _verificationStatus == "UNDER_REVIEW")
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
                        Padding(
                          padding: EdgeInsets.only(top: 4.0, bottom: 4.0),
                          child: Row(
                            children: <Widget>[
                              Expanded(
                                flex: 6,
                                child: Row(
                                  children: <Widget>[
                                    OutlineButton(
                                      borderSide: BorderSide(
                                          color: Theme.of(context)
                                              .primaryColorDark),
                                      onPressed: () {
                                        getAddressImage();
                                      },
                                      child: Row(
                                        children: <Widget>[
                                          Icon(Icons.add),
                                          Padding(
                                            padding: const EdgeInsets.only(
                                                left: 3.0),
                                            child: Text("FRONT COPY"),
                                          )
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Expanded(
                                flex: 1,
                                child: Container(),
                              ),
                              Expanded(
                                flex: 6,
                                child: Row(
                                  children: <Widget>[
                                    OutlineButton(
                                      borderSide: BorderSide(
                                          color: Theme.of(context)
                                              .primaryColorDark),
                                      onPressed: () {
                                        getAddressBackCopyImage();
                                      },
                                      child: Row(
                                        children: <Widget>[
                                          Icon(Icons.add),
                                          Padding(
                                            padding: const EdgeInsets.only(
                                                left: 6.0),
                                            child: Text("BACK COPY"),
                                          )
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            ],
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.only(top: 4.0, bottom: 4.0),
                          child: Row(
                            children: <Widget>[
                              Expanded(
                                flex: 6,
                                child: Row(
                                  children: <Widget>[
                                    _addressImage == null
                                        ? Container()
                                        : Expanded(
                                            child: Padding(
                                              padding: const EdgeInsets.only(
                                                  left: 16.0),
                                              child: Text(
                                                basename(_addressImage.path),
                                                maxLines: 2,
                                              ),
                                            ),
                                          )
                                  ],
                                ),
                              ),
                              Expanded(
                                flex: 1,
                                child: Container(),
                              ),
                              Expanded(
                                flex: 6,
                                child: Row(
                                  children: <Widget>[
                                    _addressBackCopyImage == null
                                        ? Container()
                                        : Expanded(
                                            child: Padding(
                                              padding: const EdgeInsets.only(
                                                  left: 16.0),
                                              child: Text(
                                                basename(
                                                    _addressBackCopyImage.path),
                                                maxLines: 3,
                                              ),
                                            ),
                                          )
                                  ],
                                ),
                              )
                            ],
                          ),
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
                                    color: Theme.of(context).indicatorColor,
                                  ),
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
    var image = await ImagePicker.pickImage(
        source: ImageSource.gallery, maxWidth: 1200);
    bool isDocsValidSize = true;
    var docLength = await image.length();
    if ((docLength) >= (allowdDocSizeInMB * 1024 * 1024)) {
      isDocsValidSize = false;
    }
    if (image != null) {
      if (isDocsValidSize) {
        callback(image);
      } else {
        ActionUtil().showMsgOnTop(
            "Doc size should be less than " +
                allowdDocSizeInMB.toString() +
                "MB",
            _scaffoldKey.currentContext);
      }
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

  Future getAddressBackCopyImage() async {
    getImage((File image) {
      setState(() {
        _addressBackCopyImage = image;
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
      /*string to uri */
      var uriPANUpload = Uri.parse(BaseUrl().apiUrl + ApiUtil.UPLOAD_DOC_PAN);
      var uriAddressUpload = Uri.parse(BaseUrl().apiUrl +
          ApiUtil.UPLOAD_DOC_ADDRESS +
          _selectedAddressDocType);

      var panLength = await _panImage.length();
      var panStream =
          http.ByteStream(DelegatingStream.typed(_panImage.openRead()));
      var addressLength = await _addressImage.length();
      var addressStream =
          http.ByteStream(DelegatingStream.typed(_addressImage.openRead()));

      var addressBackCopyLength;
      var addressBackCopyStream;

      var httpRequestForPAN = http.MultipartRequest("POST", uriPANUpload);
      var httpRequestForAddress =
          http.MultipartRequest("POST", uriAddressUpload);

      /*add multipart form to request*/
      httpRequestForPAN.files.add(http.MultipartFile(
          'pan', panStream, panLength,
          filename: basename(_panImage.path),
          contentType: MediaType('image', 'jpg')));
      print("<<<<<<Upload doc called 3>>>>>>");
      httpRequestForAddress.files.add(http.MultipartFile(
          'kyc', addressStream, addressLength,
          filename: basename(_addressImage.path),
          contentType: MediaType('image', 'jpg')));

      if (_addressBackCopyImage != null) {
        /* Address back images is optional.So it may be null*/
        addressBackCopyLength = await _addressBackCopyImage.length();
        addressBackCopyStream = http.ByteStream(
            DelegatingStream.typed(_addressBackCopyImage.openRead()));
        httpRequestForAddress.files.add(http.MultipartFile(
            'kyc_back_copy', addressBackCopyStream, addressBackCopyLength,
            filename: basename(_addressBackCopyImage.path),
            contentType: MediaType('image', 'jpg')));
      }

      httpRequestForAddress.headers["cookie"] = cookie;
      httpRequestForPAN.headers["cookie"] = cookie;

      Map<String, dynamic> panResponseBody;

      if (_panVerificationStatus != "DOC_SUBMITTED") {
        http.StreamedResponse panResponse =
            await httpRequestForPAN.send().then((onValue) {
          return http.Response.fromStream(onValue);
        }).then(
          (http.Response res) {
            print("panResponseBody");
            panResponseBody = json.decode(res.body);
            print(panResponseBody);
            if (res.statusCode >= 200 && res.statusCode <= 299) {
              panResponseBody = json.decode(res.body);

              if (panResponseBody["err"] != null && panResponseBody["err"]) {
                ActionUtil().showMsgOnTop(
                    panResponseBody["msg"], _scaffoldKey.currentContext);
              }
              setState(() {
                _panVerificationStatus = panResponseBody["pan_verification"];
                _addressVerificationStatus =
                    panResponseBody["address_verification"];
              });
              _setDocVerificationStatus();
              /* After PAN upload success upload the address docs */
            } else if (res.statusCode == 413) {
              print(res.statusCode);
              _setDocVerificationStatus();
            }
          },
        );
      }

      print("_addressVerificationStatus " + _addressVerificationStatus);

      if (_addressVerificationStatus != "DOC_SUBMITTED") {
        http.StreamedResponse addressResponse =
            await httpRequestForAddress.send().then((onValue) {
          return http.Response.fromStream(onValue);
        }).then(
          (http.Response res) {
            print("Address response ");
            panResponseBody = json.decode(res.body);
            print(res.statusCode);
            print(panResponseBody);
            if (res.statusCode >= 200 && res.statusCode <= 299) {
              panResponseBody = json.decode(res.body);
              if (panResponseBody["err"] != null && panResponseBody["err"]) {
                ActionUtil().showMsgOnTop(
                    panResponseBody["msg"], _scaffoldKey.currentContext);
              }
              setState(() {
                _panVerificationStatus = panResponseBody["pan_verification"];
                _addressVerificationStatus =
                    panResponseBody["address_verification"];
              });
              _setDocVerificationStatus();
              /* After PAN upload success upload the address docs */

            } else if (res.statusCode == 413) {
              _setDocVerificationStatus();
            }
          },
        );
      }
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
        http.Request("POST", Uri.parse(BaseUrl().apiUrl + ApiUtil.SEND_OTP));
    req.body = json.encode({
      "phone": mobileController.text.toString(),
      "isChanged": mobile.toString() != mobileController.text.toString(),
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
    }).whenComplete(() {
      ActionUtil().showLoader(_scaffoldKey.currentContext, false);
    });
  }

  _verifyOTP() {
    http.Request req =
        http.Request("POST", Uri.parse(BaseUrl().apiUrl + ApiUtil.VERIFY_OTP));
    req.body = json.encode({
      "otp": otpController.text.toString(),
    });
    return HttpManager(http.Client())
        .sendRequest(req)
        .then((http.Response res) {
      if (res.statusCode >= 200 && res.statusCode <= 299) {
        // authenticateWithdraw();
        setState(() {
          _bIsMobileVerified = true;
        });
      } else {
        Map<String, dynamic> response = json.decode(res.body);
        // _scaffoldKey.currentState.showSnackBar(
        //   SnackBar(
        //     content: Text(response["error"]["erroMessage"]),
        //   ),
        // );
        ActionUtil().showMsgOnTop(
            response["error"]["erroMessage"], _scaffoldKey.currentContext);
      }
    }).whenComplete(() {
      ActionUtil().showLoader(_scaffoldKey.currentContext, false);
    });
  }

  initFormInputs() {
    acIFSCCodeController.text =
        _withdrawData.ifscCode != null ? _withdrawData.ifscCode.toString() : "";
    accountFirstNameController.text = _withdrawData.firstName != null
        ? _withdrawData.firstName.toString()
        : "";
    accountLastNameController.text =
        _withdrawData.lastName != null ? _withdrawData.lastName.toString() : "";
    accountNumberController.text = _withdrawData.accountNumber != null
        ? _withdrawData.accountNumber.toString()
        : "";
    firstNameController.text =
        _withdrawData.firstName != null && _withdrawData.firstName.isNotEmpty
            ? _withdrawData.firstName
            : "";
    lastNameController.text =
        (_withdrawData.lastName != null && _withdrawData.lastName.isNotEmpty)
            ? _withdrawData.lastName
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
                      amount: double.parse(amountController.text));
                }
              },
            )
          ],
        );
      },
    );
  }

  makeWithdrawRequest(BuildContext context,
      {int withdrawType, double amount}) async {
    http.Request req =
        http.Request("POST", Uri.parse(BaseUrl().apiUrl + ApiUtil.WITHDRAW));
    req.body = json.encode({
      "amount": amount,
      "bankDetails": {
        "account_number": accountNumberController.text,
        "ifsc_code": acIFSCCodeController.text,
        "bank_name": withdrawType == 4
            ? firstNameController.text + " " + lastNameController.text
            : accountFirstNameController.text +
                " " +
                accountLastNameController.text,
      },
      "hasBankDetails": (_withdrawData.accountNumber != null &&
          _withdrawData.accountNumber != "" &&
          _withdrawData.loginName != null &&
          _withdrawData.loginName != "" &&
          _withdrawData.ifscCode != "" &&
          _withdrawData.ifscCode != null),
      "withdraw_type": withdrawType,
      "name": firstNameController.text
    });
    await HttpManager(http.Client()).sendRequest(req).then(
      (http.Response res) async {
        if (res.statusCode >= 200 && res.statusCode <= 299) {
          updateWithdrawData();
          String result = await showDialog(
            context: context,
            builder: (context) => WithdrawSuccess(
                withdrawResponse: json.decode(res.body),
                withdrawType: withdrawType),
          );

          if (result != null) {
            openWithdrawHistory(context);
          }
        } else {
          Map<String, dynamic> response = json.decode(res.body);
          if (response["error"] != null) {
            // _scaffoldKey.currentState.showSnackBar(
            //   SnackBar(
            //     content: Text(response["error"]["erroMessage"]),
            //   ),
            // );
            ActionUtil().showMsgOnTop(
                response["error"]["erroMessage"], _scaffoldKey.currentContext);
          }
        }
      },
    ).whenComplete(() {
      ActionUtil().showLoader(context, false);
    });
  }

  openWithdrawHistory(BuildContext context) {
    return Navigator.of(context).push(
      FantasyPageRoute(
        pageBuilder: (context) => WithdrawHistory(),
        fullscreenDialog: true,
      ),
    );
  }

  Widget getPaytmWithDrawWidget(BuildContext context) {
    return SingleChildScrollView(
      child: Form(
        key: _paytmFormKey,
        child: ((_withdrawModes["paytm"] as List).indexOf("mobile") != -1 &&
                    !_bIsMobileVerified) ||
                ((_withdrawModes["paytm"] as List).indexOf("pan card") != -1 &&
                    !_bIsKYCVerified)
            ? Padding(
                padding: EdgeInsets.all(8.0),
                child: Column(
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: ExpansionPanelList(
                            expansionCallback: (int index, bool isExpanded) {
                              setState(() {
                                if (_selectedItemIndex == index) {
                                  _selectedItemIndex = -1;
                                } else {
                                  _selectedItemIndex = index;
                                }
                              });
                            },
                            children: [
                              getMobileVerificationWidget(context, 4),
                              getKYCVerificationWidget(context),
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
                    padding: EdgeInsets.symmetric(vertical: 8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
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
                          padding: EdgeInsets.only(left: 4.0),
                          child: Text(
                            strings.rupee +
                                (_withdrawData.withdrawableAmount
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
                        padding: EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
                        child: Column(
                          children: <Widget>[
                            Row(
                              children: <Widget>[
                                Expanded(
                                  child: SimpleTextBox(
                                    controller: paytmAmountController,
                                    labelText: "Enter Amount(" +
                                        strings.rupee +
                                        (_withdrawData.minWithdraw
                                            .toStringAsFixed(0)) +
                                        "Min)",
                                    keyboardType: TextInputType.number,
                                    validator: (value) {
                                      if (value.isEmpty) {
                                        return "Please enter amount to withdraw";
                                      } else {
                                        double amount = double.parse(value);
                                        if (amount <
                                            _withdrawData.paytmMinWithdraw) {
                                          return "You can not withdraw amount less than " +
                                              strings.rupee +
                                              _withdrawData.paytmMinWithdraw
                                                  .toStringAsFixed(2);
                                        } else if (amount >
                                            _withdrawData.withdrawableAmount) {
                                          return "You can not withdraw more than " +
                                              strings.rupee +
                                              _withdrawData.withdrawableAmount
                                                  .toStringAsFixed(2);
                                        } else if (amount >
                                            _withdrawData.paytmMaxWithdraw) {
                                          return "You can not withdraw more than " +
                                              strings.rupee +
                                              _withdrawData.paytmMaxWithdraw
                                                  .toStringAsFixed(2);
                                        }
                                      }
                                    },
                                  ),
                                ),
                              ],
                            ),
                            Padding(
                              padding: EdgeInsets.fromLTRB(0.0, 16.0, 0.0, 0.0),
                              child: Row(
                                children: <Widget>[
                                  Expanded(
                                    child: Padding(
                                      padding: EdgeInsets.only(right: 4.0),
                                      child: SimpleTextBox(
                                        controller: firstNameController,
                                        enabled:
                                            _withdrawData.loginName == null ||
                                                _withdrawData.loginName == "",
                                        labelText: "First name",
                                        keyboardType: TextInputType.text,
                                        validator: (value) {
                                          if (value.isEmpty) {
                                            return "Account name is required for paytm withdraw.";
                                          }
                                        },
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Padding(
                                      padding: EdgeInsets.only(left: 4.0),
                                      child: SimpleTextBox(
                                        controller: lastNameController,
                                        enabled:
                                            _withdrawData.loginName == null ||
                                                _withdrawData.loginName == "",
                                        labelText: "Last name",
                                        keyboardType: TextInputType.text,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
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
                                      textAlign: TextAlign.justify,
                                      text: TextSpan(
                                          style: TextStyle(
                                            color: Colors.black54,
                                            fontSize: Theme.of(context)
                                                .primaryTextTheme
                                                .caption
                                                .fontSize,
                                          ),
                                          children: [
                                            TextSpan(
                                                text:
                                                    "*Make sure your verified mobile number "),
                                            TextSpan(
                                              text: _withdrawData.mobile,
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            TextSpan(
                                              text:
                                                  " is registered with PAYTM and its KYC verification is completed on PAYTM.",
                                            )
                                          ]),
                                    ),
                                  )
                                ],
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.only(top: 8.0),
                              child: Row(
                                children: <Widget>[
                                  Expanded(
                                    child: Padding(
                                      padding: EdgeInsets.only(bottom: 16.0),
                                      child: Container(
                                        height: 48.0,
                                        child: ColorButton(
                                          onPressed: () async {
                                            if (_paytmFormKey.currentState
                                                .validate()) {
                                              makeWithdrawRequest(
                                                context,
                                                withdrawType: 4,
                                                amount: double.parse(
                                                  paytmAmountController.text,
                                                ),
                                              );
                                            }
                                          },
                                          child: Text(
                                            "REQUEST WITHDRAWAL",
                                            style: Theme.of(context)
                                                .primaryTextTheme
                                                .subhead
                                                .copyWith(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.w700,
                                                ),
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
                  ),
                  Padding(
                    padding: EdgeInsets.only(top: 16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Padding(
                          padding: EdgeInsets.only(right: 8.0),
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
                          child: Image.asset("images/paytm.png"),
                        ),
                      ],
                    ),
                  )
                ],
              ),
      ),
    );
  }

  Widget getBankWithdrawWidget(BuildContext context) {
    return SingleChildScrollView(
      child: ((_withdrawModes["bank"] as List).indexOf("mobile") != -1 &&
                  !_bIsMobileVerified) ||
              ((_withdrawModes["bank"] as List).indexOf("pan card") != -1 &&
                  !_bIsKYCVerified)
          ? Padding(
              padding: EdgeInsets.all(8.0),
              child: Column(
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: ExpansionPanelList(
                          expansionCallback: (int index, bool isExpanded) {
                            setState(() {
                              if (_selectedItemIndex == index) {
                                _selectedItemIndex = -1;
                              } else {
                                _selectedItemIndex = index;
                              }
                            });
                          },
                          children: [
                            getMobileVerificationWidget(context, 1),
                            getKYCVerificationWidget(context),
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
                      padding: EdgeInsets.symmetric(vertical: 8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
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
                            padding: EdgeInsets.only(left: 4.0),
                            child: Text(
                              strings.rupee +
                                  (_withdrawData.withdrawableAmount
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
                          padding: EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 8.0),
                          child: Column(
                            children: <Widget>[
                              Padding(
                                padding: EdgeInsets.symmetric(vertical: 8.0),
                                child: Row(
                                  children: <Widget>[
                                    Expanded(
                                      child: SimpleTextBox(
                                        controller: amountController,
                                        labelText: "Enter Amount(" +
                                            strings.rupee +
                                            (_withdrawData.minWithdraw
                                                .toStringAsFixed(0)) +
                                            "Min)",
                                        keyboardType: TextInputType.number,
                                        validator: (value) {
                                          if (value.isEmpty) {
                                            return "Please enter amount to withdraw";
                                          } else {
                                            double amount = double.parse(value);
                                            if (amount <
                                                _withdrawData.minWithdraw) {
                                              return "You can not withdraw amount less than " +
                                                  strings.rupee +
                                                  _withdrawData.minWithdraw
                                                      .toString();
                                            } else if (amount >
                                                _withdrawData
                                                    .withdrawableAmount) {
                                              return "You can not withdraw more than " +
                                                  _withdrawData
                                                      .withdrawableAmount
                                                      .toString() +
                                                  ")";
                                            } else if (amount >
                                                _withdrawData.maxWithdraw) {
                                              return "You can not withdraw more than " +
                                                  strings.rupee +
                                                  _withdrawData.maxWithdraw
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
                                padding: EdgeInsets.symmetric(vertical: 8.0),
                                child: Row(
                                  children: <Widget>[
                                    Expanded(
                                      child: Padding(
                                        padding: EdgeInsets.only(right: 4.0),
                                        child: SimpleTextBox(
                                          controller:
                                              accountFirstNameController,
                                          enabled: _withdrawData.firstName ==
                                                  null ||
                                              _withdrawData.firstName.isEmpty,
                                          labelText: "First name",
                                          keyboardType: TextInputType.text,
                                          validator: (value) {
                                            if (value.isEmpty) {
                                              return "Account name is required for bank withdraw.";
                                            }
                                          },
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: Padding(
                                        padding: EdgeInsets.only(left: 4.0),
                                        child: SimpleTextBox(
                                          controller: accountLastNameController,
                                          enabled: _withdrawData.firstName ==
                                                  null ||
                                              _withdrawData.firstName.isEmpty,
                                          labelText: "Last name",
                                          keyboardType: TextInputType.text,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Padding(
                                padding: EdgeInsets.symmetric(vertical: 8.0),
                                child: Row(
                                  children: <Widget>[
                                    Expanded(
                                      child: SimpleTextBox(
                                        controller: accountNumberController,
                                        enabled:
                                            _withdrawData.accountNumber == null,
                                        labelText: "Account number",
                                        keyboardType: TextInputType.number,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Padding(
                                padding: EdgeInsets.symmetric(vertical: 8.0),
                                child: Row(
                                  children: <Widget>[
                                    Expanded(
                                      child: SimpleTextBox(
                                        controller: acIFSCCodeController,
                                        enabled: _withdrawData.ifscCode == null,
                                        labelText: "IFSC code",
                                        keyboardType: TextInputType.text,
                                        validator: (value) {
                                          if (RegExp(r'^[A-Za-z]{4}0[A-Z0-9a-z]{6}$')
                                                  .allMatches(value)
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
                                padding: EdgeInsets.symmetric(vertical: 16.0),
                                child: Row(
                                  children: <Widget>[
                                    Expanded(
                                      child: Text(
                                        "*Account name is auto-populated as per your KYC if it is not matching with the Name of your Bank Account, please send a mail to support@howzat.com",
                                        textAlign: TextAlign.justify,
                                        style: TextStyle(
                                          color: Colors.black54,
                                          fontSize: Theme.of(context)
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
                                      padding: EdgeInsets.only(bottom: 16.0),
                                      child: Container(
                                        height: 48.0,
                                        child: ColorButton(
                                          onPressed: () {
                                            if (_withdrawData.withdrawCost !=
                                                    null &&
                                                _withdrawData.withdrawCost >
                                                    0 &&
                                                _withdrawData
                                                        .numberOfFreeWithdraw <
                                                    _withdrawData
                                                        .totalWithdraw) {
                                              confirmWithdrawRequest(context);
                                            } else {
                                              if (_formKey.currentState
                                                  .validate()) {
                                                makeWithdrawRequest(
                                                  context,
                                                  withdrawType: 1,
                                                  amount: double.parse(
                                                    amountController.text,
                                                  ),
                                                );
                                              }
                                            }
                                          },
                                          child: Text(
                                            "REQUEST WITHDRAWAL",
                                            style: Theme.of(context)
                                                .primaryTextTheme
                                                .subhead
                                                .copyWith(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                          ),
                                        ),
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
    );
  }

  Widget getTabByWithdrawMode(BuildContext context, String mode) {
    switch (mode) {
      case "paytm":
        return getPaytmWithDrawWidget(context);
      case "bank":
        return getBankWithdrawWidget(context);
    }
    return Container();
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldPage(
      scaffoldKey: _scaffoldKey,
      appBar: AppBar(
        elevation: 0.0,
        title: Text(
          "withdrawal".toUpperCase(),
        ),
        actions: <Widget>[
          IconButton(
            icon: Icon(
              Icons.compare_arrows,
              size: Theme.of(context).primaryTextTheme.display1.fontSize,
            ),
            onPressed: () async {
              await openWithdrawHistory(context);
              updateWithdrawData();
            },
          )
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 4.0,
          labelStyle: Theme.of(context).primaryTextTheme.title.copyWith(
                fontWeight: FontWeight.w600,
              ),
          tabs: _withdrawModes.keys.map((k) {
            return Tab(
              child: Text(k.toUpperCase()),
            );
          }).toList(),
        ),
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: _withdrawModes.keys.map((k) {
                return getTabByWithdrawMode(context, k);
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
