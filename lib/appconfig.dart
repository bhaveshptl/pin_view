import 'package:flutter/material.dart';
import 'package:meta/meta.dart';
import 'package:redux/redux.dart';

class AppConfig extends InheritedWidget {
  AppConfig({
    @required this.store,
    @required Widget child,
    @required this.appName,
    @required this.channelId,
    @required this.apiBaseUrl,
    @required this.showBackground,
    @required Duration carouselSlideTime,
  }) : super(child: child);

  final Store store;
  final String appName;
  final String channelId;
  final String apiBaseUrl;
  final bool showBackground;
  final Duration carouselSlideTime = Duration(seconds: 5);

  static AppConfig of(BuildContext context) {
    return context.inheritFromWidgetOfExactType(AppConfig);
  }

  @override
  bool updateShouldNotify(InheritedWidget oldWidget) => false;
}
