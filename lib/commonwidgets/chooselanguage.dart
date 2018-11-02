import 'package:flutter/material.dart';

class ChooseLanguage extends StatefulWidget {
  final List<dynamic> languages;
  final Function onLanguageChange;

  ChooseLanguage({this.languages, this.onLanguageChange});

  @override
  ChooseLanguageState createState() {
    return new ChooseLanguageState();
  }
}

class ChooseLanguageState extends State<ChooseLanguage> {
  Map<String, dynamic> _selectedMaterial;

  @override
  void initState() {
    super.initState();
    _selectedMaterial = widget.languages[0];
  }

  Color _nameToColor(String name) {
    assert(name.length > 1);
    final int hash = name.hashCode & 0xffff;
    final double hue = (360.0 * hash / (1 << 15)) % 360.0;
    return HSVColor.fromAHSV(1.0, hue, 0.4, 0.90).toColor();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  "YOUR APP YOUR LANGUAGE",
                  style: TextStyle(
                    fontSize: Theme.of(context).primaryTextTheme.title.fontSize,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColorDark,
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(top: 16.0, bottom: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: widget.languages.map<Widget>((dynamic language) {
                return Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: ChoiceChip(
                    key: ValueKey<dynamic>(language),
                    backgroundColor: _nameToColor(language["label"]),
                    label: Padding(
                      padding: const EdgeInsets.only(left: 24.0, right: 24.0),
                      child: Text(language["label"].toUpperCase()),
                    ),
                    selected: _selectedMaterial["label"] == language["label"],
                    onSelected: (bool value) {
                      setState(() {
                        _selectedMaterial =
                            value ? language : _selectedMaterial;
                      });
                    },
                  ),
                );
              }).toList(),
            ),
          ),
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  _selectedMaterial["description"],
                  style: TextStyle(
                    fontSize:
                        Theme.of(context).primaryTextTheme.subhead.fontSize,
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: EdgeInsets.only(
              top: 16.0,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Expanded(
                  child: RaisedButton(
                    onPressed: () {
                      widget.onLanguageChange(_selectedMaterial);
                      Navigator.of(context).pop(_selectedMaterial);
                    },
                    child: Text(
                      "CONTINUE WITH '" +
                          _selectedMaterial["label"].toUpperCase() +
                          "'",
                      style: TextStyle(color: Colors.white54),
                    ),
                    color: Theme.of(context).primaryColorDark,
                  ),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}
