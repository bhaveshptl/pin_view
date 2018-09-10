import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'package:playfantasy/utils/apiutil.dart';
import 'package:playfantasy/utils/authresult.dart';

class SigninForm extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => new SigninFormState();
}

class SigninFormState extends State<SigninForm> {
  String _authName;
  String _password;
  final formKey = new GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    doSignIn() async {
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
        AuthResult(res, context, setState).processResult();
      }).whenComplete(() => print('completed'));
    }

    return Form(
      key: formKey,
      child: new Container(
        padding: EdgeInsets.fromLTRB(30.0, 20.0, 30.0, 20.0),
        child: new Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            new Container(
              padding: EdgeInsets.only(bottom: 10.0),
              child: new Text(
                "Welcome to Playfantasy!",
                style: TextStyle(
                    fontSize:
                        Theme.of(context).primaryTextTheme.headline.fontSize,
                    color: Theme.of(context).primaryTextTheme.headline.color),
              ),
            ),
            new TextFormField(
              keyboardType: TextInputType.emailAddress,
              onSaved: (val) => _authName = val,
              validator: (value) {
                if (value.isEmpty) {
                  return 'Please enter username or email or mobile.';
                }
              },
              decoration: new InputDecoration(
                labelText: "Enter email or mobile",
                labelStyle: TextStyle(
                  color: Colors.black54,
                ),
              ),
              style: TextStyle(
                  color: Colors.black87,
                  fontSize: Theme.of(context).primaryTextTheme.title.fontSize),
            ),
            new TextFormField(
              obscureText: true,
              onSaved: (val) => _password = val,
              validator: (value) {
                if (value.isEmpty) {
                  return 'Please enter Password';
                }
              },
              keyboardType: TextInputType.text,
              decoration: new InputDecoration(
                labelText: "Enter password",
                labelStyle: TextStyle(
                  color: Colors.black54,
                ),
              ),
              style: TextStyle(
                  color: Colors.black87,
                  fontSize: Theme.of(context).primaryTextTheme.title.fontSize),
            ),
            new Container(
              margin: EdgeInsets.only(top: 40.0),
              child: new SizedBox(
                width: 150.0,
                child: new RaisedButton(
                  child: new Text("SIGN IN"),
                  textColor: Colors.black87,
                  shape: new RoundedRectangleBorder(
                    borderRadius: new BorderRadius.circular(20.0),
                  ),
                  splashColor: Theme.of(context).primaryColorDark,
                  highlightColor: Theme.of(context).primaryColorDark,
                  onPressed: () {
                    if (formKey.currentState.validate()) {
                      formKey.currentState.save();
                      doSignIn();
                    }
                  },
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
