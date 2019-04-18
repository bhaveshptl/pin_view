import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SimpleTextBox extends StatelessWidget {
  final bool enabled;
  final String hintText;
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
  final List<TextInputFormatter> inputFormatters;

  SimpleTextBox({
    this.enabled,
    this.onSaved,
    this.hintText,
    this.labelText,
    this.validator,
    this.prefixIcon,
    this.suffixIcon,
    this.controller,
    this.labelStyle,
    this.keyboardType,
    this.inputFormatters,
    this.obscureText = false,
    this.alwaysShowPlaceholder = true,
  });

  @override
  Widget build(BuildContext context) {
    final InputBorder enabledBorder = OutlineInputBorder(
      borderSide: BorderSide(
        color: Colors.grey.shade400,
      ),
    );

    final InputBorder disabledBorder = OutlineInputBorder(
      borderSide: BorderSide(
        color: Colors.grey.shade300,
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
      enabled: enabled,
      onSaved: onSaved,
      validator: validator,
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      decoration: InputDecoration(
        filled: true,
        hintText: hintText,
        labelText: labelText,
        suffixIcon: suffixIcon,
        prefixIcon: prefixIcon,
        labelStyle: labelStyle,
        fillColor: Colors.white70,
        errorBorder: errorBorder,
        focusedBorder: focusedBorder,
        enabledBorder: enabledBorder,
        disabledBorder: disabledBorder,
        hasFloatingPlaceholder: alwaysShowPlaceholder,
        focusedErrorBorder: errorBorder,
      ),
    );
  }
}
