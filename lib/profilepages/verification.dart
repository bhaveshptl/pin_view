import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart';

import 'package:playfantasy/utils/stringtable.dart';

class Verification extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => VerificationState();
}

class VerificationState extends State<Verification> {
  int _selectedItemIndex = -1;

  File _image;

  Future getImage() async {
    var image = await ImagePicker.pickImage(source: ImageSource.camera);

    setState(() {
      String fileName = basename(image.path);
      _image = image;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(strings.get("ACCOUNT_VERIFICATION")),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 72.0),
                    child: Container(
                      margin: const EdgeInsets.all(16.0),
                      child: ExpansionPanelList(
                        expansionCallback: (int index, bool isExpanded) {
                          setState(() {
                            if (_selectedItemIndex == index) {
                              _selectedItemIndex = -1;
                            } else {
                              _selectedItemIndex = index;
                            }
                          });
                        },
                        children: [
                          ExpansionPanel(
                            isExpanded: _selectedItemIndex == 0,
                            headerBuilder: (context, isExpanded) {
                              return Padding(
                                padding: const EdgeInsets.only(left: 16.0),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: <Widget>[
                                    Text(
                                      strings.get("EMAIL"),
                                    ),
                                    Icon(Icons.remove_circle_outline),
                                  ],
                                ),
                              );
                            },
                            body: Column(
                              children: <Widget>[
                                Divider(
                                  height: 2.0,
                                  color: Colors.black12,
                                ),
                                Form(
                                  child: Column(
                                    children: <Widget>[
                                      ListTile(
                                        leading: TextFormField(
                                          keyboardType:
                                              TextInputType.emailAddress,
                                          decoration: InputDecoration(
                                            labelText: "Enter e-mail address",
                                            hintText: 'example@abc.com',
                                          ),
                                        ),
                                      ),
                                      ListTile(
                                        leading: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.end,
                                          children: <Widget>[
                                            FlatButton(
                                              onPressed: () {},
                                              child: Text(
                                                strings
                                                    .get("VERIFY")
                                                    .toUpperCase(),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          ExpansionPanel(
                            isExpanded: _selectedItemIndex == 1,
                            headerBuilder: (context, isExpanded) {
                              return Padding(
                                padding: const EdgeInsets.only(left: 16.0),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: <Widget>[
                                    Text(
                                      strings.get("MOBILE"),
                                    ),
                                    Icon(Icons.check_circle_outline),
                                  ],
                                ),
                              );
                            },
                            body: Column(
                              children: <Widget>[
                                Divider(
                                  height: 2.0,
                                  color: Colors.black12,
                                ),
                                Form(
                                  child: Column(
                                    children: <Widget>[
                                      ListTile(
                                        leading: TextFormField(
                                          keyboardType: TextInputType.phone,
                                          decoration: InputDecoration(
                                              labelText: "Enter mobile number",
                                              hintText: "9999999999",
                                              prefix: Padding(
                                                padding: const EdgeInsets.only(
                                                    right: 4.0),
                                                child: Text("+91"),
                                              )),
                                        ),
                                      ),
                                      ListTile(
                                        leading: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.end,
                                          children: <Widget>[
                                            FlatButton(
                                              onPressed: () {},
                                              child: Text(
                                                strings
                                                    .get("VERIFY")
                                                    .toUpperCase(),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          ExpansionPanel(
                            isExpanded: _selectedItemIndex == 2,
                            headerBuilder: (context, isExpanded) {
                              return Padding(
                                padding: const EdgeInsets.only(left: 16.0),
                                child: Row(
                                  children: <Widget>[
                                    Text(
                                      strings.get("KYC"),
                                    ),
                                  ],
                                ),
                              );
                            },
                            body: Column(
                              children: <Widget>[
                                Divider(
                                  height: 2.0,
                                  color: Colors.black12,
                                ),
                                Form(
                                  child: ListTile(
                                    leading: Row(
                                      children: <Widget>[
                                        FlatButton(
                                          onPressed: () {
                                            getImage();
                                          },
                                          child: Text("Select pan card"),
                                        )
                                      ],
                                    ),
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
            )
          ],
        ),
      ),
    );
  }
}
