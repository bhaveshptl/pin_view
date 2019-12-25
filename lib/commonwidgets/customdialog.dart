import 'package:flutter/material.dart';

class CustomDialog extends StatelessWidget {
  final Dialog dialog;
  final EdgeInsets padding;

  CustomDialog({this.dialog, @required this.padding});

  @override
  Widget build(BuildContext context) {
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(
          viewInsets: MediaQuery.of(context).viewInsets +
              (EdgeInsets.symmetric(horizontal: -40.0, vertical: -24.0)) +
              padding),
      child: dialog,
    );
  }
}
