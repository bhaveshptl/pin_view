import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SimpleTextBox extends StatelessWidget {
  final bool enabled;
  final TextStyle style;
  final String hintText;
  final String labelText;
  final bool obscureText;
  final Widget prefixIcon;
  final Widget suffixIcon;
  final Color color;
  final Color borderColor;
  final double borderWidth;
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
  final TextCapitalization textCapitalization;

  SimpleTextBox(
      {this.style,
      this.enabled,
      this.onSaved,
      this.hintText,
      this.focusNode,
      this.labelText,
      this.validator,
      this.prefixIcon,
      this.suffixIcon,
      this.color,
      this.controller,
      this.labelStyle,
      this.borderColor,
      this.borderWidth,
      this.keyboardType,
      this.contentPadding,
      this.inputFormatters,
      this.focusedBorderColor,
      this.obscureText = false,
      this.alwaysShowPlaceholder = true,
      this.textCapitalization});

  @override
  Widget build(BuildContext context) {
    final InputBorder enabledBorder = OutlineInputBorder(
      borderSide: BorderSide(
        color: borderColor != null ? borderColor : Colors.grey.shade400,
        width: borderWidth != null ? borderWidth : 1,
      ),
    );

    final InputBorder disabledBorder = OutlineInputBorder(
      borderSide: BorderSide(
        color: Colors.grey.shade300,
      ),
    );

    final InputBorder focusedBorder = OutlineInputBorder(
      borderSide: BorderSide(
        width: borderWidth != null ? borderWidth : 1,
        color: focusedBorderColor != null
            ? focusedBorderColor
            : Theme.of(context).primaryColor,
      ),
    );

    final InputBorder errorBorder = OutlineInputBorder(
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
      textCapitalization: textCapitalization != null
          ? textCapitalization
          : TextCapitalization.none,
      decoration: InputDecoration(
        filled: true,
        hintText: hintText,
        labelText: labelText,
        suffixIcon: suffixIcon,
        prefixIcon: prefixIcon,
        labelStyle: labelStyle,
        errorBorder: errorBorder,
        fillColor: color != null ? color : Colors.white70,
        focusedBorder: focusedBorder,
        enabledBorder: enabledBorder,
        contentPadding: contentPadding == null
            ? EdgeInsets.symmetric(horizontal: 12.0, vertical: 12.0)
            : contentPadding,
        disabledBorder: disabledBorder,
        hasFloatingPlaceholder: alwaysShowPlaceholder,
        focusedErrorBorder: errorBorder,
      ),
    );
  }
}
