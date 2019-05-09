import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class UnderlineTextBox extends StatelessWidget {
  final bool enabled;
  final TextStyle style;
  final String hintText;
  final String labelText;
  final bool obscureText;
  final Widget prefixIcon;
  final Widget suffixIcon;
  final Color borderColor;
  final FocusNode focusNode;
  final TextStyle labelStyle;
  final Color focusedBorderColor;
  final bool alwaysShowPlaceholder;
  final TextInputType keyboardType;
  final FormFieldSetter<String> onSaved;
  final TextEditingController controller;
  final EdgeInsetsGeometry contentPadding;
  final FormFieldValidator<String> validator;
  final List<TextInputFormatter> inputFormatters;

  UnderlineTextBox({
    this.style,
    this.enabled,
    this.onSaved,
    this.hintText,
    this.focusNode,
    this.labelText,
    this.validator,
    this.prefixIcon,
    this.suffixIcon,
    this.controller,
    this.labelStyle,
    this.borderColor,
    this.keyboardType,
    this.contentPadding,
    this.inputFormatters,
    this.focusedBorderColor,
    this.obscureText = false,
    this.alwaysShowPlaceholder = true,
  });

  @override
  Widget build(BuildContext context) {
    final InputBorder enabledBorder = UnderlineInputBorder(
      borderSide: BorderSide(
        color: borderColor != null ? borderColor : Colors.grey.shade400,
      ),
    );

    final InputBorder disabledBorder = UnderlineInputBorder(
      borderSide: BorderSide(
        color: Colors.grey.shade300,
      ),
    );

    final InputBorder focusedBorder = UnderlineInputBorder(
      borderSide: BorderSide(
        color: focusedBorderColor != null
            ? focusedBorderColor
            : Theme.of(context).primaryColor,
      ),
    );

    final InputBorder errorBorder = UnderlineInputBorder(
      borderSide: BorderSide(
        color: Theme.of(context).errorColor,
      ),
    );

    return TextFormField(
      style: style,
      enabled: enabled,
      onSaved: onSaved,
      focusNode: focusNode,
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
        errorBorder: errorBorder,
        fillColor: Colors.white70,
        focusedBorder: focusedBorder,
        enabledBorder: enabledBorder,
        contentPadding: contentPadding,
        disabledBorder: disabledBorder,
        hasFloatingPlaceholder: alwaysShowPlaceholder,
        focusedErrorBorder: errorBorder,
      ),
    );
  }
}