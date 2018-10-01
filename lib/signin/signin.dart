import 'dart:ui';
import 'dart:convert';
import 'package:http/http.dart' as http;

import 'package:flutter/material.dart';
import 'package:playfantasy/commonwidgets/loader.dart';
import 'package:playfantasy/utils/apiutil.dart';
import 'package:playfantasy/signin/siginform.dart';
import 'package:playfantasy/utils/authresult.dart';

class Signin extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => new SigninState();
}

class SigninState extends State<Signin> {
  bool _bShowLoader = false;

  _showLoader(bool bShow) {
    setState(() {
      _bShowLoader = bShow;
    });
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
      AuthResult(res, context, setState).processResult(() {
        setState(() {
          _showLoader(false);
        });
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        Scaffold(
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
                    child: SigninForm(
                      onSubmit: (_authName, _password) {
                        doSignIn(_authName, _password);
                      },
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
