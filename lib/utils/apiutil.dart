class ApiUtil {
  static const SHARED_PREFERENCE_KEY = "fantasy_cookie";
  static const SHARED_PREFERENCE_USER_KEY = "fantasy_user";
  static const SHARED_PREFERENCE_SPORT_SELECTION = "fantasy_sport_selection";
  static const WS_SHARED_PREFERENCE_KEY = "ws_fantasy_cookie";
  static const LANGUAGE_TABLE = "fantasy_language_table";
  static const WEBSOCKET_URL = "wss://lobby-stg.playfantasy.com/path?pid=";
  static const UPDATE_LANGUAGE_TABLE =
      BASE_API_URL + "v2/lobby/updatestringtable";

  static const BASE_URL = "https://stg.playfantasy.com";
  static const PAYMENT_BASE_URL = BASE_URL;
  static const DEPOSIT_URL = PAYMENT_BASE_URL + "/deposit";

  static const BASE_API_URL = BASE_URL + "/api/";
  static const LOGIN_URL = BASE_API_URL + "ups/login";
  static const LOGOUT_URL = BASE_API_URL + "ups/logout";
  static const GET_COOKIE_URL = BASE_API_URL + "lobby/getcookie";
  static const AUTH_CHECK_URL = BASE_API_URL + "ups/login/status";
  static const GOOGLE_LOGIN_URL =
      BASE_API_URL + "ups/socialLogin/withcontext/google/native";
  static const FACEBOOK_LOGIN_URL =
      BASE_API_URL + "ups/socialLogin/withcontext/facebook/native";
  static const SIGN_UP = BASE_API_URL + "ups/signup";
  static const FORGOT_PASSWORD = BASE_API_URL + "ups/forgotPassword";
  static const RESET_PASSWORD =
      BASE_API_URL + "v2/ups/user/forgotPassword/resetpassword";

  static const RECOMMENDED_PRIZE_STRUCTURE =
      BASE_API_URL + "lobby/contest/prizestructure/suggestion/";

  static const CREATE_TEAM = BASE_API_URL + "lobby/fanteam";
  static const EDIT_TEAM = BASE_API_URL + "lobby/fanteam/";
  static const GET_MY_CONTEST_MY_TEAMS =
      BASE_API_URL + "lobby/user/contest/teams";
  static const JOIN_CONTEST = BASE_API_URL + "v2/lobby/joincontest";
  static const SWITCH_CONTEST_TEAM = BASE_API_URL + "lobby/contest/switch";
  static const CREATE_AND_JOIN_CONTEST = BASE_API_URL + "lobby/contest";
  static const STATE_LIST = BASE_API_URL + "verify/states-list";
  static const UPDATE_DOB_STATE = BASE_API_URL + "ups/user/updateUser";
  static const VERIFICATION_STATUS = BASE_API_URL + "ups/user/verify";
  static const SEND_OTP = BASE_API_URL + "verify/activate/mobile";
  static const VERIFY_OTP = BASE_API_URL + "verify/mobile";
  static const SEND_VERIFICATION_MAIL = BASE_API_URL + "verify/activate/mail";
  static const KYC_DOC_LIST = BASE_API_URL + "verify/kyc-doc-list";
  static const UPLOAD_DOC = BASE_API_URL + "verify/upload-doc/";
  static const USER_BALANCE = BASE_API_URL + "lobby/userbalance";

  static const GET_MY_CONTESTS = BASE_API_URL + "lobby/user/mycontests/v2/";
  static const GET_CONTEST_TEAMS = BASE_API_URL + "lobby/contest/";
  static const GET_PRIZESTRUCTURE = BASE_API_URL + "lobby/contest/";
  static const GET_TEAM_INFO = BASE_API_URL + "lobby/contest/";
  static const SEARCH_CONTEST = BASE_API_URL + "lobby/contest/private";

  static const GET_REFERRAL_CODE = BASE_API_URL + "ups/user/referdetails";
}
