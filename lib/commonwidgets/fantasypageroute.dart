import 'package:flutter/cupertino.dart';

class FantasyPageRoute extends CupertinoPageRoute {
  final bool fullscreenDialog;
  final WidgetBuilder pageBuilder;
  FantasyPageRoute({this.pageBuilder, this.fullscreenDialog = false})
      : super(builder: pageBuilder, fullscreenDialog: fullscreenDialog);

  @override
  Duration get transitionDuration => const Duration(milliseconds: 425);
}
