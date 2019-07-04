import 'package:flutter/material.dart';

class PromoInput extends StatefulWidget {
  final List<Map<String, dynamic>> promoCodes;
  PromoInput(this.promoCodes);

  @override
  _PromoStateInput createState() => _PromoStateInput();
}

class _PromoStateInput extends State<PromoInput> {
  @override
  Widget build(BuildContext context) {
    return SimpleDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(4.0),
      ),
      contentPadding: EdgeInsets.all(0.0),
      children: <Widget>[
        Container(
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
                          "Apply Pormocode",
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
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              ),
              Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  children: widget.promoCodes.map((promoCode) {
                    return Container();
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
