import 'package:flutter/material.dart';
import 'package:playfantasy/utils/stringtable.dart';

class LobbyBottomNavigation extends StatelessWidget {
  final int _screenIndex;
  final Function onNavigationSelectionChange;

  LobbyBottomNavigation(this.onNavigationSelectionChange, this._screenIndex);

  void onTabTapped(BuildContext context, int index) {
    onNavigationSelectionChange(context, index);
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
      child: BottomNavigationBar(
        onTap: (int index) {
          onTabTapped(context, index);
        },
        fixedColor: Colors.white,
        type: BottomNavigationBarType.fixed,
        items: [
          BottomNavigationBarItem(
            icon: Image.asset(
              "images/mycontests_icon3.png",
              height: 24.0,
            ),
            title: Text(
              strings.get("MY_CONTESTS"),
              textAlign: TextAlign.center,
              maxLines: 2,
            ),
          ),
          BottomNavigationBarItem(
            icon: Icon(
              Icons.account_balance_wallet,
              // color: Colors.black87,
            ),
            title: Text(
              strings.get("ADD_CASH"),
              textAlign: TextAlign.center,
              maxLines: 2,
            ),
          ),
          BottomNavigationBarItem(
            icon: _screenIndex == 1
                ? Icon(
                    Icons.add_circle,
                    // color: Colors.black87,
                  )
                : Image.asset(
                    "images/earncash.png",
                    height: 24.0,
                  ),
            title: Text(
              _screenIndex == 0 ? strings.get("EARN_CASH") : "Create contest",
              textAlign: TextAlign.center,
              maxLines: 2,
            ),
          ),
          BottomNavigationBarItem(
            icon: Icon(
              _screenIndex == 0 ? Icons.account_circle : Icons.people,
              // color: Colors.black87,
            ),
            title: Text(
              _screenIndex == 0
                  ? strings.get("PROFILE")
                  : strings.get("MY_TEAMS"),
              textAlign: TextAlign.center,
              maxLines: 2,
            ),
          ),
        ],
      ),
    );
  }
}
