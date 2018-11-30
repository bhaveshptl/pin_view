class BaseUrl {
  static String apiUrl;
  static String websocketUrl;

  BaseUrl._internal();
  factory BaseUrl() => BaseUrl._internal();

  setApiUrl(String url) {
    apiUrl = url;
  }

  setWebSocketUrl(String url) {
    websocketUrl = url;
  }
}

class ApiUtil {
  static const SHARED_PREFERENCE_KEY = "fantasy_cookie";
  static const ANALYTICS_COOKIE = "fantasy_analytics_cookie";
  static const SHARED_PREFERENCE_USER_KEY = "fantasy_user";
  static const SHARED_PREFERENCE_SPORT_SELECTION = "fantasy_sport_selection";
  static const SHARED_PREFERENCE_FIREBASE_TOKEN = "deviceId";
  static const WS_SHARED_PREFERENCE_KEY = "ws_fantasy_cookie";
  static const LANGUAGE_TABLE = "fantasy_language_table";
  static const KEY_INIT_DATA = "fantasy_init_data";

  static const UPDATE_LANGUAGE_TABLE = "/api/v2/lobby/updatestringtable";
  static const COOKIE_PAGE = "/assets/cookie.html";

  static const LOGIN_URL = "/api/ups/login";
  static const LOGOUT_URL = "/api/ups/logout";
  static const GET_COOKIE_URL = "/api/lobby/getcookie";
  static const AUTH_CHECK_URL = "/api/v2/ups/login/status";
  static const GOOGLE_LOGIN_URL =
      "/api/ups/socialLogin/withcontext/google/native";
  static const FACEBOOK_LOGIN_URL =
      "/api/ups/socialLogin/withcontext/facebook/native";
  static const SIGN_UP = "/api/ups/signup";
  static const FORGOT_PASSWORD = "/api/ups/forgotPassword";
  static const RESET_PASSWORD = "/api/v2/ups/user/forgotPassword/resetpassword";
  static const INIT_DATA = "/api/v2/lobby/initData";

  static const RECOMMENDED_PRIZE_STRUCTURE =
      "/api/lobby/contest/prizestructure/suggestion/";

  static const CREATE_TEAM = "/api/lobby/fanteam";
  static const EDIT_TEAM = "/api/lobby/fanteam/";
  static const GET_MY_CONTEST_MY_TEAMS = "/api/lobby/user/contest/teams";
  static const JOIN_CONTEST = "/api/v2/lobby/joincontest";
  static const SWITCH_CONTEST_TEAM = "/api/lobby/contest/switch";
  static const CREATE_AND_JOIN_CONTEST = "/api/v2/lobby/contest";
  static const STATE_LIST = "/api/verify/states-list";
  static const UPDATE_DOB_STATE = "/api/ups/user/updateUser";
  static const VERIFICATION_STATUS = "/api/ups/user/verify";
  static const SEND_OTP = "/api/verify/activate/mobile";
  static const VERIFY_OTP = "/api/verify/mobile";
  static const SEND_VERIFICATION_MAIL = "/api/verify/activate/mail";
  static const KYC_DOC_LIST = "/api/verify/kyc-doc-list";
  static const UPLOAD_DOC = "/api/verify/upload-doc/";
  static const USER_BALANCE = "/api/lobby/userbalance";

  static const GET_MY_CONTESTS = "/api/lobby/user/mycontests/v2/";
  static const GET_CONTEST_TEAMS = "/api/lobby/contest/";
  static const GET_PRIZESTRUCTURE = "/api/lobby/contest/";
  static const GET_TEAM_INFO = "/api/lobby/contest/";
  static const SEARCH_CONTEST = "/api/v2/lobby/contest/private";

  static const UPDATE_USER_PROFILE = "/api/ups/user";
  static const GET_USER_PROFILE = "/api/v2/ups/user/info";
  static const CHANGE_PASSWORD = "/api/ups/user/changePassword";
  static const GET_REFERRAL_CODE = "/api/ups/user/referdetails";
  static const CHANGE_TEAM_NAME = "/api/ups/user/updateUserName";
  static const GET_ACCOUNT_DETAILS = "/api/account/overview";
  static const PARTNER_REQUEST = "/api/ups/partner-request";
  static const DEPOSIT_INFO = "/api/payment/player/deposit/v2";
  static const PAYMENT_MODE = "/api/payment/player/deposit/proceed/v2";
  static const INIT_PAYMENT = "/api/payment/player/deposit/init-pay?";
  static const CONTACTUS_SUBMIT = "/api/ups/contactUs/submit";
  static const CONTACTUS_FORM = "/api/ups/contactUsForm";
  
  static const AUTH_WITHDRAW = "/api/v2/ups/user/authWithdraw";
  static const WITHDRAW = "/api/ups/user/withdraw";
  static const WITHDRAW_HISTORY = "/api/ups/user/withdraw/list";
  static const CANCEL_WITHDRAW = "/api/ups/user/withdraw/cancel/";
  static const CHECK_APP_UPDATE = "/api/v2/lobby/update";
  static const PAYMENT_SUCCESS = "/assets/payment-response.html";
}
