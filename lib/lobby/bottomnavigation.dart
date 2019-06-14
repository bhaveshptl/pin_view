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
        icon: Image.asset(
          activeIndex == 0 ? "images/home-select.png" : "images/home.png",
          height: 28.0,
        ),
        title: Text(
          "Home",
          textAlign: TextAlign.center,
          style: TextStyle(
            fontWeight: FontWeight.w600,
          ),
          maxLines: 2,
        ),
      ),
    );
    items.add(
      BottomNavigationBarItem(
        icon: Image.asset(
          activeIndex == 1
              ? "images/my-matches-select.png"
              : "images/my-matches.png",
          height: 28.0,
        ),
        title: Text(
          "My Matches",
          textAlign: TextAlign.center,
          style: TextStyle(
            fontWeight: FontWeight.w600,
          ),
          maxLines: 2,
        ),
      ),
    );

    items.add(
      BottomNavigationBarItem(
        icon: Image.asset(
          activeIndex == 2
              ? "images/add-cash-select.png"
              : "images/add-cash.png",
          height: 28.0,
        ),
        title: Text(
          "Add Cash",
          textAlign: TextAlign.center,
          style: TextStyle(
            fontWeight: FontWeight.w600,
          ),
          maxLines: 2,
        ),
      ),
    );

    items.add(
      BottomNavigationBarItem(
        icon: Image.asset(
          activeIndex == 3
              ? "images/raf-earn-select.png"
              : "images/refer-earn.png",
          height: 28.0,
        ),
        title: Text(
          "Refer & Earn",
          textAlign: TextAlign.center,
          style: TextStyle(
            fontWeight: FontWeight.w600,
          ),
          maxLines: 2,
        ),
      ),
    );

    items.add(
      BottomNavigationBarItem(
        icon: Image.asset(
          activeIndex == 4 ? "images/menu-icon.png" : "images/menu-icon.png",
          height: 28.0,
          width: 24.0,
        ),
        title: Text(
          "More",
          textAlign: TextAlign.center,
          style: TextStyle(
            fontWeight: FontWeight.w600,
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
                fontSize: 16.0,
              ),
            ),
      ),
      child: Container(
        height: 64.0,
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
