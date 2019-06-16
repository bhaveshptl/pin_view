import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:playfantasy/action_utils/action_util.dart';

import 'package:playfantasy/utils/apiutil.dart';
import 'package:playfantasy/utils/httpmanager.dart';
import 'package:playfantasy/utils/stringtable.dart';

class ChangePassword extends StatefulWidget {
  @override
  ChangePasswordState createState() => ChangePasswordState();
}

class ChangePasswordState extends State<ChangePassword> {
  String cookie = "";
  String password = "";

  bool bDigitsCountMatch = false;
  bool bLettersCountMatch = false;
  bool passConstraintMatch = false;
  bool bSpecialCharCountMatch = false;

  bool _obscureNewPassword = true;
  bool _obscureCurrentPassword = true;
  final _formKey = new GlobalKey<FormState>();
  TextEditingController _newPasswordController = TextEditingController();
  TextEditingController _currentPasswordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _newPasswordController.addListener(() {
      setState(() {
        password = _newPasswordController.text;
        bDigitsCountMatch = password.contains(RegExp('[0-9]'));
        bLettersCountMatch = password.contains(RegExp('[A-z]'));
        bSpecialCharCountMatch =
            password.contains(RegExp('[_@#\$?().,!/:{}><;`*~%^&+=]'));
        passConstraintMatch = bDigitsCountMatch &&
            bLettersCountMatch &&
            bSpecialCharCountMatch &&
            password.length >= 8;
      });
    });
  }

  _onChangePassword() async {
    http.Request req = http.Request(
        "POST", Uri.parse(BaseUrl().apiUrl + ApiUtil.CHANGE_PASSWORD));
    req.body = json.encode({
      "newPassword": _newPasswordController.text,
      "oldPassword": _currentPasswordController.text,
    });
    await HttpManager(http.Client()).sendRequest(req).then(
      (http.Response res) {
        if (res.statusCode >= 200 && res.statusCode <= 299) {
          Navigator.of(context).pop("Password changed successfully.");
        } else if (res.statusCode >= 400 && res.statusCode < 500) {
          Map<String, dynamic> response = json.decode(res.body);
          Navigator.of(context).pop(response["error"]);
        }
      },
    ).whenComplete(() {
      ActionUtil().showLoader(context, false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text("Change password"),
      content: Container(
        width: MediaQuery.of(context).size.width,
        child: Form(
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
                        contentPadding: EdgeInsets.all(4.0),
                        border: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: Colors.black38,
                          ),
                        ),
                        prefixIcon: Icon(
                          Icons.lock,
                          size: 16.0,
                        ),
                        suffixIcon: GestureDetector(
                          onTap: () {
                            setState(() {
                              _obscureCurrentPassword =
                                  !_obscureCurrentPassword;
                            });
                          },
                          child: Icon(
                            _obscureCurrentPassword
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
                      obscureText: _obscureCurrentPassword,
                    ),
                  )
                ],
              ),
              Padding(
                padding: EdgeInsets.only(top: 16.0),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: TextFormField(
                        controller: _newPasswordController,
                        decoration: InputDecoration(
                          labelText: "New password",
                          contentPadding: EdgeInsets.all(0.0),
                          border: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: Colors.black38,
                            ),
                          ),
                          prefixIcon: Icon(
                            Icons.lock,
                            size: 16.0,
                          ),
                          suffixIcon: GestureDetector(
                            onTap: () {
                              setState(() {
                                _obscureNewPassword = !_obscureNewPassword;
                              });
                            },
                            child: Icon(
                              _obscureNewPassword
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                              size: 16.0,
                            ),
                          ),
                        ),
                        validator: (value) {
                          if (value.isEmpty) {
                            return strings.get("PASSWORD_ERROR");
                          } else if (!passConstraintMatch) {
                            strings.get("PASSWORD_CONSTRAINT_NOT_MATCHED");
                          }
                        },
                        obscureText: _obscureNewPassword,
                      ),
                    )
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(8.0, 16.0, 8.0, 16.0),
                child: Container(
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12.0),
                      color: passConstraintMatch
                          ? Color.fromRGBO(0, 255, 0, 0.1)
                          : Color.fromRGBO(255, 0, 0, 0.1),
                      border: Border.all(
                        color: passConstraintMatch ? Colors.teal : Colors.red,
                      )),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Row(
                          children: <Widget>[
                            Text(strings.get("PASSWORD_SHOULD"),
                                style: TextStyle(color: Colors.teal)),
                          ],
                        ),
                        Row(
                          children: <Widget>[
                            Text(" - " + strings.get("MIN_CHAR"),
                                style: TextStyle(
                                    color: password.length >= 8
                                        ? Colors.teal
                                        : Colors.red)),
                          ],
                        ),
                        Row(
                          children: <Widget>[
                            Text(" - " + strings.get("ATLEAST_NUMBER"),
                                style: TextStyle(
                                    color: bDigitsCountMatch
                                        ? Colors.teal
                                        : Colors.red)),
                          ],
                        ),
                        Row(
                          children: <Widget>[
                            Text(" - " + strings.get("ATLEAST_ALPHABET"),
                                style: TextStyle(
                                    color: bLettersCountMatch
                                        ? Colors.teal
                                        : Colors.red)),
                          ],
                        ),
                        Row(
                          children: <Widget>[
                            Text(
                                " - " +
                                    strings.get("ATLEAST_SPECIAL_CHARACTER"),
                                style: TextStyle(
                                    color: bSpecialCharCountMatch
                                        ? Colors.teal
                                        : Colors.red)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
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
