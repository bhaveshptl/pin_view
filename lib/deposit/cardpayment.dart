import 'package:flutter/material.dart';
import 'package:playfantasy/commonwidgets/color_button.dart';
import 'package:playfantasy/utils/stringtable.dart';

class CardPaymentForm extends StatefulWidget {
  @override
  CardPaymentFormState createState() => CardPaymentFormState();
}

class CardPaymentFormState extends State<CardPaymentForm> {
  TextEditingController cformCVVController = TextEditingController();
  String cformCVV = ""; 
  bool _obscureCVV = true;
  final _formKey = new GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
  }

  _onPaySecurely() async {
    Map<String, dynamic> data = new Map();
    data["validData"]=true; 
    data["cvv"]="1223";
    Navigator.of(context).pop(data);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text("PAYMENT"),
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
                      controller: cformCVVController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: "CVV",
                        counterText: "",
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
                              _obscureCVV =
                                  !_obscureCVV;
                            });
                          },
                          child: Icon(
                            _obscureCVV
                                ? Icons.visibility
                                : Icons.visibility_off,
                            size: 16.0,
                          ),
                        ),
                      ),
                      validator: (value) {
                        if (value.isEmpty) {
                          return "Please provid valid CVV";
                        }
                      },
                      obscureText: _obscureCVV,
                      maxLength: 4,
                    ),
                  )
                ],
              ),
              Padding(
                padding: EdgeInsets.only(top: 16.0),
                child: Row(
                  children: <Widget>[
                    ColorButton(
                      child: Text(                       
                        strings.get("PAY_SECURELY").toUpperCase(),
                        style: Theme.of(context)
                            .primaryTextTheme
                            .headline
                            .copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      onPressed: () {
                        _onPaySecurely();
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
