import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:device_info/device_info.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_login/flutter_facebook_login.dart';

import 'package:playfantasy/appconfig.dart';
import 'package:playfantasy/commonwidgets/textbox.dart';
import 'package:playfantasy/signin/signin.dart';
import 'package:playfantasy/utils/apiutil.dart';
import 'package:playfantasy/utils/authresult.dart';
import 'package:playfantasy/utils/httpmanager.dart';
import 'package:playfantasy/utils/stringtable.dart';
import 'package:playfantasy/utils/sharedprefhelper.dart';
import 'package:playfantasy/commonwidgets/color_button.dart';
import 'package:playfantasy/commonwidgets/scaffoldpage.dart';
import 'package:playfantasy/redux/actions/loader_actions.dart';
import 'package:playfantasy/commonwidgets/fantasypageroute.dart';

class Signup extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => new SignupState();
}

class SignupState extends State<Signup> {
  String _authName;
  String _password;
  String _deviceId;
  String _pfRefCode;
  bool _obscureText = true;

  bool _bShowReferralInput = false;
  String _installReferringLink = "";
  static const branch_io_platform =
      const MethodChannel('com.algorin.pf.branch');
  final formKey = new GlobalKey<FormState>();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey();
  final TextEditingController _referralCodeController = TextEditingController();

  static const _kFontFam = 'MyFlutterApp';
  static const IconData gplus_squared =
      const IconData(0xf0d4, fontFamily: _kFontFam);
  static const IconData facebook_squared =
      const IconData(0xf308, fontFamily: _kFontFam);

  @override
  void initState() {
    super.initState();

    _getFirebaseId();
    _initBranchStuff();
  }

  _getFirebaseId() async {
    _deviceId = await SharedPrefHelper.internal()
        .getFromSharedPref(ApiUtil.SHARED_PREFERENCE_FIREBASE_TOKEN);
  }

  _initBranchStuff() {
    _getBranchRefCode().then((String refcode) {
      _pfRefCode = refcode;
      setState(() {
        _referralCodeController.text = _pfRefCode;
      });
    });

    _getInstallReferringLink().then((String installReferringLink) {
      setState(() {
        _installReferringLink = installReferringLink;
      });
    });
  }

  showLoader(bool bShow) {
    AppConfig.of(context)
        .store
        .dispatch(bShow ? LoaderShowAction() : LoaderHideAction());
  }

  Future<String> _getBranchRefCode() async {
    String value;
    try {
      value = await branch_io_platform.invokeMethod('_getBranchRefCode');
    } catch (e) {
      print(e);
    }
    return value;
  }

  Future<String> _getInstallReferringLink() async {
    String value;
    try {
      value = await branch_io_platform.invokeMethod('_getInstallReferringLink');
    } catch (e) {
      print(e);
    }
    return value;
  }

  _showReferralInput() {
    setState(() {
      _bShowReferralInput = !_bShowReferralInput;
    });
  }

  _doSignUp() async {
    showLoader(true);
    DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();

    Map<String, dynamic> _payload = {};
    if (isMobileNumber(_authName)) {
      _payload["phone"] = _authName;
    } else {
      _payload["email"] = _authName;
    }
    _payload["password"] = _password;

    if (Theme.of(context).platform == TargetPlatform.android) {
      AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
      _payload["context"] = {
        "refCode": _referralCodeController.text,
        "channel_id": HttpManager.channelId,
        "deviceId": _deviceId,
        "uid": "",
        "model": androidInfo.model,
        "platformType": androidInfo.version.baseOS,
        "manufacturer": androidInfo.manufacturer,
        "googleaddid": "",
        "serial": androidInfo.androidId,
      };
      if (_installReferringLink.length > 0) {
        var uri = Uri.parse(_installReferringLink);
        uri.queryParameters.forEach((k, v) {
          try {
            _payload["context"][k] = v;
          } catch (e) {
            print(e);
          }
        });
      }
    }

    http.Request req =
        http.Request("POST", Uri.parse(BaseUrl().apiUrl + ApiUtil.SIGN_UP));
    req.body = json.encode(_payload);
    await HttpManager(http.Client()).sendRequest(req).then(
      (http.Response res) {
        if (res.statusCode >= 200 && res.statusCode <= 299) {
          AuthResult(res, _scaffoldKey).processResult(() {});
        } else {
          final dynamic response =
              json.decode(res.body).cast<String, dynamic>();
          String error = response['error']['erroMessage'];
          if (error == null && response['error']['errorCode'] != null) {
            error = strings.get(response['error']['errorCode']);
          } else if (error == null) {
            error = strings.get("INVALID_USERNAME_PASSWORD");
          }
          _scaffoldKey.currentState.showSnackBar(
            SnackBar(
              content: Text(error),
            ),
          );
        }
        showLoader(false);
      },
    );
  }

  bool isMobileNumber(String input) {
    if (input.length == 10 || isNumeric(input)) {
      return true;
    }
    return false;
  }

  bool isNumeric(String s) {
    if (s == null) {
      return false;
    }
    return int.parse(s, onError: (e) => null) != null;
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
    });
  }

  _launchSignIn() {
    Navigator.of(context).pushReplacement(FantasyPageRoute(
      pageBuilder: (context) => SignInPage(),
    ));
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
                _launchSignIn();
              },
              child: Text(
                "Login".toUpperCase(),
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
                      "Register now, It's Free",
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
                                      labelText: strings.get("EMAIL_OR_MOBILE"),
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
                              Padding(
                                padding: EdgeInsets.only(top: 16.0),
                                child: Row(
                                  children: <Widget>[
                                    Expanded(
                                      child: SimpleTextBox(
                                        onSaved: (val) => _password = val,
                                        labelText: strings.get("PASSWORD"),
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
                              Padding(
                                padding: EdgeInsets.symmetric(vertical: 8.0),
                                child: Row(
                                  children: <Widget>[
                                    Expanded(
                                      child: SimpleTextBox(
                                        controller: _referralCodeController,
                                        labelText: strings.get("REFERRAL_CODE"),
                                      ),
                                    )
                                  ],
                                ),
                              ),
                              Row(
                                children: <Widget>[
                                  Expanded(
                                    child: ColorButton(
                                      onPressed: () {
                                        if (formKey.currentState.validate()) {
                                          formKey.currentState.save();
                                          _doSignUp();
                                        }
                                      },
                                      child: Container(
                                        child: Text(
                                          "Register for Free",
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
                                          padding: EdgeInsets.symmetric(
                                              vertical: 8.0),
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: <Widget>[
                                              Icon(
                                                gplus_squared,
                                                color: Colors.black,
                                                size: 32.0,
                                              ),
                                              Padding(
                                                padding: EdgeInsets.symmetric(
                                                    horizontal: 16.0),
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
                                          padding: EdgeInsets.symmetric(
                                              vertical: 8.0),
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: <Widget>[
                                              Icon(
                                                facebook_squared,
                                                color: Colors.white,
                                                size: 32.0,
                                              ),
                                              Padding(
                                                padding: EdgeInsets.symmetric(
                                                    horizontal: 16.0),
                                                child: Container(
                                                  height: 32.0,
                                                  width: 1.0,
                                                  color: Colors.black26,
                                                ),
                                              ),
                                              Expanded(
                                                child: Text(
                                                  "Continue with Facebook",
                                                  style: TextStyle(
                                                      color: Colors.white),
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
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Text(
                  "By registering you accept you are 18+ and agree to our ",
                  style: TextStyle(
                    fontSize:
                        Theme.of(context).primaryTextTheme.caption.fontSize,
                  ),
                  textAlign: TextAlign.center,
                ),
                InkWell(
                  child: Text(
                    "T&C.",
                    style: Theme.of(context).primaryTextTheme.caption.copyWith(
                          color: Colors.black,
                          fontWeight: FontWeight.w900,
                          decoration: TextDecoration.underline,
                        ),
                  ),
                  onTap: () {},
                )
              ],
            ),
            Padding(
              padding: EdgeInsets.symmetric(vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Text(
                    "Already a Member? ",
                    style: TextStyle(
                      fontSize:
                          Theme.of(context).primaryTextTheme.button.fontSize,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  InkWell(
                    child: Text(
                      " Login Now.",
                      style: Theme.of(context).primaryTextTheme.button.copyWith(
                            color: Theme.of(context).primaryColor,
                            fontWeight: FontWeight.w900,
                            decoration: TextDecoration.underline,
                          ),
                    ),
                    onTap: () {
                      _launchSignIn();
                    },
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
