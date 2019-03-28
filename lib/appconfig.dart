import 'package:flutter/material.dart';
import 'package:meta/meta.dart';

class AppConfig extends InheritedWidget {
  AppConfig({
    @required this.appName,
    @required this.channelId,
    @required this.apiBaseUrl,
    @required this.showBackground,
    @required Widget child,
  }) : super(child: child);

  final String appName;
  final String channelId;
  final String apiBaseUrl;
  final bool showBackground;

  static AppConfig of(BuildContext context) {
    return context.inheritFromWidgetOfExactType(AppConfig);
  }

  @override
  bool updateShouldNotify(InheritedWidget oldWidget) => false;
}
