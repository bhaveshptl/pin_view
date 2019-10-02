import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:playfantasy/commonwidgets/color_button.dart';
import 'package:playfantasy/commonwidgets/routelauncher.dart';
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

  // @override
  // Widget build(BuildContext context) {
  //   return AlertDialog(
  //     shape: RoundedRectangleBorder(
  //       borderRadius: BorderRadius.circular(4.0),
  //     ),
  //     titlePadding: EdgeInsets.symmetric(horizontal: 0.0),
  //     title: Container(
  //       width: MediaQuery.of(context).size.width,
  //       child: Column(
  //         mainAxisAlignment: MainAxisAlignment.end,
  //         children: <Widget>[
  //           Stack(
  //             alignment: Alignment.centerRight,
  //             children: <Widget>[
  //               Row(
  //                 children: <Widget>[
  //                   Expanded(
  //                     child: Text(
  //                       "Apply Promocode",
  //                       style:
  //                           Theme.of(context).primaryTextTheme.title.copyWith(
  //                                 color: Colors.black,
  //                                 fontWeight: FontWeight.w700,
  //                               ),
  //                       textAlign: TextAlign.center,
  //                     ),
  //                   ),
  //                 ],
  //               ),
  //               InkWell(
  //                 child: Padding(
  //                   padding: EdgeInsets.all(8.0),
  //                   child: Icon(
  //                     Icons.close,
  //                   ),
  //                 ),
  //                 onTap: () {
  //                   Navigator.of(context).pop();
  //                 },
  //               ),
  //             ],
  //           ),
  //         ],
  //       ),
  //     ),
  //     contentPadding: EdgeInsets.all(0.0),
  //     content: SingleChildScrollView(
  //       child: Padding(
  //         padding: EdgeInsets.all(16.0),
  //         child: Column(
  //           children: widget.promoCodes.map((promoCode) {
  //             bool bPromoSelected = selectedPromo == null ||
  //                 selectedPromo["promoCode"] != promoCode["promoCode"];
  //             return Padding(
  //               padding: EdgeInsets.symmetric(vertical: 8.0),
  //               child: InkWell(
  //                 onTap: () {
  //                   onSelectPromo(promoCode);
  //                 },
  //                 child: DottedBorder(
  //                   padding: EdgeInsets.fromLTRB(0.0, 8.0, 8.0, 8.0),
  //                   color:
  //                       !bPromoSelected ? Colors.green : Colors.grey.shade300,
  //                   child: Column(
  //                     children: <Widget>[
  //                       Row(
  //                         mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //                         children: <Widget>[
  //                           Row(
  //                             mainAxisAlignment: MainAxisAlignment.start,
  //                             children: <Widget>[
  //                               Container(
  //                                 height: 40.0,
  //                                 width: 32.0,
  //                                 child: FlatButton(
  //                                   onPressed: () {
  //                                     onSelectPromo(promoCode);
  //                                   },
  //                                   padding: EdgeInsets.all(0.0),
  //                                   child: Container(
  //                                     decoration: BoxDecoration(
  //                                       shape: BoxShape.circle,
  //                                       border: Border.all(
  //                                         color: (selectedPromo == null ||
  //                                                 selectedPromo["promoCode"] !=
  //                                                     promoCode["promoCode"])
  //                                             ? Colors.grey.shade300
  //                                             : Color.fromRGBO(70, 165, 12, 1),
  //                                         width: 1.0,
  //                                       ),
  //                                     ),
  //                                     padding: EdgeInsets.all(2.0),
  //                                     child: bPromoSelected
  //                                         ? CircleAvatar(
  //                                             radius: 6.0,
  //                                             backgroundColor:
  //                                                 Colors.grey.shade300,
  //                                           )
  //                                         : CircleAvatar(
  //                                             radius: 6.0,
  //                                             backgroundColor: Colors.white,
  //                                             child: CircleAvatar(
  //                                               radius: 6.0,
  //                                               backgroundColor: Color.fromRGBO(
  //                                                   70, 165, 12, 1),
  //                                             ),
  //                                           ),
  //                                   ),
  //                                 ),
  //                               ),
  //                               Column(
  //                                 crossAxisAlignment: CrossAxisAlignment.start,
  //                                 children: <Widget>[
  //                                   Text(
  //                                     promoCode["promoCode"],
  //                                     style: TextStyle(
  //                                       color: bPromoSelected
  //                                           ? Colors.black
  //                                           : Color.fromRGBO(70, 165, 12, 1),
  //                                       fontWeight: FontWeight.bold,
  //                                     ),
  //                                   ),
  //                                   Padding(
  //                                     padding: EdgeInsets.only(top: 4.0),
  //                                     child: Row(
  //                                       mainAxisAlignment:
  //                                           MainAxisAlignment.start,
  //                                       children: <Widget>[
  //                                         Text(
  //                                           "Valid till ${getPromoExpiry(promoCode)}",
  //                                           style: TextStyle(
  //                                             color: bPromoSelected
  //                                                 ? Colors.black
  //                                                 : Color.fromRGBO(
  //                                                     70, 165, 12, 1),
  //                                             fontSize: Theme.of(context)
  //                                                 .primaryTextTheme
  //                                                 .caption
  //                                                 .fontSize,
  //                                           ),
  //                                         ),
  //                                       ],
  //                                     ),
  //                                   ),
  //                                 ],
  //                               )
  //                             ],
  //                           ),
  //                           bShowBonusDistribution
  //                               ? Icon(
  //                                   bPromoSelected
  //                                       ? Icons.expand_more
  //                                       : Icons.expand_less,
  //                                   color: !bPromoSelected
  //                                       ? Colors.green
  //                                       : Colors.black,
  //                                 )
  //                               : Container(),
  //                         ],
  //                       ),
  //                       bShowBonusDistribution &&
  //                               selectedPromo != null &&
  //                               selectedPromo["promoCode"] ==
  //                                   promoCode["promoCode"]
  //                           ? getBonusDistribution()
  //                           : Container()
  //                     ],
  //                   ),
  //                 ),
  //               ),
  //             );
  //           }).toList(),
  //         ),
  //       ),
  //     ),
  //     actions: <Widget>[
  //       Row(
  //         mainAxisAlignment: MainAxisAlignment.center,
  //         mainAxisSize: MainAxisSize.max,
  //         children: <Widget>[
  //           Container(
  //             height: 40.0,
  //             width: MediaQuery.of(context).size.width - 96.0,
  //             child: ColorButton(
  //               child: Text(
  //                 "APPLY",
  //                 style: Theme.of(context).primaryTextTheme.title.copyWith(
  //                       color: Colors.white,
  //                     ),
  //               ),
  //               onPressed: selectedPromo == null
  //                   ? null
  //                   : () {
  //                       Event event = Event(name: "apply_promo_code");
  //                       event.setDepositAmount(widget.amount);
  //                       event.setFirstDeposit(widget.isFirstDeposit);
  //                       event.setPromoCode(selectedPromo == null
  //                           ? ""
  //                           : selectedPromo["promoCode"]);

  //                       AnalyticsManager().addEvent(event);
  //                       Navigator.of(context).pop(selectedPromo);
  //                     },
  //             ),
  //           )
  //         ],
  //       )
  //     ],
  //   );
  // }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Container(
        padding: EdgeInsets.all(8),
        color: Colors.grey.shade300,
        child:
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Text("Promos & Offers".toUpperCase(),),
              
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
      ),
      titlePadding: EdgeInsets.all(0),
      titleTextStyle: TextStyle(
        color: Colors.grey.shade800,
        fontSize: Theme.of(context).primaryTextTheme.title.fontSize,
        fontWeight: FontWeight.bold,
      ),
      elevation: 3.0,
      content: getPromoUI(),
      contentPadding: EdgeInsets.all(4),
      actions: <Widget>[],

    );
  }

  getPromoUI() {
    
    List<Widget> rows = [];
    List<Widget> promoTiles = [];
    int i = 0;
    Widget row;
  
    row = getEnterPromoTextRow();
    rows.add(row);

    // widget.promoCodes.forEach((promoCode) {
    //   promoTiles.add(getPromoCodeTile(promoCode, i));

    //   if(i % 2 == 1) {
        
    //     row = new Row(
    //       children : promoTiles,
    //       mainAxisAlignment: MainAxisAlignment.spaceBetween,
    //     );

    //     rows.add(row);
    //     promoTiles = [];
    //   }

    //   i++;
    // });

    // if(i % 2 == 1) {

    //   promoTiles.add(Container(width: 50,));

    //   row = new Row(
    //     children : promoTiles,
    //     mainAxisAlignment: MainAxisAlignment.spaceBetween,
    //   );
    //   rows.add(row);
    // }

    row = getMoreInfoRow();
    rows.add(row);

    Widget scrollView = SingleChildScrollView(
      padding: EdgeInsets.all(0),
      child: Column(children: rows),
    );

    return scrollView;
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

        FlatButton(
          child:  Text("Apply".toUpperCase()),
          onPressed: () {
              Navigator.of(context).pop(promoController.text);
          },
        ),
      ],
    );
  }

  getPromoCodeTile(promoCode, promoPos) {

    bool bPromoSelected = selectedPromo != null &&
      selectedPromo["promoCode"] == promoCode["promoCode"];
   
    return Container(
        child: FlatButton(
          padding: EdgeInsets.all(2),
          child: Card(
            elevation: 3.0,
            child: Padding(
              padding: EdgeInsets.all(8),
              child: 
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[

                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: <Widget>[
                        Text(promoCode["promoCode"], 
                          textAlign: TextAlign.left,
                          style: TextStyle(
                            color: bPromoSelected ? Colors.green : Colors.grey.shade700,
                            fontWeight: FontWeight.bold,
                            fontSize: Theme.of(context)
                                .primaryTextTheme
                                .subhead
                                .fontSize
                          ), 
                        ),
                      ],
                    ),

                    Text("(" + promoCode["percentage"].toString() + "% Extra)", 
                      textAlign: TextAlign.left,
                      style: TextStyle(
                        color: bPromoSelected ? Colors.green : Colors.grey.shade700,
                        fontWeight: FontWeight.bold,
                        fontStyle: FontStyle.italic,
                        fontSize: Theme.of(context)
                            .primaryTextTheme
                            .subhead
                            .fontSize
                      ), 
                    ),

                    //Divider(height: 3, color: Colors.grey.shade900),
                    Container(
                      height: 10,
                      width: 120, 
                      decoration: BoxDecoration(
                        border: Border(bottom: BorderSide(color: Colors.grey.shade300, ))
                      ),
                    ),
                    
                    Row(
                      children: <Widget>[

                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[

                            Align(
                              alignment: Alignment.centerLeft,
                              child: Padding(
                                padding: EdgeInsets.all(4), 
                                child: Text("Min Deposit " + strings.rupee + promoCode["minimum"].toString(),
                                  style: TextStyle(color: bPromoSelected ? Colors.green : Colors.grey.shade700),
                                  textAlign: TextAlign.start,
                                )
                              ), 
                            ),
                            
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Padding(
                                padding: EdgeInsets.all(4), 
                                child: Text("Max Benefits " + strings.rupee + promoCode["maximum"].toString(),
                                  style: TextStyle(color: bPromoSelected ? Colors.green : Colors.grey.shade700),
                                  textAlign: TextAlign.start,
                                )
                              )
                            ),
                          ],
                        ),
                        
                        Container(
                          margin: EdgeInsets.only(left: 6),
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
                          padding: EdgeInsets.all(2),
                          child: !bPromoSelected
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
                      ],
                    )
                    
                  ],
                )
                
            ),
          ),
          onPressed: () {
            //onSelectPromo(promoCode);
            Navigator.of(context).pop(promoCode["promoCode"]);
          },
        )
      );

  }


}

