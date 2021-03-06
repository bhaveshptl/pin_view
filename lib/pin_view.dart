library pin_view;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sms/sms.dart';

class SmsListener {
  final Pattern from;
  final Function formatBody;

  SmsListener({@required this.from, this.formatBody});
}

class PinView extends StatefulWidget {
  final Function submit;
  final Function(String) onChange;
  final int count;
  final bool obscureText;
  final bool autoFocusFirstField;
  final bool enabled;
  final List<int> dashPositions;
  final SmsListener sms;
  final TextStyle style;
  final TextStyle dashStyle;
  final InputDecoration inputDecoration;
  final EdgeInsetsGeometry margin;
  final Widget title;

  PinView({
    @required this.submit,
    @required this.count,
    this.onChange,
    this.obscureText: false,
    this.autoFocusFirstField: true,
    this.enabled: true,
    this.dashPositions: const [],
    this.sms,
    this.dashStyle: const TextStyle(fontSize: 30.0, color: Colors.grey),
    this.style: const TextStyle(
      fontSize: 20.0,
      fontWeight: FontWeight.w500,
    ),
    this.inputDecoration: const InputDecoration(border: UnderlineInputBorder()),
    this.margin: const EdgeInsets.all(5.0),
    this.title,
  });

  @override
  _PinViewState createState() => _PinViewState();
}

class _PinViewState extends State<PinView> {
  List<TextEditingController> _controllers;
  List<FocusNode> _focusNodes;
  List<String> _pin;
  SmsReceiver _smsReceiver;

  @override
  void initState() {
    super.initState();
    if (widget.sms != null) {
      _listenSms();
    }
    _pin = List<String>.generate(widget.count, (int index) => "");
    _focusNodes =
        List.generate(widget.count, (int index) => FocusNode()).toList();
    _controllers =
        List.generate(widget.count, (int index) => TextEditingController());
  }

  void _listenSms() async {
    _smsReceiver = SmsReceiver();
    _smsReceiver.onSmsReceived.listen((SmsMessage message) {
      if (widget.sms.from.allMatches(message.sender).length > 0) {
        String code = widget.sms.formatBody != null
            ? widget.sms.formatBody(message.body)
            : message.body;
        for (TextEditingController controller in _controllers) {
          controller.text = code[_controllers.indexOf(controller)];
          _pin[_controllers.indexOf(controller)] = controller.text;
        }
        FocusScope.of(context).requestFocus(_focusNodes[_pin.length - 1]);

        if (widget.onChange != null) {
          widget.onChange(_pin.join());
        }
        widget.submit(_pin.join());
      }
    });
  }

  Widget _dash() {
    return Flexible(flex: 1, child: Text("-", style: widget.dashStyle));
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> pins = List<Widget>.generate(
        widget.count, (int index) => _singlePinView(index)).toList();

    for (int i in widget.dashPositions) {
      if (i <= widget.count) {
        List<int> smaller =
            widget.dashPositions.where((int d) => d < i).toList();
        pins.insert(i + smaller.length, _dash());
      }
    }

    return Column(
      children: <Widget>[
        widget.title == null ? Container() : widget.title,
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: pins,
        ),
      ],
    );
  }

  Widget _singlePinView(int index) {
    return Flexible(
      flex: 3,
      child: Container(
        margin: widget.margin,
        child: TextField(
          enabled: widget.enabled,
          controller: _controllers[index],
          obscureText: widget.obscureText,
          autofocus: widget.autoFocusFirstField ? index == 0 : false,
          focusNode: _focusNodes[index],
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          style: widget.style,
          inputFormatters: [
            LengthLimitingTextInputFormatter(
              index == widget.count - 1 ? 1 : 2,
            ),
          ],
          decoration: widget.inputDecoration,
          textInputAction: TextInputAction.next,
          onChanged: (String val) {
            if (val.length == 1) {
              _pin[index] = val;
              if (index != _focusNodes.length - 1) {
                _focusNodes[index].unfocus();
                FocusScope.of(context).requestFocus(_focusNodes[index + 1]);
              }
            } else if (val.length == 2) {
              _controllers[index].text = val.substring(0, 1);
              _pin[index] = val.substring(0, 1);
              if ((index + 1) < _controllers.length) {
                _controllers[index + 1].text = "";
                _controllers[index + 1].text = val.substring(1);
                _pin[index + 1] = val.substring(1);
                FocusScope.of(context).requestFocus(_focusNodes[index + 1]);
              } else {
                _controllers[index].selection = TextSelection.fromPosition(
                    TextPosition(offset: _controllers[index].text.length));
              }
            } else if (val.length > 2) {
              int endIndex =
                  val.length >= widget.count ? widget.count : val.length;
              int focusIndex =
                  endIndex == widget.count ? endIndex - 1 : endIndex;

              for (int i = 0; i < widget.count; i++) {
                if (i >= endIndex) {
                  _controllers[i].text = "";
                  _pin[i] = "";
                } else {
                  String character = val.substring(i, i + 1);
                  _controllers[i].text = character;
                  _pin[i] = character;
                }
              }

              FocusScope.of(context).requestFocus(_focusNodes[focusIndex]);
            } else {
              _pin[index] = "";
              if (index != 0) {
                _focusNodes[index].unfocus();
                FocusScope.of(context).requestFocus(_focusNodes[index - 1]);
              }
            }

            if (widget.onChange != null) {
              widget.onChange(_pin.join());
            }

            if (_pin.indexOf("") == -1) {
              widget.submit(_pin.join());
            }
          },
        ),
      ),
    );
  }
}
