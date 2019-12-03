import 'package:flutter/cupertino.dart';

class FantasyPageRoute extends CupertinoPageRoute {
  final bool fullscreenDialog;
  final WidgetBuilder pageBuilder;
  final RouteSettings routeSettings;
  FantasyPageRoute({this.pageBuilder, this.fullscreenDialog = false,this.routeSettings})
      : super(builder: pageBuilder, fullscreenDialog: fullscreenDialog,settings:routeSettings);

  @override
  Duration get transitionDuration => const Duration(milliseconds: 425);
}
