import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:playfantasy/commonwidgets/textbox.dart';
import 'package:playfantasy/providers/user.dart';
import 'package:playfantasy/utils/apiutil.dart';
import 'package:playfantasy/utils/httpmanager.dart';
import 'package:provider/provider.dart';

class MobileVerification extends StatefulWidget {
  final Function onVerificationSuccess;
  final Function onVerificationError;

  MobileVerification({this.onVerificationError, this.onVerificationSuccess});

  @override
  _MobileVerificationState createState() => _MobileVerificationState();
}

class _MobileVerificationState extends State<MobileVerification> {
  bool _bIsOTPSent = false;
  String _mobileVerificationError;

  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final TextEditingController _otpController = TextEditingController();
  final TextEditingController _mobileController = TextEditingController();

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((_) => setData(context));
    super.initState();
  }

  void setData(BuildContext context) {
    User user = Provider.of<User>(context);
    if (user.emailId != null) {
      _mobileController.text = user.mobile;
    }
  }

  Future<Map<String, dynamic>> sendOTP(BuildContext context,
      {String mobile, bool shouldUpdate}) {
    http.Request req =
        http.Request("POST", Uri.parse(BaseUrl().apiUrl + ApiUtil.SEND_OTP));
    req.body = json.encode({
      "phone": mobile,
      "isChanged": shouldUpdate,
    });
    return HttpManager(http.Client())
        .sendRequest(req)
        .then((http.Response res) {
      if (res.statusCode >= 200 && res.statusCode <= 299) {
        return {"error": false};
      } else {
        final response = json.decode(res.body);
        return {
          "error": true,
          "message": response["error"]["erroMessage"],
        };
      }
    });
  }

  Future<Map<String, dynamic>> verifyOTP(BuildContext context, {String otp}) {
    http.Request req =
        http.Request("POST", Uri.parse(BaseUrl().apiUrl + ApiUtil.VERIFY_OTP));
    req.body = json.encode({
      "otp": otp,
    });
    return HttpManager(http.Client())
        .sendRequest(req)
        .then((http.Response res) {
      if (res.statusCode >= 200 && res.statusCode <= 299) {
        widget.onVerificationSuccess();
        return {
          "error": false,
        };
      } else {
        final response = json.decode(res.body);
        return {
          "error": true,
          "message": response["error"]["erroMessage"],
        };
      }
    });
  }

  void onSendOTP(BuildContext ccontext, String mobile) async {
    setState(() {
      _mobileVerificationError = null;
    });
    Map<String, dynamic> result = await sendOTP(
      context,
      mobile: _mobileController.text,
      shouldUpdate: _mobileController.text != mobile,
    );

    setState(() {
      if (!result["error"]) {
        _bIsOTPSent = true;
      } else {
        _mobileVerificationError = result["message"];
      }
    });
  }

  void onVerifyOTP() async {
    User user = Provider.of<User>(context);
    setState(() {
      _mobileVerificationError = "";
    });
    Map<String, dynamic> result =
        await verifyOTP(context, otp: _otpController.text);

    if (!result["error"]) {
      user.verificationStatus.updateMobileVerificationStatus(true);
    } else {
      setState(() {
        if (!result["error"]) {
          _bIsOTPSent = true;
        } else {
          _mobileVerificationError = result["message"];
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Consumer<User>(
          builder: (context, user, child) {
            return Form(
              key: formKey,
              child: ChangeNotifierProvider<VerificationStatus>.value(
                value: user.verificationStatus,
                child: Consumer<VerificationStatus>(
                  builder: (ctx, verificationStatus, child) {
                    return !verificationStatus.isMobileVerified
                        ? Column(
                            children: <Widget>[
                              ListTile(
                                title: SimpleTextBox(
                                  controller: _mobileController,
                                  labelText: "Enter mobile number",
                                  keyboardType: TextInputType.phone,
                                  enabled:
                                      !verificationStatus.isMobileVerified &&
                                          !_bIsOTPSent,
                                  inputFormatters: [
                                    LengthLimitingTextInputFormatter(
                                      10,
                                    ),
                                    BlacklistingTextInputFormatter(
                                      RegExp("[\/,. -/#\$]"),
                                    ),
                                  ],
                                  validator: (val) {
                                    if (val.isEmpty) {
                                      return "Please enter mobile number.";
                                    }
                                    return null;
                                  },
                                ),
                              ),
                              _bIsOTPSent
                                  ? ListTile(
                                      title: SimpleTextBox(
                                        validator: (value) {
                                          if (value.isEmpty && _bIsOTPSent) {
                                            return 'Please enter OTP.';
                                          }
                                          return null;
                                        },
                                        inputFormatters: [
                                          LengthLimitingTextInputFormatter(
                                            6,
                                          ),
                                          BlacklistingTextInputFormatter(
                                            RegExp("[\/,. -/#\$]"),
                                          ),
                                        ],
                                        controller: _otpController,
                                        keyboardType: TextInputType.number,
                                        labelText: "Enter OTP",
                                      ),
                                    )
                                  : Container(),
                              _mobileVerificationError == null
                                  ? Container()
                                  : Padding(
                                      padding: EdgeInsets.fromLTRB(
                                          16.0, 8.0, 16.0, 8.0),
                                      child: Row(
                                        children: <Widget>[
                                          Text(
                                            _mobileVerificationError,
                                            style: TextStyle(
                                              color:
                                                  Theme.of(context).errorColor,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                              Padding(
                                padding: const EdgeInsets.only(
                                  top: 8.0,
                                  left: 16.0,
                                  right: 16.0,
                                ),
                                child: Row(
                                  children: <Widget>[
                                    Expanded(
                                      child: Text(
                                        "You will receive an OTP on this number. Please do not share an OTP with anyone.",
                                        style: TextStyle(color: Colors.black54),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              ListTile(
                                title: Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: <Widget>[
                                    FlatButton(
                                      onPressed: () {
                                        if (_bIsOTPSent) {
                                          if (formKey.currentState.validate()) {
                                            onVerifyOTP();
                                          }
                                        } else {
                                          if (formKey.currentState.validate()) {
                                            onSendOTP(context, user.mobile);
                                          }
                                        }
                                      },
                                      child: Text(
                                        !_bIsOTPSent
                                            ? "Send OTP".toUpperCase()
                                            : "VERIFY".toUpperCase(),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          )
                        : Column(
                            children: <Widget>[
                              ListTile(
                                title: Text(
                                  user.mobile.toString(),
                                ),
                              ),
                            ],
                          );
                  },
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
