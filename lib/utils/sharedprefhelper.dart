import 'dart:async';
import 'dart:convert';

import 'package:playfantasy/utils/apiutil.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SharedPrefHelper {
  SharedPrefHelper.internal();
  factory SharedPrefHelper() => _instance;
  static SharedPrefHelper _instance = new SharedPrefHelper.internal();

  Future<SharedPreferences> _prefs = SharedPreferences.getInstance();
  static String wsCookie;

  saveCookieToStorage(String cookie) async {
    final pref = await _prefs;
    pref.setString(ApiUtil.SHARED_PREFERENCE_KEY, cookie);
  }

  getCookie() async {
    final pref = await _prefs;
    return pref.get(ApiUtil.SHARED_PREFERENCE_KEY);
  }

  saveWSCookieToStorage(String cookie) async {
    wsCookie = cookie;
    final pref = await _prefs;
    pref.setString(ApiUtil.WS_SHARED_PREFERENCE_KEY, cookie);
  }

  getWSCookie() async {
    final pref = await _prefs;
    return pref.get(ApiUtil.WS_SHARED_PREFERENCE_KEY);
  }

  removeCookie() async {
    wsCookie = null;
    final pref = await _prefs;
    return pref.remove(ApiUtil.SHARED_PREFERENCE_KEY);
  }

  saveSportsType(String _sportType) async {
    final pref = await _prefs;
    pref.setString(ApiUtil.SHARED_PREFERENCE_SPORT_SELECTION, _sportType);
  }

  getSportsType() async {
    final pref = await _prefs;
    return pref.get(ApiUtil.SHARED_PREFERENCE_SPORT_SELECTION);
  }

  saveLanguageTable(
      {String version, Map<String, dynamic> table, int lang}) async {
    final pref = await _prefs;
    pref.setString(
      ApiUtil.LANGUAGE_TABLE,
      json.encode({"version": version, "table": table, "language": lang}),
    );
  }

  getLanguageTable() async {
    final pref = await _prefs;
    return pref.get(ApiUtil.LANGUAGE_TABLE);
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
