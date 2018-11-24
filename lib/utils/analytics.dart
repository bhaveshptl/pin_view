import 'dart:async';

class AnalyticsManager {
  String _url;
  int _duration;
  List<Map<String, dynamic>> analyticsEvents = [];

  AnalyticsManager._internal();
  factory AnalyticsManager() => AnalyticsManager._internal();

  init({String url, int duration = 5}) {
    _url = url;
    _duration = duration;
  }

  statAnalytics() {
    Timer(Duration(seconds: _duration), () {
      AnalyticsManager().statAnalytics();
    });
  }

  addEvent(Map<String, dynamic> event) {
    analyticsEvents.add(event);
  }
}
