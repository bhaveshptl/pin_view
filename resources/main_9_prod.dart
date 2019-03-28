import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:playfantasy/routes.dart';
import 'package:playfantasy/appconfig.dart';
import 'package:playfantasy/splashscreen.dart';
import 'package:playfantasy/utils/httpmanager.dart';

disableDeviceRotation() {
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
}

///
/// Bootstraping APP.
///
void main() async {
  String channelId = "10";
  const apiBaseUrl = "https://www.playfantasy.com";

  disableDeviceRotation();

  HttpManager.channelId = channelId;
  var configuredApp = AppConfig(
    appName: 'Smart11',
    channelId: channelId,
    showBackground: true,
    apiBaseUrl: apiBaseUrl,
    child: MaterialApp(
      home: SplashScreen(
        apiBaseUrl: apiBaseUrl,
        channelId: channelId,
      ),
      routes: FantasyRoutes().getRoutes(),
      theme: ThemeData(
        primaryColor: Color.fromRGBO(97, 6, 0, 1),
        primaryColorLight: Color.fromRGBO(148, 56, 42, 1),
        primaryColorDark: Color.fromRGBO(57, 0, 0, 1),
      ),
    ),
  );

  runApp(configuredApp);
}
