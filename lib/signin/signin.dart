import 'dart:ui';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_login/flutter_facebook_login.dart';

import 'package:playfantasy/utils/apiutil.dart';
import 'package:playfantasy/signin/siginform.dart';
import 'package:playfantasy/utils/authresult.dart';
import 'package:playfantasy/commonwidgets/loader.dart';

class Signin extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => new SigninState();
}

class SigninState extends State<Signin> {
  bool isLoggedIn = false;
  bool _bShowLoader = false;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey();

  _showLoader(bool bShow) {
    setState(() {
      _bShowLoader = bShow;
    });
  }

  _doFacebookLogin(BuildContext context) async {
    var facebookLogin = new FacebookLogin();
    var result = await facebookLogin.logInWithReadPermissions(['email','public_profile']);

    switch (result.status) {
      case FacebookLoginStatus.loggedIn:
        _sendTokenToAuthenticate(result.accessToken.token);
        // _showLoggedInUI();
        break;
      case FacebookLoginStatus.cancelledByUser:
        // _showCancelledMessage();
        break;
      case FacebookLoginStatus.error:
        // _showErrorOnUI(result.errorMessage);
        break;
    }
  }

  _sendTokenToAuthenticate(String token) async {
    http.Client()
        .post(
      ApiUtil.FACEBOOK_LOGIN_URL,
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

  doGoogleLogin(BuildContext context) async {
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
            _googleSignInAccount.authHeaders.then((onValue) {
              print(onValue);
            });
            http.Client()
                .post(
              ApiUtil.GOOGLE_LOGIN_URL,
              headers: {'Content-type': 'application/json'},
              body: json.encode({
                "context": {"channel_id": 3},
                "accessToken": _googleSignInAuthentication.idToken
              }),
            )
                .then((http.Response res) {
              if (res.statusCode >= 200 && res.statusCode <= 299) {
                AuthResult(res, _scaffoldKey).processResult(
                  () {},
                );
              } else {
                final dynamic response =
                    json.decode(res.body).cast<String, dynamic>();
                setState(() {
                  _scaffoldKey.currentState
                      .showSnackBar(SnackBar(content: Text(response['error'])));
                });
              }
            });
          },
        );
      },
    );
  }

  doSignIn(String _authName, String _password) async {
    _showLoader(true);
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
        AuthResult(res, _scaffoldKey).processResult(() {
          setState(() {
            _showLoader(false);
          });
        });
      } else {
        final dynamic response = json.decode(res.body).cast<String, dynamic>();
        setState(() {
          _showLoader(false);
          _scaffoldKey.currentState
              .showSnackBar(SnackBar(content: Text(response['error'])));
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        Scaffold(
          key: _scaffoldKey,
          appBar: AppBar(
            title: Text("SIGN IN"),
          ),
          body: Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                  image: AssetImage("images/landingPageBG.jpg"),
                  fit: BoxFit.cover),
            ),
            child: Center(
              child: ClipRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
                  child: Container(
                    child: Column(
                      children: <Widget>[
                        Row(
                          children: <Widget>[
                            Expanded(
                              child: SigninForm(
                                onSubmit: (_authName, _password) {
                                  doSignIn(_authName, _password);
                                },
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: <Widget>[
                            OutlineButton(
                              onPressed: () {
                                doGoogleLogin(context);
                              },
                              child: Text("Google"),
                            ),
                            OutlineButton(
                              onPressed: () {
                                _doFacebookLogin(context);
                              },
                              child: Text("Facebook"),
                            )
                          ],
                        )
                      ],
                    ),
                    height: 340.0,
                    width: MediaQuery.of(context).size.width * 0.9,
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10.0),
                        color: Colors.grey.shade200.withOpacity(0.5)),
                  ),
                ),
              ),
            ),
          ),
        ),
        _bShowLoader
            ? Center(
                child: Container(
                  color: Colors.black54,
                  child: Loader(),
                  constraints: BoxConstraints.expand(),
                ),
              )
            : Container(),
      ],
    );
  }
}
