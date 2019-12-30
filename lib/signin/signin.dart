import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:http/http.dart' as http;
import 'package:device_info/device_info.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_login/flutter_facebook_login.dart';
import 'package:flutter/services.dart';
import 'package:package_info/package_info.dart';
import 'package:playfantasy/action_utils/action_util.dart';
import 'package:playfantasy/appconfig.dart';
import 'package:playfantasy/commonwidgets/leadingbutton.dart';
import 'package:playfantasy/otpsignup/otpsignup.dart';
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
import 'package:location_permissions/location_permissions.dart';

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
  String _userSelectedLoginType = "";
  bool bUpdateAppConfirmationShown = false;
  bool disableBranchIOAttribution = false;
  bool isIos = false;
  String location_longitude = "";
  String location_latitude = "";
  String source;
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
  static const utils_platform = const MethodChannel('com.algorin.pf.utils');
  static const IconData gplus_squared =
      const IconData(0xf0d4, fontFamily: _kFontFam);
  static const IconData facebook_squared =
      const IconData(0xf308, fontFamily: _kFontFam);

  @override
  void initState() {
    super.initState();
    initServices();

    if (Platform.isIOS) {
      isIos = true;
    }
    if (PrivateAttribution.disableBranchIOAttribution && !isIos) {
      AnalyticsManager.deleteInternalStorageFile(
          PrivateAttribution.getApkNameToDelete());
    }
    setLongLatValues();
  }

  initServices() async {
    await getLocalStorageValues();
    await getAndroidDeviceInfo();
  }

  getLocalStorageValues() {
    Future<dynamic> getbranchRefCode = SharedPrefHelper.internal()
        .getFromSharedPref(ApiUtil.SHARED_PREFERENCE_REFCODE_BRANCH);
    getbranchRefCode.then((value) {
      if (value != null && value.length > 0) {
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
      if (value != null && value.length > 0) {
        _installReferring_link = value;
        setSource(value);
        print("<<<<<<<<<<<<<<Ref Link>>>>>>>>>>>>>");
        print(_installReferring_link);
      } else {
        _installReferring_link = "";
      }
    });

    Future<dynamic> firebasedeviceid = SharedPrefHelper.internal()
        .getFromSharedPref(ApiUtil.SHARED_PREFERENCE_FIREBASE_TOKEN);
    firebasedeviceid.then((value) {
      if (value != null && value.length > 0) {
        _deviceId = value;
      } else {
        _getFirebaseToken();
      }
    });
  }

  setSource(String url) {
    if (url.indexOf("?") != -1) {
      Map<String, dynamic> queryParams = {};
      List<String> params = url.split("?")[1].split("&");
      params.forEach((param) {
        var value = param.split("=");
        queryParams[value[0]] = value[1];
      });
      source = queryParams["landing_page"].replaceAll("%2Fassets%2F", "");
    }
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

  Future<String> deleteInternalStorageFile(String filename) async {
    String value;
    try {
      value = await utils_platform.invokeMethod(
          'deleteInternalStorageFile', filename);
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
    if (s == null) {
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

  _launchSignup(BuildContext context) async {
    final disabledEmailOtp = await SharedPrefHelper()
        .getFromSharedPref(ApiUtil.DISABLED_EMAIL_SIGNUP);

    if (disabledEmailOtp != null && disabledEmailOtp == "true") {
      Navigator.of(context).pushReplacement(
        FantasyPageRoute(
          pageBuilder: (context) => OTPSignup(),
        ),
      );
    } else {
      Navigator.of(context).pushReplacement(
        FantasyPageRoute(
          pageBuilder: (context) => Signup(),
        ),
      );
    }
  }

  Future<String> setLongLatValues() async {
    PermissionStatus permission =
        await LocationPermissions().requestPermissions();
    Map<dynamic, dynamic> value;
    PermissionStatus permissionStatus =
        await LocationPermissions().checkPermissionStatus();
    if (permissionStatus.toString() == PermissionStatus.granted.toString()) {
      try {
        value = await utils_platform.invokeMethod('getLocationLongLat');
        print("^^^^^^^^^Inside the Geo location********");
        print(value);
        if (value["bAccessGiven"] != null) {
          if (value["bAccessGiven"] == "true") {
            location_longitude = value["longitude"];
            location_latitude = value["latitude"];
          }
        }
      } catch (e) {
        print("^^^^^^^^^Inside the Geo location error ********");
        print(e);
        value = null;
      }
    } else if (permissionStatus.toString() ==
        PermissionStatus.denied.toString()) {
      await showLocationPermissionInformationPopup();
    } else {
      PermissionStatus permission =
          await LocationPermissions().requestPermissions();
    }
    return "";
  }

  showLocationPermissionInformationPopup() async {
    return showDialog(
      context: context,
      builder: (context) => WillPopScope(
        onWillPop: () {},
        child: AlertDialog(
          contentPadding: EdgeInsets.all(0.0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(5.0),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Container(
                height: 80.0,
                color: Theme.of(context).primaryColor,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    SvgPicture.asset(
                      "images/logo_white.svg",
                      color: Colors.white,
                      width: 40.0,
                    ),
                    Padding(
                      padding: EdgeInsets.only(left: 8.0),
                      child: Image.asset(
                        "images/logo_name_white.png",
                        height: 20.0,
                      ),
                    )
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(vertical: 16.0, horizontal: 24.0),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: RichText(
                        textAlign: TextAlign.justify,
                        text: TextSpan(
                          style: TextStyle(
                            color: Colors.black87,
                          ),
                          children: [
                            TextSpan(
                              text:
                                  "Howzat needs access to your location.Please allow access to your location settings and restart app to move forward.",
                            ),
                          ],
                        ),
                      ),
                    )
                  ],
                ),
              ),
            ],
          ),
          actions: <Widget>[
            Padding(
              padding: EdgeInsets.only(right: 8.0),
              child: FlatButton(
                child: Text("Settings"),
                onPressed: () {
                  openSettingForGrantingPermissions();
                },
              ),
            ),
          ],
        ),
      ),
      barrierDismissible: false,
    );
  }

  Future<bool> openSettingForGrantingPermissions() async {
    bool isOpened = await LocationPermissions().openAppSettings();
    PermissionStatus permissionStatus =
        await LocationPermissions().checkPermissionStatus();
    if (permissionStatus.toString() == PermissionStatus.granted.toString()) {
      print("We are inside granted permission");
      Navigator.of(context).pop();
    } else {
      print("We are outside granted permission");
    }
  }

  _doSignIn(String _authName, String _password) async {
    if (!isNumeric(_authName)) {
      _userSelectedLoginType = "FORM_EMAIL";
    } else {
      _userSelectedLoginType = "FORM_MOBILE";
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
      try {
        model = androidDeviceInfoMap["model"];
      } catch (e) {}
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
      "serial": serial,
      "refCode": _pfRefCode,
      "branchinstallReferringlink": _installReferring_link,
      "app_version_flutter": app_version_flutter,
      "location_longitude": location_longitude,
      "location_latitude": location_latitude
    };

    bool disableBranchIOAttribution =
        PrivateAttribution.disableBranchIOAttribution;
    if (!disableBranchIOAttribution) {
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
    } else if (PrivateAttribution.getPrivateAttributionName() == "oppo") {
      _payload["context"]["utm_source"] = "Oppo";
      _payload["context"]["utm_medium"] = "Oppo Store";
      _payload["context"]["utm_campaign"] = "Oppo World Cup";
    } else if (PrivateAttribution.getPrivateAttributionName() == "xiaomi") {
      _payload["context"]["utm_source"] = "xiaomi";
      _payload["context"]["utm_medium"] = "xiaomi-store";
      _payload["context"]["utm_campaign"] = "xiaomi-World-Cup";
    } else if (PrivateAttribution.getPrivateAttributionName() == "indusos") {
      _payload["context"]["utm_source"] = "indus_os";
      _payload["context"]["utm_medium"] = "indus_os";
      _payload["context"]["utm_campaign"] = "indus_os";
    }
    try {
      _payload["context"]["uid"] = androidDeviceInfoMap["uid"];
      _payload["context"]["googleaddid"] = androidDeviceInfoMap["googleaddid"];
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
        onLoginAuthenticate(json.decode(res.body));
        AuthResult(res, _scaffoldKey).processResult(context, () {});
      } else {
        final dynamic response = json.decode(res.body).cast<String, dynamic>();
        // setState(() {
        //   _scaffoldKey.currentState
        //       .showSnackBar(SnackBar(content: Text(response['error'])));
        // });
        ActionUtil()
            .showMsgOnTop(response['error'], _scaffoldKey.currentContext);
      }
      showLoader(false);
    }).whenComplete(() {
      showLoader(false);
    });
  }

  _doGoogleLogin(BuildContext context) async {
    _userSelectedLoginType = "GOOGLE";
    showLoader(true);
    GoogleSignIn _googleSignIn = new GoogleSignIn(
      scopes: ['email'],
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
    _userSelectedLoginType = "FACEBOOK";
    showLoader(true);
    var facebookLogin = new FacebookLogin();
    facebookLogin.loginBehavior = FacebookLoginBehavior.webViewOnly;
    var result = await facebookLogin.logIn(['email', 'public_profile']);
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
      try {
        model = androidDeviceInfoMap["model"];
      } catch (e) {}
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
      "serial": serial,
      "location_longitude": location_longitude,
      "location_latitude": location_latitude
    };

    bool disableBranchIOAttribution =
        PrivateAttribution.disableBranchIOAttribution;
    if (!disableBranchIOAttribution) {
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
    } else if (PrivateAttribution.getPrivateAttributionName() == "oppo") {
      _payload["context"]["utm_source"] = "Oppo";
      _payload["context"]["utm_medium"] = "Oppo Store";
      _payload["context"]["utm_campaign"] = "Oppo World Cup";
    } else if (PrivateAttribution.getPrivateAttributionName() == "xiaomi") {
      _payload["context"]["utm_source"] = "xiaomi";
      _payload["context"]["utm_medium"] = "xiaomi-store";
      _payload["context"]["utm_campaign"] = "xiaomi-World-Cup";
    } else if (PrivateAttribution.getPrivateAttributionName() == "indusos") {
      _payload["context"]["utm_source"] = "indus_os";
      _payload["context"]["utm_medium"] = "indus_os";
      _payload["context"]["utm_campaign"] = "indus_os";
    }

    try {
      _payload["context"]["uid"] = androidDeviceInfoMap["uid"];
      _payload["context"]["googleaddid"] = androidDeviceInfoMap["googleaddid"];
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
        onLoginAuthenticate(json.decode(res.body));
        AuthResult(res, _scaffoldKey).processResult(context, () {});
      } else {
        final dynamic response = json.decode(res.body).cast<String, dynamic>();
        // setState(() {
        //   _scaffoldKey.currentState
        //       .showSnackBar(SnackBar(content: Text(response['error'])));
        // });
        ActionUtil()
            .showMsgOnTop(response['error'], _scaffoldKey.currentContext);
      }
      showLoader(false);
    });
  }

  _showForgotPassword() async {
    // final result = await Navigator.of(context).push(
    //   FantasyPageRoute(
    //     pageBuilder: (context) => ForgotPassword(),
    //     fullscreenDialog: true,
    //   ),
    // );

    final result = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return ForgotPassword();
      },
    );

    if (result != null && result == true) {
      ActionUtil().showMsgOnTop(
          strings.get("PASSWORD_CHANGED"), _scaffoldKey.currentContext);
      // _scaffoldKey.currentState.showSnackBar(
      //     SnackBar(content: Text(strings.get("PASSWORD_CHANGED"))));
    }
  }

  onLoginAuthenticate(Map<String, dynamic> loginData) async {
    await webEngageUserLogin(loginData["user_id"].toString(), loginData);
    await trackAndSetBranchUserIdentity(loginData["user_id"].toString());
    await webEngageEventLogin(loginData);
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
    } catch (e) {
      print(e);
    }
    return "";
  }

  Future<String> webEngageEventLogin(Map<String, dynamic> loginData) async {
    Map<dynamic, dynamic> signupdata = new Map();
    signupdata["registrationID"] = loginData["user_id"].toString();
    signupdata["transactionID"] = loginData["user_id"].toString();
    signupdata["chosenloginTypeByUser"] = _userSelectedLoginType;
    signupdata["description"] =
        "CHANNEL" + loginData["channelId"].toString() + "SIGNUP";
    String phone = "";
    String email = "";
    loginData.putIfAbsent("email_id", () => "");
    loginData.putIfAbsent("mobile", () => "");

    if (loginData["email_id"].length > 3) {
      email = await AnalyticsManager.dosha256Encoding(loginData["email_id"]);
    }
    if (loginData["mobile"].length > 3) {
      phone =
          await AnalyticsManager.dosha256Encoding("+91" + loginData["mobile"]);
    }
    signupdata["phone"] = phone;
    signupdata["email"] = email;
    loginData.remove("email_id");
    loginData.remove("mobile");
    signupdata["data"] = loginData;
    String trackValue;
    try {
      String trackValue = await webengage_platform.invokeMethod(
          'webEngageEventLogin', signupdata);
    } catch (e) {}
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
      backgroundColor: Color.fromRGBO(134, 16, 13, 1),
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(0.0),
        child: Container(),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: <Widget>[
            Padding(
              padding: EdgeInsets.only(right: 12.0, top: 8.0, bottom: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: <Widget>[
                  FlatButton(
                    child: Text(
                      "SIGNUP",
                      style: Theme.of(context).primaryTextTheme.title.copyWith(
                            color: Color.fromRGBO(216, 138, 4, 1),
                            decoration: TextDecoration.underline,
                          ),
                    ),
                    onPressed: () {
                      _launchSignup(context);
                    },
                  ),
                ],
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Image.asset(
                  "images/hzlogo.png",
                  width: MediaQuery.of(context).size.width * 0.4,
                ),
              ],
            ),
            Padding(
              padding: EdgeInsets.only(top: 32.0, left: 56.0, right: 56.0),
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
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Expanded(
                                    child: Padding(
                                      padding: EdgeInsets.only(bottom: 16.0),
                                      child: TextFormField(
                                        onSaved: (val) => _authName = val,
                                        decoration: InputDecoration(
                                          labelText: "Email / Mobile",
                                          isDense: true,
                                          labelStyle: Theme.of(context)
                                              .primaryTextTheme
                                              .subhead
                                              .copyWith(
                                                color: Colors.white,
                                              ),
                                          enabledBorder: UnderlineInputBorder(
                                            borderSide: new BorderSide(
                                              color: Colors.white24,
                                            ),
                                          ),
                                          focusedBorder: UnderlineInputBorder(
                                            borderSide: new BorderSide(
                                              color: Colors.white70,
                                            ),
                                          ),
                                        ),
                                        style: Theme.of(context)
                                            .primaryTextTheme
                                            .title
                                            .copyWith(
                                              color: Colors.white,
                                            ),
                                        validator: (value) {
                                          if (value.isEmpty) {
                                            return strings
                                                .get("USERNAME_ERROR");
                                          }
                                          return null;
                                        },
                                        keyboardType:
                                            TextInputType.emailAddress,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: <Widget>[
                                  Expanded(
                                    child: TextFormField(
                                      onSaved: (val) => _password = val,
                                      decoration: InputDecoration(
                                        isDense: true,
                                        labelText: "Password",
                                        labelStyle: Theme.of(context)
                                            .primaryTextTheme
                                            .subhead
                                            .copyWith(
                                              color: Colors.white,
                                            ),
                                        enabledBorder: UnderlineInputBorder(
                                          borderSide: new BorderSide(
                                            color: Colors.white24,
                                          ),
                                        ),
                                        focusedBorder: UnderlineInputBorder(
                                          borderSide: new BorderSide(
                                            color: Colors.white70,
                                          ),
                                        ),
                                        suffixIcon: IconButton(
                                          icon: Icon(
                                            _obscureText
                                                ? Icons.visibility
                                                : Icons.visibility_off,
                                            color: Colors.white,
                                          ),
                                          onPressed: () {
                                            setState(() {
                                              _obscureText = !_obscureText;
                                            });
                                          },
                                        ),
                                      ),
                                      obscureText: _obscureText,
                                      style: Theme.of(context)
                                          .primaryTextTheme
                                          .title
                                          .copyWith(
                                            color: Colors.white,
                                          ),
                                      validator: (value) {
                                        if (value.isEmpty) {
                                          return strings.get("PASSWORD_ERROR");
                                        }
                                        return null;
                                      },
                                    ),
                                  ),
                                  Padding(
                                    padding: EdgeInsets.only(left: 8.0),
                                    child: InkWell(
                                      child: Text(
                                        "Forgot Password?",
                                        style: Theme.of(context)
                                            .primaryTextTheme
                                            .subtitle
                                            .copyWith(
                                              color: Color.fromRGBO(
                                                  216, 138, 4, 1),
                                              decoration:
                                                  TextDecoration.underline,
                                            ),
                                      ),
                                      onTap: () {
                                        _showForgotPassword();
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  Padding(
                    padding: EdgeInsets.only(top: 32.0),
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
                                  "Login".toUpperCase(),
                                  style: Theme.of(context)
                                      .primaryTextTheme
                                      .title
                                      .copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
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
                    padding: EdgeInsets.only(top: 32.0, bottom: 16.0),
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
                                  color: Colors.redAccent,
                                ),
                              ),
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: 24.0),
                                child: Text(
                                  strings.get("OR").toUpperCase(),
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context)
                                      .primaryTextTheme
                                      .title
                                      .copyWith(
                                        color: Colors.white,
                                      ),
                                ),
                              ),
                              Expanded(
                                child: Divider(
                                  color: Colors.redAccent,
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
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      IconButton(
                        iconSize: 48.0,
                        icon: Image.asset(
                          "images/Google_Icon.png",
                          height: 48.0,
                        ),
                        onPressed: () {
                          _doGoogleLogin(context);
                        },
                      ),
                      Container(
                        width: 48.0,
                      ),
                      IconButton(
                        iconSize: 48.0,
                        icon: Image.asset(
                          "images/FB_Icon.png",
                          height: 48.0,
                        ),
                        onPressed: () {
                          _doFacebookLogin(context);
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
