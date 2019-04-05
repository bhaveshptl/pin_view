import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:device_info/device_info.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_login/flutter_facebook_login.dart';

import 'package:playfantasy/appconfig.dart';
import 'package:playfantasy/commonwidgets/color_button.dart';
import 'package:playfantasy/commonwidgets/scaffoldpage.dart';
import 'package:playfantasy/commonwidgets/textbox.dart';
import 'package:playfantasy/redux/actions/loader_actions.dart';
import 'package:playfantasy/signup/signup.dart';
import 'package:playfantasy/utils/apiutil.dart';
import 'package:playfantasy/utils/authresult.dart';
import 'package:playfantasy/utils/httpmanager.dart';
import 'package:playfantasy/utils/stringtable.dart';
import 'package:playfantasy/utils/sharedprefhelper.dart';
import 'package:playfantasy/commonwidgets/forgotpassword.dart';
import 'package:playfantasy/commonwidgets/fantasypageroute.dart';

class SignInPage extends StatefulWidget {
  SignInPage();

  @override
  State<StatefulWidget> createState() => new SignInPageState();
}

class SignInPageState extends State<SignInPage> {
  String _authName;
  String _password;
  String _deviceId;

  bool _obscureText = true;
  bool bUpdateAppConfirmationShown = false;

  final formKey = new GlobalKey<FormState>();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey();

  static const _kFontFam = 'MyFlutterApp';
  static const IconData gplus_squared =
      const IconData(0xf0d4, fontFamily: _kFontFam);
  static const IconData facebook_squared =
      const IconData(0xf308, fontFamily: _kFontFam);

  @override
  void initState() {
    super.initState();

    Future<dynamic> firebasedeviceid = SharedPrefHelper.internal()
        .getFromSharedPref(ApiUtil.SHARED_PREFERENCE_FIREBASE_TOKEN);
    firebasedeviceid.then((value) {
      _deviceId = value;
    });
  }

  showLoader(bool bShow) {
    AppConfig.of(context)
        .store
        .dispatch(bShow ? LoaderShowAction() : LoaderHideAction());
  }

  updateStringTable(Map<String, dynamic> language) async {
    http.Request req = http.Request(
        "POST", Uri.parse(BaseUrl().apiUrl + ApiUtil.UPDATE_LANGUAGE_TABLE));
    req.body = json.encode({
      "language": int.parse(language["id"]),
    });
    await HttpManager(http.Client()).sendRequest(req).then(
      (http.Response res) {
        if (res.statusCode >= 200 && res.statusCode <= 299) {
          Map<String, dynamic> response = json.decode(res.body);
          if (response["update"]) {
            setState(() {
              strings.set(
                language: response["language"],
                table: response["table"],
              );
            });
            SharedPrefHelper().saveLanguageTable(
                version: response["version"],
                lang: response["language"],
                table: response["table"]);
          }
        }
      },
    );
  }

  _launchSignup(BuildContext context) {
    Navigator.of(context).pushReplacement(
      FantasyPageRoute(
        pageBuilder: (context) => Signup(),
      ),
    );
  }

  _doSignIn(String _authName, String _password) async {
    DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;

    showLoader(true);

    http.Request req =
        http.Request("POST", Uri.parse(BaseUrl().apiUrl + ApiUtil.LOGIN_URL));
    req.body = json.encode({
      "context": {
        "channel_id": HttpManager.channelId,
        "deviceId": _deviceId,
        "uid": "",
        "model": androidInfo.model,
        "platformType": androidInfo.version.baseOS,
        "manufacturer": androidInfo.manufacturer,
        "googleaddid": "",
        "serial": androidInfo.androidId
      },
      "value": {"auth_attribute": _authName, "password": _password}
    });
    return HttpManager(http.Client())
        .sendRequest(req)
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
      showLoader(false);
    });
  }

  _doGoogleLogin(BuildContext context) async {
    showLoader(true);
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
        ).whenComplete(() {
          showLoader(false);
        });
      },
    ).whenComplete(() {
      showLoader(false);
    });
  }

  _doFacebookLogin(BuildContext context) async {
    showLoader(true);
    var facebookLogin = new FacebookLogin();
    facebookLogin.loginBehavior = FacebookLoginBehavior.nativeWithFallback;
    var result = await facebookLogin
        .logInWithReadPermissions(['email', 'public_profile']);
    switch (result.status) {
      case FacebookLoginStatus.loggedIn:
        _sendTokenToAuthenticate(result.accessToken.token, 2);
        break;
      case FacebookLoginStatus.cancelledByUser:
        showLoader(false);
        break;
      case FacebookLoginStatus.error:
        showLoader(false);
        break;
      default:
        showLoader(false);
    }
  }

  _sendTokenToAuthenticate(String token, int authFor) async {
    http.Client()
        .post(
      BaseUrl().apiUrl +
          (authFor == 1
              ? ApiUtil.GOOGLE_LOGIN_URL
              : (authFor == 2
                  ? ApiUtil.FACEBOOK_LOGIN_URL
                  : ApiUtil.GOOGLE_LOGIN_URL)),
      headers: {'Content-type': 'application/json'},
      body: json.encode({
        "context": {
          "channel_id": HttpManager.channelId,
        },
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
      showLoader(false);
    });
  }

  _showForgotPassword() async {
    final result = await Navigator.of(context).push(
      FantasyPageRoute(
        pageBuilder: (context) => ForgotPassword(),
        fullscreenDialog: true,
      ),
    );

    if (result != null && result == true) {
      _scaffoldKey.currentState.showSnackBar(
          SnackBar(content: Text(strings.get("PASSWORD_CHANGED"))));
    }
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldPage(
      scaffoldKey: _scaffoldKey,
      appBar: AppBar(
        title: Padding(
          padding: EdgeInsets.all(8.0),
          child: Image.asset("images/logo_with_name.png"),
        ),
        actions: <Widget>[
          Padding(
            padding: EdgeInsets.all(8.0),
            child: ColorButton(
              onPressed: () {
                _launchSignup(context);
              },
              child: Text(
                "Register".toUpperCase(),
                style: TextStyle(
                  color: Theme.of(context).primaryColor,
                  fontWeight: FontWeight.w900,
                ),
              ),
              color: Color.fromRGBO(243, 180, 81, 1),
            ),
          )
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: <Widget>[
            Image.asset("images/referal.png"),
            Padding(
              padding: EdgeInsets.symmetric(vertical: 16.0),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      "Welcome! Login & Start Playing.",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Theme.of(context).primaryColor,
                        fontWeight: FontWeight.w900,
                        fontSize:
                            Theme.of(context).primaryTextTheme.subhead.fontSize,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 48.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: Form(
                          key: formKey,
                          child: Column(
                            children: <Widget>[
                              Row(
                                children: <Widget>[
                                  Expanded(
                                    child: SimpleTextBox(
                                      onSaved: (val) => _authName = val,
                                      labelText: "Username or Email",
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
                              Padding(
                                padding: EdgeInsets.only(top: 16.0),
                                child: Row(
                                  children: <Widget>[
                                    Expanded(
                                      child: SimpleTextBox(
                                        onSaved: (val) => _password = val,
                                        labelText: "Password",
                                        suffixIcon: IconButton(
                                          onPressed: () {
                                            setState(() {
                                              _obscureText = !_obscureText;
                                            });
                                          },
                                          padding: EdgeInsets.all(0.0),
                                          icon: Icon(
                                            _obscureText
                                                ? Icons.visibility
                                                : Icons.visibility_off,
                                          ),
                                        ),
                                        validator: (value) {
                                          if (value.isEmpty) {
                                            return strings
                                                .get("PASSWORD_ERROR");
                                          }
                                        },
                                        obscureText: _obscureText,
                                      ),
                                    )
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: <Widget>[
                      InkWell(
                        onTap: () {
                          _showForgotPassword();
                        },
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(4.0, 4.0, 0.0, 4.0),
                          child: Text(
                            strings.get("FORGOT_PASSWORD"),
                            style: TextStyle(
                              color: Colors.black54,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      )
                    ],
                  ),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: ColorButton(
                          onPressed: () {
                            if (formKey.currentState.validate()) {
                              formKey.currentState.save();
                              _doSignIn(_authName, _password);
                            }
                          },
                          child: Container(
                            child: Text(
                              "Login",
                              style: Theme.of(context)
                                  .primaryTextTheme
                                  .button
                                  .copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                  ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 8.0),
                    child: Row(
                      children: <Widget>[
                        Expanded(
                          flex: 1,
                          child: Container(),
                        ),
                        Expanded(
                          flex: 3,
                          child: Row(
                            children: <Widget>[
                              Expanded(
                                child: Divider(
                                  color: Colors.black54,
                                ),
                              ),
                              CircleAvatar(
                                radius: 12.0,
                                backgroundColor: Colors.white,
                                child: Text(
                                  strings.get("OR").toUpperCase(),
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context)
                                      .primaryTextTheme
                                      .caption
                                      .copyWith(
                                        color: Colors.black54,
                                      ),
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
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 8.0),
                    child: Row(
                      children: <Widget>[
                        Expanded(
                          child: ColorButton(
                            onPressed: () {
                              _doGoogleLogin(context);
                            },
                            color: Colors.white,
                            child: Container(
                              padding: EdgeInsets.symmetric(vertical: 8.0),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: <Widget>[
                                  Icon(
                                    gplus_squared,
                                    color: Colors.black,
                                    size: 32.0,
                                  ),
                                  Padding(
                                    padding:
                                        EdgeInsets.symmetric(horizontal: 16.0),
                                    child: Container(
                                      height: 32.0,
                                      width: 1.0,
                                      color: Colors.black26,
                                    ),
                                  ),
                                  Expanded(
                                    child: Text(
                                      "Continue with Google",
                                      style: TextStyle(
                                        color: Colors.black,
                                        fontWeight: FontWeight.w900,
                                      ),
                                      textAlign: TextAlign.left,
                                    ),
                                  ),
                                ],
                              ),
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
                          child: ColorButton(
                            onPressed: () {
                              _doFacebookLogin(context);
                            },
                            color: Color.fromRGBO(59, 89, 153, 1),
                            child: Container(
                              padding: EdgeInsets.symmetric(vertical: 8.0),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: <Widget>[
                                  Icon(
                                    facebook_squared,
                                    color: Colors.white,
                                    size: 32.0,
                                  ),
                                  Padding(
                                    padding:
                                        EdgeInsets.symmetric(horizontal: 16.0),
                                    child: Container(
                                      height: 32.0,
                                      width: 1.0,
                                      color: Colors.black26,
                                    ),
                                  ),
                                  Expanded(
                                    child: Text(
                                      "Continue with Facebook",
                                      style: TextStyle(color: Colors.white),
                                      textAlign: TextAlign.left,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        )
                      ],
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Text(
                        "Not a Member yet?",
                        style: TextStyle(color: Colors.black38),
                      ),
                      InkWell(
                        onTap: () {
                          _launchSignup(context);
                        },
                        child: Padding(
                          padding: EdgeInsets.all(4.0),
                          child: Text(
                            "Register now",
                            style: TextStyle(
                              color: Theme.of(context).primaryColor,
                              fontWeight: FontWeight.bold,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      )
                    ],
                  ),
                  AppConfig.of(context).channelId != '3' &&
                          AppConfig.of(context).channelId != '10'
                      ? Column(
                          children: <Widget>[
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: <Widget>[
                                Text("powered by"),
                              ],
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: <Widget>[
                                Image.asset(
                                  "images/playfantasy.png",
                                  height: 64.0,
                                  width: 64.0,
                                ),
                              ],
                            ),
                          ],
                        )
                      : Container()
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
