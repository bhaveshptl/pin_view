import 'package:flutter/material.dart';

class LobbyBottomNavigation extends StatelessWidget {
  final int _currentIndex;
  final Function onNavigationSelectionChange;

  LobbyBottomNavigation(this._currentIndex, this.onNavigationSelectionChange);

  void onTabTapped(int index) {
    onNavigationSelectionChange(index);
  }

  @override
  Widget build(BuildContext context) {
    return new Theme(
      data: Theme.of(context).copyWith(
        splashColor: Theme.of(context).primaryColorDark,
        textTheme: Theme.of(context).textTheme.copyWith(
            caption: new TextStyle(color: Theme.of(context).primaryColorDark)),
      ),
      child: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: onTabTapped,
        items: [
          BottomNavigationBarItem(
            icon: new Icon(
              Icons.home,
              color: Theme.of(context).primaryColorDark,
            ),
            title: new Text(
              'ALL SERIES',
              style: TextStyle(
                  color: Theme.of(context).primaryColorDark,
                  fontSize:
                      Theme.of(context).primaryTextTheme.caption.fontSize),
            ),
          ),
          BottomNavigationBarItem(
            icon: new Icon(
              Icons.mail,
              color: Theme.of(context).primaryColorDark,
            ),
            title: new Text(
              'CONTEST CODE',
              style: TextStyle(
                  color: Theme.of(context).primaryColorDark,
                  fontSize:
                      Theme.of(context).primaryTextTheme.caption.fontSize),
            ),
          ),
          BottomNavigationBarItem(
            icon: Icon(
              Icons.person,
              color: Theme.of(context).primaryColorDark,
            ),
            title: Text(
              'MY CONTESTS',
              style: TextStyle(
                  color: Theme.of(context).primaryColorDark,
                  fontSize:
                      Theme.of(context).primaryTextTheme.caption.fontSize),
            ),
          ),
          BottomNavigationBarItem(
            icon: Icon(
              Icons.group_work,
              color: Theme.of(context).primaryColorDark,
            ),
            title: Text(
              'EARN CASH',
              style: TextStyle(
                  color: Theme.of(context).primaryColorDark,
                  fontSize:
                      Theme.of(context).primaryTextTheme.caption.fontSize),
            ),
          ),
          BottomNavigationBarItem(
            icon: Icon(
              Icons.attach_money,
              color: Theme.of(context).primaryColorDark,
            ),
            title: Text(
              'ADD CASH',
              style: TextStyle(
                  color: Theme.of(context).primaryColorDark,
                  fontSize:
                      Theme.of(context).primaryTextTheme.caption.fontSize),
            ),
          ),
        ],
      ),
    );
  }
}
