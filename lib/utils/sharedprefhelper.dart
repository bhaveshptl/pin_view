import 'dart:async';

import 'package:playfantasy/utils/apiutil.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SharedPrefHelper {
  SharedPrefHelper.internal();
  factory SharedPrefHelper() => _instance;
  static SharedPrefHelper _instance = new SharedPrefHelper.internal();

  Future<SharedPreferences> _prefs = SharedPreferences.getInstance();

  saveCookieToStorage(String cookie) async {
    final pref = await _prefs;
    pref.setString(ApiUtil.SHARED_PREFERENCE_KEY, cookie);
  }

  getCookie() async {
    final pref = await _prefs;
    return pref.get(ApiUtil.SHARED_PREFERENCE_KEY);
  }

  removeCookie() async {
    final pref = await _prefs;
    return pref.remove(ApiUtil.SHARED_PREFERENCE_KEY);
  }

  saveToSharedPref(String key, String value) async {
    final pref = await _prefs;
    pref.setString(key, value);
  }

  getFromSharedPref(String key) async {
    final pref = await _prefs;
    return pref.get(key);
  }
}
