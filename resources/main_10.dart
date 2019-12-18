import 'package:playfantasy/providers/user.dart';
import 'package:provider/provider.dart';
import 'package:redux/redux.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'dart:io';
import 'package:playfantasy/appconfig.dart';
import 'package:playfantasy/splashscreen.dart';
import 'package:playfantasy/utils/httpmanager.dart';
import 'package:playfantasy/redux/reducers/loader.dart';
import 'package:playfantasy/redux/models/loader_model.dart';
import 'package:package_info/package_info.dart';

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
  WidgetsFlutterBinding.ensureInitialized();
  String channelId = "10";
  const apiBaseUrl = "https://stage.howzat.com";
  String fcmSubscribeId = 'channelId_' + channelId + '_news' + '_stage';

  PackageInfo packageInfo = await PackageInfo.fromPlatform();
  String appVersion = packageInfo.version.toString();
  bool isIos = Platform.isIOS;

  disableDeviceRotation();

  HttpManager.channelId = channelId;
  HttpManager.appVersion = appVersion;
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
    appVersion: appVersion,
    isIos: isIos,
    carouselSlideTime: Duration(seconds: 10),
    child: StoreProvider(
      store: store,
      child: MultiProvider(
        providers: [
          ChangeNotifierProvider<User>.value(
            value: User(),
          ),
        ],
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
    ),
  );

  runApp(configuredApp);
}
