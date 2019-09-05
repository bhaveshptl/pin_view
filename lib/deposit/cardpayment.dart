import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:playfantasy/commonwidgets/color_button.dart';
import 'package:playfantasy/utils/stringtable.dart';
import 'package:playfantasy/utils/maskedTextController.dart';

class CardPaymentForm extends StatefulWidget {
  @override
  CardPaymentFormState createState() => CardPaymentFormState();
}

class CardPaymentFormState extends State<CardPaymentForm> {
  /* Card payment UI */
  final _formKey = new GlobalKey<FormState>();
  TextEditingController cformNameOnCardController = TextEditingController();
  TextEditingController cformCVVController = TextEditingController();
  TextEditingController cformCardNumberController =
      MaskedTextController(mask: '0000 0000 0000 0000 0000 0000');
  TextEditingController cformExpDateController =
      MaskedTextController(mask: '00/00');
  String cformNameOnTheCard = "";
  String cformCVV = "";
  String cformCardNumber = "";
  String cformExpMonth = "";
  String cformExpYear = "";
  String cformExpDate = "";
  String cformCardImagePath = "images/bank_card.png";
  bool cformSaveCardDetails = false;
  bool cformObscureCVV = true;
  FocusNode cformCVVFocusnode = FocusNode();
  FocusNode cformExpDateFocusnode = FocusNode();
  FocusNode cformNameFocusnode = FocusNode();
  FocusNode cformCardNumberFocusnode = FocusNode();

  @override
  void initState() {
    super.initState();
    cformControllerListener();
  }

  _onPaySecurely() async {
    Map<String, dynamic> data = new Map();
    data["validData"] = true;
    data["cformCVV"] = cformCVV;
    data["cformNameOnTheCard"] = cformNameOnTheCard;
    data["cformCardNumber"] = cformCardNumber;
    data["cformExpMonth"] = cformExpMonth;
    data["cformExpYear"] = cformExpYear;

    print(data);
    Navigator.of(context).pop(data);
  }

  onClosePopup() {
    Map<String, dynamic> data = new Map();
    data["validData"] = false;
    Navigator.of(context).pop(data);
  }

  /** Card Payment ui*/
  String validateTheExpireDate(String date) {
    String value = date.toString();
    var mnthlst = new List(12);
    mnthlst = [
      "01",
      "02",
      "03",
      "04",
      "05",
      "06",
      "07",
      "08",
      "09",
      "10",
      "11",
      "12"
    ];
    if (value.isEmpty) {
      return "Please enter Exp Month";
    } else if (!mnthlst.contains(cformExpMonth)) {
      return "Please enter valid month";
    } else {
      return null;
    }
  }

  cformControllerListener() {
    cformExpDateController.addListener(() {
      print(cformExpDateController.text);
      setState(() {
        cformExpDate = cformExpDateController.text;
        cformExpMonth = cformExpDate.split("/")[0];
        cformExpYear = cformExpDate.split("/")[1];
        cformExpYear = "20" + cformExpYear;
      });
    });
    cformNameOnCardController.addListener(() {
      setState(() {
        cformNameOnTheCard = cformNameOnCardController.text;
      });
    });
    cformCVVController.addListener(() {
      setState(() {
        cformCVV = cformCVVController.text;
      });
    });
    cformNameOnCardController.addListener(() {
      setState(() {
        cformExpDate = cformNameOnCardController.text;
      });
    });
    cformCardNumberController.addListener(() {
      List<String> visa = ["4"];
      List<String> americanExpress = ["34", "37"];
      List<String> discover = ["6011", "622126", "622925", "644", "649", "65"];
      List<String> mastercard = [
        "51",
        "55",
        "2221",
        "2229",
        "223",
        "229",
        "23",
        "26",
        "270",
        "271",
        "2720"
      ];

      setState(() {
        cformCardNumber = cformCardNumberController.text
            .replaceAll(new RegExp(r"\s\b|\b\s"), "");
      });

      if (cformCardNumber.startsWith("4")) {
        /*Visa Card*/
        setState(() {
          cformCardImagePath = "images/bank_visa.png";
        });
      }
      if (cformCardNumber.startsWith("34") ||
          cformCardNumber.startsWith("37")) {
        setState(() {
          cformCardImagePath = "images/amex.png";
        });
      }
      for (var c in mastercard) {
        if (cformCardNumber.startsWith(c)) {
          setState(() {
            cformCardImagePath = "images/bank_mastercad.png";
          });
        }
      }

      for (var c in discover) {
        if (cformCardNumber.startsWith(c)) {
          setState(() {
            cformCardImagePath = "images/bank_discover.png";
          });
        }
      }
    });
  }

  void _toggleCVVVisibility() {}

  Form getCardPaymentFormWidget(String paymentType) {
    return Form(
        key: _formKey,
        child: Column(
          children: <Widget>[
            Padding(
              padding: EdgeInsets.only(top: 2.0, bottom: 4.0),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Container(
                        height: 48.0,
                        child: TextFormField(
                          controller: cformCardNumberController,
                          focusNode: cformCardNumberFocusnode,
                          onFieldSubmitted: (value) {
                            cformCardNumberFocusnode.unfocus();
                            FocusScope.of(context)
                                .requestFocus(cformExpDateFocusnode);
                          },
                          decoration: InputDecoration(
                            labelText: 'Card Number',
                            counterText: "",
                            suffixIcon: Padding(
                              padding:
                                  const EdgeInsetsDirectional.only(end: 8.0),
                              child: Image.asset(cformCardImagePath,
                                height: 2, width: 1), 
                            ),
                            contentPadding: EdgeInsets.all(12.0),
                            border: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: Colors.black38,
                              ),
                            ),
                          ),
                          validator: (String value) {
                            if (value.isEmpty) {
                              return "Please enter the card number";
                            }
                          },
                          keyboardType: TextInputType.number,
                          maxLength: 23
                        )),
                  )
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.only(top: 4.0, bottom: 4.0),
              child: Row(
                children: <Widget>[
                  Expanded(
                      flex: 8,
                      child: TextFormField(
                        controller: cformExpDateController,
                        focusNode: cformExpDateFocusnode,
                        onFieldSubmitted: (value) {
                          cformExpDateFocusnode.unfocus();
                          FocusScope.of(context)
                              .requestFocus(cformCVVFocusnode);
                        },
                        decoration: const InputDecoration(
                          labelText: 'Expiry Date',
                          hintText:"MM/YY",
                          counterText: "",
                          contentPadding: EdgeInsets.all(12.0),
                          border: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: Colors.black38,
                            ),
                          ),
                        ),
                        validator: (String value) {
                          return validateTheExpireDate(value);
                        },
                        keyboardType: TextInputType.number,
                        maxLength: 6,
                      )),
                  Expanded(
                    flex: 1,
                    child: Container(),
                  ),
                  Expanded(
                    flex: 8,
                    child: TextFormField(
                        controller: cformCVVController,
                        focusNode: cformCVVFocusnode,
                        onFieldSubmitted: (value) {
                          cformCVVFocusnode.unfocus();
                          FocusScope.of(context)
                              .requestFocus(cformNameFocusnode);
                        },
                        decoration: const InputDecoration(
                          labelText: 'CVV',
                          counterText: "",
                          contentPadding: EdgeInsets.all(12.0),
                          fillColor: Colors.blue,
                          border: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: Colors.black38,
                            ),
                          ),
                        ),
                        validator: (String value) {
                          if (value.isEmpty) {
                            return "Please enter a valid CVV";
                          }
                        },
                        maxLength: 4,
                        obscureText: cformObscureCVV,
                        keyboardType: TextInputType.number),
                  )
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.only(top: 8.0),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Container(
                        height: 48.0,
                        child: TextFormField(
                          controller: cformNameOnCardController,
                          focusNode: cformNameFocusnode,
                          onFieldSubmitted: (value) {
                            cformCVVFocusnode.unfocus();
                          },
                          decoration: const InputDecoration(
                            labelText: "Card Holder's Name",
                            contentPadding: EdgeInsets.all(12.0),
                            border: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: Colors.black38,
                              ),
                            ),
                          ),
                          validator: (String value) {
                            if (value.isEmpty) {
                              return "Please enter name on the Card";
                            } else {
                              return null;
                            }
                          },
                        )),
                  )
                ],
              ),
            ),
            // Padding(
            //     padding: EdgeInsets.only(top: 16.0),
            //     child: Row(children: <Widget>[
            //       Checkbox(
            //         value: cformSaveCardDetails,
            //         onChanged: (bool value) {
            //           setState(() {
            //             cformSaveCardDetails = value;
            //           });
            //         },
            //       ),
            //       Text("Securely  save this  card")
            //     ])),
            Padding(
              padding: EdgeInsets.only(top: 8.0),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Container(
                      height: 48.0,
                      child: ColorButton(
                        onPressed: () {
                          if (_formKey.currentState.validate()) {
                            _onPaySecurely();
                          }
                        },
                        child: Text(
                          strings.get("PAY_SECURELY").toUpperCase(),
                          style:
                              Theme.of(context).primaryTextTheme.title.copyWith(
                                    color: Colors.white,
                                  ),
                        ),
                      ),
                    ),
                  )
                ],
              ),
            ),
          ],
        ));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(4.0),
      ),
      titlePadding: EdgeInsets.symmetric(horizontal: 0.0),
      title: Container(
        width: MediaQuery.of(context).size.width,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: <Widget>[
            Stack(
              alignment: Alignment.centerRight,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        "Payment",
                        style:
                            Theme.of(context).primaryTextTheme.title.copyWith(
                                  color: Colors.black,
                                  fontWeight: FontWeight.w700,
                                ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
                InkWell(
                  child: Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Icon(
                      Icons.close,
                    ),
                  ),
                  onTap: () {
                    onClosePopup();
                  },
                ),
              ],
            ),
          ],
        ),
      ),
      content: Container(
          width: MediaQuery.of(context).size.width,
          child: DottedBorder(
              padding: EdgeInsets.fromLTRB(4.0, 40.0, 4.0, 8.0),
              color: Colors.green,
              child: getCardPaymentFormWidget(""))),
    );
  }
}
