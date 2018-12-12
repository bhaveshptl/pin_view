import 'dart:async';
import 'dart:convert';
import 'package:device_info/device_info.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_login/flutter_facebook_login.dart';
import 'package:playfantasy/appconfig.dart';
import 'package:playfantasy/commonwidgets/update.dart';

import 'package:playfantasy/signup/signup.dart';
import 'package:playfantasy/utils/apiutil.dart';
import 'package:playfantasy/utils/authresult.dart';
import 'package:playfantasy/utils/httpmanager.dart';
import 'package:playfantasy/utils/stringtable.dart';
import 'package:playfantasy/utils/sharedprefhelper.dart';
import 'package:playfantasy/commonwidgets/chooselanguage.dart';
import 'package:playfantasy/commonwidgets/forgotpassword.dart';

class LandingPage extends StatefulWidget {
  final String appUrl;
  final bool isForceUpdate;
  final bool chooseLanguage;
  final bool updateAvailable;
  final List<dynamic> languages;

  LandingPage({
    this.appUrl,
    this.languages,
    this.isForceUpdate,
    this.chooseLanguage,
    this.updateAvailable,
  });

  @override
  State<StatefulWidget> createState() => new LandingPageState();
}

class LandingPageState extends State<LandingPage> {
  String _authName;
  String _password;
  String _deviceId;
  bool _obscureText = true;
  List<dynamic> _languages;
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
    if (widget.chooseLanguage != null && widget.chooseLanguage) {
      _showChooseLanguage();
    }
    if (widget.languages == null) {
      Future<dynamic> futureInitData =
          SharedPrefHelper().getFromSharedPref(ApiUtil.KEY_INIT_DATA);
      futureInitData.then((onValue) {
        setState(() {
          _languages = json.decode(onValue)["languages"];
        });
      });
    } else {
      _languages = widget.languages;
    }

    Future<dynamic> firebasedeviceid = SharedPrefHelper.internal()
        .getFromSharedPref(ApiUtil.SHARED_PREFERENCE_FIREBASE_TOKEN);
    firebasedeviceid.then((value) {
      _deviceId = value;
    });
  }

  _showUpdatingAppDialog(String url) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return DownloadAPK(
          url: url,
          isForceUpdate: widget.isForceUpdate,
        );
      },
      barrierDismissible: !widget.isForceUpdate,
    );
  }

  _showChooseLanguage() {
    Timer(
      Duration(milliseconds: 2000),
      () {
        _scaffoldKey.currentState.showBottomSheet(
          (context) {
            return Container(
              height: 300.0,
              decoration: new BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16.0),
                  topRight: Radius.circular(16.0),
                ),
                boxShadow: [
                  new BoxShadow(
                    color: Colors.black,
                    blurRadius: 20.0,
                  ),
                ],
              ),
              child: ChooseLanguage(
                languages: _languages,
                onLanguageChange: updateStringTable,
              ),
            );
          },
        );
      },
    );
  }

  updateStringTable(Map<String, dynamic> language) async {
    http.Request req = http.Request(
        "POST", Uri.parse(BaseUrl.apiUrl + ApiUtil.UPDATE_LANGUAGE_TABLE));
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
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Signup(),
        fullscreenDialog: true,
      ),
    );
  }

  _doSignIn(String _authName, String _password) async {
    DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;

    http.Request req =
        http.Request("POST", Uri.parse(BaseUrl.apiUrl + ApiUtil.LOGIN_URL));
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
      BaseUrl.apiUrl +
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
    if (widget.updateAvailable != null &&
        widget.updateAvailable &&
        !bUpdateAppConfirmationShown) {
      bUpdateAppConfirmationShown = true;
      Timer(Duration(seconds: 1), () {
        _showUpdatingAppDialog(widget.appUrl);
      });
    }

    return Scaffold(
      key: _scaffoldKey,
      body: Stack(
        children: <Widget>[
          Center(
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
                          image: new AssetImage("images/logo.png"),
                        ),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: ListTile(
                      leading: Column(
                        children: <Widget>[
                          Row(
                            children: <Widget>[
                              Text(
                                "Welcome to " +
                                    AppConfig.of(context).appName +
                                    ",",
                                style: TextStyle(
                                    color: Colors.black87,
                                    fontWeight: FontWeight.bold,
                                    fontSize: Theme.of(context)
                                        .primaryTextTheme
                                        .title
                                        .fontSize),
                              ),
                            ],
                          ),
                          Row(
                            children: <Widget>[
                              Padding(
                                padding: const EdgeInsets.only(top: 4.0),
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
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: <Widget>[
                                  Icon(gplus_squared),
                                  Padding(
                                    padding: EdgeInsets.only(left: 4.0),
                                    child: Text(
                                      strings.get("GOOGLE").toUpperCase(),
                                    ),
                                  ),
                                ],
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
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: <Widget>[
                                  Icon(facebook_squared),
                                  Padding(
                                    padding: EdgeInsets.only(left: 4.0),
                                    child: Text(
                                      strings.get("FACEBOOK").toUpperCase(),
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
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(left: 16.0, right: 16.0),
                          child: Form(
                            key: formKey,
                            child: Column(
                              children: <Widget>[
                                Padding(
                                  padding: EdgeInsets.only(top: 8.0),
                                  child: Row(
                                    children: <Widget>[
                                      Expanded(
                                        child: TextFormField(
                                          onSaved: (val) => _authName = val,
                                          decoration: InputDecoration(
                                            labelText: "Email or Mobile number",
                                            contentPadding: EdgeInsets.all(0.0),
                                            prefixIcon: Icon(
                                              Icons.face,
                                              size: 16.0,
                                            ),
                                            border: OutlineInputBorder(
                                              borderSide: BorderSide(
                                                color: Colors.black38,
                                              ),
                                            ),
                                          ),
                                          validator: (value) {
                                            if (value.isEmpty) {
                                              return strings
                                                  .get("USERNAME_ERROR");
                                            }
                                          },
                                          keyboardType:
                                              TextInputType.emailAddress,
                                        ),
                                      )
                                    ],
                                  ),
                                ),
                                Padding(
                                  padding: EdgeInsets.only(top: 24.0),
                                  child: Row(
                                    children: <Widget>[
                                      Expanded(
                                        child: TextFormField(
                                          onSaved: (val) => _password = val,
                                          decoration: InputDecoration(
                                            labelText: strings.get("PASSWORD"),
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
                                                  _obscureText = !_obscureText;
                                                });
                                              },
                                              child: Icon(
                                                _obscureText
                                                    ? Icons.visibility
                                                    : Icons.visibility_off,
                                                size: 16.0,
                                              ),
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
                      ),
                    ],
                  ),
                  Padding(
                    padding:
                        EdgeInsets.only(right: 16.0, top: 4.0, bottom: 8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: <Widget>[
                        InkWell(
                          onTap: () {
                            _showForgotPassword();
                          },
                          child: Padding(
                            padding: EdgeInsets.only(
                                left: 4.0, top: 2.0, bottom: 2.0),
                            child: Text(
                              strings.get("FORGOT_PASSWORD"),
                              style: TextStyle(color: Colors.black54),
                            ),
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Text(
                        strings.get("DONT_HAVE_ACCOUNT"),
                        style: TextStyle(color: Colors.black38),
                      ),
                      InkWell(
                        onTap: () {
                          _launchSignup(context);
                        },
                        child: Padding(
                          padding: EdgeInsets.all(4.0),
                          child: Text(
                            strings.get("SIGNUP").toUpperCase(),
                            style: TextStyle(
                                color: Colors.black54,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                      )
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      FlatButton(
                        child: Text(
                          "CHANGE LANGUAGE",
                          style: TextStyle(
                            fontSize: Theme.of(context)
                                .primaryTextTheme
                                .caption
                                .fontSize,
                            color: Colors.black45,
                          ),
                        ),
                        onPressed: () {
                          _showChooseLanguage();
                        },
                      )
                    ],
                  ),
                  AppConfig.of(context).channelId != '3'
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
          ),
        ],
      ),
    );
  }
}
