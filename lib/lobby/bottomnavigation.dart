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
    return BottomNavigationBar(
      onTap: (int index) {
        onTabTapped(context, index);
      },
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
            style: Theme.of(context).primaryTextTheme.body2.copyWith(
                  color: Colors.black87,
                ),
          ),
        ),
        BottomNavigationBarItem(
          icon: Icon(
            Icons.account_balance_wallet,
            color: Colors.black87,
          ),
          title: Text(
            strings.get("ADD_CASH"),
            textAlign: TextAlign.center,
            maxLines: 2,
            style: Theme.of(context).primaryTextTheme.body2.copyWith(
                  color: Colors.black87,
                ),
          ),
        ),
        BottomNavigationBarItem(
          icon: _screenIndex == 1
              ? Icon(
                  Icons.add_circle,
                  color: Colors.black87,
                )
              : Image.asset(
                  "images/earncash.png",
                  height: 24.0,
                ),
          title: Text(
            _screenIndex == 0 ? strings.get("EARN_CASH") : "Create contest",
            textAlign: TextAlign.center,
            maxLines: 2,
            style: Theme.of(context).primaryTextTheme.body2.copyWith(
                  color: Colors.black87,
                ),
          ),
        ),
        BottomNavigationBarItem(
          icon: Icon(
            _screenIndex == 0 ? Icons.account_circle : Icons.people,
            color: Colors.black87,
          ),
          title: Text(
            _screenIndex == 0
                ? strings.get("PROFILE")
                : strings.get("MY_TEAMS"),
            textAlign: TextAlign.center,
            maxLines: 2,
            style: Theme.of(context).primaryTextTheme.body2.copyWith(
                  color: Colors.black87,
                ),
          ),
        ),
      ],
    );
  }
}
