import 'package:flutter/material.dart';
import 'package:meta/meta.dart';

class AppConfig extends InheritedWidget {
  AppConfig({
    @required this.appName,
    @required this.channelId,
    @required this.apiBaseUrl,
    @required this.websocketUrl,
    @required Widget child,
  }) : super(child: child);

  final String appName;
  final String channelId;
  final String apiBaseUrl;
  final String websocketUrl;

  static AppConfig of(BuildContext context) {
    return context.inheritFromWidgetOfExactType(AppConfig);
  }

  @override
  bool updateShouldNotify(InheritedWidget oldWidget) => false;
}
