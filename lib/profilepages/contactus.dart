import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_webview_plugin/flutter_webview_plugin.dart';
import 'package:http/http.dart' as http;
import 'package:playfantasy/action_utils/action_util.dart';
import 'package:playfantasy/commonwidgets/scaffoldpage.dart';

import 'package:playfantasy/utils/apiutil.dart';
import 'package:playfantasy/utils/httpmanager.dart';

class ContactUs extends StatefulWidget {
  @override
  ContactUsState createState() => ContactUsState();
}

class ContactUsState extends State<ContactUs> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _description = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _mobileController = TextEditingController();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  bool emailEnabled = false;
  bool showSubCategory = false;
  bool phoneNumberEnabled = true;
  List<dynamic> categoriesData = [];
  List<DropdownMenuItem<String>> categoriesList = [];
  List<DropdownMenuItem<String>> subCategoriesList = [];

  String emailId = "";
  String phoneNumber = "";
  String selectedCategorie;
  String selectedSubCategory;
  String selectedCategorieIndex;

  @override
  void initState() {
    super.initState();
    _getFormDetails();
  }

  _getFormDetails() async {
    http.Request req = http.Request(
      "GET",
      Uri.parse(
        BaseUrl().apiUrl + ApiUtil.CONTACTUS_FORM,
      ),
    );
    return HttpManager(http.Client()).sendRequest(req).then(
      (http.Response res) {
        if (res.statusCode >= 200 && res.statusCode <= 299) {
          Map<String, dynamic> response = json.decode(res.body);
          setState(() {
            emailId = response['email'];
            phoneNumber = response['mobile'];

            categoriesData = response['categories'];
            _emailController.text = emailId;
            _mobileController.text = phoneNumber;
            if (phoneNumber != null && phoneNumber.length > 0) {
              phoneNumberEnabled = false;
            }
            if (emailId != null && emailId.length > 0) {
              emailEnabled = true;
            }
          });
          categoriesList = [];
          for (var i = 0; i < categoriesData.length; i++) {
            Map<String, dynamic> data = categoriesData[i];
            categoriesList.add(new DropdownMenuItem(
              child: new Text(data["id"]),
              value: i.toString(),
            ));
          }
        } else if (res.statusCode == 401) {
          Map<String, dynamic> response = json.decode(res.body);
          if (response["error"]["reasons"].length > 0) {}
        }
      },
    ).whenComplete(() {
      ActionUtil().showLoader(context, false);
    });
  }

  setSubCategoriesListData(index) {
    Map<String, dynamic> selectedCategoryData =
        categoriesData[int.parse(index)];
    selectedCategorie = selectedCategoryData["id"];
    List<dynamic> subCategoryData = selectedCategoryData["subcategories"];
    subCategoriesList = [];
    for (var i = 0; i < subCategoryData.length; i++) {
      Map<String, dynamic> data = subCategoryData[i];
      subCategoriesList.add(new DropdownMenuItem(
        child: new Text(data["id"]),
        value: data["id"],
      ));
    }
  }

  submitForm() async {
    http.Request req = http.Request(
        "POST", Uri.parse(BaseUrl().apiUrl + ApiUtil.CONTACTUS_SUBMIT));
    req.body = json.encode({
      "category": selectedCategorie,
      "subCategory": selectedSubCategory,
      "comments": _description.text,
      "toEmail": "support@playfantasy.com",
      "fromEmail": _emailController.text,
      "phone": _mobileController.text
    });
    return HttpManager(http.Client())
        .sendRequest(req)
        .then((http.Response res) {
      if (res.statusCode >= 200 && res.statusCode < 300) {
        //  Navigator.of(context).pop();
        _showDialog(
            "Your support request has been submitted successfully. We will get back to you soon.");
      } else {
        _showDialog("Unable to process request. Please try again...!");
      }
    }).whenComplete(() {
      ActionUtil().showLoader(context, false);
    });
  }

  void _showDialog(msg) {
    // flutter defined function
    showDialog(
      context: context,
      builder: (BuildContext context) {
        // return object of type Dialog
        return AlertDialog(
          title: new Text("Alert"),
          content: new Text(msg),
          actions: <Widget>[
            // usually buttons at the bottom of the dialog
            new FlatButton(
              child: new Text("Close"),
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  _showMessage(String message) {
    ActionUtil().showMsgOnTop(message, context);
    // _scaffoldKey.currentState.showSnackBar(SnackBar(
    //   content: Text(message),
    // ));
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

  _launchStaticPage(String name) {
    String url = "";
    String title = "";
    switch (name) {
      case "FAQ":
        title = "FAQ";
        url = BaseUrl().staticPageUrls["FAQ"];
        break;
    }
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => WebviewScaffold(
              url: url,
              clearCache: true,
              appBar: AppBar(
                title: Text(
                  title.toUpperCase(),
                ),
              ),
            ),
        fullscreenDialog: true,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldPage(
      scaffoldKey: _scaffoldKey,
      appBar: AppBar(
        title: Text(
          "Contact Us".toUpperCase(),
        ),
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
                            enabled: phoneNumberEnabled,
                            decoration: InputDecoration(
                              labelText: "Mobile Number",
                            ),
                            inputFormatters: [
                              LengthLimitingTextInputFormatter(
                                10,
                              )
                            ],
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
                      Expanded(
                        child: new DropdownButton<String>(
                            items: categoriesList,
                            hint: Text("Select category"),
                            value: selectedCategorieIndex,
                            elevation: 16,
                            iconSize: 32.0,
                            onChanged: (newVal) {
                              selectedCategorieIndex = newVal;
                              setSubCategoriesListData(selectedCategorieIndex);
                              this.setState(() {
                                showSubCategory = true;
                              });
                            }),
                      )
                    ]),
                    Row(
                      children: <Widget>[
                        showSubCategory == true
                            ? Expanded(
                                child: DropdownButton<String>(
                                    items: subCategoriesList,
                                    hint: Text("Select Subcategory"),
                                    value: selectedSubCategory,
                                    elevation: 16,
                                    iconSize: 32.0,
                                    onChanged: (newVal) {
                                      this.setState(() {
                                        selectedSubCategory = newVal;
                                      });
                                    }),
                              )
                            : Text("")
                      ],
                    ),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: TextFormField(
                            controller: _description,
                            decoration: InputDecoration(
                              labelText: "Description",
                            ),
                            validator: (value) {
                              if (value.isEmpty) {
                                return "Please explain your issue!";
                              }
                            },
                            keyboardType: TextInputType.text,
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
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 32.0),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: OutlineButton(
                      onPressed: () {
                        _launchStaticPage("FAQ");
                      },
                      borderSide: BorderSide(
                        color: Theme.of(context).primaryColor,
                      ),
                      highlightedBorderColor: Theme.of(context).primaryColor,
                      child: Text(
                        "FAQ",
                        style: TextStyle(
                          color: Theme.of(context).primaryColor,
                          fontWeight: FontWeight.bold,
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
    );
  }
}
