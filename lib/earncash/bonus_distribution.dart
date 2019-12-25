import 'package:flutter/material.dart';
import 'package:playfantasy/commonwidgets/customdialog.dart';
import 'package:playfantasy/utils/stringtable.dart';

class BonusDistribution extends StatefulWidget {
  final int amount;
  final Map<String, dynamic> bonusDistribution;

  BonusDistribution({this.amount, this.bonusDistribution});

  @override
  BonusDistributionState createState() => BonusDistributionState();
}

class BonusDistributionState extends State<BonusDistribution> {
  int getTotalWagerAmount(promoCode) {
    return ((widget.amount * promoCode["nonPlayablePercentage"]) /
            (promoCode['wagerPercentage'] * promoCode["chunks"]))
        .floor();
  }

  int getWagerReleaseAmount(promoCode) {
    return ((widget.amount * (promoCode["nonPlayablePercentage"] / 100)) /
            promoCode["chunks"])
        .floor();
  }

  int getInstantBonus(promoCode) {
    return (widget.amount * promoCode["instantCashPercentage"] / 100).floor();
  }

  int getPlayableBonus(promoCode) {
    return (widget.amount * promoCode["playablePercentage"] / 100).floor();
  }

  int getLockedBonusAmount(promoCode) {
    return (widget.amount * promoCode["nonPlayablePercentage"] / 100).floor();
  }

  getBonusDistributionWidget() {
    return Container(
      child: Column(
        children: <Widget>[
          Container(
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: Colors.white,
                ),
              ),
              color: Color.fromRGBO(235, 251, 255, 1),
            ),
            child: Row(
              children: <Widget>[
                Container(
                  width: 2.0,
                  color: Colors.white,
                  height: 36.0,
                ),
                Expanded(
                  child: Container(
                    padding:
                        EdgeInsets.symmetric(vertical: 12.0, horizontal: 4.0),
                    child: Text(
                      "1st Slab",
                      textAlign: TextAlign.center,
                      style: Theme.of(context).primaryTextTheme.body1.copyWith(
                            color: Colors.black,
                          ),
                    ),
                  ),
                ),
                Container(
                  width: 2.0,
                  color: Colors.white,
                  height: 36.0,
                ),
                Expanded(
                  child: Container(
                    padding:
                        EdgeInsets.symmetric(vertical: 12.0, horizontal: 4.0),
                    child: Text(
                      getTotalWagerAmount(widget.bonusDistribution["referral"])
                          .toString(),
                      textAlign: TextAlign.center,
                      style: Theme.of(context).primaryTextTheme.body1.copyWith(
                            color: Colors.black,
                          ),
                    ),
                  ),
                ),
                Container(
                  width: 2.0,
                  color: Colors.white,
                  height: 36.0,
                ),
                Expanded(
                  child: Container(
                    padding:
                        EdgeInsets.symmetric(vertical: 12.0, horizontal: 4.0),
                    child: Text(
                      getWagerReleaseAmount(
                              widget.bonusDistribution["referral"])
                          .toString(),
                      textAlign: TextAlign.center,
                      style: Theme.of(context).primaryTextTheme.body1.copyWith(
                            color: Colors.black,
                          ),
                    ),
                  ),
                ),
                Container(
                  width: 2.0,
                  color: Colors.white,
                  height: 36.0,
                ),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: Colors.white,
                ),
              ),
              color: Color.fromRGBO(210, 245, 255, 1),
            ),
            child: Row(
              children: <Widget>[
                Container(
                  width: 2.0,
                  color: Colors.white,
                  height: 36.0,
                ),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(5.0),
                    ),
                    child: Container(
                      padding:
                          EdgeInsets.symmetric(vertical: 12.0, horizontal: 4.0),
                      child: Text(
                        "2st Slab",
                        textAlign: TextAlign.center,
                        style:
                            Theme.of(context).primaryTextTheme.body1.copyWith(
                                  color: Colors.black,
                                ),
                      ),
                    ),
                  ),
                ),
                Container(
                  width: 2.0,
                  color: Colors.white,
                  height: 36.0,
                ),
                Expanded(
                  child: Container(
                    padding:
                        EdgeInsets.symmetric(vertical: 12.0, horizontal: 4.0),
                    child: Text(
                      getTotalWagerAmount(widget.bonusDistribution["referral"])
                          .toString(),
                      textAlign: TextAlign.center,
                      style: Theme.of(context).primaryTextTheme.body1.copyWith(
                            color: Colors.black,
                          ),
                    ),
                  ),
                ),
                Container(
                  width: 2.0,
                  color: Colors.white,
                  height: 36.0,
                ),
                Expanded(
                  child: Container(
                    padding:
                        EdgeInsets.symmetric(vertical: 12.0, horizontal: 4.0),
                    child: Text(
                      getWagerReleaseAmount(
                              widget.bonusDistribution["referral"])
                          .toString(),
                      textAlign: TextAlign.center,
                      style: Theme.of(context).primaryTextTheme.body1.copyWith(
                            color: Colors.black,
                          ),
                    ),
                  ),
                ),
                Container(
                  width: 2.0,
                  color: Colors.white,
                  height: 36.0,
                ),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: Colors.white,
                ),
              ),
              color: Color.fromRGBO(235, 251, 255, 1),
            ),
            child: Row(
              children: <Widget>[
                Container(
                  width: 2.0,
                  color: Colors.white,
                  height: 36.0,
                ),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(5.0),
                    ),
                    child: Container(
                      padding:
                          EdgeInsets.symmetric(vertical: 12.0, horizontal: 4.0),
                      child: Text(
                        "-",
                        textAlign: TextAlign.center,
                        style:
                            Theme.of(context).primaryTextTheme.body1.copyWith(
                                  color: Colors.black,
                                ),
                      ),
                    ),
                  ),
                ),
                Container(
                  width: 2.0,
                  color: Colors.white,
                  height: 36.0,
                ),
                Expanded(
                  child: Container(
                    padding:
                        EdgeInsets.symmetric(vertical: 12.0, horizontal: 4.0),
                    child: Text(
                      "-",
                      textAlign: TextAlign.center,
                      style: Theme.of(context).primaryTextTheme.body1.copyWith(
                            color: Colors.black,
                          ),
                    ),
                  ),
                ),
                Container(
                  width: 2.0,
                  color: Colors.white,
                  height: 36.0,
                ),
                Expanded(
                  child: Container(
                    padding:
                        EdgeInsets.symmetric(vertical: 12.0, horizontal: 4.0),
                    child: Text(
                      "-",
                      textAlign: TextAlign.center,
                      style: Theme.of(context).primaryTextTheme.body1.copyWith(
                            color: Colors.black,
                          ),
                    ),
                  ),
                ),
                Container(
                  width: 2.0,
                  color: Colors.white,
                  height: 36.0,
                ),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: Colors.white,
                ),
              ),
              color: Color.fromRGBO(210, 245, 255, 1),
            ),
            child: Row(
              children: <Widget>[
                Container(
                  width: 2.0,
                  color: Colors.white,
                  height: 36.0,
                ),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(5.0),
                    ),
                    child: Container(
                      padding:
                          EdgeInsets.symmetric(vertical: 12.0, horizontal: 4.0),
                      child: Text(
                        (widget.bonusDistribution["referral"]["chunks"])
                                .toString() +
                            "th slab",
                        textAlign: TextAlign.center,
                        style:
                            Theme.of(context).primaryTextTheme.body1.copyWith(
                                  color: Colors.black,
                                ),
                      ),
                    ),
                  ),
                ),
                Container(
                  width: 2.0,
                  color: Colors.white,
                  height: 36.0,
                ),
                Expanded(
                  child: Container(
                    padding:
                        EdgeInsets.symmetric(vertical: 12.0, horizontal: 4.0),
                    child: Text(
                      getTotalWagerAmount(widget.bonusDistribution["referral"])
                          .toString(),
                      textAlign: TextAlign.center,
                      style: Theme.of(context).primaryTextTheme.body1.copyWith(
                            color: Colors.black,
                          ),
                    ),
                  ),
                ),
                Container(
                  width: 2.0,
                  color: Colors.white,
                  height: 36.0,
                ),
                Expanded(
                  child: Container(
                    padding:
                        EdgeInsets.symmetric(vertical: 12.0, horizontal: 4.0),
                    child: Text(
                      getWagerReleaseAmount(
                              widget.bonusDistribution["referral"])
                          .toString(),
                      textAlign: TextAlign.center,
                      style: Theme.of(context).primaryTextTheme.body1.copyWith(
                            color: Colors.black,
                          ),
                    ),
                  ),
                ),
                Container(
                  width: 2.0,
                  color: Colors.white,
                  height: 36.0,
                ),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: Colors.white,
                ),
              ),
              color: Color.fromRGBO(235, 251, 255, 1),
            ),
            child: Row(
              children: <Widget>[
                Container(
                  width: 2.0,
                  color: Colors.white,
                  height: 36.0,
                ),
                Expanded(
                  flex: 2,
                  child: Container(
                    padding:
                        EdgeInsets.symmetric(vertical: 12.0, horizontal: 4.0),
                    child: Text(
                      "Total locked bonus ${strings.rupee}${getWagerReleaseAmount(widget.bonusDistribution['referral']).toString()}*${(widget.bonusDistribution["referral"]["chunks"]).toString()}",
                      textAlign: TextAlign.center,
                      style: Theme.of(context).primaryTextTheme.body1.copyWith(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                ),
                Container(
                  width: 2.0,
                  color: Colors.white,
                  height: 36.0,
                ),
                Expanded(
                  child: Container(
                    padding:
                        EdgeInsets.symmetric(vertical: 12.0, horizontal: 4.0),
                    child: Text(
                      strings.rupee +
                          (getLockedBonusAmount(
                                  widget.bonusDistribution['referred']))
                              .toString(),
                      textAlign: TextAlign.center,
                      style: Theme.of(context).primaryTextTheme.body1.copyWith(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                ),
                Container(
                  width: 2.0,
                  color: Colors.white,
                  height: 36.0,
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CustomDialog(
      padding: EdgeInsets.symmetric(horizontal: 16.0),
      dialog: Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4.0),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: <Widget>[
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
            SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.only(left: 8.0, right: 8.0, bottom: 8.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            "Refer and Earn Bonus",
                            style: Theme.of(context)
                                .primaryTextTheme
                                .title
                                .copyWith(
                                  color: Colors.orange,
                                  fontWeight: FontWeight.w700,
                                ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                    SingleChildScrollView(
                      child: Container(
                        width: MediaQuery.of(context).size.width,
                        padding: EdgeInsets.all(16.0),
                        child: Column(
                          children: <Widget>[
                            Row(
                              children: <Widget>[
                                Expanded(
                                  child: Text(
                                    "Howzat offers a very lucrative refer and earn bonus for their users. You can earn cash everytime your friends play any cash tournament.",
                                    style: Theme.of(context)
                                        .primaryTextTheme
                                        .body2
                                        .copyWith(
                                          color: Colors.black,
                                          fontWeight: FontWeight.normal,
                                        ),
                                    textAlign: TextAlign.justify,
                                  ),
                                ),
                              ],
                            ),
                            Padding(
                              padding: EdgeInsets.only(top: 16.0),
                              child: Row(
                                children: <Widget>[
                                  Expanded(
                                    child: Text(
                                      "You earn instant cash of ${strings.rupee}${getInstantBonus(widget.bonusDistribution['referred'])} and bonus of ${strings.rupee}${getPlayableBonus(widget.bonusDistribution['referred'])} when your friend make deposit. Also you will get upto ${strings.rupee}${getLockedBonusAmount(widget.bonusDistribution['referred'])} for additional ${strings.rupee}${getTotalWagerAmount(widget.bonusDistribution['referred']) * widget.bonusDistribution['referred']["chunks"]} that your friend plays.",
                                      // "You earn your first bonus part of ${strings.rupee}${getWagerReleaseAmount(widget.bonusDistribution["referred"])} when your friend play for ${strings.rupee}${getTotalWagerAmount(widget.bonusDistribution["referred"])} and then you can get upto ${strings.rupee} bonus of 10 for additional 500 that your friend plays.",
                                      textAlign: TextAlign.justify,
                                      style: Theme.of(context)
                                          .primaryTextTheme
                                          .body2
                                          .copyWith(
                                            color: Colors.black,
                                            fontWeight: FontWeight.normal,
                                          ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.only(top: 16.0),
                              child: Row(
                                children: <Widget>[
                                  Expanded(
                                    child: Text(
                                      "You can earn upto ${strings.rupee}${widget.amount}/Friend",
                                      style: Theme.of(context)
                                          .primaryTextTheme
                                          .body2
                                          .copyWith(
                                            color: Colors.black,
                                            fontWeight: FontWeight.normal,
                                          ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.only(top: 16.0),
                              child: Row(
                                children: <Widget>[
                                  Expanded(
                                    child: Text(
                                      "Locked Bonus Release",
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              margin: EdgeInsets.only(top: 16.0),
                              child: ClipRRect(
                                borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(8.0),
                                  topRight: Radius.circular(8.0),
                                ),
                                child: IntrinsicHeight(
                                  child: Container(
                                    color: Color.fromRGBO(2, 139, 205, 1),
                                    child: Row(
                                      children: <Widget>[
                                        Expanded(
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.only(
                                              topLeft: Radius.circular(5.0),
                                            ),
                                            child: Container(
                                              padding: EdgeInsets.symmetric(
                                                  vertical: 12.0),
                                              child: Text(
                                                "Slab",
                                                textAlign: TextAlign.center,
                                                style: Theme.of(context)
                                                    .primaryTextTheme
                                                    .body1
                                                    .copyWith(
                                                      color: Colors.white,
                                                    ),
                                              ),
                                            ),
                                          ),
                                        ),
                                        Container(
                                          width: 2.0,
                                          color: Colors.white,
                                        ),
                                        Expanded(
                                          child: Container(
                                            padding: EdgeInsets.symmetric(
                                                vertical: 12.0),
                                            child: Text(
                                              "Friend's Played amount",
                                              textAlign: TextAlign.center,
                                              style: Theme.of(context)
                                                  .primaryTextTheme
                                                  .body1
                                                  .copyWith(
                                                    color: Colors.white,
                                                  ),
                                            ),
                                          ),
                                        ),
                                        Container(
                                          width: 2.0,
                                          color: Colors.white,
                                        ),
                                        Expanded(
                                          child: Container(
                                            padding: EdgeInsets.symmetric(
                                                vertical: 12.0),
                                            child: Text(
                                              "Bonus Released",
                                              textAlign: TextAlign.center,
                                              style: Theme.of(context)
                                                  .primaryTextTheme
                                                  .body1
                                                  .copyWith(
                                                    color: Colors.white,
                                                  ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            getBonusDistributionWidget(),
                          ],
                        ),
                      ),
                    )
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
