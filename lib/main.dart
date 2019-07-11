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

///
/// Bootstraping APP.
///
void main() async {
  String channelId = "10";
  const apiBaseUrl = "https://beta.howzat.com";
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
    disableBranchIOAttribution: false,
    privateAttributionName: "",
    apiBaseUrl: apiBaseUrl,
    carouselSlideTime: Duration(seconds: 10),
    child: StoreProvider(
      store: store,
      child: MaterialApp(
        builder: (context, child) {
          return MediaQuery(
            child: child,
            data: MediaQuery.of(context).copyWith(textScaleFactor: 0.8),
          );
        },
        home: SplashScreen(
          apiBaseUrl: apiBaseUrl,
          channelId: channelId,
          fcmSubscribeId: fcmSubscribeId,
        ),
        theme: ThemeData(
          primaryColor: Color.fromRGBO(134, 16, 14, 1),
          primaryColorLight: Color.fromRGBO(188, 69, 53, 1),
          primaryColorDark: Color.fromRGBO(84, 0, 0, 1),
          accentColor: Color.fromRGBO(211, 37, 24, 1),
        ),
      ),
    ),
  );

  runApp(configuredApp);
}
