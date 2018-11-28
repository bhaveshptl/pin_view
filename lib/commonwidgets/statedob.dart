import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:playfantasy/appconfig.dart';

import 'package:playfantasy/utils/apiutil.dart';
import 'package:playfantasy/modal/stateinfo.dart';
import 'package:playfantasy/utils/httpmanager.dart';
import 'package:playfantasy/utils/stringtable.dart';
import 'package:playfantasy/utils/sharedprefhelper.dart';

class StateDob extends StatefulWidget {
  final Function onSuccess;
  StateDob({this.onSuccess});

  @override
  State<StatefulWidget> createState() => StateDobState();
}

class StateDobState extends State<StateDob> {
  String _selectedState = "-1";
  List<StateInfo> _lstState = [];
  bool _bShowValidationError = false;
  static int currentYear = DateTime.now().year;
  DateTime _date = new DateTime(currentYear - 18);
  String _defaultText = "YYYY-MM-DD";

  _onSubmit(BuildContext context) async {
    if (_defaultText != null) {
      setState(() {
        _bShowValidationError = true;
      });
    } else {
      String cookie;
      Future<dynamic> futureCookie = SharedPrefHelper.internal().getCookie();
      await futureCookie.then((value) {
        cookie = value;
      });

      return new http.Client()
          .put(
        BaseUrl.apiUrl + ApiUtil.UPDATE_DOB_STATE,
        headers: {
          'Content-type': 'application/json',
          "cookie": cookie,
          "channelId": AppConfig.of(context).channelId
        },
        body: json.encode({"dob": getDate(), "state": _selectedState}),
      )
          .then((http.Response res) {
        if (res.statusCode >= 200 && res.statusCode <= 300) {
          if (widget.onSuccess != null) {
            widget.onSuccess(
              strings.get("STATE_DOB_UPDATED"),
            );
          }
          Navigator.of(context).pop();
        }
      });
    }
  }

  Future<Null> _selectDate(BuildContext context) async {
    final DateTime picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(1947),
      lastDate: DateTime(currentYear),
    );

    if (picked != null) {
      setState(() {
        _date = picked;
        _defaultText = null;
        _bShowValidationError = false;
      });
    }
  }

  _getStateList() async {
    http.Request req = http.Request(
      "GET",
      Uri.parse(BaseUrl.apiUrl + ApiUtil.STATE_LIST),
    );
    return HttpManager(http.Client())
        .sendRequest(req)
        .then((http.Response res) {
      if (res.statusCode >= 200 && res.statusCode <= 299) {
        setState(() {
          _lstState = (json.decode(res.body) as List)
              .map((i) => StateInfo.fromJson(i))
              .toList();
        });
      }
    });
  }

  List<DropdownMenuItem> _getStateListItems(BuildContext context) {
    List<DropdownMenuItem> lstMenuItems = [];
    if (_lstState.length > 0) {
      for (StateInfo state in _lstState) {
        lstMenuItems.add(
          DropdownMenuItem(
            child: Container(
                width: 140.0,
                child: Text(
                  state.value,
                  overflow: TextOverflow.ellipsis,
                )),
            value: state.code,
          ),
        );
      }
      _selectedState =
          _selectedState == "-1" ? _lstState[0].code : _selectedState;
    } else {
      lstMenuItems.add(DropdownMenuItem(
        child: Container(
          width: 140.0,
          child: Text(""),
        ),
        value: "-1",
      ));
    }
    return lstMenuItems;
  }

  getDate() {
    return (_date.year.toString() +
        "-" +
        (_date.month >= 10
            ? _date.month.toString()
            : ("0" + _date.month.toString())) +
        "-" +
        (_date.day >= 10
            ? _date.day.toString()
            : ("0" + _date.day.toString())));
  }

  @override
  void initState() {
    super.initState();
    _getStateList();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(strings.get("DETAILS").toUpperCase()),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Text(
                  strings.get("STATE"),
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                DropdownButton(
                  onChanged: (value) {
                    setState(() {
                      _selectedState = value;
                    });
                  },
                  items: _getStateListItems(context),
                  value: _selectedState,
                )
              ],
            ),
          ),
          Row(
            children: <Widget>[
              Expanded(
                flex: 1,
                child: Text(
                  strings.get("DOB"),
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              Expanded(
                child: OutlineButton(
                  onPressed: () {
                    _selectDate(context);
                  },
                  child: _defaultText != null
                      ? Text(_defaultText)
                      : Text(getDate()),
                ),
              )
            ],
          ),
          Row(
            children: <Widget>[
              _bShowValidationError
                  ? Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Text(
                        strings.get("SELECT_DOB"),
                        style: TextStyle(color: Theme.of(context).errorColor),
                      ),
                    )
                  : Container(),
            ],
          )
        ],
      ),
      actions: <Widget>[
        FlatButton(
          child: Text(strings.get("CANCEL").toUpperCase()),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        FlatButton(
          child: Text(strings.get("SUBMIT").toUpperCase()),
          onPressed: () {
            _onSubmit(context);
          },
        )
      ],
    );
  }
}
