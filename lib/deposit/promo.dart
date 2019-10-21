import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:playfantasy/commonwidgets/textbox.dart';
import 'package:playfantasy/modal/analytics.dart';
import 'package:playfantasy/redux/actions/loader_actions.dart';
import 'package:playfantasy/utils/analytics.dart';
import 'package:playfantasy/utils/stringtable.dart';

import '../appconfig.dart';

class PromoInput extends StatefulWidget {
  final int amount;
  final bool isFirstDeposit;
  final dynamic selectedPromo;
  final List<dynamic> promoCodes;
  PromoInput(
      {this.promoCodes, this.amount, this.isFirstDeposit, this.selectedPromo});

  @override
  _PromoStateInput createState() => _PromoStateInput();
}

class _PromoStateInput extends State<PromoInput> {
  dynamic selectedPromo;
  double bonusAmount = 0.0;
  bool bShowBonusDistribution = true;
  
  TextEditingController promoController = TextEditingController();

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
    Event event = Event(name: "have_promo_code");
    event.setDepositAmount(widget.amount);
    event.setFirstDeposit(widget.isFirstDeposit);
    event.setPromoCode(selectedPromo == null ? "" : selectedPromo["promoCode"]);

    AnalyticsManager().addEvent(event);

    promoController.addListener(() {
      setState(() {});
    });
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
    Event event = Event(name: "select_promo_code");
    event.setDepositAmount(widget.amount);
    event.setFirstDeposit(widget.isFirstDeposit);
    event.setPromoCode(selectedPromo == null ? "" : selectedPromo["promoCode"]);

    AnalyticsManager().addEvent(event);
  }

  getPromoExpiry(promoCode) {
    DateTime _date = DateTime.fromMillisecondsSinceEpoch(promoCode["endDate"]);
    return _date.day.toString() + mapMonths[_date.month];
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Container(
        width: MediaQuery.of(context).size.width,
        //width: 200,
        padding: EdgeInsets.all(8),
        color: Colors.grey.shade300,
        child:
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Text("Promos & Offers".toUpperCase(),),
                getRemoveButton(),
              ],
            ),
          ),
      ),
      titlePadding: EdgeInsets.all(0),
      titleTextStyle: TextStyle(
        color: Colors.grey.shade800,
        fontSize: Theme.of(context).primaryTextTheme.title.fontSize,
        fontWeight: FontWeight.bold,
      ),
      elevation: 3.0,
      content: getPromoUIV4(),
      //content: Container(width: 200, child: getPromoUIV4()),
      contentPadding: EdgeInsets.all(8),
      actions: <Widget>[],

    );
  }

  getPromoUIV3() {
    List<Widget> rows = [];
    List<Widget> promoTiles = [];
    int i = 0;
    Widget row;
  
    row = getEnterPromoTextRow();
    rows.add(row);

    widget.promoCodes.forEach((promoCode) {
      promoTiles.add(getPromoCodeTileV3(promoCode));

      if(i % 2 == 1) {
        
        row = new Row(
          children : promoTiles,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
        );

        rows.add(row);
        promoTiles = [];
      }

      i++;
    });

    if(i % 2 == 1) {

      promoTiles.add(Expanded(child: Container(),));

      row = new Row(
        children : promoTiles,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
      );
      rows.add(row);
    }

    row = getMoreInfoRow();
    rows.add(row);

    Widget scrollView = SingleChildScrollView(
      padding: EdgeInsets.all(0),
      child: Column(children: rows),
    );

    return Container(
      //height: MediaQuery.of(context).size.height - 200,
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height - 200,),
      child: scrollView
    );
  }

  getPromoUIV4() {
    List<Widget> rows = [];
    
    rows.add(getEnterPromoTextRow());

    widget.promoCodes.forEach((promoCode) {
      Row row = Row(
        mainAxisSize: MainAxisSize.max, 
        children: <Widget>[
          getPromoCodeTileV4(promoCode)
        ],
      );
      rows.add(row);
    });

    rows.add(getMoreInfoRow());

    Widget scrollView = SingleChildScrollView(
      padding: EdgeInsets.all(0),
      child: Column(
        children: rows,
      ),
    );

    return Container(
      //height: MediaQuery.of(context).size.height - 200,
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height - 200,),
      child: scrollView
    );
  }

  showLoader(bool bShow) {
    AppConfig.of(context)
        .store
        .dispatch(bShow ? LoaderShowAction() : LoaderHideAction());
  }

  getMoreInfoRow() {
    return FlatButton(
      onPressed: () {
        Navigator.of(context).pop("OpenMoreInfo");
      },
      child: Container(
        margin: EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: Theme.of(context).primaryColor, ))
        ),
        child: Text("click here for more info",
          style: TextStyle(
            fontStyle: FontStyle.italic,
            color: Theme.of(context).primaryColor,
          ),
        ),
      ),
    );
  }

  getEnterPromoTextRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        
        Expanded(
          
          child: Container(
            padding: EdgeInsets.all(4),
            margin: EdgeInsets.all(8),
            child: SimpleTextBox(
              hintText: "Enter promo".toUpperCase(),
              labelText: "Enter promo".toUpperCase(),
              controller: promoController,
              
            ),
          ),
        ),

        Container(
          margin: EdgeInsets.symmetric(horizontal: 8),
          child: FlatButton(
            textColor: Colors.white,
            disabledTextColor: Colors.grey.shade500,
            color: Colors.green,
            disabledColor: Colors.grey.shade100,
            child:  Text("Apply".toUpperCase(), style: TextStyle(fontWeight: FontWeight.bold),),
            onPressed: promoController.text != "" 
            ? () {
                Navigator.of(context).pop(promoController.text);
            }
            : null,
          ),
        ),
      ],
    );
  }

  getPromoCodeTileV3(promoCode) {
   
    return Expanded(
        //width: 150,
        child: Card(
          elevation: 3.0,
          margin: EdgeInsets.all(8),
          child: InkWell(
            onTap: () {
              Navigator.of(context).pop(promoCode["promoCode"]);
            },
            child: Padding(
              padding: EdgeInsets.all(8),
              child: 
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[

                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: <Widget>[
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Text(promoCode["promoCode"], 
                            textAlign: TextAlign.left,
                            style: TextStyle(
                              color: Colors.grey.shade700,
                              fontWeight: FontWeight.bold,
                              fontSize: Theme.of(context)
                                  .primaryTextTheme
                                  .title
                                  .fontSize
                            ), 
                          ),
                        ),
                      ],
                    ),

                    Text(promoCode["percentage"].toString() + "% Extra", 
                      textAlign: TextAlign.left,
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontStyle: FontStyle.italic,
                        fontSize: Theme.of(context)
                            .primaryTextTheme
                            .subhead
                            .fontSize
                      ), 
                    ),

                    Align(
                      alignment: Alignment.centerLeft,
                      child: Padding(
                        padding: EdgeInsets.all(4), 
                        child: Text("Min Deposit " + strings.rupee + promoCode["minimum"].toString(),
                          style: TextStyle(color: Colors.grey.shade700),
                          textAlign: TextAlign.start,
                        )
                      ), 
                    ),

                    Align(
                      alignment: Alignment.centerRight,
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.green), 
                          borderRadius: BorderRadius.circular(2.0),
                        ),

                        child: Padding(
                          padding: const EdgeInsets.all(4.0),
                          child: Text("Apply Now",
                            style: TextStyle(color: Colors.green),
                            textAlign: TextAlign.start,
                          ),
                        ),
                      ), 
                    ),

                  ],
                )
                
            ),
          ),
        )
      );
  }

  getPromoCodeTileV4(promoCode) {
   
    return Expanded(
      child: Container(
          height: 110,
          child: Card(
            elevation: 3.0,
            margin: EdgeInsets.all(12),
            child: InkWell(
              onTap: () {
                Navigator.of(context).pop(promoCode["promoCode"]);
              },
              child: Container(
                width: 200,
                padding: EdgeInsets.all(8),
                child: 

                  Row(
                    children: <Widget>[
                      Expanded(
                        flex: 7, 
                        child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[

                          Row(
                            children: <Widget>[
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4),
                                child: Text(promoCode["promoCode"], 
                                  style: TextStyle(
                                    color: Colors.grey.shade700,
                                    fontWeight: FontWeight.bold,
                                    fontSize: Theme.of(context)
                                        .primaryTextTheme
                                        .title
                                        .fontSize
                                  ), 
                                ),
                              ),
                            ],
                          ),

                          
                          Container(
                            margin: EdgeInsets.only(top: 4),
                            child: Text(promoCode["percentage"].toString() + "% Extra", 
                              style: TextStyle(
                                color: Colors.grey.shade700,
                                fontStyle: FontStyle.italic,
                                fontSize: Theme.of(context)
                                    .primaryTextTheme
                                    .subhead
                                    .fontSize
                              ), 
                            ),
                          ),

                          Container(
                            margin: EdgeInsets.only(top: 4),
                            child: Text("Min Deposit " + strings.rupee + promoCode["minimum"].toString(),
                              style: TextStyle(color: Colors.grey.shade700),
                            ),
                          ),

                        ],
                      ),),
                      
                      Expanded(
                        flex: 4, 
                        child: Align(
                          alignment: Alignment.center,
                          child: Container(
                            padding: EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                            color: Colors.green,
                            child: Text("APPLY", 
                              style: TextStyle(
                                fontSize: Theme.of(context).primaryTextTheme.subhead.fontSize,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  )
                  
              ),
            ),
          )
        ),
    );
  }


  Widget getRemoveButton() {

    return InkWell(
      onTap: () {
        Navigator.of(context).pop();
      },
      child: Container(
         decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            width: 1.0,
            color: Theme.of(context).primaryColor,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(4.0),
          child: Icon(Icons.close, 
            size: Theme.of(context).primaryTextTheme.subhead.fontSize,
            color: Theme.of(context).primaryColor,
          ),
        ),
      ),
    );
  }

}

