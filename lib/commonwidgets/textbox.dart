import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class SimpleTextBox extends StatelessWidget {
  final String labelText;
  final bool obscureText;
  final Widget prefixIcon;
  final Widget suffixIcon;
  final TextStyle labelStyle;
  final bool alwaysShowPlaceholder;
  final TextInputType keyboardType;
  final FormFieldSetter<String> onSaved;
  final TextEditingController controller;
  final FormFieldValidator<String> validator;

  SimpleTextBox({
    this.onSaved,
    this.labelText,
    this.validator,
    this.prefixIcon,
    this.suffixIcon,
    this.controller,
    this.labelStyle,
    this.keyboardType,
    this.obscureText = false,
    this.alwaysShowPlaceholder = true,
  });

  @override
  Widget build(BuildContext context) {
    final InputBorder enabledBorder = OutlineInputBorder(
      borderSide: BorderSide(
        color: Colors.black54,
      ),
    );

    final InputBorder focusedBorder = OutlineInputBorder(
      borderSide: BorderSide(
        color: Theme.of(context).primaryColor,
      ),
    );

    final InputBorder errorBorder = OutlineInputBorder(
      borderSide: BorderSide(
        color: Theme.of(context).errorColor,
      ),
    );

    return TextFormField(
      onSaved: onSaved,
      validator: validator,
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: labelText,
        suffixIcon: suffixIcon,
        prefixIcon: prefixIcon,
        labelStyle: labelStyle,
        filled: true,
        fillColor: Colors.white70,
        errorBorder: errorBorder,
        focusedBorder: focusedBorder,
        enabledBorder: enabledBorder,
        hasFloatingPlaceholder: alwaysShowPlaceholder,
        focusedErrorBorder: errorBorder,
        contentPadding: EdgeInsets.all(12.0),
      ),
    );
  }
}
