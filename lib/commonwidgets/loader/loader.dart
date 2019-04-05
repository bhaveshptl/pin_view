import "package:flutter/material.dart";

class LoaderWidget extends StatelessWidget {
  LoaderWidget();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        color: Colors.black26,
        child: Center(
          child: Container(
            height: 56.0,
            padding: EdgeInsets.all(16.0),
            decoration: BoxDecoration(
                color: Theme.of(context).primaryColorDark,
                borderRadius: BorderRadius.circular(5.0),
                boxShadow: [
                  BoxShadow(
                    blurRadius: 15.0,
                    spreadRadius: 15.0,
                    color: Colors.black12,
                  )
                ]),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Padding(
                  padding: EdgeInsets.only(right: 16.0),
                  child: Container(
                    height: 24.0,
                    width: 24.0,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.0,
                    ),
                  ),
                ),
                Text(
                  "Loading...",
                  style: TextStyle(
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
