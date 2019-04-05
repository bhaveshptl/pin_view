import 'package:redux/redux.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_redux/flutter_redux.dart';

import 'package:playfantasy/routes.dart';
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

///
/// Bootstraping APP.
///
void main() async {
  String channelId = "10";
  const apiBaseUrl = "https://www.playfantasy.com";
  String fcmSubscribeId = 'channelId_' + channelId + '_news' + '_prod';

  disableDeviceRotation();

  HttpManager.channelId = channelId;
  final store = Store<LoaderModel>(
    showLoader,
    initialState: LoaderModel(isLoading: false),
  );

  var configuredApp = AppConfig(
    store: store,
    appName: 'Howzat',
    channelId: channelId,
    showBackground: false,
    apiBaseUrl: apiBaseUrl,
    carouselSlideTime: Duration(seconds: 10),
    child: StoreProvider(
      store: store,
      child: MaterialApp(
        home: SplashScreen(
          apiBaseUrl: apiBaseUrl,
          channelId: channelId,
          fcmSubscribeId: fcmSubscribeId,
        ),
        routes: FantasyRoutes().getRoutes(),
        theme: ThemeData(
          fontFamily: 'Muli',
          primaryColor: Color.fromRGBO(97, 6, 0, 1),
          primaryColorLight: Color.fromRGBO(148, 56, 42, 1),
          primaryColorDark: Color.fromRGBO(57, 0, 0, 1),
          accentColor: Color.fromRGBO(211, 37, 24, 1),
        ),
      ),
    ),
  );

  runApp(configuredApp);
}
