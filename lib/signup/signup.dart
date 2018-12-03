import 'dart:convert';
import 'package:device_info/device_info.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_login/flutter_facebook_login.dart';
import 'package:platform/platform.dart';
import 'package:playfantasy/appconfig.dart';
import 'package:playfantasy/utils/sharedprefhelper.dart';
import 'package:playfantasy/utils/apiutil.dart';
import 'package:playfantasy/utils/authresult.dart';
import 'package:playfantasy/utils/httpmanager.dart';
import 'package:playfantasy/utils/stringtable.dart';

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
  String _installAndroid_link;
  bool _bShowReferralInput = false;
  String _installReferring_link = "";
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
    Future<dynamic> firebasedeviceid = SharedPrefHelper.internal()
        .getFromSharedPref(ApiUtil.SHARED_PREFERENCE_FIREBASE_TOKEN);
    firebasedeviceid.then((value) {
      _deviceId = value;
    });

    _initBranchStuff();
  }

/////////////////////
  ///Branch///////////
///////////////////

  _initBranchStuff() {
    _getBranchRefCode().then((String refcode) {
      _pfRefCode = refcode;
      setState(() {
        _referralCodeController.text = _pfRefCode;
      });
    });

    _getInstallReferringLink().then((String installReferring_link) {
      setState(() {
        _installReferring_link = installReferring_link;
      });
    });
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
        "serial": androidInfo.hardware,
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
    }

    http.Request req =
        http.Request("POST", Uri.parse(BaseUrl.apiUrl + ApiUtil.SIGN_UP));
    req.body = json.encode(_payload);
    await HttpManager(http.Client()).sendRequest(req).then((http.Response res) {
      if (res.statusCode >= 200 && res.statusCode <= 299) {
        AuthResult(res, _scaffoldKey).processResult(() {});
      } else {
        final dynamic response = json.decode(res.body).cast<String, dynamic>();
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
    });
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text(
          strings.get("SIGNUP"),
        ),
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
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: Image(
                      height: 80.0,
                      fit: BoxFit.scaleDown,
                      image: new AssetImage("images/fantasy-logo.png"),
                    ),
                  ),
                ],
              ),
              ListTile(
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
                          padding: const EdgeInsets.only(top: 4.0),
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
                        padding: const EdgeInsets.only(left: 4.0),
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
                                padding: EdgeInsets.only(left: 8.0),
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
                      padding: const EdgeInsets.only(left: 16.0, right: 16.0),
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
                                        labelText:
                                            strings.get("EMAIL_OR_MOBILE"),
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
                                              .get("EMAIL_OR_MOBILE_ERROR");
                                        }
                                      },
                                      keyboardType: TextInputType.emailAddress,
                                    ),
                                  )
                                ],
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.only(top: 16.0),
                              child: Row(
                                children: <Widget>[
                                  Expanded(
                                    child: TextFormField(
                                      onSaved: (val) => _password = val,
                                      decoration: InputDecoration(
                                        labelText: strings.get("PASSWORD"),
                                        hintText:
                                            strings.get("MIN_CHARS_PASSWORD"),
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
                                          return strings.get("PASSWORD_ERROR");
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
                padding: const EdgeInsets.only(left: 16.0, top: 16.0),
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
                      padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 0.0),
                      child: Row(
                        children: <Widget>[
                          Expanded(
                            child: TextFormField(
                              controller: _referralCodeController,
                              decoration: InputDecoration(
                                labelText: strings.get("REFERRAL_CODE"),
                                border: OutlineInputBorder(
                                  borderSide: BorderSide(
                                    color: Colors.black38,
                                  ),
                                ),
                                contentPadding: EdgeInsets.all(12.0),
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
                            style: TextStyle(
                              fontSize: Theme.of(context)
                                  .primaryTextTheme
                                  .caption
                                  .fontSize,
                            ),
                          ),
                          Container(
                            height: 18.0,
                            child: FlatButton(
                              padding: EdgeInsets.fromLTRB(4.0, 0.0, 0.0, 0.0),
                              child: Text(
                                strings.get("TERMS_AND_CONDITION"),
                                style: TextStyle(
                                  fontSize: Theme.of(context)
                                      .primaryTextTheme
                                      .caption
                                      .fontSize,
                                ),
                              ),
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
