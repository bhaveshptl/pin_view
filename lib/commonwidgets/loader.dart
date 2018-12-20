import "package:flutter/material.dart";

class Loader extends StatelessWidget {
  Loader();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        height: 56.0,
        padding: EdgeInsets.all(16.0),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(3.0),
            boxShadow: [
              BoxShadow(
                blurRadius: 5.0,
                spreadRadius: 5.0,
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
            Text("Loading..."),
          ],
        ),
      ),
    );
  }
}
