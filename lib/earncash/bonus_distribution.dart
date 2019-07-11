import 'package:flutter/material.dart';
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
                  color: Colors.grey,
                ),
              ),
            ),
            child: Row(
              children: <Widget>[
                Container(
                  width: 1.0,
                  color: Colors.grey,
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
                        "1st Slab",
                        textAlign: TextAlign.left,
                        style:
                            Theme.of(context).primaryTextTheme.caption.copyWith(
                                  color: Colors.black,
                                ),
                      ),
                    ),
                  ),
                ),
                Container(
                  width: 1.0,
                  color: Colors.grey,
                  height: 36.0,
                ),
                Expanded(
                  child: Container(
                    padding:
                        EdgeInsets.symmetric(vertical: 12.0, horizontal: 4.0),
                    child: Text(
                      getTotalWagerAmount(widget.bonusDistribution["referral"])
                          .toString(),
                      textAlign: TextAlign.right,
                      style:
                          Theme.of(context).primaryTextTheme.caption.copyWith(
                                color: Colors.black,
                              ),
                    ),
                  ),
                ),
                Container(
                  width: 1.0,
                  color: Colors.grey,
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
                      textAlign: TextAlign.right,
                      style:
                          Theme.of(context).primaryTextTheme.caption.copyWith(
                                color: Colors.black,
                              ),
                    ),
                  ),
                ),
                Container(
                  width: 1.0,
                  color: Colors.grey,
                  height: 36.0,
                ),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: Colors.grey,
                ),
              ),
            ),
            child: Row(
              children: <Widget>[
                Container(
                  width: 1.0,
                  color: Colors.grey,
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
                        textAlign: TextAlign.left,
                        style:
                            Theme.of(context).primaryTextTheme.caption.copyWith(
                                  color: Colors.black,
                                ),
                      ),
                    ),
                  ),
                ),
                Container(
                  width: 1.0,
                  color: Colors.grey,
                  height: 36.0,
                ),
                Expanded(
                  child: Container(
                    padding:
                        EdgeInsets.symmetric(vertical: 12.0, horizontal: 4.0),
                    child: Text(
                      getTotalWagerAmount(widget.bonusDistribution["referral"])
                          .toString(),
                      textAlign: TextAlign.right,
                      style:
                          Theme.of(context).primaryTextTheme.caption.copyWith(
                                color: Colors.black,
                              ),
                    ),
                  ),
                ),
                Container(
                  width: 1.0,
                  color: Colors.grey,
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
                      textAlign: TextAlign.right,
                      style:
                          Theme.of(context).primaryTextTheme.caption.copyWith(
                                color: Colors.black,
                              ),
                    ),
                  ),
                ),
                Container(
                  width: 1.0,
                  color: Colors.grey,
                  height: 36.0,
                ),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: Colors.grey,
                ),
              ),
            ),
            child: Row(
              children: <Widget>[
                Container(
                  width: 1.0,
                  color: Colors.grey,
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
                        textAlign: TextAlign.left,
                        style:
                            Theme.of(context).primaryTextTheme.caption.copyWith(
                                  color: Colors.black,
                                ),
                      ),
                    ),
                  ),
                ),
                Container(
                  width: 1.0,
                  color: Colors.grey,
                  height: 36.0,
                ),
                Expanded(
                  child: Container(
                    padding:
                        EdgeInsets.symmetric(vertical: 12.0, horizontal: 4.0),
                    child: Text(
                      "-",
                      textAlign: TextAlign.right,
                      style:
                          Theme.of(context).primaryTextTheme.caption.copyWith(
                                color: Colors.black,
                              ),
                    ),
                  ),
                ),
                Container(
                  width: 1.0,
                  color: Colors.grey,
                  height: 36.0,
                ),
                Expanded(
                  child: Container(
                    padding:
                        EdgeInsets.symmetric(vertical: 12.0, horizontal: 4.0),
                    child: Text(
                      "-",
                      textAlign: TextAlign.right,
                      style:
                          Theme.of(context).primaryTextTheme.caption.copyWith(
                                color: Colors.black,
                              ),
                    ),
                  ),
                ),
                Container(
                  width: 1.0,
                  color: Colors.grey,
                  height: 36.0,
                ),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: Colors.grey,
                ),
              ),
            ),
            child: Row(
              children: <Widget>[
                Container(
                  width: 1.0,
                  color: Colors.grey,
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
                        textAlign: TextAlign.left,
                        style:
                            Theme.of(context).primaryTextTheme.caption.copyWith(
                                  color: Colors.black,
                                ),
                      ),
                    ),
                  ),
                ),
                Container(
                  width: 1.0,
                  color: Colors.grey,
                  height: 36.0,
                ),
                Expanded(
                  child: Container(
                    padding:
                        EdgeInsets.symmetric(vertical: 12.0, horizontal: 4.0),
                    child: Text(
                      getTotalWagerAmount(widget.bonusDistribution["referral"])
                          .toString(),
                      textAlign: TextAlign.right,
                      style:
                          Theme.of(context).primaryTextTheme.caption.copyWith(
                                color: Colors.black,
                              ),
                    ),
                  ),
                ),
                Container(
                  width: 1.0,
                  color: Colors.grey,
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
                      textAlign: TextAlign.right,
                      style:
                          Theme.of(context).primaryTextTheme.caption.copyWith(
                                color: Colors.black,
                              ),
                    ),
                  ),
                ),
                Container(
                  width: 1.0,
                  color: Colors.grey,
                  height: 36.0,
                ),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: Colors.grey,
                ),
              ),
            ),
            child: Row(
              children: <Widget>[
                Container(
                  width: 1.0,
                  color: Colors.grey,
                  height: 36.0,
                ),
                Expanded(
                  flex: 2,
                  child: ClipRRect(
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(5.0),
                    ),
                    child: Container(
                      padding:
                          EdgeInsets.symmetric(vertical: 12.0, horizontal: 4.0),
                      child: Text(
                        "Total locked bonus ${strings.rupee}${getWagerReleaseAmount(widget.bonusDistribution['referral']).toString()}*${(widget.bonusDistribution["referral"]["chunks"]).toString()}",
                        textAlign: TextAlign.left,
                        style:
                            Theme.of(context).primaryTextTheme.caption.copyWith(
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                    ),
                  ),
                ),
                Container(
                  width: 1.0,
                  color: Colors.grey,
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
                      textAlign: TextAlign.right,
                      style:
                          Theme.of(context).primaryTextTheme.caption.copyWith(
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                              ),
                    ),
                  ),
                ),
                Container(
                  width: 1.0,
                  color: Colors.grey,
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
                        "Refer and Earn Bonus",
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
                          "You can earn upto ${strings.rupee}${widget.amount}/Friend"),
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
              Padding(
                padding: EdgeInsets.only(top: 16.0),
                child: Container(
                  color: Theme.of(context).primaryColor,
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(5.0),
                          ),
                          child: Container(
                            padding: EdgeInsets.symmetric(vertical: 12.0),
                            child: Text(
                              "Slab",
                              textAlign: TextAlign.center,
                              style: Theme.of(context)
                                  .primaryTextTheme
                                  .caption
                                  .copyWith(
                                    color: Colors.white,
                                  ),
                            ),
                          ),
                        ),
                      ),
                      Container(
                        width: 1.0,
                        color: Colors.grey,
                        height: 36.0,
                      ),
                      Expanded(
                        child: Container(
                          padding: EdgeInsets.symmetric(vertical: 12.0),
                          child: Text(
                            "Friend's Played amount",
                            textAlign: TextAlign.center,
                            style: Theme.of(context)
                                .primaryTextTheme
                                .caption
                                .copyWith(
                                  color: Colors.white,
                                ),
                          ),
                        ),
                      ),
                      Container(
                        width: 1.0,
                        color: Colors.grey,
                        height: 36.0,
                      ),
                      Expanded(
                        child: Container(
                          padding: EdgeInsets.symmetric(vertical: 12.0),
                          child: Text(
                            "Bonus Released",
                            textAlign: TextAlign.center,
                            style: Theme.of(context)
                                .primaryTextTheme
                                .caption
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
              getBonusDistributionWidget(),
            ],
          ),
        ),
      ),
    );
  }
}
