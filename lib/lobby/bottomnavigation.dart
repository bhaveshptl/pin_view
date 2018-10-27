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
      data: Theme.of(context).copyWith(
        splashColor: Theme.of(context).primaryColorDark,
        textTheme: Theme.of(context).textTheme.copyWith(
            caption: TextStyle(color: Theme.of(context).primaryColorDark)),
      ),
      child: BottomNavigationBar(
        onTap: (int index) {
          onTabTapped(context, index);
        },
        type: BottomNavigationBarType.fixed,
        items: [
          BottomNavigationBarItem(
            activeIcon: Icon(
              Icons.home,
              color: Theme.of(context).primaryColorDark,
            ),
            icon: Icon(
              Icons.home,
              color: Theme.of(context).primaryColor,
            ),
            title: Text(
              _screenIndex == 0
                  ? strings.get("ALL_SERIES").toUpperCase()
                  : strings.get("CONTESTS").toUpperCase(),
              textAlign: TextAlign.center,
              maxLines: 2,
              style: TextStyle(
                  color: Theme.of(context).primaryColor,
                  fontSize:
                      Theme.of(context).primaryTextTheme.caption.fontSize),
            ),
          ),
          BottomNavigationBarItem(
            activeIcon: Icon(
              _screenIndex == 0 ? Icons.search : Icons.add_circle,
              color: Theme.of(context).primaryColorDark,
            ),
            icon: Icon(
              _screenIndex == 0 ? Icons.search : Icons.add_circle,
              color: Theme.of(context).primaryColor,
            ),
            title: Text(
              _screenIndex == 0
                  ? strings.get("CONTEST_CODE").toUpperCase()
                  : strings.get("MY_TEAMS").toUpperCase(),
              textAlign: TextAlign.center,
              maxLines: 2,
              style: TextStyle(
                  color: Theme.of(context).primaryColor,
                  fontSize:
                      Theme.of(context).primaryTextTheme.caption.fontSize),
            ),
          ),
          BottomNavigationBarItem(
            activeIcon: Icon(
              Icons.person,
              color: Theme.of(context).primaryColorDark,
            ),
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
                  fontSize:
                      Theme.of(context).primaryTextTheme.caption.fontSize),
            ),
          ),
          BottomNavigationBarItem(
            activeIcon: Icon(
              Icons.group_work,
              color: Theme.of(context).primaryColorDark,
            ),
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
                  fontSize:
                      Theme.of(context).primaryTextTheme.caption.fontSize),
            ),
          ),
          BottomNavigationBarItem(
            activeIcon: Icon(
              Icons.attach_money,
              color: Theme.of(context).primaryColorDark,
            ),
            icon: Icon(
              Icons.attach_money,
              color: Theme.of(context).primaryColor,
            ),
            title: Text(
              strings.get("ADD_CASH").toUpperCase(),
              textAlign: TextAlign.center,
              maxLines: 2,
              style: TextStyle(
                  color: Theme.of(context).primaryColor,
                  fontSize:
                      Theme.of(context).primaryTextTheme.caption.fontSize),
            ),
          ),
        ],
      ),
    );
  }
}
