import 'dart:io';
import 'dart:convert';
import 'package:path/path.dart';
import 'package:async/async.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_webview_plugin/flutter_webview_plugin.dart';

import 'package:playfantasy/utils/apiutil.dart';
import 'package:playfantasy/utils/stringtable.dart';
import 'package:playfantasy/utils/sharedprefhelper.dart';

class Verification extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => VerificationState();
}

class VerificationState extends State<Verification> {
  String cookie;

  String email;
  String mobile;
  File _panImage;
  File _addressImage;
  bool _bIsOTPSent = false;
  bool _bIsMailSent = false;
  int _selectedItemIndex = -1;
  List<Widget> _messageList = [];
  bool _bIsEmailVerified = false;
  String _emailVerificationError;
  List<dynamic> _addressList = [];
  bool _bIsMobileVerified = false;
  String _mobileVerificationError;
  bool _bShowImageUploadError = false;

  String _docName;
  String _verificationStatus;
  String _panVerificationStatus;
  String _addressVerificationStatus;
  String _selectedAddressDocType = "";

  final formKey = new GlobalKey<FormState>();

  final TextEditingController _otpController = new TextEditingController();
  final TextEditingController _emailController = new TextEditingController();
  final TextEditingController _mobileController = new TextEditingController();

  @override
  void initState() {
    super.initState();
    FlutterWebviewPlugin().close();
    _getVerificationStatus();
    _setAddressList();
  }

  _setAddressList() async {
    if (cookie == null) {
      Future<dynamic> futureCookie = SharedPrefHelper.internal().getCookie();
      await futureCookie.then((value) {
        cookie = value;
      });
    }

    return new http.Client().get(
      ApiUtil.KYC_DOC_LIST,
      headers: {'Content-type': 'application/json', "cookie": cookie},
    ).then((http.Response res) {
      if (res.statusCode == 200) {
        List<dynamic> response = json.decode(res.body);
        setState(() {
          _addressList = response;
          _selectedAddressDocType = _addressList[0]["name"];
        });
      }
    });
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

  _getVerificationStatus() async {
    String cookie;
    Future<dynamic> futureCookie = SharedPrefHelper.internal().getCookie();
    await futureCookie.then((value) {
      cookie = value;
    });

    return new http.Client().get(
      ApiUtil.VERIFICATION_STATUS,
      headers: {'Content-type': 'application/json', "cookie": cookie},
    ).then((http.Response res) {
      if (res.statusCode == 200) {
        Map<String, dynamic> response = json.decode(res.body);
        setState(() {
          email = response["email"];
          mobile = response["mobile"] != null ? response["mobile"] : "";
          _bIsEmailVerified = response["email_verification"];
          _bIsMobileVerified = response["mobile_verification"];
          _panVerificationStatus = response["pan_verification"];
          _addressVerificationStatus = response["address_verification"];
          _emailController.text = email;
          _mobileController.value =
              TextEditingController.fromValue(TextEditingValue(text: mobile))
                  .value;
          _setDocVerificationStatus();
        });
      }
    });
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

  _sendVerificationMail() async {
    setState(() {
      _emailVerificationError = null;
    });

    if (cookie == null) {
      Future<dynamic> futureCookie = SharedPrefHelper.internal().getCookie();
      await futureCookie.then((value) {
        cookie = value;
      });
    }

    return new http.Client()
        .post(
      ApiUtil.SEND_VERIFICATION_MAIL,
      headers: {
        'Content-type': 'application/json',
        "cookie": cookie,
      },
      body: json.encoder.convert({
        "email": _emailController.text.toString(),
        "isChanged": email.toString() != _emailController.text.toString(),
      }),
    )
        .then((http.Response res) {
      if (res.statusCode >= 200 && res.statusCode <= 299) {
        setState(() {
          _bIsMailSent = true;
        });
      } else {
        final response = json.decode(res.body);
        setState(() {
          _emailVerificationError = response["error"]["erroMessage"];
        });
      }
    });
  }

  _sendOTP() async {
    setState(() {
      _mobileVerificationError = null;
    });

    if (cookie == null) {
      Future<dynamic> futureCookie = SharedPrefHelper.internal().getCookie();
      await futureCookie.then((value) {
        cookie = value;
      });
    }

    return new http.Client()
        .post(
      ApiUtil.SEND_OTP,
      headers: {
        'Content-type': 'application/json',
        "cookie": cookie,
      },
      body: json.encoder.convert({
        "phone": _mobileController.text.toString(),
        "isChanged": mobile.toString() != _mobileController.text.toString(),
      }),
    )
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
    return new http.Client()
        .post(
      ApiUtil.VERIFY_OTP,
      headers: {
        'Content-type': 'application/json',
        "cookie": cookie,
      },
      body: json.encoder.convert({
        "otp": _otpController.text.toString(),
      }),
    )
        .then((http.Response res) {
      if (res.statusCode >= 200 && res.statusCode <= 299) {
        setState(() {
          _bIsMobileVerified = true;
        });
      }
    });
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
      if (cookie == null) {
        Future<dynamic> futureCookie = SharedPrefHelper.internal().getCookie();
        await futureCookie.then((value) {
          cookie = value;
        });
      }

      // string to uri
      var uri = Uri.parse(ApiUtil.UPLOAD_DOC + _selectedAddressDocType);

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          strings.get("ACCOUNT_VERIFICATION"),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 72.0),
                    child: Container(
                      margin: const EdgeInsets.all(16.0),
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
                          ExpansionPanel(
                            isExpanded: _selectedItemIndex == 0,
                            headerBuilder: (context, isExpanded) {
                              return Padding(
                                padding: const EdgeInsets.only(left: 16.0),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: <Widget>[
                                    Text(
                                      strings.get("EMAIL"),
                                    ),
                                    _bIsEmailVerified
                                        ? Icon(Icons.check_circle_outline)
                                        : Icon(Icons.remove_circle_outline),
                                  ],
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
                                  child: !_bIsEmailVerified
                                      ? _bIsMailSent
                                          ? Column(
                                              children: <Widget>[
                                                ListTile(
                                                  leading: Text(
                                                      "Verification mail sent successfully. Please check your mail and visit verification link to verify your email."),
                                                )
                                              ],
                                            )
                                          : Column(
                                              children: <Widget>[
                                                ListTile(
                                                  leading: TextFormField(
                                                    controller:
                                                        _emailController,
                                                    keyboardType: TextInputType
                                                        .emailAddress,
                                                    decoration: InputDecoration(
                                                      labelText:
                                                          "Enter e-mail address",
                                                      hintText:
                                                          'example@abc.com',
                                                    ),
                                                  ),
                                                ),
                                                _emailVerificationError == null
                                                    ? Container()
                                                    : Padding(
                                                        padding:
                                                            EdgeInsets.fromLTRB(
                                                                16.0,
                                                                8.0,
                                                                16.0,
                                                                8.0),
                                                        child: Row(
                                                          children: <Widget>[
                                                            Text(
                                                              _emailVerificationError,
                                                              style: TextStyle(
                                                                color: Theme.of(
                                                                        context)
                                                                    .errorColor,
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                    top: 8.0,
                                                    left: 16.0,
                                                    right: 16.0,
                                                  ),
                                                  child: Row(
                                                    children: <Widget>[
                                                      Expanded(
                                                        child: Text(
                                                          "You will receive verification link on this e-mail address. Please visit link to verify your e-mail address.",
                                                          style: TextStyle(
                                                              color: Colors
                                                                  .black54),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                ListTile(
                                                  leading: Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment.end,
                                                    children: <Widget>[
                                                      FlatButton(
                                                        onPressed: () {
                                                          _sendVerificationMail();
                                                        },
                                                        child: Text(
                                                          strings
                                                              .get("VERIFY")
                                                              .toUpperCase(),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            )
                                      : Column(
                                          children: <Widget>[
                                            ListTile(leading: Text(email)),
                                          ],
                                        ),
                                ),
                              ],
                            ),
                          ),
                          ExpansionPanel(
                            isExpanded: _selectedItemIndex == 1,
                            headerBuilder: (context, isExpanded) {
                              return Padding(
                                padding: const EdgeInsets.only(left: 16.0),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: <Widget>[
                                    Text(
                                      strings.get("MOBILE"),
                                    ),
                                    _bIsMobileVerified
                                        ? Icon(Icons.check_circle_outline)
                                        : Icon(Icons.remove_circle_outline),
                                  ],
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
                                  key: formKey,
                                  child: !_bIsMobileVerified
                                      ? Column(
                                          children: <Widget>[
                                            ListTile(
                                              leading: TextFormField(
                                                controller: _mobileController,
                                                keyboardType:
                                                    TextInputType.phone,
                                                decoration: InputDecoration(
                                                    labelText:
                                                        "Enter mobile number",
                                                    hintText: "9999999999",
                                                    prefix: Padding(
                                                      padding:
                                                          const EdgeInsets.only(
                                                              right: 4.0),
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
                                                      controller:
                                                          _otpController,
                                                      keyboardType:
                                                          TextInputType.phone,
                                                      decoration:
                                                          InputDecoration(
                                                        labelText: "Enter OTP",
                                                      ),
                                                    ),
                                                  )
                                                : Container(),
                                            _mobileVerificationError == null
                                                ? Container()
                                                : Padding(
                                                    padding:
                                                        EdgeInsets.fromLTRB(
                                                            16.0,
                                                            8.0,
                                                            16.0,
                                                            8.0),
                                                    child: Row(
                                                      children: <Widget>[
                                                        Text(
                                                          _mobileVerificationError,
                                                          style: TextStyle(
                                                            color: Theme.of(
                                                                    context)
                                                                .errorColor,
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
                                                      style: TextStyle(
                                                          color:
                                                              Colors.black54),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            ListTile(
                                              leading: Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.end,
                                                children: <Widget>[
                                                  FlatButton(
                                                    onPressed: () {
                                                      if (_bIsOTPSent) {
                                                        if (formKey.currentState
                                                            .validate()) {
                                                          _verifyOTP();
                                                        }
                                                      } else {
                                                        _sendOTP();
                                                      }
                                                    },
                                                    child: Text(
                                                      !_bIsOTPSent
                                                          ? strings
                                                              .get("SEND_OTP")
                                                              .toUpperCase()
                                                          : strings
                                                              .get("VERIFY")
                                                              .toUpperCase(),
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
                          ),
                          ExpansionPanel(
                            isExpanded: _selectedItemIndex == 2,
                            headerBuilder: (context, isExpanded) {
                              return Padding(
                                padding: const EdgeInsets.only(left: 16.0),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
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
                                          padding: const EdgeInsets.fromLTRB(
                                              16.0, 8.0, 16.0, 8.0),
                                          child: Column(
                                            children: <Widget>[
                                              Row(
                                                children: <Widget>[
                                                  OutlineButton(
                                                    borderSide: BorderSide(
                                                        color: Theme.of(context)
                                                            .primaryColorDark),
                                                    onPressed: () {
                                                      getPanImage();
                                                    },
                                                    child: Row(
                                                      children: <Widget>[
                                                        Icon(Icons.add),
                                                        Padding(
                                                          padding:
                                                              const EdgeInsets
                                                                      .only(
                                                                  left: 8.0),
                                                          child: Text("Pan card"
                                                              .toUpperCase()),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  _panImage == null
                                                      ? Container()
                                                      : Expanded(
                                                          child: Padding(
                                                            padding:
                                                                const EdgeInsets
                                                                        .only(
                                                                    left: 16.0),
                                                            child: Text(
                                                              basename(_panImage
                                                                  .path),
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
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceBetween,
                                                children: <Widget>[
                                                  Text("Address type"),
                                                  Padding(
                                                    padding:
                                                        const EdgeInsets.only(
                                                            left: 16.0),
                                                    child: DropdownButton(
                                                      style: TextStyle(
                                                          color: Colors.black45,
                                                          fontSize: Theme.of(
                                                                  context)
                                                              .primaryTextTheme
                                                              .title
                                                              .fontSize),
                                                      onChanged: (value) {
                                                        setState(() {
                                                          _selectedAddressDocType =
                                                              value;
                                                        });
                                                      },
                                                      value:
                                                          _selectedAddressDocType,
                                                      items: _getAddressTypes(),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              Row(
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
                                                          padding:
                                                              const EdgeInsets
                                                                      .only(
                                                                  left: 8.0),
                                                          child: Text(
                                                              _getDocValueFromName(
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
                                                                const EdgeInsets
                                                                        .only(
                                                                    left: 16.0),
                                                            child: Text(
                                                              basename(
                                                                  _addressImage
                                                                      .path),
                                                              maxLines: 3,
                                                            ),
                                                          ),
                                                        )
                                                ],
                                              ),
                                              _bShowImageUploadError
                                                  ? Padding(
                                                      padding:
                                                          const EdgeInsets.only(
                                                              top: 8.0,
                                                              bottom: 8.0),
                                                      child: Row(
                                                        children: <Widget>[
                                                          Expanded(
                                                            child: Text(
                                                              "Please select pan card and address proof document both.",
                                                              style: TextStyle(
                                                                  color: Theme.of(
                                                                          context)
                                                                      .errorColor),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    )
                                                  : Container(),
                                              Padding(
                                                padding: const EdgeInsets.only(
                                                    top: 8.0, bottom: 8.0),
                                                child: Row(
                                                  children: <Widget>[
                                                    Expanded(
                                                      child: Text(
                                                        "Upload both sides of aadhaar card or any other address proof where your name, date of birth & address is clearly visible.",
                                                        style: TextStyle(
                                                            color: Theme.of(
                                                                    context)
                                                                .indicatorColor),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              Padding(
                                                padding: const EdgeInsets.only(
                                                    top: 8.0, bottom: 8.0),
                                                child: Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.end,
                                                  children: <Widget>[
                                                    FlatButton(
                                                      onPressed: () {
                                                        _onUploadDocuments();
                                                      },
                                                      child: Text(
                                                        strings
                                                            .get("UPLOAD")
                                                            .toUpperCase(),
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
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    FlutterWebviewPlugin().launch(ApiUtil.BASE_URL, hidden: true);
    super.dispose();
  }
}

class DocVerificationMessages {
  static String DOC_SUBMITTED =
      "- Address documents have been uploaded successfully. The status will be updated within 2 working days.";
  static String VERIFIED = "- You can now make cash withdrawal requests.";
}

class PanVerificationMessages {
  static String UNDER_REVIEW =
      "- PAN verification is in progress. The status will be updated within 2 working days.";
  static String DOC_REJECTED =
      "- Your PAN verification request has been rejected. Please contact customer support for more details.";
  static String VERIFIED = "- Your PAN has been verified successfully.";
}

class AddressVerificationMessages {
  static String UNDER_REVIEW =
      "- Address verification is in progress.  The status will be updated within 2 working days.";
  static String DOC_REJECTED =
      "- Your address verification request has been rejected. Please contact customer support for more details.";
  static String VERIFIED = "- Your address has been verified successfully.";
}
