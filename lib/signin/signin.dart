import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:device_info/device_info.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_login/flutter_facebook_login.dart';
import 'package:flutter/services.dart';
import 'package:package_info/package_info.dart';
import 'package:playfantasy/appconfig.dart';
import 'package:playfantasy/signup/signup.dart';
import 'package:playfantasy/utils/apiutil.dart';
import 'package:playfantasy/utils/authresult.dart';
import 'package:playfantasy/utils/httpmanager.dart';
import 'package:playfantasy/utils/stringtable.dart';
import 'package:playfantasy/commonwidgets/textbox.dart';
import 'package:playfantasy/signin/forgotpassword.dart';
import 'package:playfantasy/utils/sharedprefhelper.dart';
import 'package:playfantasy/commonwidgets/color_button.dart';
import 'package:playfantasy/commonwidgets/scaffoldpage.dart';
import 'package:playfantasy/redux/actions/loader_actions.dart';
import 'package:playfantasy/commonwidgets/fantasypageroute.dart';
import 'package:playfantasy/utils/analytics.dart';

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
  String googleAddId = "";
  List<dynamic> _languages;
  String _installReferring_link = "";
  String _pfRefCode;
  String _userSelectedLoginType="";
  bool bUpdateAppConfirmationShown = false;
  Map<dynamic, dynamic> androidDeviceInfoMap;

  final formKey = new GlobalKey<FormState>();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey();

  static const _kFontFam = 'MyFlutterApp';
  static const firebase_fcm_platform =
      const MethodChannel('com.algorin.pf.fcm');
  static const branch_io_platform =
      const MethodChannel('com.algorin.pf.branch');
  static const webengage_platform =
      const MethodChannel('com.algorin.pf.webengage');
  static const IconData gplus_squared =
      const IconData(0xf0d4, fontFamily: _kFontFam);
  static const IconData facebook_squared =
      const IconData(0xf308, fontFamily: _kFontFam);

  @override
  void initState() {
    super.initState();

    getLocalStorageValues();
    getAndroidDeviceInfo().then((String value) {});
  }

  getLocalStorageValues() {
    Future<dynamic> getbranchRefCode = SharedPrefHelper.internal()
        .getFromSharedPref(ApiUtil.SHARED_PREFERENCE_REFCODE_BRANCH);
    getbranchRefCode.then((value) {
      if (value.length > 0) {
        _pfRefCode = value;

        print("<<<<<<<<<<<<<<Ref Code>>>>>>>>>>>>>");
        print(_pfRefCode);
      } else {
        _pfRefCode = "";
      }
    });
    Future<dynamic> getbranchReferringLink = SharedPrefHelper.internal()
        .getFromSharedPref(ApiUtil.SHARED_PREFERENCE_INSTALLREFERRING_BRANCH);
    getbranchReferringLink.then((value) {
      if (value.length > 0) {
        _installReferring_link = value;
        print("<<<<<<<<<<<<<<Ref Link>>>>>>>>>>>>>");
        print(_installReferring_link);
      } else {
        _installReferring_link = "";
      }
    });

    Future<dynamic> firebasedeviceid = SharedPrefHelper.internal()
        .getFromSharedPref(ApiUtil.SHARED_PREFERENCE_FIREBASE_TOKEN);
    firebasedeviceid.then((value) {
      if (value.length > 0) {
        _deviceId = value;
      } else {
        _getFirebaseToken();
      }
    });

    Future<dynamic> googleAddId_from_local = SharedPrefHelper.internal()
        .getFromSharedPref(ApiUtil.SHARED_PREFERENCE_GOOGLE_ADDID);
    googleAddId_from_local.then((value) {
      if (value.length > 0) {
        googleAddId = value;
      } else {
        _getGoogleAddId().then((String value) {
          googleAddId = value;
        });
      }
    });
  }

  Future<String> _getGoogleAddId() async {
    String value;
    try {
      value = await branch_io_platform.invokeMethod('_getGoogleAddId');
    } catch (e) {}
    return value;
  }

  Future<String> getAndroidDeviceInfo() async {
    Map<dynamic, dynamic> value;
    try {
      value = await branch_io_platform.invokeMethod('_getAndroidDeviceInfo');
      androidDeviceInfoMap = value;
    } catch (e) {}
    return "";
  }

  Future<String> _getFirebaseToken() async {
    String value;
    try {
      value = await firebase_fcm_platform.invokeMethod('_getFirebaseToken');
      _deviceId = value;
    } catch (e) {}
    return value;
  }

  showLoader(bool bShow) {
    AppConfig.of(context)
        .store
        .dispatch(bShow ? LoaderShowAction() : LoaderHideAction());
  }

  bool isNumeric(String s) {
  if(s == null) {
    return false;
  }
  return double.parse(s, (e) => null) != null;
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
    if(!isNumeric(_authName)){
     _userSelectedLoginType="FORM_EMAIL";
    }else{
      _userSelectedLoginType="FORM_MOBILE";
    }
    DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    String app_version_flutter = packageInfo.version;
    String model = "";
    String manufacturer = "";
    String serial = "";
    if (Platform.isAndroid) {
      AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
      model = androidInfo.model;
      manufacturer = androidInfo.manufacturer;
      serial = androidInfo.androidId;
    }
    if (Platform.isIOS) {
      IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
      model = androidDeviceInfoMap["model"];
      manufacturer = "Apple";
      serial = "";
    }
    Map<String, dynamic> _payload = {};
    showLoader(true);
    _payload["value"] = {"auth_attribute": _authName, "password": _password};
    _payload["context"] = {
      "channel_id": HttpManager.channelId,
      "deviceId": _deviceId,
      "model": model,
      "manufacturer": manufacturer,
      "googleaddid": googleAddId,
      "serial": serial,
      "refCode": _pfRefCode,
      "branchinstallReferringlink": _installReferring_link,
      "app_version_flutter": app_version_flutter
    };

    if (_installReferring_link.length > 0) {
      var uri = Uri.parse(_installReferring_link);
      uri.queryParameters.forEach((k, v) {
        try {
          _payload["context"][k] = v;
        } catch (e) {
          print(e);
        }
      });
    }

    try {
      _payload["context"]["uid"] = androidDeviceInfoMap["uid"];
      _payload["context"]["platformType"] = androidDeviceInfoMap["version"];
      _payload["context"]["network_operator"] =
          androidDeviceInfoMap["network_operator"];
      _payload["context"]["firstInstallTime"] =
          androidDeviceInfoMap["firstInstallTime"];
      _payload["context"]["lastUpdateTime"] =
          androidDeviceInfoMap["lastUpdateTime"];
      _payload["context"]["device_ip_"] = androidDeviceInfoMap["device_ip_"];
      _payload["context"]["network_type"] =
          androidDeviceInfoMap["network_type"];
      _payload["context"]["googleEmailList"] =
          json.encode(androidDeviceInfoMap["googleEmailList"]);
    } catch (e) {}

    http.Request req =
        http.Request("POST", Uri.parse(BaseUrl().apiUrl + ApiUtil.LOGIN_URL));
    req.body = json.encode(_payload);
    return HttpManager(http.Client())
        .sendRequest(req)
        .then((http.Response res) {
      if (res.statusCode >= 200 && res.statusCode <= 299) {
        AuthResult(res, _scaffoldKey).processResult(() {});
        onLoginAuthenticate(json.decode(res.body));
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
    _userSelectedLoginType="GOOGLE";
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
    _userSelectedLoginType="FACEBOOK";
    showLoader(true);
    var facebookLogin = new FacebookLogin();
    facebookLogin.loginBehavior = FacebookLoginBehavior.webViewOnly;
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
    DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    String app_version_flutter = packageInfo.version;
    String model = "";
    String manufacturer = "";
    String serial = "";

    if (Platform.isAndroid) {
      AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
      model = androidInfo.model;
      manufacturer = androidInfo.manufacturer;
      serial = androidInfo.androidId;
    }
    if (Platform.isIOS) {
      IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
      model = androidDeviceInfoMap["model"];
      manufacturer = "Apple";
      serial = "";
    }
    Map<String, dynamic> _payload = {};
    _payload["accessToken"] = token;
    _payload["context"] = {
      "refCode": _pfRefCode,
      "channel_id": HttpManager.channelId,
      "deviceId": _deviceId,
      "model": model,
      "manufacturer": manufacturer,
      "googleaddid": googleAddId,
      "serial": serial,
    };
    if (_installReferring_link.length > 0) {
      var uri = Uri.parse(_installReferring_link);
      uri.queryParameters.forEach((k, v) {
        try {
          _payload["context"][k] = v;
        } catch (e) {
          print(e);
        }
      });
    }
    try {
      _payload["context"]["uid"] = androidDeviceInfoMap["uid"];
      _payload["context"]["platformType"] = androidDeviceInfoMap["version"];
      _payload["context"]["network_operator"] =
          androidDeviceInfoMap["network_operator"];
      _payload["context"]["firstInstallTime"] =
          androidDeviceInfoMap["firstInstallTime"];
      _payload["context"]["lastUpdateTime"] =
          androidDeviceInfoMap["lastUpdateTime"];
      _payload["context"]["device_ip_"] = androidDeviceInfoMap["device_ip_"];
      _payload["context"]["network_type"] =
          androidDeviceInfoMap["network_type"];
      _payload["context"]["googleEmailList"] =
          json.encode(androidDeviceInfoMap["googleEmailList"]);
    } catch (e) {}

    http.Client()
        .post(
      BaseUrl().apiUrl +
          (authFor == 1
              ? ApiUtil.GOOGLE_LOGIN_URL
              : (authFor == 2
                  ? ApiUtil.FACEBOOK_LOGIN_URL
                  : ApiUtil.GOOGLE_LOGIN_URL)),
      headers: {'Content-type': 'application/json'},
      body: json.encode(_payload),
    )
        .then((http.Response res) {
      if (res.statusCode >= 200 && res.statusCode <= 299) {
        AuthResult(res, _scaffoldKey).processResult(
          () {},
        );
        onLoginAuthenticate(json.decode(res.body));
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

  onLoginAuthenticate(Map<String, dynamic> loginData) {
    print("<<<<<<<<<Login Data>>>>>>>>>");
    print(loginData);
    trackAndSetBranchUserIdentity(loginData["user_id"].toString());
    webEngageUserLogin(loginData["user_id"].toString(), loginData);
  }

  
  Future<String> webEngageUserLogin(
      String userId, Map<String, dynamic> loginData) async {
    String result = "";
    Map<dynamic, dynamic> data = new Map();
    data["trackingType"] = "login";
    data["value"] = userId;
    try {
      result =
          await webengage_platform.invokeMethod('webengageTrackUser', data);

      print(">>>>>>>>>>>>>>>>>>>>>>>>>web engage login>>>>>>>>>>>>>>>>>>>>");
      print(result);
      webEngageEventLogin(loginData);

    } catch (e) {
      print(e);
    }
    return "";
  }


  Future<String> webEngageEventLogin(Map<String, dynamic> loginData) async {
    Map<dynamic, dynamic> signupdata = new Map();
    signupdata["registrationID"] = loginData["user_id"].toString();
    signupdata["transactionID"] = loginData["user_id"].toString();
    signupdata["loginType"] = _userSelectedLoginType;
    signupdata["description"] =
        "CHANNEL" + loginData["channelId"].toString() + "SIGNUP";
    signupdata["data"] = loginData;
    String trackValue;
    try {
      String trackValue = await webengage_platform.invokeMethod(
          'webEngageEventLogin', signupdata);
      print("<<<<<<<<<<web engage user login event>>>>>>>");
      print(trackValue);
    } catch (e) {
      print("<<<<<<<<<<web engage user login event>>>>>>>");
      print(e);
    }
    return trackValue;
  }

  Future<String> trackAndSetBranchUserIdentity(String userId) async {
    String value;
    try {
      value = await branch_io_platform.invokeMethod(
          'trackAndSetBranchUserIdentity', userId);
    } catch (e) {
      print(e);
    }
    return value;
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldPage(
      scaffoldKey: _scaffoldKey,
      appBar: AppBar(
        title: Padding(
          padding: EdgeInsets.all(8.0),
          child: Row(
            children: <Widget>[
              Image.asset("images/logo_white.png"),
              Padding(
                padding: EdgeInsets.only(left: 8.0),
                child: Image.asset(
                  "images/logo_name_white.png",
                  height: 20.0,
                ),
              ),
            ],
          ),
        ),
        actions: <Widget>[
          Padding(
            padding: EdgeInsets.all(10.0),
            child: ColorButton(
              onPressed: () {
                _launchSignup(context);
              },
              child: Text(
                "Register".toUpperCase(),
                style: Theme.of(context).primaryTextTheme.subhead.copyWith(
                      color: Color.fromRGBO(25, 14, 4, 1),
                      fontWeight: FontWeight.w700,
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
            Image.network(
                "https://d2cbroser6kssl.cloudfront.net/images/banners_10/banner_howzat_referral_raf_250.jpg"),
            Padding(
              padding: EdgeInsets.symmetric(vertical: 16.0),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      "Welcome! Login & Start Playing.",
                      textAlign: TextAlign.center,
                      style: Theme.of(context).primaryTextTheme.title.copyWith(
                            color: Theme.of(context).primaryColor,
                            fontWeight: FontWeight.w700,
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
                                    child: Padding(
                                      padding: EdgeInsets.only(bottom: 16.0),
                                      child: SimpleTextBox(
                                        onSaved: (val) => _authName = val,
                                        labelText: "Username or Email",
                                        validator: (value) {
                                          if (value.isEmpty) {
                                            return strings
                                                .get("USERNAME_ERROR");
                                          }
                                        },
                                        keyboardType:
                                            TextInputType.emailAddress,
                                      ),
                                    ),
                                  )
                                ],
                              ),
                              Row(
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
                  Padding(
                    padding: EdgeInsets.only(top: 8.0),
                    child: Row(
                      children: <Widget>[
                        Expanded(
                          child: Container(
                            height: 48.0,
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
                                      .title
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
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.only(top: 8.0),
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
                                  color: Colors.grey.shade400,
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
                                  color: Colors.grey.shade400,
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
                          child: FlatButton(
                            onPressed: () {
                              _doGoogleLogin(context);
                            },
                            padding: EdgeInsets.all(0.0),
                            color: Colors.transparent,
                            child: Image.asset(
                              "images/googleBtn.png",
                              fit: BoxFit.cover,
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
                          child: FlatButton(
                            padding: EdgeInsets.all(0.0),
                            onPressed: () {
                              _doFacebookLogin(context);
                            },
                            color: Colors.transparent,
                            child: Image.asset(
                              "images/fbButton.png",
                              fit: BoxFit.cover,
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
                        style:
                            Theme.of(context).primaryTextTheme.subhead.copyWith(
                                  color: Colors.grey.shade600,
                                ),
                      ),
                      InkWell(
                        onTap: () {
                          _launchSignup(context);
                        },
                        child: Padding(
                          padding: EdgeInsets.all(4.0),
                          child: Text(
                            "Register now",
                            style: Theme.of(context)
                                .primaryTextTheme
                                .subhead
                                .copyWith(
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
                          AppConfig.of(context).channelId != '10' && AppConfig.of(context).channelId != '13'
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
