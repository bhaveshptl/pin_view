import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:playfantasy/commonwidgets/color_button.dart';
import 'package:playfantasy/utils/stringtable.dart';

class PromoInput extends StatefulWidget {
  final int amount;
  final dynamic selectedPromo;
  final List<dynamic> promoCodes;
  PromoInput({this.promoCodes, this.amount, this.selectedPromo});

  @override
  _PromoStateInput createState() => _PromoStateInput();
}

class _PromoStateInput extends State<PromoInput> {
  dynamic selectedPromo;
  double bonusAmount = 0.0;

  @override
  void initState() {
    super.initState();
    selectedPromo = widget.selectedPromo;
  }

  setBonusAmount() {
    double customAmountBonus =
        widget.amount * selectedPromo["percentage"] / 100;

    if (selectedPromo == null || widget.amount < selectedPromo["minimum"]) {
      customAmountBonus = 0.0;
    } else if (customAmountBonus > selectedPromo["maximum"]) {
      customAmountBonus = (selectedPromo["maximum"]).toDouble();
    }
    bonusAmount = customAmountBonus;
  }

  int getTotalWagerAmount() {
    return ((bonusAmount * selectedPromo["nonPlayablePercentage"]) /
            (selectedPromo['wagerPercentage'] * selectedPromo["chunks"]))
        .floor();
  }

  int getWagerReleaseAmount() {
    return ((bonusAmount * (selectedPromo["nonPlayablePercentage"] / 100)) /
            selectedPromo["chunks"])
        .floor();
  }

  Widget getBonusDistribution() {
    return Row(
      children: <Widget>[
        Expanded(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 8.0),
            child: Column(
              children: <Widget>[
                Container(
                  padding: EdgeInsets.symmetric(
                    vertical: 8.0,
                  ),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: Colors.grey.shade300,
                      ),
                    ),
                  ),
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        child: Text("Min deposit"),
                      ),
                      Expanded(
                        child: Text(strings.rupee +
                            selectedPromo["minimum"].toString()),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(
                    vertical: 8.0,
                  ),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: Colors.grey.shade300,
                      ),
                    ),
                  ),
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        child: Text("Bonus Amount"),
                      ),
                      Expanded(
                        child: Text(
                            selectedPromo["playablePercentage"].toString() +
                                "%"),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(
                    vertical: 8.0,
                  ),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: Colors.grey.shade300,
                      ),
                    ),
                  ),
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        child: Text("Locked Bonus"),
                      ),
                      Expanded(
                        child: Text(
                            selectedPromo["nonPlayablePercentage"].toString() +
                                "%"),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(
                    vertical: 8.0,
                  ),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: Colors.grey.shade300,
                      ),
                    ),
                  ),
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        child: Text("Instant Cash"),
                      ),
                      Expanded(
                        child: Text(
                            selectedPromo["instantCashPercentage"].toString() +
                                "%"),
                      ),
                    ],
                  ),
                ),
                bonusAmount == 0
                    ? Container()
                    : Container(
                        padding: EdgeInsets.symmetric(
                          vertical: 8.0,
                        ),
                        child: Row(
                          children: <Widget>[
                            Expanded(
                              child: Text(
                                "Each time you play for ${strings.rupee}${getTotalWagerAmount()} you get ${strings.rupee}${getWagerReleaseAmount()} to playable bonus from locked bonus",
                                style: Theme.of(context)
                                    .primaryTextTheme
                                    .caption
                                    .copyWith(
                                      color: Colors.black,
                                    ),
                              ),
                            ),
                          ],
                        ),
                      )
              ],
            ),
          ),
        )
      ],
    );
  }

  onSelectPromo(promoCode) {
    if (selectedPromo == null ||
        selectedPromo["promoCode"] != promoCode["promoCode"]) {
      setState(() {
        selectedPromo = promoCode;
        setBonusAmount();
      });
    } else {
      setState(() {
        selectedPromo = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(4.0),
      ),
      titlePadding: EdgeInsets.symmetric(horizontal: 0.0),
      title: Container(
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
          ],
        ),
      ),
      contentPadding: EdgeInsets.all(0.0),
      content: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            children: widget.promoCodes.map((promoCode) {
              return Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0),
                child: InkWell(
                  onTap: () {
                    onSelectPromo(promoCode);
                  },
                  child: DottedBorder(
                    color: Colors.green,
                    child: Column(
                      children: <Widget>[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: <Widget>[
                            Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: <Widget>[
                                Container(
                                  height: 40.0,
                                  width: 40.0,
                                  child: FlatButton(
                                    onPressed: () {
                                      onSelectPromo(promoCode);
                                    },
                                    padding: EdgeInsets.all(0.0),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: (selectedPromo == null ||
                                                  selectedPromo["promoCode"] !=
                                                      promoCode["promoCode"])
                                              ? Colors.black
                                              : Color.fromRGBO(70, 165, 12, 1),
                                          width: 1.0,
                                        ),
                                      ),
                                      padding: EdgeInsets.all(2.0),
                                      child: (selectedPromo == null ||
                                              selectedPromo["promoCode"] !=
                                                  promoCode["promoCode"])
                                          ? CircleAvatar(
                                              radius: 6.0,
                                              backgroundColor:
                                                  Colors.transparent,
                                            )
                                          : CircleAvatar(
                                              radius: 6.0,
                                              backgroundColor: Colors.white,
                                              child: CircleAvatar(
                                                radius: 6.0,
                                                backgroundColor: Color.fromRGBO(
                                                    70, 165, 12, 1),
                                              ),
                                            ),
                                    ),
                                  ),
                                ),
                                Text(
                                  promoCode["promoCode"],
                                )
                              ],
                            ),
                            Icon(
                              Icons.expand_more,
                              color: Colors.green,
                            ),
                          ],
                        ),
                        selectedPromo != null &&
                                selectedPromo["promoCode"] ==
                                    promoCode["promoCode"]
                            ? getBonusDistribution()
                            : Container()
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
      actions: <Widget>[
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.max,
          children: <Widget>[
            Container(
              height: 40.0,
              width: MediaQuery.of(context).size.width - 96.0,
              child: ColorButton(
                child: Text(
                  "APPLY",
                  style: Theme.of(context).primaryTextTheme.title.copyWith(
                        color: Colors.white,
                      ),
                ),
                onPressed: selectedPromo == null
                    ? null
                    : () {
                        Navigator.of(context).pop(selectedPromo);
                      },
              ),
            )
          ],
        )
      ],
    );
  }
}
