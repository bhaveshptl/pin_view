import 'package:flutter/material.dart';

class AddCashButton extends StatelessWidget {
  final String text;
  final Function onPressed;
  AddCashButton({@required this.text, @required this.onPressed});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(right: 8.0),
      child: FlatButton(
        padding: EdgeInsets.all(0.0),
        child: Container(
          decoration: BoxDecoration(
            color: Color.fromRGBO(61, 155, 1, 1),
            borderRadius: BorderRadius.circular(4.0),
          ),
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(
                width: 2.0,
                color: Color.fromRGBO(33, 213, 9, 1),
              ),
              borderRadius: BorderRadius.circular(4.0),
            ),
            child: Row(
              children: <Widget>[
                Container(
                  padding: EdgeInsets.all(8.0),
                  decoration: BoxDecoration(
                    color: Color.fromRGBO(61, 99, 37, 1),
                    borderRadius: BorderRadius.circular(4.0),
                  ),
                  child: Text(
                    text,
                    style: Theme.of(context).primaryTextTheme.subhead.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                Icon(
                  Icons.add,
                  color: Colors.white,
                )
              ],
            ),
          ),
        ),
        onPressed: () {
          onPressed();
        },
      ),
    );
  }
}
