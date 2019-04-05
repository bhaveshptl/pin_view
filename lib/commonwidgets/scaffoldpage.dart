import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

import 'package:flutter_redux/flutter_redux.dart';
import 'package:playfantasy/redux/models/loader_model.dart';
import 'package:playfantasy/commonwidgets/loader/loader.dart';

class ScaffoldPage extends StatelessWidget {
  final Widget body;
  final Widget title;
  final Widget action;
  final AppBar appBar;
  final GlobalKey scaffoldKey;
  final Widget floatingActionButton;
  final Color backgroundColor;

  ScaffoldPage({
    this.scaffoldKey,
    this.body,
    this.title,
    this.action,
    this.appBar,
    this.backgroundColor,
    this.floatingActionButton,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
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
        ),
        StoreConnector<LoaderModel, LoaderModel>(
            converter: (store) => store.state,
            builder: (context, loader) {
              return Stack(
                children: <Widget>[
                  (loader.isLoading ? LoaderWidget() : Container()),
                ],
              );
            })
      ],
    );
  }
}