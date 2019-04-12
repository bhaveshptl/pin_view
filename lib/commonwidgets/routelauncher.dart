import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:package_info/package_info.dart';

import 'package:playfantasy/appconfig.dart';
import 'package:playfantasy/modal/deposit.dart';
import 'package:playfantasy/modal/l1.dart';
import 'package:playfantasy/modal/myteam.dart';
import 'package:playfantasy/utils/apiutil.dart';
import 'package:playfantasy/deposit/addcash.dart';
import 'package:playfantasy/earncash/earncash.dart';
import 'package:playfantasy/utils/httpmanager.dart';
import 'package:playfantasy/utils/stringtable.dart';
import 'package:playfantasy/withdraw/withdraw.dart';
import 'package:playfantasy/profilepages/update.dart';
import 'package:playfantasy/profilepages/statedob.dart';
import 'package:playfantasy/profilepages/myprofile.dart';
import 'package:playfantasy/profilepages/myaccount.dart';
import 'package:playfantasy/utils/joincontesterror.dart';
import 'package:playfantasy/deposit/transactionsuccess.dart';
import 'package:playfantasy/commonwidgets/fantasypageroute.dart';

RouteLauncher routeLauncher = new RouteLauncher();

class RouteLauncher {
  RouteLauncher._internal();
  factory RouteLauncher() => RouteLauncher._internal();

  launchAddCash(BuildContext context,
      {Function onSuccess, Function onFailed, Function onComplete}) async {
    Deposit depositData = await getDepositInfo(context);
    if (depositData != null) {
      final result = await Navigator.of(context).push(
        FantasyPageRoute(
          pageBuilder: (context) => AddCash(
                depositData: depositData,
              ),
        ),
      );
      if (result != null) {
        if (onSuccess == null) {
          routeLauncher.showTransactionResult(context, json.decode(result));
        } else {
          onSuccess(result);
        }
      }
    }
    if (onComplete != null) {
      onComplete();
    }
  }

  showTransactionResult(
      BuildContext context, Map<String, dynamic> transactionResult) {
    if (transactionResult["authStatus"] == "Authorised") {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return TransactionSuccess(transactionResult, () {
            Navigator.of(context).pop();
          });
        },
      );
    }
  }

  getDepositInfo(BuildContext context) async {
    http.Request req = http.Request(
      "GET",
      Uri.parse(
        BaseUrl().apiUrl + ApiUtil.DEPOSIT_INFO,
      ),
    );
    return await HttpManager(http.Client()).sendRequest(req).then(
      (http.Response res) {
        if (res.statusCode >= 200 && res.statusCode <= 299) {
          return Deposit.fromJson(
            json.decode(res.body),
          );
        } else if (res.statusCode >= 400 && res.statusCode <= 499) {
          JoinContestError error =
              JoinContestError(json.decode(res.body)["error"]);
          if (error.isBlockedUser()) {
            showJoinContestError(
              context: context,
              title: error.getTitle(),
              message: error.getErrorMessage(),
            );
          }
          return null;
        }
      },
    );
  }

  launchBannerRoute({
    Map<String, dynamic> banner,
    GlobalKey<ScaffoldState> scaffoldKey,
    Function onComplete,
    BuildContext context,
  }) async {
    switch (banner["CTA"]) {
      case "DEPOSIT":
        launchAddCash(scaffoldKey.currentContext, onComplete: onComplete);
        break;
      case "REFERRAL":
        launchEarnCash(scaffoldKey, onComplete: onComplete);
        break;
      case "WITHDRAW":
        launchWithdraw(scaffoldKey, onComplete: onComplete);
        break;
      case "NA":
        onComplete();
        break;
      case "PROFILE":
        launchMyProfile(context, onComplete: onComplete);
        break;
      case "UPDATE":
        _performUpdateCheck(context, onComplete: onComplete);
        break;
      default:
    }
  }

  _performUpdateCheck(BuildContext context, {Function onComplete}) async {
    PackageInfo _packageInfo = await PackageInfo.fromPlatform();
    _showUpdateDialog(context);

    http.Request req = http.Request(
        "POST", Uri.parse(BaseUrl().apiUrl + ApiUtil.CHECK_APP_UPDATE));
    req.body = json.encode({
      "version": double.parse(_packageInfo.version),
      "channelId": AppConfig.of(context).channelId,
    });
    await HttpManager(http.Client()).sendRequest(req).then((http.Response res) {
      if (res.statusCode >= 200 && res.statusCode <= 299) {
        Navigator.of(context).pop();
        Map<String, dynamic> response = json.decode(res.body);
        if (response["update"]) {
          _showUpdatingAppDialog(
              response["updateUrl"], response["isForceUpdate"],
              logs: response["updateLogs"],
              context: context,
              onComplete: onComplete);
        } else {
          _showAppUptoDateDialog(context);
          if (onComplete != null) {
            onComplete();
          }
        }
      }
    });
  }

  _showUpdateDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Row(
                children: <Widget>[
                  CircularProgressIndicator(),
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(left: 16.0),
                      child: Text("Checking for an update..."),
                    ),
                  ),
                ],
              )
            ],
          ),
        );
      },
    );
  }

  _showUpdatingAppDialog(String url, bool bIsForceUpdate,
      {List<dynamic> logs, BuildContext context, Function onComplete}) async {
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return DownloadAPK(
          url: url,
          logs: logs,
          isForceUpdate: bIsForceUpdate,
        );
      },
      barrierDismissible: false,
    );
    if (onComplete != null) {
      onComplete();
    }
  }

  _showAppUptoDateDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Icon(
                    Icons.update,
                    size: 48.0,
                  ),
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(left: 16.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: <Widget>[
                          Text("App is running on latest version"),
                        ],
                      ),
                    ),
                  ),
                ],
              )
            ],
          ),
          contentPadding: EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 0.0),
          actions: <Widget>[
            FlatButton(
              child: Text(strings.get("OK").toUpperCase()),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  launchWithdraw(GlobalKey<ScaffoldState> _scaffoldKey,
      {Function onComplete}) async {
    http.Request req = http.Request(
      "GET",
      Uri.parse(
        BaseUrl().apiUrl + ApiUtil.AUTH_WITHDRAW,
      ),
    );
    return HttpManager(http.Client()).sendRequest(req).then(
      (http.Response res) {
        if (res.statusCode >= 200 && res.statusCode <= 299) {
          Map<String, dynamic> response = json.decode(res.body);
          showWithdraw(_scaffoldKey.currentContext, response);
        } else if (res.statusCode == 401) {
          Map<String, dynamic> response = json.decode(res.body);

          if (response["error"].length > 0) {
            JoinContestError error = JoinContestError(response["error"]);
            if (error.isBlockedUser()) {
              showJoinContestError(
                title: error.getTitle(),
                message: error.getErrorMessage(),
                context: _scaffoldKey.currentContext,
              );
            } else {
              int errorCode = error.getErrorCode();
              switch (errorCode) {
                case 3:
                  showDialog(
                    context: _scaffoldKey.currentContext,
                    builder: (BuildContext context) {
                      return StateDob(
                        onSuccess: (String msg) {
                          _scaffoldKey.currentState.showSnackBar(SnackBar(
                            content: Text(msg),
                          ));
                          launchWithdraw(_scaffoldKey);
                        },
                      );
                    },
                  );
                  break;
                case 6:
                case -1:
                  showWithdraw(_scaffoldKey.currentContext, response["data"]);
                  break;
              }
            }
          }
        }
        if (onComplete != null) {
          onComplete();
        }
      },
    );
  }

  launchMyProfile(BuildContext context, {Function onComplete}) async {
    await Navigator.of(context).push(
      FantasyPageRoute(
        pageBuilder: (context) => MyProfile(),
      ),
    );
    if (onComplete != null) {
      onComplete();
    }
  }

  showWithdraw(BuildContext context, Map<String, dynamic> response) {
    Navigator.of(context).push(
      FantasyPageRoute(
        pageBuilder: (context) => Withdraw(
              data: response,
            ),
      ),
    );
  }

  showJoinContestError(
      {@required BuildContext context, String title, String message}) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: <Widget>[
            FlatButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                strings.get("OK").toUpperCase(),
              ),
            )
          ],
        );
      },
    );
  }

  launchEarnCash(GlobalKey<ScaffoldState> scaffoldKey,
      {Function onComplete}) async {
    Map<String, dynamic> response = await getEarnCashData(scaffoldKey);
    if (onComplete != null) {
      onComplete();
    }
    if (response != null) {
      await Navigator.of(scaffoldKey.currentContext).push(
        FantasyPageRoute(
          pageBuilder: (context) => EarnCash(
                data: response,
              ),
        ),
      );
    }
  }

  getEarnCashData(GlobalKey<ScaffoldState> scaffoldKey) async {
    http.Request req = http.Request(
      "GET",
      Uri.parse(
        BaseUrl().apiUrl + ApiUtil.GET_REFERRAL_CODE,
      ),
    );
    return HttpManager(http.Client()).sendRequest(req).then(
      (http.Response res) {
        if (res.statusCode >= 200 && res.statusCode <= 299) {
          return json.decode(res.body);
        } else {
          showMessage(scaffoldKey.currentState,
              "Something went wrong. Please try again later.");
          return null;
        }
      },
    );
  }

  showMessage(ScaffoldState currentState, String msg) {
    currentState.showSnackBar(
      SnackBar(
        content: Text(msg),
      ),
    );
  }

  launchAccounts(GlobalKey<ScaffoldState> scaffoldKey,
      {Function onComplete}) async {
    Map<String, dynamic> data =
        await getAccountData(currentState: scaffoldKey.currentState);
    if (data != null) {
      Navigator.of(scaffoldKey.currentContext).push(
        FantasyPageRoute(
          pageBuilder: (context) => MyAccount(
                accountData: data,
              ),
        ),
      );
    }
    if (onComplete != null) {
      onComplete();
    }
  }

  getAccountData({ScaffoldState currentState}) async {
    http.Request req = http.Request(
      "GET",
      Uri.parse(
        BaseUrl().apiUrl + ApiUtil.GET_ACCOUNT_DETAILS,
      ),
    );
    return HttpManager(http.Client()).sendRequest(req).then(
      (http.Response res) {
        if (res.statusCode >= 200 && res.statusCode <= 299) {
          return json.decode(res.body);
        } else if (res.statusCode >= 400 &&
            res.statusCode <= 499 &&
            currentState != null) {
          showMessage(
              currentState, "Something went wrong. Please try again later.");
          return null;
        }
      },
    );
  }

  getPrizeStructure(Contest contest) async {
    http.Request req = http.Request(
      "GET",
      Uri.parse(BaseUrl().apiUrl +
          ApiUtil.GET_PRIZESTRUCTURE +
          contest.id.toString() +
          "/prizestructure"),
    );
    return HttpManager(http.Client()).sendRequest(req).then(
      (http.Response res) {
        if (res.statusCode >= 200 && res.statusCode <= 299) {
          return json.decode(res.body);
        } else {
          return Future.value(null);
        }
      },
    );
  }

  getTeamPlayers({int contestId, int teamId}) async {
    http.Request req = http.Request(
      "GET",
      Uri.parse(
        BaseUrl().apiUrl +
            ApiUtil.GET_TEAM_INFO +
            contestId.toString() +
            "/teams/" +
            teamId.toString(),
      ),
    );
    return HttpManager(http.Client())
        .sendRequest(req)
        .then((http.Response res) {
      if (res.statusCode >= 200 && res.statusCode <= 299) {
        Map<String, dynamic> response = json.decode(res.body);
        response["id"] = response["id"] == null ? teamId : response["id"];
        return MyTeam.fromJson(response);
      } else {
        return null;
      }
    });
  }
}
