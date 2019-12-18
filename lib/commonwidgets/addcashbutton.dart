import 'package:flutter/material.dart';
import 'package:playfantasy/appconfig.dart';
import 'package:playfantasy/commonwidgets/currencytext.dart';
import 'package:playfantasy/commonwidgets/routelauncher.dart';
import 'package:playfantasy/redux/actions/loader_actions.dart';

class AddCashButton extends StatelessWidget {
  final double amount;
  final bool showPlus;
  final String location;
  final Function onPressed;
  AddCashButton({
    this.onPressed,
    @required this.amount,
    @required this.location,
    this.showPlus = true,
  });

  _launchAddCash(BuildContext context,
      {String source, String promoCode, double prefilledAmount}) async {
    showLoader(context, true);
    routeLauncher.launchAddCash(
      context,
      source: source,
      promoCode: promoCode,
      prefilledAmount: prefilledAmount,
      onComplete: () {
        showLoader(context, false);
      },
    );
  }

  showLoader(BuildContext context, bool bShow) {
    AppConfig.of(context)
        .store
        .dispatch(bShow ? LoaderShowAction() : LoaderHideAction());
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 36.0,
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
                  constraints: BoxConstraints(
                    minWidth: 80.0,
                  ),
                  decoration: BoxDecoration(
                    color: Color.fromRGBO(61, 99, 37, 1),
                    borderRadius: BorderRadius.circular(4.0),
                  ),
                  child: Center(
                    child: CurrencyText(
                      amount: amount,
                      isChips: false,
                      style:
                          Theme.of(context).primaryTextTheme.subhead.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                    ),
                  ),
                ),
                showPlus
                    ? Icon(
                        Icons.add,
                        color: Colors.white,
                      )
                    : Container()
              ],
            ),
          ),
        ),
        onPressed: () {
          if (onPressed == null) {
            _launchAddCash(context);
          } else {
            onPressed();
          }
        },
      ),
    );
  }
}
