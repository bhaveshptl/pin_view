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
  bool bShowBonusDistribution = true;

  Map<int, String> mapMonths = {
    1: "Jan",
    2: "Feb",
    3: "Mar",
    4: "Apr",
    5: "May",
    6: "Jun",
    7: "Jul",
    8: "Aug",
    9: "Sep",
    10: "Oct",
    11: "Nov",
    12: "Dec"
  };

  @override
  void initState() {
    super.initState();
    if (widget.selectedPromo == null && widget.amount > 0) {
      var promoCodeToSelect;
      double selectedPromoBonus = 0;
      widget.promoCodes.forEach((promo) {
        double bonusAmount = getBonusAmountForPromo(promo);
        if (bonusAmount > 0 && bonusAmount > selectedPromoBonus) {
          promoCodeToSelect = promo;
          selectedPromoBonus = bonusAmount;
        }
      });
      selectedPromo = promoCodeToSelect;
    } else {
      selectedPromo = widget.selectedPromo;
    }
    if (selectedPromo != null) {
      setBonusAmount();
    }
  }

  getBonusAmountForPromo(promoCode) {
    double customAmountBonus = widget.amount * promoCode["percentage"] / 100;

    if (promoCode == null || widget.amount < promoCode["minimum"]) {
      customAmountBonus = 0.0;
    } else if (customAmountBonus > promoCode["maximum"]) {
      customAmountBonus = (promoCode["maximum"]).toDouble();
    }
    return customAmountBonus;
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
    int totalWagerAmount = getTotalWagerAmount();
    int wagerReleaseAmount = getWagerReleaseAmount();
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 8.0),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 8.0),
              child: Column(
                children: <Widget>[
                  selectedPromo["percentage"] == 0
                      ? Container()
                      : Container(
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
                                child: Text(
                                  "Total Benefits",
                                  style: Theme.of(context)
                                      .primaryTextTheme
                                      .body1
                                      .copyWith(
                                        color: Colors.black,
                                      ),
                                ),
                              ),
                              Expanded(
                                child: Row(
                                  children: <Widget>[
                                    Text(
                                      selectedPromo["percentage"].toString() +
                                          "%",
                                      style: Theme.of(context)
                                          .primaryTextTheme
                                          .body1
                                          .copyWith(
                                            color: Colors.black,
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                  ],
                                ),
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
                          child: Text(
                            "Min deposit",
                            style: Theme.of(context)
                                .primaryTextTheme
                                .body1
                                .copyWith(
                                  color: Colors.black,
                                ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            strings.rupee + selectedPromo["minimum"].toString(),
                            style: Theme.of(context)
                                .primaryTextTheme
                                .body1
                                .copyWith(
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
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
                          child: Text(
                            "Max Benefits",
                            style: Theme.of(context)
                                .primaryTextTheme
                                .body1
                                .copyWith(
                                  color: Colors.black,
                                ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            strings.rupee + selectedPromo["maximum"].toString(),
                            style: Theme.of(context)
                                .primaryTextTheme
                                .body1
                                .copyWith(
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  selectedPromo["playablePercentage"] == 0
                      ? Container()
                      : Container(
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
                                child: Text(
                                  "Playable Bonus",
                                  style: Theme.of(context)
                                      .primaryTextTheme
                                      .body1
                                      .copyWith(
                                        color: Colors.black,
                                      ),
                                ),
                              ),
                              Expanded(
                                child: Row(
                                  children: <Widget>[
                                    Text(
                                      selectedPromo["playablePercentage"]
                                              .toString() +
                                          "%",
                                      style: Theme.of(context)
                                          .primaryTextTheme
                                          .body1
                                          .copyWith(
                                            color: Colors.black,
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                  selectedPromo["nonPlayablePercentage"] == 0
                      ? Container()
                      : Container(
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
                                child: Text(
                                  "Locked Bonus",
                                  style: Theme.of(context)
                                      .primaryTextTheme
                                      .body1
                                      .copyWith(
                                        color: Colors.black,
                                      ),
                                ),
                              ),
                              Expanded(
                                child: Row(
                                  children: <Widget>[
                                    Text(
                                      selectedPromo["nonPlayablePercentage"]
                                              .toString() +
                                          "%",
                                      style: Theme.of(context)
                                          .primaryTextTheme
                                          .body1
                                          .copyWith(
                                            color: Colors.black,
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                  selectedPromo["instantCashPercentage"] == 0
                      ? Container()
                      : Container(
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
                                child: Text(
                                  "Instant Cash",
                                  style: Theme.of(context)
                                      .primaryTextTheme
                                      .body1
                                      .copyWith(
                                        color: Colors.black,
                                      ),
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  selectedPromo["instantCashPercentage"]
                                          .toString() +
                                      "%",
                                  style: Theme.of(context)
                                      .primaryTextTheme
                                      .body1
                                      .copyWith(
                                        color: Colors.black,
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                              ),
                            ],
                          ),
                        ),
                  bonusAmount == 0 ||
                          !(totalWagerAmount > 0 && wagerReleaseAmount > 0)
                      ? Container()
                      : Container(
                          padding: EdgeInsets.symmetric(
                            vertical: 8.0,
                          ),
                          child: Row(
                            children: <Widget>[
                              Expanded(
                                child: Text(
                                  "Each time you play for ${strings.rupee}${totalWagerAmount.toString()} you get ${strings.rupee}${wagerReleaseAmount.toString()} to playable bonus from locked bonus",
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
      ),
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

  getPromoExpiry(promoCode) {
    DateTime _date = DateTime.fromMillisecondsSinceEpoch(promoCode["endDate"]);
    return _date.day.toString() + mapMonths[_date.month];
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
                        "Apply Promocode",
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
              bool bPromoSelected = selectedPromo == null ||
                  selectedPromo["promoCode"] != promoCode["promoCode"];
              return Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0),
                child: InkWell(
                  onTap: () {
                    onSelectPromo(promoCode);
                  },
                  child: DottedBorder(
                    padding: EdgeInsets.fromLTRB(0.0, 8.0, 8.0, 8.0),
                    color:
                        !bPromoSelected ? Colors.green : Colors.grey.shade300,
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
                                  width: 32.0,
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
                                              ? Colors.grey.shade300
                                              : Color.fromRGBO(70, 165, 12, 1),
                                          width: 1.0,
                                        ),
                                      ),
                                      padding: EdgeInsets.all(2.0),
                                      child: bPromoSelected
                                          ? CircleAvatar(
                                              radius: 6.0,
                                              backgroundColor:
                                                  Colors.grey.shade300,
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
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    Text(
                                      promoCode["promoCode"],
                                      style: TextStyle(
                                        color: bPromoSelected
                                            ? Colors.black
                                            : Color.fromRGBO(70, 165, 12, 1),
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Padding(
                                      padding: EdgeInsets.only(top: 4.0),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.start,
                                        children: <Widget>[
                                          Text(
                                            "Valid till ${getPromoExpiry(promoCode)}",
                                            style: TextStyle(
                                              color: bPromoSelected
                                                  ? Colors.black
                                                  : Color.fromRGBO(
                                                      70, 165, 12, 1),
                                              fontSize: Theme.of(context)
                                                  .primaryTextTheme
                                                  .caption
                                                  .fontSize,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                )
                              ],
                            ),
                            bShowBonusDistribution
                                ? Icon(
                                    bPromoSelected
                                        ? Icons.expand_more
                                        : Icons.expand_less,
                                    color: !bPromoSelected
                                        ? Colors.green
                                        : Colors.black,
                                  )
                                : Container(),
                          ],
                        ),
                        bShowBonusDistribution &&
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
