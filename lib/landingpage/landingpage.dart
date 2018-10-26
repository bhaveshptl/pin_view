import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_login/flutter_facebook_login.dart';
import 'package:playfantasy/commonwidgets/forgotpassword.dart';

import 'package:playfantasy/signup/signup.dart';
import 'package:playfantasy/utils/apiutil.dart';
import 'package:playfantasy/utils/authresult.dart';
import 'package:playfantasy/utils/stringtable.dart';

class LandingPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => new LandingPageState();
}

class LandingPageState extends State<LandingPage> {
  String _authName;
  String _password;
  bool _obscureText = true;

  final formKey = new GlobalKey<FormState>();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey();

  // Toggles the password show status
  void _toggle() {
    setState(() {
      _obscureText = !_obscureText;
    });
  }

  _launchSignup(BuildContext context) {
    Navigator.of(context).push(
      new MaterialPageRoute(
        builder: (context) => Signup(),
        fullscreenDialog: true,
      ),
    );
  }

  _doSignIn(String _authName, String _password) async {
    return new http.Client()
        .post(
      ApiUtil.LOGIN_URL,
      headers: {'Content-type': 'application/json'},
      body: json.encoder.convert({
        "context": {"channel_id": 3},
        "value": {"auth_attribute": _authName, "password": _password}
      }),
    )
        .then((http.Response res) {
      if (res.statusCode >= 200 && res.statusCode <= 299) {
        AuthResult(res, _scaffoldKey).processResult(() {});
      } else {
        final dynamic response = json.decode(res.body).cast<String, dynamic>();
        setState(() {
          _scaffoldKey.currentState
              .showSnackBar(SnackBar(content: Text(response['error'])));
        });
      }
    });
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

  _showForgotPassword() async {
    final result = await Navigator.of(context).push(MaterialPageRoute(
      builder: (context) => ForgotPassword(),
      fullscreenDialog: true,
    ));

    if (result != null && result == true) {
      _scaffoldKey.currentState.showSnackBar(
          SnackBar(content: Text(strings.get("PASSWORD_CHANGED"))));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.only(top: 16.0, bottom: 24.0),
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
                              strings.get("SIGN_IN_TO_CONTINUE"),
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
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
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
              Row(
                children: <Widget>[
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(left: 8.0, right: 8.0),
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
                                      labelText: strings.get("USERNAME"),
                                      icon: const Padding(
                                        padding:
                                            const EdgeInsets.only(top: 15.0),
                                        child: const Icon(Icons.face),
                                      ),
                                    ),
                                    validator: (value) {
                                      if (value.isEmpty) {
                                        return strings.get("USERNAME_ERROR");
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
                                      icon: const Padding(
                                        padding:
                                            const EdgeInsets.only(top: 15.0),
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
                ],
              ),
              ListTile(
                leading: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: <Widget>[
                    FlatButton(
                      onPressed: () {
                        _showForgotPassword();
                      },
                      padding: EdgeInsets.fromLTRB(4.0, 0.0, 2.0, 0.0),
                      child: Text(
                        strings.get("FORGOT_PASSWORD"),
                        style: TextStyle(color: Colors.black54),
                      ),
                    )
                  ],
                ),
              ),
              ListTile(
                leading: Row(
                  children: <Widget>[
                    Expanded(
                      child: RaisedButton(
                        onPressed: () {
                          if (formKey.currentState.validate()) {
                            formKey.currentState.save();
                            _doSignIn(_authName, _password);
                          }
                        },
                        color: Theme.of(context).primaryColor,
                        child: Container(
                          child: Text(
                            strings.get("SIGNIN").toUpperCase(),
                            style: TextStyle(color: Colors.white70),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              ListTile(
                leading: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Text(
                      strings.get("DONT_HAVE_ACCOUNT"),
                      style: TextStyle(color: Colors.black38),
                    ),
                    FlatButton(
                      onPressed: () {
                        _launchSignup(context);
                      },
                      padding: EdgeInsets.fromLTRB(4.0, 0.0, 2.0, 0.0),
                      child: Text(
                        strings.get("SIGNUP").toUpperCase(),
                        style: TextStyle(
                            color: Colors.black54, fontWeight: FontWeight.bold),
                      ),
                    )
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
