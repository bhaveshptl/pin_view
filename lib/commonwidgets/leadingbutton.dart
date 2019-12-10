import 'package:flutter/material.dart';

class LeadingButton extends StatelessWidget {
  final bool isSinglePage;
  LeadingButton({this.isSinglePage = true});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Image.asset(
        isSinglePage ? "images/arrow.png" : "images/arrow2.png",
        height: 18.0,
      ),
      onPressed: () {
        Navigator.of(context).pop();
      },
    );
  }
}
