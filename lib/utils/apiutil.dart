class ApiUtil {
  static const SHARED_PREFERENCE_KEY = "fantasy_cookie";
  static const SHARED_REFERENCE_USER_KEY = "fantasy_user";

  static const BASE_URL = "https://stg.playfantasy.com";

  static const BASE_API_URL = BASE_URL + "/api";
  static const LOGIN_URL = BASE_API_URL + "/ups/login";
  static const LOGOUT_URL = BASE_API_URL + "/ups/logout";
  static const AUTH_CHECK_URL = BASE_API_URL + "/ups/login/status";
}
