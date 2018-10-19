import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'package:playfantasy/utils/apiutil.dart';
import 'package:playfantasy/utils/stringtable.dart';

class ForgotPassword extends StatefulWidget {
  @override
  _ForgotPasswordState createState() => _ForgotPasswordState();
}

class _ForgotPasswordState extends State<ForgotPassword> {
  String _authName;
  String _otpCookie;
  String _authError = "";
  int _forgotPassMode = 1;
  String _passChangeError = "";
  final GlobalKey<FormState> _formKey = new GlobalKey<FormState>();
  final GlobalKey<FormState> _newPassFormKey = new GlobalKey<FormState>();
  final TextEditingController _authNameController = new TextEditingController();
  final TextEditingController _otpController = new TextEditingController();
  final TextEditingController _newPasswordController =
      new TextEditingController();
  final TextEditingController _reEnterPasswordController =
      new TextEditingController();

  _requestOTP() async {
    _authName = _authNameController.text;
    http.Client()
        .post(
      ApiUtil.FORGOT_PASSWORD,
      headers: {'Content-type': 'application/json'},
      body: json.encode({
        "username": _authName,
        "isEmail": _authName.indexOf("@") != -1,
      }),
    )
        .then((http.Response res) {
      if (res.statusCode >= 200 && res.statusCode <= 299) {
        _otpCookie = res.headers["set-cookie"];
        setState(() {
          if (_authName.indexOf("@") != -1) {
            _forgotPassMode = 2;
          } else {
            _forgotPassMode = 3;
          }
        });
      }
    });
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
    if (value.length != 10)
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
      ApiUtil.RESET_PASSWORD,
      headers: {'Content-type': 'application/json', "cookie": _otpCookie},
      body: json.encode({
        "username": _authName,
        "otp": _otpController.text,
        "password": _newPasswordController.text,
        "context": {"source": "", "channel_id": "3"}
      }),
    )
        .then((http.Response res) {
      if (res.statusCode >= 200 && res.statusCode <= 299) {
        Map<String, dynamic> respose = json.decode(res.body);
        if (respose["err"] != null && respose["err"]) {
          setState(() {
            _passChangeError = respose["errMsg"];
          });
        } else {
          Navigator.of(context).pop(true);
        }
        print(res);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return _forgotPassMode == 1
        ? AlertDialog(
            title: Text(
              strings.get("FORGOT_PASS_TITLE"),
            ),
            content: Column(
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
                            Row(
                              children: <Widget>[
                                Expanded(
                                  child: TextFormField(
                                    controller: _authNameController,
                                    decoration: InputDecoration(
                                      labelText: strings.get("EMAIL_OR_MOBILE"),
                                    ),
                                    validator: (value) {
                                      if (value.isEmpty) {
                                        return strings
                                            .get("EMAIL_OR_MOBILE_ERROR");
                                      }
                                    },
                                    keyboardType: TextInputType.emailAddress,
                                  ),
                                ),
                              ],
                            ),
                            _authError.length > 0
                                ? Padding(
                                    padding: const EdgeInsets.only(top: 8.0),
                                    child: Row(
                                      children: <Widget>[
                                        Text(
                                          _authError,
                                          style: TextStyle(
                                              color: Colors.redAccent),
                                        ),
                                      ],
                                    ),
                                  )
                                : Container(),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            actions: <Widget>[
              FlatButton(
                child: Text(
                  strings.get("SUBMIT").toUpperCase(),
                ),
                onPressed: () {
                  String emailError = validateEmail(_authNameController.text);
                  String mobileError = validateMobile(_authNameController.text);
                  if (emailError != null && mobileError != null) {
                    setState(() {
                      _authError = strings.get("VALID_EMAIL_OR_MOBILE_ERROR");
                    });
                  } else {
                    setState(() {
                      _authError = "";
                    });
                    _requestOTP();
                  }
                },
              )
            ],
          )
        : AlertDialog(
            title: Text(
              strings.get("FORGOT_PASS_TITLE"),
            ),
            content: GestureDetector(
              onTap: () {
                FocusScope.of(context).requestFocus(new FocusNode());
              },
              child: SingleChildScrollView(
                child: Form(
                  key: _newPassFormKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      _forgotPassMode == 2
                          ? Row(
                              children: <Widget>[
                                Expanded(
                                  child: Text(
                                    strings.get("LINK_SENT"),
                                  ),
                                )
                              ],
                            )
                          : Container(),
                      _forgotPassMode == 2
                          ? Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: <Widget>[
                                  Expanded(
                                    child: Container(),
                                  ),
                                  Expanded(
                                    child: Row(
                                      children: <Widget>[
                                        Expanded(
                                          child: Padding(
                                            padding: const EdgeInsets.only(
                                                right: 8.0),
                                            child: Container(
                                              color: Colors.black12,
                                              height: 2.0,
                                            ),
                                          ),
                                        ),
                                        Expanded(
                                          child: Text(
                                            strings.get("OR").toUpperCase(),
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                        Expanded(
                                          child: Padding(
                                            padding: const EdgeInsets.only(
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
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: TextFormField(
                              controller: _otpController,
                              decoration: InputDecoration(
                                labelText: strings.get("ENTER_OTP"),
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
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: TextFormField(
                              controller: _newPasswordController,
                              decoration: InputDecoration(
                                labelText: strings.get("NEW_PASSWORD"),
                              ),
                              validator: (value) {
                                if (value.isEmpty) {
                                  return strings.get("NEW_PASSWORD_ERROR");
                                }
                              },
                              keyboardType: TextInputType.text,
                              obscureText: true,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: TextFormField(
                              controller: _reEnterPasswordController,
                              decoration: InputDecoration(
                                labelText: strings.get("REENTER_PASSWORD"),
                              ),
                              validator: (value) {
                                if (value.isEmpty) {
                                  return strings.get("REENTER_PASSWORD_ERROR");
                                }
                              },
                              keyboardType: TextInputType.text,
                              obscureText: true,
                            ),
                          ),
                        ],
                      ),
                      _passChangeError.length > 0
                          ? Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Row(
                                children: <Widget>[
                                  Text(
                                    _passChangeError,
                                    style: TextStyle(color: Colors.redAccent),
                                  ),
                                ],
                              ),
                            )
                          : Container(),
                    ],
                  ),
                ),
              ),
            ),
            actions: <Widget>[
              FlatButton(
                child: Text(
                  strings.get("SUBMIT").toUpperCase(),
                ),
                onPressed: () {
                  FocusScope.of(context).requestFocus(new FocusNode());
                  if (_newPassFormKey.currentState.validate()) {
                    if ((_newPasswordController.text ==
                        _reEnterPasswordController.text)) {
                      _submitNewPassword();
                    } else {
                      setState(() {
                        _passChangeError = strings.get("PASSWORD_NOT_MATCH");
                      });
                    }
                  }
                },
              )
            ],
          );
  }
}
