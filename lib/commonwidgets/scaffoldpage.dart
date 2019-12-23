import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

import 'package:flutter_redux/flutter_redux.dart';
import 'package:playfantasy/commonwidgets/leadingbutton.dart';
import 'package:playfantasy/redux/models/loader_model.dart';
import 'package:playfantasy/commonwidgets/loader/loader.dart';

class ScaffoldPage extends StatelessWidget {
  final Widget body;
  final Widget title;
  final Widget action;
  final Widget endDrawer;
  final Widget bottomSheet;
  final GlobalKey scaffoldKey;
  final Color backgroundColor;
  final Widget bottomNavigationBar;
  final PreferredSizeWidget appBar;
  final Widget floatingActionButton;

  ScaffoldPage({
    this.body,
    this.title,
    this.action,
    this.appBar,
    this.endDrawer,
    this.bottomSheet,
    this.scaffoldKey,
    this.backgroundColor,
    this.bottomNavigationBar,
    this.floatingActionButton,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.bottomCenter,
      children: <Widget>[
        Container(
          color: backgroundColor ?? Color.fromRGBO(237, 237, 237, 1),
        ),
        Scaffold(
          key: scaffoldKey,
          appBar: appBar == null
              ? title == null
                  ? null
                  : AppBar(
                      title: title,
                      actions: <Widget>[
                        action,
                      ],
                      leading: LeadingButton(),
                      titleSpacing: 0.0,
                    )
              : appBar,
          body: body,
          endDrawer: endDrawer,
          bottomSheet: bottomSheet,
          backgroundColor: Colors.transparent,
          bottomNavigationBar: bottomNavigationBar,
          floatingActionButton: floatingActionButton,
        ),
        StoreConnector<LoaderModel, LoaderModel>(
          converter: (store) => store.state,
          builder: (context, loader) {
            return Stack(
              children: <Widget>[
                (loader.isLoading ? LoaderWidget() : Container()),
              ],
            );
          },
        ),
      ],
    );
  }
}
