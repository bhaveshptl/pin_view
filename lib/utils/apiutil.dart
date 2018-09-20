class ApiUtil {
  static const SHARED_PREFERENCE_KEY = "fantasy_cookie";
  static const SHARED_REFERENCE_USER_KEY = "fantasy_user";
  static const WS_SHARED_PREFERENCE_KEY = "ws_fantasy_cookie";
  static const WEBSOCKET_URL = "wss://lobby-stg.playfantasy.com/path?pid=";

  static const BASE_URL = "https://stg.playfantasy.com";
  static const PAYMENT_BASE_URL = "https://test.justkhel.com";
  static const DEPOSIT_URL = PAYMENT_BASE_URL + "/deposit";

  static const BASE_API_URL = BASE_URL + "/api";
  static const LOGIN_URL = BASE_API_URL + "/ups/login";
  static const LOGOUT_URL = BASE_API_URL + "/ups/logout";
  static const GET_COOKIE_URL = BASE_API_URL + "/lobby/getcookie";
  static const AUTH_CHECK_URL = BASE_API_URL + "/ups/login/status";
}
