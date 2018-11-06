import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'package:playfantasy/utils/apiutil.dart';
import 'package:playfantasy/utils/stringtable.dart';
import 'package:playfantasy/utils/sharedprefhelper.dart';

class ChangePassword extends StatefulWidget {
  @override
  ChangePasswordState createState() => ChangePasswordState();
}

class ChangePasswordState extends State<ChangePassword> {
  String cookie = "";
  bool _obscureNewPassword = true;
  bool _obscureCurrentPassword = true;
  final _formKey = new GlobalKey<FormState>();
  TextEditingController _newPasswordController = TextEditingController();
  TextEditingController _currentPasswordController = TextEditingController();

  _onChangePassword() async {
    if (cookie == null || cookie == "") {
      Future<dynamic> futureCookie = SharedPrefHelper.internal().getCookie();
      await futureCookie.then((value) {
        cookie = value;
      });
    }

    await http.Client()
        .post(
      ApiUtil.CHANGE_PASSWORD,
      headers: {'Content-type': 'application/json', "cookie": cookie},
      body: json.encode({
        "newPassword": _newPasswordController.text,
        "oldPassword": _currentPasswordController.text,
      }),
    )
        .then(
      (http.Response res) {
        if (res.statusCode >= 200 && res.statusCode <= 299) {
          Navigator.of(context).pop("Password changed successfully.");
        } else if (res.statusCode >= 400 && res.statusCode < 500) {
          Map<String, dynamic> response = json.decode(res.body);
          Navigator.of(context).pop(response["error"]);
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text("Change password"),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: TextFormField(
                    controller: _currentPasswordController,
                    decoration: InputDecoration(
                      labelText: "Current password",
                      hintText: strings.get("MIN_CHARS_PASSWORD"),
                      icon: Padding(
                        padding: EdgeInsets.only(top: 15.0),
                        child: Icon(Icons.lock),
                      ),
                      suffixIcon: GestureDetector(
                        onTap: () {
                          setState(() {
                            _obscureCurrentPassword = !_obscureCurrentPassword;
                          });
                        },
                        child: Icon(_obscureCurrentPassword
                            ? Icons.visibility
                            : Icons.visibility_off),
                      ),
                    ),
                    validator: (value) {
                      if (value.isEmpty) {
                        return strings.get("PASSWORD_ERROR");
                      }
                    },
                    obscureText: _obscureCurrentPassword,
                  ),
                )
              ],
            ),
            Row(
              children: <Widget>[
                Expanded(
                  child: TextFormField(
                    controller: _newPasswordController,
                    decoration: InputDecoration(
                      labelText: "New password",
                      hintText: strings.get("MIN_CHARS_PASSWORD"),
                      icon: Padding(
                        padding: EdgeInsets.only(top: 15.0),
                        child: Icon(Icons.lock),
                      ),
                      suffixIcon: GestureDetector(
                        onTap: () {
                          setState(() {
                            _obscureNewPassword = !_obscureNewPassword;
                          });
                        },
                        child: Icon(_obscureNewPassword
                            ? Icons.visibility
                            : Icons.visibility_off),
                      ),
                    ),
                    validator: (value) {
                      if (value.isEmpty) {
                        return strings.get("PASSWORD_ERROR");
                      }
                    },
                    obscureText: _obscureNewPassword,
                  ),
                )
              ],
            ),
          ],
        ),
      ),
      actions: <Widget>[
        FlatButton(
          child: Text('CANCEL'),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        FlatButton(
          child: Text('CHANGE'),
          onPressed: () {
            if (_formKey.currentState.validate()) {
              _onChangePassword();
            }
          },
        ),
      ],
    );
  }
}
