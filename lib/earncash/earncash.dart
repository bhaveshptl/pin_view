import 'dart:convert';
import 'dart:io';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:playfantasy/action_utils/action_util.dart';
import 'package:playfantasy/appconfig.dart';
import 'package:playfantasy/commonwidgets/addcashbutton.dart';
import 'package:playfantasy/commonwidgets/leadingbutton.dart';
import 'package:playfantasy/commonwidgets/routelauncher.dart';
import 'package:playfantasy/earncash/bonus_distribution.dart';
import 'package:playfantasy/providers/user.dart';
import 'package:playfantasy/redux/actions/loader_actions.dart';
import 'package:playfantasy/utils/apiutil.dart';
import 'package:playfantasy/utils/httpmanager.dart';
import 'package:playfantasy/utils/analytics.dart';
import 'package:playfantasy/utils/sharedprefhelper.dart';
import 'package:playfantasy/utils/stringtable.dart';
import 'package:playfantasy/commonwidgets/scaffoldpage.dart';
import 'package:playfantasy/commonwidgets/color_button.dart';
import 'package:provider/provider.dart';

class EarnCash extends StatefulWidget {
  final Map<String, dynamic> data;

  EarnCash({this.data});

  @override
  EarnCashState createState() {
    return new EarnCashState();
  }
}

class EarnCashState extends State<EarnCash> {
  int refAAmount = 0;
  int refBAmount = 0;
  String cookie = "";
  String refCode = "";
  String inviteUrl = "";
  String inviteMsg = "";
  double userBalance = 0.0;
  List<dynamic> inviteSteps;
  static const social_share_platform =
      const MethodChannel('com.algorin.pf.socialshare');
  static const utils_platform = const MethodChannel('com.algorin.pf.utils');

  List<dynamic> _carousel = [];
  final _scaffoldKey = new GlobalKey<ScaffoldState>();

  static const _kFontFam = 'MyFlutterApp';
  static const IconData gplus_squared =
      const IconData(0xf0d4, fontFamily: _kFontFam);
  static const IconData facebook_squared =
      const IconData(0xf308, fontFamily: _kFontFam);

  @override
  void initState() {
    super.initState();
    setReferralDetails();
    _getBanners();
    if (Platform.isIOS) {
      initSocialShareChannel();
    }
  }

  showLoader(bool bShow) {
    AppConfig.of(context)
        .store
        .dispatch(bShow ? LoaderShowAction() : LoaderHideAction());
  }

  _launchAddCash(
      {String source, String promoCode, double prefilledAmount}) async {
    showLoader(true);
    routeLauncher.launchAddCash(
      context,
      source: source,
      promoCode: promoCode,
      prefilledAmount: prefilledAmount,
      onComplete: () {
        showLoader(false);
      },
    );
  }

  _getProfileData() async {
    http.Request req = http.Request(
      "GET",
      Uri.parse(
        BaseUrl().apiUrl + ApiUtil.GET_USER_PROFILE,
      ),
    );
    return HttpManager(http.Client()).sendRequest(req).then(
      (http.Response res) {
        if (res.statusCode >= 200 && res.statusCode <= 299) {
          Map<String, dynamic> response = json.decode(res.body);
          return response;
        } else if (res.statusCode == 401) {
          return {};
        }
      },
    ).whenComplete(() {});
  }

  setReferralDetails() async {
    refCode = widget.data["refDetails"]["refCode"];
    refAAmount = widget.data["refDetails"]["amountUserA"];
    refBAmount = widget.data["refDetails"]["amountUserB"];
    inviteUrl =
        (widget.data["refDetails"]["refLink"] as String).replaceAll("%3d", "=");
    inviteSteps = widget.data["refDetails"]["inviteSteps"];

    /*Web engage Screen Data */
    Map<dynamic, dynamic> screendata = new Map();
    screendata["screenName"] = "EARNCASH";
    Map<String, dynamic> screenAttributedata = Map();
    screenAttributedata["refCode"] = refCode;
    screendata["data"] = screenAttributedata;
    AnalyticsManager.webengageAddScreenData(screendata);
  }

  _getBanners() async {
    http.Request req = http.Request(
        "GET",
        Uri.parse(
          BaseUrl().apiUrl + ApiUtil.GET_BANNERS + "/5",
        ));
    await HttpManager(http.Client()).sendRequest(req).then((http.Response res) {
      if (res.statusCode >= 200 && res.statusCode <= 299) {
        final banners = json.decode(res.body)["banners"];
        setState(() {
          _carousel = (banners as List).map((dynamic value) {
            return value;
          }).toList();
        });
      }
    });
  }

  _copyCode() {
    Clipboard.setData(
      ClipboardData(text: refCode),
    );
    ActionUtil().showMsgOnTop("COPIED", context);
    // _scaffoldKey.currentState.showSnackBar(
    //   SnackBar(
    //     content: Text(
    //       strings.get("COPIED"),
    //     ),
    //   ),
    // );
  }

  Future<String> initSocialShareChannel() async {
    String value;
    try {
      value =
          await social_share_platform.invokeMethod('initSocialShareChannel');
    } catch (e) {
      print(e);
    }
    return value;
  }

  Future<String> _shareNowViaWhatsAppApplication(String msg) async {
    String value;
    try {
      value = await social_share_platform.invokeMethod('shareViaWhatsApp', msg);
    } catch (e) {
      print(e);
      _shareNowViaSystemApplication(msg);
    }
    return value;
  }

  Future<String> _shareNowViaFacebookApplication(String msg) async {
    String value;
    try {
      value = await social_share_platform.invokeMethod('shareViaFacebook', msg);
    } catch (e) {
      print(e);
      _shareNowViaSystemApplication(msg);
    }
    return value;
  }

  Future<String> _shareNowViaGmailApplication(String msg) async {
    String value;
    try {
      value = await social_share_platform.invokeMethod('shareViaGmail', msg);
    } catch (e) {
      print(e);
      _shareNowViaSystemApplication(msg);
    }
    return value;
  }

  Future<String> _shareNowViaSystemApplication(String msg) async {
    String value;
    try {
      value = await social_share_platform.invokeMethod('shareText', msg);
    } catch (e) {
      print(e);
    }
    return value;
  }

  _shareNowWhatsApp() {
    inviteMsg =
        "I'm having a lot of fun playing Fantasy Sports on Howzat and winning cash prizes! Join me and get started with free " +
            strings.rupee +
            refBAmount.toString() +
            " in your account - Click " +
            inviteUrl +
            " to download the Howzat app and use my code " +
            refCode +
            " to register.";

    if (Platform.isAndroid) {
      _shareNowViaWhatsAppApplication(inviteMsg);
    }
    if (Platform.isIOS) {
      _shareNowViaWhatsAppApplication(inviteMsg);
    }
  }

  _shareNowFacebook() {
    inviteMsg =
        "I'm having a lot of fun playing Fantasy Sports on Howzat and winning cash prizes! Join me and get started with free " +
            strings.rupee +
            refBAmount.toString() +
            " in your account - Click " +
            inviteUrl +
            " to download the Howzat app and use my code " +
            refCode +
            " to register.";

    if (Platform.isAndroid) {
      _shareNowViaFacebookApplication(inviteMsg);
    }
    if (Platform.isIOS) {
      _shareNowViaFacebookApplication(inviteMsg);
    }
  }

  _shareNowGmail() {
    inviteMsg =
        "I'm having a lot of fun playing Fantasy Sports on Howzat and winning cash prizes! Join me and get started with free " +
            strings.rupee +
            refBAmount.toString() +
            " in your account - Click " +
            inviteUrl +
            " to download the Howzat app and use my code " +
            refCode +
            " to register.";
    if (Platform.isAndroid) {
      _shareNowViaGmailApplication(inviteMsg);
    }
    if (Platform.isIOS) {
      _shareNowViaGmailApplication(inviteMsg);
    }
  }

  _shareNow() {
    inviteMsg =
        "I'm having a lot of fun playing Fantasy Sports on Howzat and winning cash prizes! Join me and get started with free " +
            strings.rupee +
            refBAmount.toString() +
            " in your account - Click " +
            inviteUrl +
            " to download the Howzat app and use my code " +
            refCode +
            " to register.";
    if (Platform.isAndroid) {
      _shareNowViaSystemApplication(inviteMsg);
    }
    if (Platform.isIOS) {
      _shareNowViaSystemApplication(inviteMsg);
    }
  }

  @override
  Widget build(BuildContext context) {
    final formatCurrency = NumberFormat.currency(
      locale: "hi_IN",
      symbol: strings.rupee,
      decimalDigits: 0,
    );

    BoxDecoration iconDecoration = BoxDecoration(
      shape: BoxShape.circle,
      border: Border.all(
        width: 1.0,
        color: Colors.black26,
      ),
    );

    return ScaffoldPage(
      scaffoldKey: _scaffoldKey,
      appBar: AppBar(
        leading: LeadingButton(),
        titleSpacing: 0.0,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Text(
              "Refer & Earn".toUpperCase(),
            ),
            Consumer<User>(
              builder: (context, user, child) {
                return AddCashButton(
                  location: "topright",
                  amount: user.withdrawable + user.depositedAmount,
                );
              },
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: <Widget>[
            Container(
              width: MediaQuery.of(context).size.width,
              child: _carousel.length > 0
                  ? CarouselSlider(
                      enlargeCenterPage: true,
                      aspectRatio: 16 / 3.5,
                      viewportFraction: 1.0,
                      enableInfiniteScroll: true,
                      autoPlayInterval: Duration(seconds: 10),
                      items: _carousel.map<Widget>((dynamic banner) {
                        return Image.network(
                          banner["banner"],
                          fit: BoxFit.fitWidth,
                          width: MediaQuery.of(context).size.width,
                        );
                      }).toList(),
                      autoPlay: _carousel.length <= 2 ? false : true,
                      reverse: false,
                    )
                  : Container(),
            ),
            Padding(
              padding: EdgeInsets.only(top: 16.0),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      "Invite your friends and play Howzat",
                      textAlign: TextAlign.center,
                      style:
                          Theme.of(context).primaryTextTheme.headline.copyWith(
                                color: Colors.black,
                                fontWeight: FontWeight.w700,
                              ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.only(top: 8.0),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: "For every friend that plays, you will earn ",
                          ),
                          TextSpan(
                            text: strings.rupee + refAAmount.toString(),
                          ),
                        ],
                        style:
                            Theme.of(context).primaryTextTheme.body2.copyWith(
                                  color: Colors.black,
                                ),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
            widget.data["bonusDistribution"] == null ||
                    widget.data["bonusDistribution"]["referral"] == null ||
                    widget.data["bonusDistribution"]["referred"] == null
                ? Container()
                : InkWell(
                    child: Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Row(
                        children: <Widget>[
                          Expanded(
                            child: Text(
                              "Click here for more info",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.blue,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    onTap: () async {
                      final result = await showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return BonusDistribution(
                            amount: refAAmount,
                            bonusDistribution: widget.data["bonusDistribution"],
                          );
                        },
                      );
                    },
                  ),
            Padding(
              padding: EdgeInsets.all(8.0),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Card(
                      child: Column(
                        children: <Widget>[
                          Padding(
                            padding: EdgeInsets.only(top: 16.0, bottom: 8.0),
                            child: Row(
                              children: <Widget>[
                                Expanded(
                                  child: Text(
                                    "Send your referral code",
                                    textAlign: TextAlign.center,
                                    style: Theme.of(context)
                                        .primaryTextTheme
                                        .body1
                                        .copyWith(
                                          color: Colors.black,
                                          fontWeight: FontWeight.w600,
                                        ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Row(
                            children: <Widget>[
                              Expanded(
                                child: Text(
                                  refCode,
                                  style: Theme.of(context)
                                      .primaryTextTheme
                                      .title
                                      .copyWith(
                                        color: Color.fromRGBO(70, 165, 12, 1),
                                        fontWeight: FontWeight.w800,
                                      ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ],
                          ),
                          Padding(
                            padding: EdgeInsets.only(
                                left: 32.0,
                                right: 32.0,
                                bottom: 16.0,
                                top: 16.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: <Widget>[
                                Container(
                                  width: 56.0,
                                  height: 56.0,
                                  decoration: iconDecoration,
                                  child: InkWell(
                                    onTap: () {
                                      _shareNowWhatsApp();
                                    },
                                    child: Padding(
                                      padding: EdgeInsets.all(8.0),
                                      child: Image.asset(
                                        "images/watsapp.png",
                                        height: 32.0,
                                      ),
                                    ),
                                  ),
                                ),
                                Container(
                                  width: 56.0,
                                  height: 56.0,
                                  decoration: iconDecoration,
                                  child: InkWell(
                                    onTap: () {
                                      _shareNowFacebook();
                                    },
                                    child: Padding(
                                      padding: EdgeInsets.all(8.0),
                                      child: Image.asset(
                                        "images/facebook.png",
                                        height: 32.0,
                                      ),
                                    ),
                                  ),
                                ),
                                Container(
                                  width: 56.0,
                                  height: 56.0,
                                  decoration: iconDecoration,
                                  child: InkWell(
                                    onTap: () {
                                      _shareNowGmail();
                                    },
                                    child: Padding(
                                      padding: EdgeInsets.all(8.0),
                                      child: Image.asset(
                                        "images/gmail.png",
                                      ),
                                    ),
                                  ),
                                ),
                                Container(
                                  width: 56.0,
                                  height: 56.0,
                                  decoration: iconDecoration,
                                  child: InkWell(
                                    onTap: () {
                                      _copyCode();
                                    },
                                    child: Icon(
                                      Icons.content_copy,
                                      size: 32.0,
                                      color: Colors.black45,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.only(
                                left: 32.0,
                                right: 32.0,
                                bottom: 24.0,
                                top: 16.0),
                            child: Row(
                              children: <Widget>[
                                Expanded(
                                  child: Container(
                                    height: 56.0,
                                    child: ColorButton(
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: <Widget>[
                                          Padding(
                                            padding:
                                                EdgeInsets.only(right: 8.0),
                                            child: Icon(
                                              Icons.share,
                                              color: Colors.white,
                                            ),
                                          ),
                                          Text(
                                            "Share".toUpperCase(),
                                            style: Theme.of(context)
                                                .primaryTextTheme
                                                .headline
                                                .copyWith(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.w800,
                                                ),
                                          ),
                                        ],
                                      ),
                                      elevation: 0.0,
                                      onPressed: () {
                                        _shareNow();
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.only(left: 16.0, top: 16.0, right: 16.0),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Padding(
                          padding: EdgeInsets.symmetric(vertical: 4.0),
                          child: Text(
                            "Share and Earn ₹$refAAmount in three easy steps!",
                            style: Theme.of(context)
                                .primaryTextTheme
                                .title
                                .copyWith(
                                  color: Colors.black,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                        ),
                        Column(
                          children: inviteSteps.map((step) {
                            return Padding(
                              padding: EdgeInsets.symmetric(vertical: 4.0),
                              child: Row(
                                children: <Widget>[
                                  Expanded(
                                    child: Padding(
                                      padding: EdgeInsets.only(left: 8.0),
                                      child: Text(
                                        step,
                                        style: Theme.of(context)
                                            .primaryTextTheme
                                            .body2
                                            .copyWith(
                                              color: Colors.black87,
                                            ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),

                        // Padding(
                        //   padding: EdgeInsets.symmetric(vertical: 4.0),
                        //   child: Row(
                        //     children: <Widget>[
                        //       Expanded(
                        //         child: Padding(
                        //           padding: EdgeInsets.only(left: 8.0),
                        //           child: Text(
                        //             "Step 2 - Share the invite code above with your friends.",
                        //             style: Theme.of(context)
                        //                 .primaryTextTheme
                        //                 .body2
                        //                 .copyWith(
                        //                   color: Colors.black87,
                        //                 ),
                        //           ),
                        //         ),
                        //       ),
                        //     ],
                        //   ),
                        // ),
                        // Padding(
                        //   padding: EdgeInsets.symmetric(vertical: 4.0),
                        //   child: Row(
                        //     children: <Widget>[
                        //       Expanded(
                        //         child: Padding(
                        //           padding: EdgeInsets.only(left: 8.0),
                        //           child: Text(
                        //             "Step 3 - Your friend joins and verifies their mobile number.",
                        //             style: Theme.of(context)
                        //                 .primaryTextTheme
                        //                 .body2
                        //                 .copyWith(
                        //                   color: Colors.black87,
                        //                 ),
                        //           ),
                        //         ),
                        //       ),
                        //     ],
                        //   ),
                        // ),
                        // Padding(
                        //   padding: EdgeInsets.only(top: 8.0),
                        //   child: Row(
                        //     children: <Widget>[
                        //       Expanded(
                        //         child: Text(
                        //           "That's it!  You get ₹$refAAmount and your friend gets ₹$refBAmount when both of you have verified your mobile numbers.",
                        //           style: Theme.of(context)
                        //               .primaryTextTheme
                        //               .body2
                        //               .copyWith(
                        //                 color: Colors.black87,
                        //                 fontWeight: FontWeight.w500,
                        //               ),
                        //         ),
                        //       ),
                        //     ],
                        //   ),
                        // )
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
