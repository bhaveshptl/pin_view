import 'package:flutter/material.dart';

class CreatePrizeStructure extends StatefulWidget {
  final customPrizes;
  final suggestedPrizes;
  final Function onSave;

  CreatePrizeStructure({this.customPrizes, this.suggestedPrizes, this.onSave});

  @override
  State<StatefulWidget> createState() => CreatePrizeStructureState();
}

class CreatePrizeStructureState extends State<CreatePrizeStructure> {
  @override
  Widget build(BuildContext context) {
    return Container(
      child: Column(
        children: <Widget>[
          Container(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.only(left: 8.0),
                  child: OutlineButton(
                    padding: EdgeInsets.all(0.0),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: Text("CANCEL"),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: RaisedButton(
                    color: Colors.teal,
                    textColor: Colors.white70,
                    padding: EdgeInsets.all(0.0),
                    onPressed: () {
                      if (widget.onSave != null) {
                        widget.onSave();
                      }
                    },
                    child: Text("SAVE"),
                  ),
                ),
              ],
            ),
          ),
          Divider(
            height: 12.0,
            color: Colors.black45,
          ),
        ],
      ),
    );
  }
}
