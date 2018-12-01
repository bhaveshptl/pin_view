import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'package:playfantasy/utils/apiutil.dart';
import 'package:playfantasy/utils/httpmanager.dart';

class ContactUs extends StatefulWidget {
  @override
  ContactUsState createState() => ContactUsState();
}

class ContactUsState extends State<ContactUs> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _mobileController = TextEditingController();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  String emailId = "";
  String phoneNumber = "";
  List<dynamic> categories = [];
  List<DropdownMenuItem<String>> categoriesList = [];
  String selectedcCategorie = null;
  List<String> test = ["item1", "item2", "item3", "item4"];

  @override
  void initState() {
    super.initState();
    _getFormDetails();
  }

  _getFormDetails() async {
    http.Request req = http.Request(
      "GET",
      Uri.parse(
        BaseUrl.apiUrl + ApiUtil.CONTACTUS_FORM,
      ),
    );
    return HttpManager(http.Client()).sendRequest(req).then(
      (http.Response res) {
        if (res.statusCode >= 200 && res.statusCode <= 299) {
          Map<String, dynamic> response = json.decode(res.body);

          // setState(() {
          //   accountDetails = Account.fromJson(json.decode(res.body));
          // });
          setState(() {
            emailId = response['email'];
            phoneNumber = response['mobile'];
            categories = response['categories'];
            _emailController.text = emailId;
            _mobileController.text = phoneNumber;
          });

          categoriesList = [];

          
          categoriesList = test
              .map(((val) => new DropdownMenuItem(
                    child: new Text(val),
                    value: val,
                  )))
              .toList();
          print(emailId);
          print(phoneNumber);
          print(categories[1]);
        } else if (res.statusCode == 401) {
          Map<String, dynamic> response = json.decode(res.body);
          if (response["error"]["reasons"].length > 0) {}
        }
      },
    );
  }

  submitForm() async {
    http.Request req = http.Request(
        "POST", Uri.parse(BaseUrl.apiUrl + ApiUtil.CONTACTUS_SUBMIT));
    req.body = json.encode({
      "category": "",
      "subCategory": "",
      "comments": "",
      "toEmail": "support@playfantasy.com",
      "fromEmail": "",
      "phone": ""
    });
    return HttpManager(http.Client())
        .sendRequest(req)
        .then((http.Response res) {
      if (res.statusCode >= 200 && res.statusCode < 300) {
        _showMessage("We will get back to you very soon...!");
      } else {
        _showMessage("Unable to process request. Please try again...!");
      }
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
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text("Contact Us"),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: <Widget>[
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
                              labelText: "Email ID",
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
                              labelText: "Mobile Number",
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
                    Row(children: <Widget>[
                      new DropdownButton<String>(
                          items: categoriesList,
                          hint: Text("Select"),
                          value: selectedcCategorie,
                          elevation: 16,
                          iconSize: 60.0,
                          onChanged: (newVal) {
                            selectedcCategorie = newVal;
                            this.setState(() {});
                          })
                    ]),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: TextFormField(
                            controller: _mobileController,
                            decoration: InputDecoration(
                              labelText: "Sub Category",
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
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: TextFormField(
                            controller: _mobileController,
                            decoration: InputDecoration(
                              labelText: "Description",
                              icon: const Padding(
                                padding: const EdgeInsets.only(top: 15.0),
                                child: const Icon(Icons.phone),
                              ),
                            ),
                            validator: (value) {
                              if (value.isEmpty) {
                                return "Please explain your issue!";
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
