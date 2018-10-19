import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_login/flutter_facebook_login.dart';

import 'package:playfantasy/utils/apiutil.dart';
import 'package:playfantasy/utils/authresult.dart';
import 'package:playfantasy/utils/stringtable.dart';

class Signup extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => new SignupState();
}

class SignupState extends State<Signup> {
  String _authName;
  String _password;
  String _referralCode;
  bool _obscureText = true;
  bool _bShowReferralInput = false;

  final formKey = new GlobalKey<FormState>();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey();

  _showReferralInput() {
    setState(() {
      _bShowReferralInput = !_bShowReferralInput;
    });
  }

  // Toggles the password show status
  void _toggle() {
    setState(() {
      _obscureText = !_obscureText;
    });
  }

  _doSignUp() async {
    Map<String, dynamic> _payload = {};
    if (isMobileNumber(_authName)) {
      _payload["phone"] = _authName;
    } else {
      _payload["email"] = _authName;
    }
    _payload["password"] = _password;
    _payload["context"] = {
      "refCode": _referralCode,
      "channel_id": 3,
    };

    return http.Client()
        .post(
      ApiUtil.SIGN_UP,
      headers: {'Content-type': 'application/json'},
      body: json.encode(_payload),
    )
        .then((http.Response res) {
      if (res.statusCode >= 200 && res.statusCode <= 299) {
        AuthResult(res, _scaffoldKey).processResult(() {});
      } else {
        final dynamic response = json.decode(res.body).cast<String, dynamic>();
        setState(() {
          _scaffoldKey.currentState.showSnackBar(
              SnackBar(content: Text(response['error']['erroMessage'])));
        });
      }
    });
  }

  bool isMobileNumber(String input) {
    if (input.length == 10) {
      return true;
    }
    return false;
  }

  _doGoogleLogin(BuildContext context) async {
    GoogleSignIn _googleSignIn = new GoogleSignIn(
      scopes: [
        'email',
        'https://www.googleapis.com/auth/contacts.readonly',
      ],
    );

    _googleSignIn.signIn().then(
      (GoogleSignInAccount _googleSignInAccount) {
        _googleSignInAccount.authentication.then(
          (GoogleSignInAuthentication _googleSignInAuthentication) {
            _sendTokenToAuthenticate(
                _googleSignInAuthentication.accessToken, 1);
          },
        );
      },
    );
  }

  _doFacebookLogin(BuildContext context) async {
    var facebookLogin = new FacebookLogin();
    facebookLogin.loginBehavior = FacebookLoginBehavior.nativeWithFallback;
    var result = await facebookLogin
        .logInWithReadPermissions(['email', 'public_profile']);

    switch (result.status) {
      case FacebookLoginStatus.loggedIn:
        _sendTokenToAuthenticate(result.accessToken.token, 2);
        break;
      case FacebookLoginStatus.cancelledByUser:
        break;
      case FacebookLoginStatus.error:
        break;
    }
  }

  _sendTokenToAuthenticate(String token, int authFor) async {
    http.Client()
        .post(
      authFor == 1
          ? ApiUtil.GOOGLE_LOGIN_URL
          : (authFor == 2
              ? ApiUtil.FACEBOOK_LOGIN_URL
              : ApiUtil.GOOGLE_LOGIN_URL),
      headers: {'Content-type': 'application/json'},
      body: json.encode({
        "context": {"channel_id": 3},
        "accessToken": token
      }),
    )
        .then((http.Response res) {
      if (res.statusCode >= 200 && res.statusCode <= 299) {
        AuthResult(res, _scaffoldKey).processResult(
          () {},
        );
      } else {
        final dynamic response = json.decode(res.body).cast<String, dynamic>();
        setState(() {
          _scaffoldKey.currentState
              .showSnackBar(SnackBar(content: Text(response['error'])));
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text("SIGN UP"),
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.only(bottom: 24.0),
                    child: Image(
                      height: 80.0,
                      fit: BoxFit.scaleDown,
                      image: new AssetImage("images/fantasy-logo.png"),
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: ListTile(
                  leading: Column(
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Text(
                            strings.get("WELCOME_TO_FANTASY"),
                            style: TextStyle(
                                color: Colors.black87,
                                fontWeight: FontWeight.bold,
                                fontSize: Theme.of(context)
                                    .primaryTextTheme
                                    .headline
                                    .fontSize),
                          ),
                        ],
                      ),
                      Row(
                        children: <Widget>[
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              strings.get("FEW_SEC_AWAY"),
                              style: TextStyle(
                                  color: Colors.black38,
                                  fontSize: Theme.of(context)
                                      .primaryTextTheme
                                      .subhead
                                      .fontSize),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              ListTile(
                leading: Row(
                  children: <Widget>[
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: RaisedButton(
                          onPressed: () {
                            _doGoogleLogin(context);
                          },
                          color: Colors.red,
                          textColor: Colors.white70,
                          child: Text(
                            strings.get("GOOGLE").toUpperCase(),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(left: 8.0),
                        child: RaisedButton(
                          onPressed: () {
                            _doFacebookLogin(context);
                          },
                          color: Colors.blue,
                          textColor: Colors.white70,
                          child: Text(
                            strings.get("FACEBOOK").toUpperCase(),
                          ),
                        ),
                      ),
                    )
                  ],
                ),
              ),
              ListTile(
                leading: Padding(
                  padding: const EdgeInsets.fromLTRB(0.0, 8.0, 0.0, 16.0),
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        flex: 1,
                        child: Container(),
                      ),
                      Expanded(
                        flex: 1,
                        child: Row(
                          children: <Widget>[
                            Expanded(
                              child: Divider(
                                color: Colors.black54,
                              ),
                            ),
                            Expanded(
                              child: Text(
                                strings.get("OR").toUpperCase(),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            Expanded(
                              child: Divider(
                                color: Colors.black54,
                              ),
                            )
                          ],
                        ),
                      ),
                      Expanded(
                        flex: 1,
                        child: Container(),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
                child: ListTile(
                  leading: Container(
                    child: Form(
                      key: formKey,
                      child: Column(
                        children: <Widget>[
                          Row(
                            children: <Widget>[
                              Expanded(
                                child: TextFormField(
                                  onSaved: (val) => _authName = val,
                                  decoration: InputDecoration(
                                    labelText: strings.get("EMAIL_OR_MOBILE"),
                                    icon: const Padding(
                                      padding: const EdgeInsets.only(top: 15.0),
                                      child: const Icon(Icons.face),
                                    ),
                                  ),
                                  validator: (value) {
                                    if (value.isEmpty) {
                                      return strings
                                          .get("EMAIL_OR_MOBILE_ERROR");
                                    }
                                  },
                                  keyboardType: TextInputType.emailAddress,
                                ),
                              )
                            ],
                          ),
                          Row(
                            children: <Widget>[
                              Expanded(
                                child: TextFormField(
                                  onSaved: (val) => _password = val,
                                  decoration: InputDecoration(
                                    labelText: strings.get("PASSWORD"),
                                    hintText: "Minimum 6 characters required",
                                    icon: const Padding(
                                      padding: const EdgeInsets.only(top: 15.0),
                                      child: const Icon(Icons.lock),
                                    ),
                                  ),
                                  validator: (value) {
                                    if (value.isEmpty) {
                                      return strings.get("PASSWORD_ERROR");
                                    }
                                  },
                                  obscureText: _obscureText,
                                ),
                              )
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16.0, 32.0, 16.0, 0.0),
                child: Row(
                  children: <Widget>[
                    Text(
                      strings.get("HAVE_REFERRAL_CODE"),
                    ),
                    Container(
                      height: 16.0,
                      child: FlatButton(
                        child: Text(
                          strings.get("APPLY_NOW").toUpperCase(),
                        ),
                        onPressed: () {
                          _showReferralInput();
                        },
                      ),
                    )
                  ],
                ),
              ),
              _bShowReferralInput
                  ? Padding(
                      padding: const EdgeInsets.fromLTRB(16.0, 0.0, 16.0, 0.0),
                      child: Row(
                        children: <Widget>[
                          Expanded(
                            child: TextFormField(
                              onSaved: (val) => _referralCode = val,
                              decoration: InputDecoration(
                                labelText: strings.get("REFERRAL_CODE"),
                              ),
                            ),
                          )
                        ],
                      ),
                    )
                  : Container(),
              Padding(
                padding: const EdgeInsets.fromLTRB(0.0, 16.0, 0.0, 8.0),
                child: ListTile(
                  leading: Column(
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Text(
                            strings.get("BY_REGISTERING"),
                          ),
                          Container(
                            height: 18.0,
                            child: FlatButton(
                              padding: EdgeInsets.fromLTRB(4.0, 0.0, 0.0, 0.0),
                              child: Text(strings.get("TERMS_AND_CONDITION")),
                              onPressed: () {},
                            ),
                          )
                        ],
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Row(
                          children: <Widget>[
                            Expanded(
                              child: RaisedButton(
                                onPressed: () {
                                  if (formKey.currentState.validate()) {
                                    formKey.currentState.save();
                                    _doSignUp();
                                  }
                                },
                                color: Theme.of(context).primaryColor,
                                child: Container(
                                  child: Text(
                                    strings.get("SIGNUP").toUpperCase(),
                                    style: TextStyle(color: Colors.white70),
                                  ),
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
            ],
          ),
        ),
      ),
    );
  }
}
