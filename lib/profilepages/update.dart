import 'dart:io';
import 'package:flutter/material.dart';
import 'package:package_info/package_info.dart';
// import 'package:permission/permission.dart';
import 'package:path_provider/path_provider.dart';
// import 'package:android_intent/android_intent.dart';
// import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:playfantasy/appconfig.dart';
import 'package:playfantasy/commonwidgets/color_button.dart';

import 'package:playfantasy/utils/stringtable.dart';

class DownloadAPK extends StatefulWidget {
  final String url;
  final bool isForceUpdate;
  final List<dynamic> logs;

  DownloadAPK({
    this.url,
    this.logs,
    this.isForceUpdate = false,
  });

  @override
  DownloadAPKState createState() => DownloadAPKState();
}

class DownloadAPKState extends State<DownloadAPK> {
  var taskId;
  bool bShowCancelButton;
  int downloadProgress = 0;
  bool downloadStarted = false;
  bool bIsAPKInstallationAvailable = false;
  // PermissionStatus permissionStatus = PermissionStatus.allow;

  @override
  void initState() {
    super.initState();
    checkForPermission();
    bShowCancelButton = !widget.isForceUpdate;
    if (widget.logs == null) {
      startDownload();
    }
  }

  checkForPermission() async {
    // List<Permissions> permissions =
    //     await Permission.getPermissionStatus([PermissionName.WriteStorage]);
    // setState(() {
    //   permissionStatus = permissions[0].permissionStatus;
    // });
    // if (permissions[0].permissionStatus != PermissionStatus.allow) {
    //   askForPermission();
    // }
  }

  askForPermission() async {
    // final result =
    //     await Permission.requestSinglePermission(PermissionName.WriteStorage);
    // if (result != null) {
    //   setState(() {
    //     permissionStatus = result;
    //   });
    // }
  }

  startDownload() async {
    setState(() {
      downloadStarted = true;
    });
    Directory appDocDir = await getExternalStorageDirectory();
    String appDocPath = appDocDir.path;

    // taskId = await FlutterDownloader.enqueue(
    //   url: widget.url,
    //   savedDir: appDocPath,
    //   showNotification: true,
    //   fileName: AppConfig.of(context).appName + ".apk",
    // );

    // FlutterDownloader.registerCallback(
    //     (String id, DownloadTaskStatus status, int progress) {
    //   if (id == taskId) {
    //     setState(() {
    //       downloadProgress = progress;
    //     });
    //     if (status == DownloadTaskStatus.complete) {
    //       setState(() {
    //         bIsAPKInstallationAvailable = true;
    //       });
    //     }
    //   }
    // });
  }

  installAPK() async {
    if (taskId != null) {
      // FlutterDownloader.open(taskId: taskId);
    } else {
      PackageInfo packageInfo = await PackageInfo.fromPlatform();
      Directory appDocDir = await getExternalStorageDirectory();
      String fileUrl =
          appDocDir.path + "/" + AppConfig.of(context).appName + ".apk";
      // AndroidIntent(
      //         action: "action_view",
      //         fileUrl: fileUrl,
      //         package: packageInfo.packageName,
      //         mimeType: "application/vnd.android.package-archive")
      //     .openFile();
    }
  }

  @override
  Widget build(BuildContext context) {
    bool bteur = true;
    return WillPopScope(
      onWillPop: widget.isForceUpdate
          ? () => Future.value(false)
          : () => Future.value(true),
      child: bteur // permissionStatus == PermissionStatus.allow
          ? SimpleDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6.0),
              ),
              children: <Widget>[
                SingleChildScrollView(
                  child: Container(
                    padding: EdgeInsets.all(32.0),
                    width: MediaQuery.of(context).size.width,
                    child: Column(
                      children: <Widget>[
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: <Widget>[
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(5.0),
                                  child: Image.asset(
                                    "images/logo.png",
                                    height: 64.0,
                                  ),
                                ),
                                Padding(
                                  padding: EdgeInsets.only(left: 8.0),
                                  child: Image.asset(
                                    "images/logo_name_white.png",
                                    color: Colors.black,
                                    height: 32.0,
                                  ),
                                ),
                              ],
                            ),
                            Padding(
                              padding: EdgeInsets.symmetric(vertical: 16.0),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: <Widget>[
                                  Expanded(
                                    child: Text(
                                      "We are upgrading!",
                                      style: Theme.of(context)
                                          .primaryTextTheme
                                          .headline
                                          .copyWith(
                                            color: Colors.black,
                                            fontWeight: FontWeight.bold,
                                          ),
                                      textAlign: TextAlign.center,
                                    ),
                                  )
                                ],
                              ),
                            ),
                            downloadStarted
                                ? Padding(
                                    padding:
                                        EdgeInsets.only(left: 8.0, right: 8.0),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: <Widget>[
                                        CircleAvatar(
                                          maxRadius: 32.0,
                                          backgroundColor:
                                              Color.fromRGBO(70, 165, 12, 1),
                                          child: Icon(
                                            Icons.file_download,
                                            size: 48.0,
                                            color: Colors.white70,
                                          ),
                                        ),
                                        Expanded(
                                          child: Padding(
                                            padding:
                                                EdgeInsets.only(left: 16.0),
                                            child: Column(
                                              children: <Widget>[
                                                Padding(
                                                  padding: EdgeInsets.only(
                                                      bottom: 8.0),
                                                  child: Row(
                                                    children: <Widget>[
                                                      Text(
                                                        downloadProgress
                                                                .toString() +
                                                            "%",
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                LinearProgressIndicator(
                                                  backgroundColor:
                                                      Colors.black12,
                                                  valueColor:
                                                      AlwaysStoppedAnimation<
                                                          Color>(Colors.green),
                                                  value:
                                                      (downloadProgress / 100),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                : Padding(
                                    padding: EdgeInsets.only(top: 8.0),
                                    child: Column(
                                      children: widget.logs.map((text) {
                                        return Container(
                                          padding: EdgeInsets.only(bottom: 8.0),
                                          child: Row(
                                            children: <Widget>[
                                              Expanded(
                                                child: Row(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: <Widget>[
                                                    Padding(
                                                      padding: EdgeInsets.only(
                                                          right: 8.0, top: 3.0),
                                                      child: Container(
                                                        height: 6.0,
                                                        width: 6.0,
                                                        decoration:
                                                            BoxDecoration(
                                                          color: Colors.black45,
                                                          shape:
                                                              BoxShape.circle,
                                                        ),
                                                      ),
                                                    ),
                                                    Expanded(
                                                      child: Text(
                                                        text,
                                                        style: Theme.of(context)
                                                            .primaryTextTheme
                                                            .subhead
                                                            .copyWith(
                                                              color:
                                                                  Colors.black,
                                                            ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                  ),
                          ],
                        ),
                        Padding(
                          padding: EdgeInsets.only(top: 32.0),
                          child: Row(
                            children: <Widget>[
                              bShowCancelButton
                                  ? Expanded(
                                      child: Container(
                                        height: 56.0,
                                        padding: EdgeInsets.all(4.0),
                                        child: ColorButton(
                                          child: Text(
                                            strings.get("CANCEL").toUpperCase(),
                                            style: Theme.of(context)
                                                .primaryTextTheme
                                                .body2
                                                .copyWith(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.w800,
                                                ),
                                          ),
                                          onPressed: () {
                                            Navigator.of(context).pop();
                                          },
                                        ),
                                      ),
                                    )
                                  : Container(),
                              Expanded(
                                child: Container(
                                  height: 56.0,
                                  padding: EdgeInsets.all(4.0),
                                  child: ColorButton(
                                    elevation: 0.0,
                                    color: Colors.orange.shade500,
                                    child: Text(
                                      bIsAPKInstallationAvailable
                                          ? "Install".toUpperCase()
                                          : "Update now".toUpperCase(),
                                      style: Theme.of(context)
                                          .primaryTextTheme
                                          .body2
                                          .copyWith(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w800,
                                          ),
                                    ),
                                    onPressed: downloadStarted &&
                                            !bIsAPKInstallationAvailable
                                        ? null
                                        : (bIsAPKInstallationAvailable
                                            ? () {
                                                installAPK();
                                              }
                                            : () {
                                                setState(() {
                                                  bShowCancelButton = false;
                                                });
                                                startDownload();
                                              }),
                                  ),
                                ),
                              )
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              ],
            )
          : AlertDialog(
              title: Text("Download update"),
              titlePadding: EdgeInsets.fromLTRB(24.0, 24.0, 24.0, 0.0),
              contentPadding: EdgeInsets.fromLTRB(24.0, 24.0, 24.0, 0.0),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: Text(
                            "Please allow storage permission to download an update."),
                      ),
                    ],
                  )
                ],
              ),
              actions: <Widget>[
                FlatButton(
                  child: Text(
                    "Give permission".toUpperCase(),
                  ),
                  onPressed: () {
                    askForPermission();
                  },
                ),
              ],
            ),
    );
  }
}
