import 'dart:convert';
import 'dart:io';
import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:playfantasy/action_utils/action_util.dart';
import 'package:playfantasy/appconfig.dart';
import 'package:playfantasy/commonwidgets/addcashbutton.dart';
import 'package:playfantasy/commonwidgets/leadingbutton.dart';
import 'package:playfantasy/commonwidgets/routelauncher.dart';
import 'package:playfantasy/providers/user.dart';
import 'package:playfantasy/redux/actions/loader_actions.dart';
import 'package:playfantasy/utils/apiutil.dart';
import 'package:playfantasy/utils/httpmanager.dart';
import 'package:playfantasy/utils/analytics.dart';
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
    BoxDecoration iconDecoration = BoxDecoration(
      shape: BoxShape.circle,
      border: Border.all(
        width: 1.0,
        color: Colors.black26,
      ),
    );

    return ScaffoldPage(
      scaffoldKey: _scaffoldKey,
      backgroundColor: Colors.white,
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
                if (user == null) {
                  return Container();
                }
                return AddCashButton(
                  location: "ec-topright",
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
            Padding(
              padding: EdgeInsets.only(top: 16.0),
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.90,
                ),
                // padding: EdgeInsets.only(top: 6.0, bottom: 6.0),
                decoration: BoxDecoration(
                  color: Color.fromRGBO(218, 246, 255, 1),
                  borderRadius: BorderRadius.all(
                    Radius.circular(24.0),
                  ),
                ),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          Text(
                            strings.rupee + "$refAAmount ",
                            style: Theme.of(context)
                                .primaryTextTheme
                                .title
                                .copyWith(
                                  color: Color.fromRGBO(255, 124, 19, 1),
                                ),
                          ),
                          Text(
                            "Total Rewards ",
                            style: Theme.of(context)
                                .primaryTextTheme
                                .title
                                .copyWith(
                                  color: Color.fromRGBO(50, 161, 214, 1),
                                ),
                          ),
                          Text(
                            "|",
                            style: Theme.of(context)
                                .primaryTextTheme
                                .title
                                .copyWith(
                                  color: Color.fromRGBO(255, 124, 19, 1),
                                ),
                          ),
                          Text(
                            " 3 Simple steps",
                            style: Theme.of(context)
                                .primaryTextTheme
                                .title
                                .copyWith(
                                  color: Color.fromRGBO(50, 161, 214, 1),
                                ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding:
                          EdgeInsets.only(right: 4.0, top: 4.0, bottom: 4.0),
                      child: Image.asset(
                        "images/Info_Icon.png",
                        height: 32.0,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.only(top: 8.0, left: 16.0),
              child: ListTile(
                leading: Image.asset("images/Step1.png"),
                isThreeLine: true,
                title: Row(
                  children: <Widget>[
                    Text(
                      "STEP 1. ",
                      style: TextStyle(
                        color: Color.fromRGBO(255, 124, 19, 1),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      "Become Eligible",
                      style:
                          Theme.of(context).primaryTextTheme.subhead.copyWith(
                                color: Colors.grey.shade800,
                                fontWeight: FontWeight.bold,
                              ),
                    ),
                  ],
                ),
                subtitle: Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        inviteSteps.length >= 1
                            ? inviteSteps[0]
                            : "By depositing a minimum of ${strings.rupee}100",
                        style:
                            Theme.of(context).primaryTextTheme.subhead.copyWith(
                                  color: Colors.grey.shade800,
                                ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.only(right: 24.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: <Widget>[
                  ColorButton(
                    child: Text(
                      "DEPOSIT",
                      style:
                          Theme.of(context).primaryTextTheme.subhead.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                    ),
                    onPressed: () {
                      showLoader(true);
                      routeLauncher.launchAddCash(
                        context,
                        onComplete: () {
                          showLoader(false);
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.only(top: 16.0, bottom: 8.0, left: 16.0),
              child: ListTile(
                leading: Image.asset("images/Step2.png"),
                isThreeLine: true,
                title: Row(
                  children: <Widget>[
                    Text(
                      "STEP 2. ",
                      style: TextStyle(
                        color: Color.fromRGBO(255, 124, 19, 1),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      "Spread The Love",
                      style:
                          Theme.of(context).primaryTextTheme.subhead.copyWith(
                                color: Colors.grey.shade800,
                                fontWeight: FontWeight.bold,
                              ),
                    ),
                  ],
                ),
                subtitle: Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        inviteSteps.length >= 2
                            ? inviteSteps[1]
                            : "By sharing your code",
                        style:
                            Theme.of(context).primaryTextTheme.subhead.copyWith(
                                  color: Colors.grey.shade800,
                                ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            InkWell(
              child: DottedBorder(
                color: Colors.green,
                dashPattern: [6.0, 2.0],
                borderType: BorderType.RRect,
                padding: EdgeInsets.all(0.0),
                radius: Radius.circular(24.0),
                strokeWidth: 3.0,
                child: Container(
                  width: 240.0,
                  height: 42.0,
                  decoration: BoxDecoration(
                    color: Color.fromRGBO(255, 251, 174, 1),
                    borderRadius: BorderRadius.circular(24.0),
                  ),
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          refCode,
                          style:
                              Theme.of(context).primaryTextTheme.title.copyWith(
                                    color: Color.fromRGBO(70, 165, 12, 1),
                                    fontWeight: FontWeight.w800,
                                  ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.all(2.0),
                        child: Image.asset("images/Copy_Icon.png"),
                      ),
                    ],
                  ),
                ),
              ),
              onTap: () {
                _copyCode();
              },
            ),
            Padding(
              padding: EdgeInsets.only(
                  left: 32.0, right: 32.0, bottom: 16.0, top: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Padding(
                    padding: EdgeInsets.only(left: 8.0, right: 8.0),
                    child: IconButton(
                      padding: EdgeInsets.all(0.0),
                      iconSize: 48.0,
                      onPressed: () {
                        _shareNowWhatsApp();
                      },
                      icon: Image.asset(
                        "images/Whatsapp_Icon.png",
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.only(left: 8.0, right: 8.0),
                    child: IconButton(
                      padding: EdgeInsets.all(0.0),
                      iconSize: 48.0,
                      onPressed: () {
                        _copyCode();
                      },
                      icon: Image.asset(
                        "images/Copy_Icon.png",
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.only(left: 8.0, right: 8.0),
                    child: IconButton(
                      padding: EdgeInsets.all(0.0),
                      iconSize: 48.0,
                      onPressed: () {
                        _shareNowFacebook();
                      },
                      icon: Image.asset(
                        "images/FB_Icon_referal.png",
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.only(left: 8.0, right: 8.0),
                    child: IconButton(
                      padding: EdgeInsets.all(0.0),
                      iconSize: 48.0,
                      onPressed: () {
                        _shareNow();
                      },
                      icon: Image.asset(
                        "images/Share_Icon.png",
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.only(top: 16.0, bottom: 8.0, left: 16.0),
              child: ListTile(
                leading: Image.asset("images/Step3.png"),
                isThreeLine: true,
                title: Row(
                  children: <Widget>[
                    Text(
                      "STEP 3. ",
                      style: TextStyle(
                        color: Color.fromRGBO(255, 124, 19, 1),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      "Let Your Friend Play",
                      style:
                          Theme.of(context).primaryTextTheme.subhead.copyWith(
                                color: Colors.grey.shade800,
                                fontWeight: FontWeight.bold,
                              ),
                    ),
                  ],
                ),
                subtitle: Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        inviteSteps.length >= 3
                            ? inviteSteps[2]
                            : "Create a contest and invite friends to join by depositing a minimum of ${strings.rupee}100",
                        style:
                            Theme.of(context).primaryTextTheme.subhead.copyWith(
                                  color: Colors.grey.shade800,
                                ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.only(right: 24.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: <Widget>[
                  ColorButton(
                    color: Color.fromRGBO(10, 156, 218, 1),
                    child: Row(
                      children: <Widget>[
                        Padding(
                          padding: EdgeInsets.only(right: 4.0),
                          child: Image.asset(
                            "images/Contest_Icon_white.png",
                            height: 20.0,
                          ),
                        ),
                        Text(
                          "CREATE CONTEST",
                          style: Theme.of(context)
                              .primaryTextTheme
                              .subhead
                              .copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ],
                    ),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              ),
            ),
            // widget.data["bonusDistribution"] == null ||
            //         widget.data["bonusDistribution"]["referral"] == null ||
            //         widget.data["bonusDistribution"]["referred"] == null
            //     ? Container()
            //     : InkWell(
            //         child: Padding(
            //           padding: EdgeInsets.all(8.0),
            //           child: Row(
            //             children: <Widget>[
            //               Expanded(
            //                 child: Text(
            //                   "Click here for more info",
            //                   textAlign: TextAlign.center,
            //                   style: TextStyle(
            //                     color: Colors.blue,
            //                     decoration: TextDecoration.underline,
            //                   ),
            //                 ),
            //               ),
            //             ],
            //           ),
            //         ),
            //         onTap: () async {
            //           final result = await showDialog(
            //             context: context,
            //             builder: (BuildContext context) {
            //               return BonusDistribution(
            //                 amount: refAAmount,
            //                 bonusDistribution: widget.data["bonusDistribution"],
            //               );
            //             },
            //           );
            //         },
            //       ),
            // Padding(
            //   padding: EdgeInsets.all(8.0),
            //   child: Row(
            //     children: <Widget>[
            //       Expanded(
            //         child: Card(
            //           child: Column(
            //             children: <Widget>[
            //               Padding(
            //                 padding: EdgeInsets.only(
            //                     left: 32.0,
            //                     right: 32.0,
            //                     bottom: 24.0,
            //                     top: 16.0),
            //                 child: Row(
            //                   children: <Widget>[
            //                     Expanded(
            //                       child: Container(
            //                         height: 56.0,
            //                         child: ColorButton(
            //                           child: Row(
            //                             mainAxisAlignment:
            //                                 MainAxisAlignment.center,
            //                             children: <Widget>[
            //                               Padding(
            //                                 padding:
            //                                     EdgeInsets.only(right: 8.0),
            //                                 child: Icon(
            //                                   Icons.share,
            //                                   color: Colors.white,
            //                                 ),
            //                               ),
            //                               Text(
            //                                 "Share".toUpperCase(),
            //                                 style: Theme.of(context)
            //                                     .primaryTextTheme
            //                                     .headline
            //                                     .copyWith(
            //                                       color: Colors.white,
            //                                       fontWeight: FontWeight.w800,
            //                                     ),
            //                               ),
            //                             ],
            //                           ),
            //                           elevation: 0.0,
            //                           onPressed: () {
            //                             _shareNow();
            //                           },
            //                         ),
            //                       ),
            //                     ),
            //                   ],
            //                 ),
            //               ),
            //             ],
            //           ),
            //         ),
            //       ),
            //     ],
            //   ),
            // ),
            // Padding(
            //   padding: EdgeInsets.only(left: 16.0, top: 16.0, right: 16.0),
            //   child: Row(
            //     children: <Widget>[
            //       Expanded(
            //         child: Column(
            //           mainAxisAlignment: MainAxisAlignment.start,
            //           crossAxisAlignment: CrossAxisAlignment.start,
            //           children: <Widget>[
            //             Padding(
            //               padding: EdgeInsets.symmetric(vertical: 4.0),
            //               child: Text(
            //                 "Share and Earn ₹$refAAmount in three easy steps!",
            //                 style: Theme.of(context)
            //                     .primaryTextTheme
            //                     .title
            //                     .copyWith(
            //                       color: Colors.black,
            //                       fontWeight: FontWeight.w700,
            //                     ),
            //               ),
            //             ),
            //             Column(
            //               children: inviteSteps.map((step) {
            //                 return Padding(
            //                   padding: EdgeInsets.symmetric(vertical: 4.0),
            //                   child: Row(
            //                     children: <Widget>[
            //                       Expanded(
            //                         child: Padding(
            //                           padding: EdgeInsets.only(left: 8.0),
            //                           child: Text(
            //                             step,
            //                             style: Theme.of(context)
            //                                 .primaryTextTheme
            //                                 .body2
            //                                 .copyWith(
            //                                   color: Colors.black87,
            //                                 ),
            //                           ),
            //                         ),
            //                       ),
            //                     ],
            //                   ),
            //                 );
            //               }).toList(),
            //             ),
            //           ],
            //         ),
            //       ),
            //     ],
            //   ),
            // ),
          ],
        ),
      ),
    );
  }
}
