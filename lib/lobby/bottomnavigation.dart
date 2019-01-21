import 'package:flutter/material.dart';
import 'package:playfantasy/utils/stringtable.dart';

class LobbyBottomNavigation extends StatelessWidget {
  final int _screenIndex;
  final Function onNavigationSelectionChange;

  LobbyBottomNavigation(this.onNavigationSelectionChange, this._screenIndex);

  void onTabTapped(BuildContext context, int index) {
    onNavigationSelectionChange(context, index);
  }

  getNavigationItems() {
    List<BottomNavigationBarItem> items = [];
    items.add(BottomNavigationBarItem(
      icon: Image.asset(
        "images/mycontests_icon3.png",
        height: 24.0,
      ),
      title: Text(
        strings.get("MY_CONTESTS"),
        textAlign: TextAlign.center,
        maxLines: 2,
      ),
    ));
    items.add(BottomNavigationBarItem(
      icon: Icon(
        Icons.account_balance_wallet,
        // color: Colors.black87,
      ),
      title: Text(
        strings.get("ADD_CASH"),
        textAlign: TextAlign.center,
        maxLines: 2,
      ),
    ));

    items.add(BottomNavigationBarItem(
      icon: _screenIndex == 0
          ? Image.asset(
              "images/earncash.png",
              height: 24.0,
            )
          : Icon(
              Icons.add_circle,
              // color: Colors.black87,
            ),
      title: Text(
        _screenIndex == 0 ? strings.get("EARN_CASH") : "Create contest",
        textAlign: TextAlign.center,
        maxLines: 2,
      ),
    ));

    items.add(BottomNavigationBarItem(
      icon: Icon(
        _screenIndex == 0 ? Icons.account_circle : Icons.people,
        // color: Colors.black87,
      ),
      title: Text(
        _screenIndex == 0
            ? strings.get("PROFILE")
            : (_screenIndex == 1 ? strings.get("MY_TEAMS") : "Predictions"),
        textAlign: TextAlign.center,
        maxLines: 2,
      ),
    ));
    return items;
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData(
        canvasColor: Theme.of(context).primaryColorDark,
        textTheme: Theme.of(context).primaryTextTheme.copyWith(
              caption: TextStyle(
                color: Colors.white,
              ),
            ),
      ),
      child: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
                blurRadius: 5.0, spreadRadius: 2.0, color: Colors.black26),
          ],
        ),
        child: BottomNavigationBar(
          onTap: (int index) {
            onTabTapped(context, index);
          },
          fixedColor: Colors.white,
          type: BottomNavigationBarType.fixed,
          items: getNavigationItems(),
        ),
      ),
    );
  }
}
