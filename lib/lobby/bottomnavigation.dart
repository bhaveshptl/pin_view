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
          icon: Icon(
            Icons.home,
            color: Theme.of(context).primaryColor,
          ),
          title: Text(
            _screenIndex == 0
                ? strings.get("ALL_SERIES").toUpperCase()
                : strings.get("MY_TEAMS").toUpperCase(),
            textAlign: TextAlign.center,
            maxLines: 2,
            style: TextStyle(
                color: Theme.of(context).primaryColor,
                fontSize: Theme.of(context).primaryTextTheme.caption.fontSize),
          ),
        ),
        BottomNavigationBarItem(
          icon: Icon(
            _screenIndex == 0 ? Icons.search : Icons.add_circle,
            color: Theme.of(context).primaryColor,
          ),
          title: Text(
            _screenIndex == 0
                ? strings.get("CONTEST_CODE").toUpperCase()
                : strings.get("CREATE_CONTEST").toUpperCase(),
            textAlign: TextAlign.center,
            maxLines: 2,
            style: TextStyle(
                color: Theme.of(context).primaryColor,
                fontSize: Theme.of(context).primaryTextTheme.caption.fontSize),
          ),
        ),
        BottomNavigationBarItem(
          icon: Icon(
            Icons.person,
            color: Theme.of(context).primaryColor,
          ),
          title: Text(
            strings.get("MY_CONTESTS").toUpperCase(),
            textAlign: TextAlign.center,
            maxLines: 2,
            style: TextStyle(
                color: Theme.of(context).primaryColor,
                fontSize: Theme.of(context).primaryTextTheme.caption.fontSize),
          ),
        ),
        BottomNavigationBarItem(
          icon: Icon(
            Icons.group_work,
            color: Theme.of(context).primaryColor,
          ),
          title: Text(
            _screenIndex == 0
                ? strings.get("EARN_CASH").toUpperCase()
                : strings.get("CREATE_CONTEST").toUpperCase(),
            textAlign: TextAlign.center,
            maxLines: 2,
            style: TextStyle(
                color: Theme.of(context).primaryColor,
                fontSize: Theme.of(context).primaryTextTheme.caption.fontSize),
          ),
        ),
        // BottomNavigationBarItem(
        //   icon: Icon(
        //     Icons.attach_money,
        //     color: Theme.of(context).primaryColor,
        //   ),
        //   title: Text(
        //     strings.get("ADD_CASH").toUpperCase(),
        //     textAlign: TextAlign.center,
        //     maxLines: 2,
        //     style: TextStyle(
        //         color: Theme.of(context).primaryColor,
        //         fontSize:
        //             Theme.of(context).primaryTextTheme.caption.fontSize),
        //   ),
        // ),
      ],
    );
  }
}
