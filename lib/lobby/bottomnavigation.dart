import 'package:flutter/material.dart';

class LobbyBottomNavigation extends StatelessWidget {
  final int activeIndex;
  final Function onNavigationSelectionChange;

  LobbyBottomNavigation(this.onNavigationSelectionChange, {this.activeIndex});

  void onTabTapped(BuildContext context, int index) {
    onNavigationSelectionChange(context, index);
  }

  getNavigationItems() {
    List<BottomNavigationBarItem> items = [];
    items.add(
      BottomNavigationBarItem(
        icon: Icon(
          Icons.home,
          size: 32.0,
        ),
        title: Text(
          "Home",
          textAlign: TextAlign.center,
          style: TextStyle(
            fontWeight: FontWeight.w800,
          ),
          maxLines: 2,
        ),
      ),
    );
    items.add(
      BottomNavigationBarItem(
        icon: Icon(
          Icons.panorama_horizontal,
          size: 32.0,
        ),
        title: Text(
          "My Matches",
          textAlign: TextAlign.center,
          style: TextStyle(
            fontWeight: FontWeight.w800,
          ),
          maxLines: 2,
        ),
      ),
    );

    items.add(
      BottomNavigationBarItem(
        icon: Icon(
          Icons.account_balance_wallet,
          size: 32.0,
        ),
        title: Text(
          "Add Cash",
          textAlign: TextAlign.center,
          style: TextStyle(
            fontWeight: FontWeight.w800,
          ),
          maxLines: 2,
        ),
      ),
    );

    items.add(
      BottomNavigationBarItem(
        icon: Icon(
          Icons.people,
          size: 32.0,
        ),
        title: Text(
          "Refer & Earn",
          textAlign: TextAlign.center,
          style: TextStyle(
            fontWeight: FontWeight.w800,
          ),
          maxLines: 2,
        ),
      ),
    );
    return items;
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData(
        canvasColor: Colors.white,
        textTheme: Theme.of(context).primaryTextTheme.copyWith(
              caption: TextStyle(
                color: Colors.black54,
                fontSize: 12.0,
                fontWeight: FontWeight.w900,
              ),
            ),
      ),
      child: Container(
        height: 72.0,
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              blurRadius: 5.0,
              spreadRadius: 2.0,
              color: Colors.black26,
            ),
          ],
        ),
        child: BottomNavigationBar(
          onTap: (int index) {
            onTabTapped(context, index);
          },
          fixedColor: Theme.of(context).primaryColor,
          type: BottomNavigationBarType.fixed,
          items: getNavigationItems(),
          currentIndex: activeIndex,
        ),
      ),
    );
  }
}
