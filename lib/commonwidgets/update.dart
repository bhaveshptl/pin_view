import 'dart:io';
import 'package:flutter/material.dart';
import 'package:permission/permission.dart';
import 'package:path_provider/path_provider.dart';
import 'package:android_intent/android_intent.dart';
import 'package:flutter_downloader/flutter_downloader.dart';

import 'package:playfantasy/utils/stringtable.dart';

class DownloadAPK extends StatefulWidget {
  final String url;
  final bool isForceUpdate;

  DownloadAPK({
    this.url,
    this.isForceUpdate = false,
  });

  @override
  DownloadAPKState createState() => DownloadAPKState();
}

class DownloadAPKState extends State<DownloadAPK> {
  var taskId;
  int downloadProgress = 0;
  bool bIsAPKInstallationAvailable = false;
  PermissionStatus permissionStatus = PermissionStatus.allow;

  @override
  void initState() {
    super.initState();
    checkForPermission();
  }

  checkForPermission() async {
    List<Permissions> permissions =
        await Permission.getPermissionStatus([PermissionName.Storage]);
    setState(() {
      permissionStatus = permissions[0].permissionStatus;
    });
    if (permissions[0].permissionStatus == PermissionStatus.allow) {
      startDownload();
    } else {
      askForPermission();
    }
  }

  askForPermission() async {
    final result =
        await Permission.requestSinglePermission(PermissionName.Storage);
    if (result != null) {
      setState(() {
        permissionStatus = result;
      });
      if (permissionStatus == PermissionStatus.allow) {
        startDownload();
      }
    }
  }

  startDownload() async {
    Directory appDocDir = await getExternalStorageDirectory();
    String appDocPath = appDocDir.path;

    taskId = await FlutterDownloader.enqueue(
      url: widget.url,
      savedDir: appDocPath,
      showNotification: true,
      fileName: "playfantasy.apk",
    );

    FlutterDownloader.registerCallback(
        (String id, DownloadTaskStatus status, int progress) {
      if (id == taskId) {
        setState(() {
          downloadProgress = progress;
        });
        if (status == DownloadTaskStatus.complete) {
          setState(() {
            bIsAPKInstallationAvailable = true;
          });
        }
      }
    });
  }

  installAPK() async {
    if (taskId != null) {
      FlutterDownloader.open(taskId: taskId);
    } else {
      Directory appDocDir = await getExternalStorageDirectory();
      String fileUrl = appDocDir.path + "/playfantasy.apk";
      AndroidIntent(
              action: "action_view",
              fileUrl: fileUrl,
              mimeType: "application/vnd.android.package-archive")
          .openFile();
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: widget.isForceUpdate
          ? () => Future.value(false)
          : () => Future.value(true),
      child: permissionStatus == PermissionStatus.allow
          ? AlertDialog(
              title: Text("Downloading..."),
              titlePadding: EdgeInsets.fromLTRB(24.0, 24.0, 24.0, 0.0),
              contentPadding: EdgeInsets.fromLTRB(24.0, 24.0, 24.0, 0.0),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Padding(
                    padding: EdgeInsets.only(bottom: 8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        CircleAvatar(
                          maxRadius: 32.0,
                          child: Icon(
                            Icons.file_download,
                            size: 48.0,
                            color: Colors.white70,
                          ),
                        ),
                        Expanded(
                          child: Padding(
                            padding: EdgeInsets.only(left: 16.0),
                            child: Column(
                              children: <Widget>[
                                Padding(
                                  padding: EdgeInsets.only(bottom: 8.0),
                                  child: Row(
                                    children: <Widget>[
                                      Text(
                                        downloadProgress.toString() + "%",
                                      ),
                                    ],
                                  ),
                                ),
                                LinearProgressIndicator(
                                  value: (downloadProgress / 100),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              actions: <Widget>[
                !widget.isForceUpdate
                    ? FlatButton(
                        child: Text(
                          strings.get("CANCEL").toUpperCase(),
                        ),
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                      )
                    : Container(),
                FlatButton(
                  child: Text(
                    "Install".toUpperCase(),
                  ),
                  onPressed: bIsAPKInstallationAvailable
                      ? () {
                          installAPK();
                          Navigator.of(context).pop();
                        }
                      : null,
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
