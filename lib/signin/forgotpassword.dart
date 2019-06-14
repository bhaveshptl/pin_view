import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:playfantasy/commonwidgets/color_button.dart';

import 'package:playfantasy/utils/apiutil.dart';
import 'package:playfantasy/utils/httpmanager.dart';
import 'package:playfantasy/utils/stringtable.dart';

class ForgotPassword extends StatefulWidget {
  @override
  _ForgotPasswordState createState() => _ForgotPasswordState();
}

class _ForgotPasswordState extends State<ForgotPassword> {
  String _authName;
  String _otpCookie;
  int _forgotPassMode = 1;

  String password = "";
  bool bDigitsCountMatch = false;
  bool bLettersCountMatch = false;
  bool passConstraintMatch = false;
  bool bSpecialCharCountMatch = false;
  bool _passObscureText = true;
  bool _repeatPassObscureText = true;

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final GlobalKey<FormState> _newPassFormKey = GlobalKey<FormState>();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  final TextEditingController _otpController = TextEditingController();
  final TextEditingController _authNameController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _reEnterPasswordController =
      TextEditingController();

  @override
  void initState() {
    super.initState();
    _newPasswordController.addListener(() {
      setState(() {
        password = _newPasswordController.text;
        bDigitsCountMatch = password.contains(RegExp('[0-9]'));
        bLettersCountMatch = password.contains(RegExp('[A-z]'));
        bSpecialCharCountMatch =
            password.contains(RegExp('[_@#\$?().,!/:{}><;`*~%^&+=]'));
        passConstraintMatch = bDigitsCountMatch &&
            bLettersCountMatch &&
            bSpecialCharCountMatch &&
            password.length >= 8;
      });
    });
  }

  _requestOTP() async {
    _authName = _authNameController.text;

    http.Request req = http.Request(
        "POST", Uri.parse(BaseUrl().apiUrl + ApiUtil.FORGOT_PASSWORD));
    req.body = json.encode({
      "username": _authName,
      "isEmail": _authName.indexOf("@") != -1,
    });
    await HttpManager(http.Client()).sendRequest(req).then((http.Response res) {
      if (res.statusCode >= 200 && res.statusCode <= 299) {
        _otpCookie = res.headers["set-cookie"];
        setState(() {
          if (_authName.indexOf("@") != -1) {
            _forgotPassMode = 2;
          } else {
            _forgotPassMode = 3;
          }
        });
      } else if (res.statusCode == 400) {
        Map<String, dynamic> response = json.decode(res.body);
        String error = response["error"] != null
            ? response["error"]
            : strings.get("SOMETHING_WENT_WRONG");
        showMsg(error);
      }
    });
  }

  showMsg(String msg) {
    _scaffoldKey.currentState.showSnackBar(
      SnackBar(
        content: Text(msg),
      ),
    );
  }

  String validateEmail(String value) {
    Pattern pattern =
        r'^(([^<>()[\]\\.,;:\s@\"]+(\.[^<>()[\]\\.,;:\s@\"]+)*)|(\".+\"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$';
    RegExp regex = new RegExp(pattern);
    if (!regex.hasMatch(value))
      return 'Enter Valid Email';
    else
      return null;
  }

  String validateMobile(String value) {
    if (isNumeric(value) && value.length != 10)
      return 'Mobile Number must be of 10 digit';
    else
      return null;
  }

  bool isNumeric(String s) {
    if (s == null) {
      return false;
    }
    return int.parse(s, onError: (e) => null) != null;
  }

  _submitNewPassword() async {
    http.Client()
        .post(
      BaseUrl().apiUrl + ApiUtil.RESET_PASSWORD,
      headers: {'Content-type': 'application/json', "cookie": _otpCookie},
      body: json.encode({
        "username": _authName,
        "otp": _otpController.text,
        "password": _newPasswordController.text,
        "context": {
          "source": "",
          "channel_id": HttpManager.channelId,
        }
      }),
    )
        .then((http.Response res) {
      if (res.statusCode >= 200 && res.statusCode <= 299) {
        Map<String, dynamic> respose = json.decode(res.body);
        if (respose["err"] != null && respose["err"]) {
          setState(() {
            showMsg(respose["errMsg"]);
          });
        } else {
          Navigator.of(context).pop(true);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return SimpleDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(4.0),
      ),
      contentPadding: EdgeInsets.all(0.0),
      children: <Widget>[
        Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: <Widget>[
            Stack(
              alignment: Alignment.centerRight,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        "FORGOT PASSWORD",
                        style:
                            Theme.of(context).primaryTextTheme.title.copyWith(
                                  color: Colors.black,
                                  fontWeight: FontWeight.w700,
                                ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
                InkWell(
                  child: Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Icon(
                      Icons.close,
                    ),
                  ),
                  onTap: () {
                    Navigator.of(context).pop();
                  },
                ),
              ],
            ),
          ],
        ),
        Padding(
          padding: EdgeInsets.all(16.0),
          child: _forgotPassMode == 1
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            strings.get("FORGOT_PASS_EMAIL"),
                            textAlign: TextAlign.justify,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: Form(
                            key: _formKey,
                            child: Column(
                              children: <Widget>[
                                Padding(
                                  padding: EdgeInsets.only(top: 16.0),
                                  child: Row(
                                    children: <Widget>[
                                      Expanded(
                                        child: TextFormField(
                                          controller: _authNameController,
                                          decoration: InputDecoration(
                                            labelText:
                                                "Enter Email or Mobile Number",
                                            border: OutlineInputBorder(
                                              borderSide: BorderSide(
                                                color: Colors.black38,
                                              ),
                                            ),
                                            contentPadding:
                                                EdgeInsets.all(12.0),
                                          ),
                                          validator: (value) {
                                            if (value.isEmpty) {
                                              return strings
                                                  .get("EMAIL_OR_MOBILE_ERROR");
                                            }
                                          },
                                          keyboardType:
                                              TextInputType.emailAddress,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 24.0),
                      child: ColorButton(
                        onPressed: () {
                          String emailError =
                              validateEmail(_authNameController.text);
                          String mobileError =
                              validateMobile(_authNameController.text);
                          if ((!isNumeric(_authNameController.text) &&
                                  emailError != null) ||
                              (isNumeric(_authNameController.text) &&
                                  mobileError != null)) {
                            showMsg(strings.get("VALID_EMAIL_OR_MOBILE_ERROR"));
                          } else {
                            _requestOTP();
                          }
                        },
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                              horizontal: 16.0, vertical: 12.0),
                          child: Text(
                            strings.get("REQUEST_OTP").toUpperCase(),
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
                )
              : Container(
                  child: GestureDetector(
                    onTap: () {
                      FocusScope.of(context).requestFocus(new FocusNode());
                    },
                    child: SingleChildScrollView(
                      child: Form(
                        key: _newPassFormKey,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            _forgotPassMode == 3
                                ? Row(
                                    children: <Widget>[
                                      Expanded(
                                        child: Text(
                                          strings.get("OTP_SENT"),
                                          style: TextStyle(
                                              color: Colors.black54,
                                              fontSize: Theme.of(context)
                                                  .primaryTextTheme
                                                  .subhead
                                                  .fontSize),
                                        ),
                                      )
                                    ],
                                  )
                                : Container(),
                            _forgotPassMode == 2
                                ? Row(
                                    children: <Widget>[
                                      Expanded(
                                        child: Text(
                                          strings.get("LINK_SENT"),
                                          style:
                                              TextStyle(color: Colors.black54),
                                        ),
                                      )
                                    ],
                                  )
                                : Container(),
                            _forgotPassMode == 2
                                ? Padding(
                                    padding: const EdgeInsets.fromLTRB(
                                        8.0, 8.0, 8.0, 0.0),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: <Widget>[
                                        Expanded(
                                          child: Container(),
                                        ),
                                        Expanded(
                                          child: Row(
                                            children: <Widget>[
                                              Expanded(
                                                child: Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                          right: 8.0),
                                                  child: Container(
                                                    color: Colors.black12,
                                                    height: 2.0,
                                                  ),
                                                ),
                                              ),
                                              Expanded(
                                                child: Text(
                                                  strings
                                                      .get("OR")
                                                      .toUpperCase(),
                                                  textAlign: TextAlign.center,
                                                ),
                                              ),
                                              Expanded(
                                                child: Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                          left: 8.0),
                                                  child: Container(
                                                    color: Colors.black12,
                                                    height: 2.0,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Expanded(
                                          child: Container(),
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
                                    child: TextFormField(
                                      controller: _otpController,
                                      decoration: InputDecoration(
                                        labelText: strings.get("ENTER_OTP"),
                                        border: OutlineInputBorder(
                                          borderSide: BorderSide(
                                            color: Colors.black38,
                                          ),
                                        ),
                                        contentPadding: EdgeInsets.all(12.0),
                                      ),
                                      validator: (value) {
                                        if (value.isEmpty) {
                                          return strings.get("ENTER_OTP_ERROR");
                                        }
                                      },
                                      keyboardType: TextInputType.emailAddress,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.only(top: 16.0),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: <Widget>[
                                  Text(
                                    strings.get("AND").toUpperCase(),
                                    style: TextStyle(color: Colors.black54),
                                  ),
                                ],
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.only(top: 16.0),
                              child: Row(
                                children: <Widget>[
                                  Expanded(
                                    child: TextFormField(
                                      controller: _newPasswordController,
                                      decoration: InputDecoration(
                                        labelText: strings.get("NEW_PASSWORD"),
                                        border: OutlineInputBorder(
                                          borderSide: BorderSide(
                                            color: Colors.black38,
                                          ),
                                        ),
                                        contentPadding: EdgeInsets.all(0.0),
                                        prefixIcon: Icon(
                                          Icons.lock,
                                          size: 16.0,
                                        ),
                                        suffixIcon: GestureDetector(
                                          onTap: () {
                                            setState(() {
                                              _passObscureText =
                                                  !_passObscureText;
                                            });
                                          },
                                          child: Icon(
                                            _passObscureText
                                                ? Icons.visibility
                                                : Icons.visibility_off,
                                            size: 16.0,
                                          ),
                                        ),
                                      ),
                                      validator: (value) {
                                        if (value.isEmpty) {
                                          return strings
                                              .get("NEW_PASSWORD_ERROR");
                                        }
                                      },
                                      keyboardType: TextInputType.text,
                                      obscureText: _passObscureText,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.only(top: 16.0),
                              child: Row(
                                children: <Widget>[
                                  Expanded(
                                    child: TextFormField(
                                      controller: _reEnterPasswordController,
                                      decoration: InputDecoration(
                                        labelText:
                                            strings.get("REENTER_PASSWORD"),
                                        border: OutlineInputBorder(
                                          borderSide: BorderSide(
                                            color: Colors.black38,
                                          ),
                                        ),
                                        contentPadding: EdgeInsets.all(0.0),
                                        prefixIcon: Icon(
                                          Icons.lock,
                                          size: 16.0,
                                        ),
                                        suffixIcon: GestureDetector(
                                          onTap: () {
                                            setState(() {
                                              _repeatPassObscureText =
                                                  !_repeatPassObscureText;
                                            });
                                          },
                                          child: Icon(
                                            _repeatPassObscureText
                                                ? Icons.visibility
                                                : Icons.visibility_off,
                                            size: 16.0,
                                          ),
                                        ),
                                      ),
                                      validator: (value) {
                                        if (value.isEmpty) {
                                          return strings
                                              .get("REENTER_PASSWORD_ERROR");
                                        }
                                      },
                                      keyboardType: TextInputType.text,
                                      obscureText: _repeatPassObscureText,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.fromLTRB(
                                  8.0, 16.0, 8.0, 16.0),
                              child: Container(
                                decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12.0),
                                    color: passConstraintMatch
                                        ? Color.fromRGBO(0, 255, 0, 0.1)
                                        : Color.fromRGBO(255, 0, 0, 0.1),
                                    border: Border.all(
                                      color: passConstraintMatch
                                          ? Colors.teal
                                          : Colors.red,
                                    )),
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Row(
                                    children: <Widget>[
                                      Expanded(
                                          child: RichText(
                                        text: TextSpan(
                                          children: [
                                            TextSpan(
                                                text: strings
                                                    .get("PASSWORD_SHOULD"),
                                                style: TextStyle(
                                                    color: Colors.teal)),
                                            TextSpan(
                                                text: strings.get("MIN_CHAR"),
                                                style: TextStyle(
                                                    color: password.length >= 8
                                                        ? Colors.teal
                                                        : Colors.red)),
                                            TextSpan(
                                                text: strings
                                                    .get("ATLEAST_NUMBER"),
                                                style: TextStyle(
                                                    color: bDigitsCountMatch
                                                        ? Colors.teal
                                                        : Colors.red)),
                                            TextSpan(
                                                text: strings
                                                    .get("ATLEAST_ALPHABET"),
                                                style: TextStyle(
                                                    color: bLettersCountMatch
                                                        ? Colors.teal
                                                        : Colors.red)),
                                            TextSpan(
                                                text: strings.get(
                                                    "ATLEAST_SPECIAL_CHARACTER"),
                                                style: TextStyle(
                                                    color:
                                                        bSpecialCharCountMatch
                                                            ? Colors.teal
                                                            : Colors.red)),
                                          ],
                                          style: TextStyle(
                                            color: Colors.red,
                                          ),
                                        ),
                                      )),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            ColorButton(
                              onPressed: () {
                                FocusScope.of(context)
                                    .requestFocus(new FocusNode());
                                if (_newPassFormKey.currentState.validate() &&
                                    passConstraintMatch) {
                                  if ((_newPasswordController.text ==
                                      _reEnterPasswordController.text)) {
                                    _submitNewPassword();
                                  } else {
                                    showMsg(strings.get("PASSWORD_NOT_MATCH"));
                                  }
                                } else if (!passConstraintMatch) {
                                  showMsg(strings
                                      .get("PASSWORD_CONSTRAINT_NOT_MATCHED"));
                                }
                              },
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 16.0, vertical: 12.0),
                                child: Text(
                                  strings.get("SUBMIT").toUpperCase(),
                                  style: Theme.of(context)
                                      .primaryTextTheme
                                      .title
                                      .copyWith(
                                        color: Colors.white,
                                      ),
                                ),
                              ),
                            )
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
        ),
      ],
    );

    // return ScaffoldPage(
    //   scaffoldKey: _scaffoldKey,
    //   appBar: AppBar(
    //     title: Text(
    //       strings.get("FORGOT_PASS_TITLE").toUpperCase(),
    //     ),
    //   ),
    //   body:
    //   ,
    // );
  }
}
