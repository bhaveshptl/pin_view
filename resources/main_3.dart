import 'package:redux/redux.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_redux/flutter_redux.dart';

import 'package:playfantasy/appconfig.dart';
import 'package:playfantasy/splashscreen.dart';
import 'package:playfantasy/utils/httpmanager.dart';
import 'package:playfantasy/redux/reducers/loader.dart';
import 'package:playfantasy/redux/models/loader_model.dart';

disableDeviceRotation() {
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
}

ThemeData _buildLightTheme() {
  const Color primaryColor = Color(0xFF0E4F87);
  const Color secondaryColor = Color(0xFF244f83);
  final ColorScheme colorScheme = const ColorScheme.light().copyWith(
    primary: primaryColor,
    secondary: secondaryColor,
  );
  final ThemeData base = ThemeData.light();
  return base.copyWith(
    colorScheme: colorScheme,
    primaryColor: primaryColor,
    primaryColorDark: secondaryColor,
    buttonColor: primaryColor,
    indicatorColor: Colors.white,
    splashColor: Colors.white24,
    splashFactory: InkRipple.splashFactory,
    accentColor: secondaryColor,
    canvasColor: Colors.white,
    scaffoldBackgroundColor: Colors.white,
    backgroundColor: Colors.white,
    errorColor: const Color(0xFFB00020),
  );
}

///
/// Bootstraping APP.
///
void main() async {
  String channelId = "3";
  const apiBaseUrl = "https://stg.playfantasy.com";
  String fcmSubscribeId = 'channelId_' + channelId + '_news' + '_stage';

  disableDeviceRotation();

  HttpManager.channelId = channelId;
  final store = Store<LoaderModel>(
    showLoader,
    initialState: LoaderModel(isLoading: false),
  );

  var configuredApp = AppConfig(
    store: store,
    appName: 'PlayFantasy',
    channelId: channelId,
    showBackground: true,
    apiBaseUrl: apiBaseUrl,
    carouselSlideTime: Duration(seconds: 5),
    child: StoreProvider(
      store: store,
      child: MaterialApp(
        home: SplashScreen(
          apiBaseUrl: apiBaseUrl,
          channelId: channelId,
          fcmSubscribeId: fcmSubscribeId,
        ),
        theme: _buildLightTheme(),
      ),
    ),
  );

  runApp(configuredApp);
}
