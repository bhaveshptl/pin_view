import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class CurrencyText extends StatelessWidget {
  final bool isChips;
  final double amount;
  final TextStyle style;
  final int decimalDigits;
  CurrencyText({
    @required this.amount,
    this.style,
    this.isChips = false,
    this.decimalDigits = 2,
  });

  @override
  Widget build(BuildContext context) {
    final formatCurrency = NumberFormat.currency(
      locale: "hi_IN",
      symbol: isChips ? "" : "₹",
      decimalDigits: decimalDigits,
    );

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        isChips
            ? Image.asset(
                "images/chips.png",
                width: 16.0,
                height: 12.0,
                fit: BoxFit.contain,
              )
            : Container(),
        Text(
          formatCurrency.format(amount),
          style: style,
        )
      ],
    );
  }
}
