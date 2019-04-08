import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

import 'package:flutter_redux/flutter_redux.dart';
import 'package:playfantasy/redux/models/loader_model.dart';
import 'package:playfantasy/commonwidgets/loader/loader.dart';

class ScaffoldPage extends StatelessWidget {
  final Widget body;
  final Widget title;
  final Widget action;
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
                    )
              : appBar,
          body: body,
          backgroundColor: Colors.transparent,
          bottomNavigationBar: bottomNavigationBar,
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
