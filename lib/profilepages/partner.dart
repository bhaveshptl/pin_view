import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:playfantasy/action_utils/action_util.dart';
import 'package:playfantasy/commonwidgets/scaffoldpage.dart';

import 'package:playfantasy/utils/apiutil.dart';
import 'package:playfantasy/utils/httpmanager.dart';

class Partner extends StatefulWidget {
  @override
  PartnerState createState() => PartnerState();
}

class PartnerState extends State<Partner> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _mobileController = TextEditingController();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  submitForm() async {
    http.Request req = http.Request(
        "POST", Uri.parse(BaseUrl().apiUrl + ApiUtil.PARTNER_REQUEST));
    req.body = json.encode({
      "email": _emailController.text,
      "mobile": _mobileController.text,
    });
    return HttpManager(http.Client())
        .sendRequest(req)
        .then((http.Response res) {
      if (res.statusCode >= 200 && res.statusCode < 300) {
        _showMessage("We will get back to you very soon...!");
      } else {
        _showMessage("Unable to process request. Please try again...!");
      }
    }).whenComplete(() {
      ActionUtil().showLoader(context, false);
    });
  }

  _showMessage(String message) {
    _scaffoldKey.currentState.showSnackBar(SnackBar(
      content: Text(message),
    ));
  }

  bool isNumeric(String s) {
    if (s == null) {
      return false;
    }
    return int.parse(s, onError: (e) => null) != null;
  }

  bool validateEmail(String value) {
    Pattern pattern =
        r'^(([^<>()[\]\\.,;:\s@\"]+(\.[^<>()[\]\\.,;:\s@\"]+)*)|(\".+\"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$';
    RegExp regex = new RegExp(pattern);
    if (!regex.hasMatch(value))
      return false;
    else
      return true;
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldPage(
      scaffoldKey: _scaffoldKey,
      appBar: AppBar(
        title: Text(
          "Partner request".toUpperCase(),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: <Widget>[
            Padding(
              padding: EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: <Widget>[
                  Container(
                    child: Column(
                      children: <Widget>[
                        Text(
                          "Together",
                          style: TextStyle(
                            color: Theme.of(context).primaryColorDark,
                            fontSize: Theme.of(context)
                                .primaryTextTheme
                                .display1
                                .fontSize,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8.0),
                    child: Container(
                      width: 2.0,
                      height: 24.0,
                      color: Colors.black12,
                    ),
                  ),
                  Container(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Row(
                          children: <Widget>[
                            Text(
                              "We" + " ",
                              style: TextStyle(
                                color: Theme.of(context).primaryColorDark,
                              ),
                            ),
                            Text(
                              "Build",
                              style: TextStyle(
                                  color: Theme.of(context).primaryColorDark,
                                  fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        Row(
                          children: <Widget>[
                            Text(
                              "We" + " ",
                              style: TextStyle(
                                color: Theme.of(context).primaryColorDark,
                              ),
                            ),
                            Text(
                              "Share",
                              style: TextStyle(
                                  color: Theme.of(context).primaryColorDark,
                                  fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ],
                    ),
                  )
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: TextFormField(
                            controller: _emailController,
                            decoration: InputDecoration(
                              labelText: "Enter email",
                              icon: const Padding(
                                padding: const EdgeInsets.only(top: 15.0),
                                child: const Icon(Icons.email),
                              ),
                            ),
                            validator: (value) {
                              if (value.isEmpty) {
                                return "Please enter email address.";
                              } else if (!validateEmail(value)) {
                                return "Please enter valid email address.";
                              }
                            },
                            keyboardType: TextInputType.emailAddress,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: TextFormField(
                            controller: _mobileController,
                            decoration: InputDecoration(
                              labelText: "Enter mobile number",
                              icon: const Padding(
                                padding: const EdgeInsets.only(top: 15.0),
                                child: const Icon(Icons.phone),
                              ),
                            ),
                            validator: (value) {
                              if (value.isEmpty) {
                                return "Please enter mobile number.";
                              } else if (!isNumeric(value) ||
                                  value.length != 10) {
                                return "Please enter valid mobile number.";
                              }
                            },
                            keyboardType: TextInputType.phone,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 32.0),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: RaisedButton(
                      onPressed: () {
                        if (_formKey.currentState.validate()) {
                          submitForm();
                        }
                      },
                      color: Theme.of(context).primaryColorDark,
                      textColor: Colors.white70,
                      child: Text("SUBMIT"),
                    ),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
