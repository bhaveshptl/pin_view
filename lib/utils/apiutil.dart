class BaseUrl {
  String apiUrl;
  Duration pollTime;
  String websocketUrl;
  String contestShareUrl;
  Map<String, dynamic> staticPageUrls;

  BaseUrl._internal();
  static final BaseUrl baseUrl = BaseUrl._internal();
  factory BaseUrl() => baseUrl;

  setApiUrl(String url) {
    apiUrl = url;
  }

  setPollTime(Duration seconds) {
    pollTime = seconds;
  }

  setWebSocketUrl(String url) {
    websocketUrl = url;
  }

  setStaticPageUrl(Map<String, dynamic> urls) {
    staticPageUrls = urls;
  }

  setContestShareUrl(String url) {
    contestShareUrl = url;
  }
}

class ApiUtil {
  static const REGISTERED_USER = "registered_user";
  static const DISABLED_EMAIL_SIGNUP = "disabled_signup";
  static const CHECK_MOBILE_VERIFICATION = "CHECK_MOBILE_VERIFICATION";
  static const SHARED_PREFERENCE_KEY = "fantasy_cookie";
  static const ANALYTICS_COOKIE = "fantasy_analytics_cookie";
  static const SHARED_PREFERENCE_USER_KEY = "fantasy_user";
  static const SHARED_PREFERENCE_SPORT_SELECTION = "fantasy_sport_selection";
  static const SHARED_PREFERENCE_FIREBASE_TOKEN = "deviceId";
  static const SHARED_PREFERENCE_REFCODE_BRANCH = "refcode_branch";
  static const SHARED_PREFERENCE_GOOGLE_ADDID = "google_addid";
  static const SHARED_PREFERENCE_INSTALLREFERRING_BRANCH = "installReferring";
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
  static const REQUEST_OTP = "/api/ups/getmobileotp";
  static const RESEND_OTP = "/api/ups/resendotp";
  static const OTP_SIGNUP = "/api/ups/otplogin";
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
  static const UPLOAD_DOC_PAN = "/api/verify/upload-pan/";
  static const UPLOAD_DOC_ADDRESS = "/api/verify/upload-doc-address/";
  static const GET_ALLOWED_DOC_SIZE_IN_MB = "/api/verify/getAllowedDocSizeInMB";
  static const USER_BALANCE = "/api/lobby/userbalance";

  static const GET_MY_CONTESTS = "/api/lobby/user/mycontests/v2/";
  static const GET_CONTEST_TEAMS = "/api/lobby/contest/";
  static const GET_PRIZESTRUCTURE = "/api/lobby/contest/";
  static const GET_PREDICTION_PRIZESTRUCTURE =
      "/api/v2/lobby/quiz/prizestructure/";
  static const GET_TEAM_INFO = "/api/lobby/contest/";
  static const SEARCH_CONTEST = "/api/v2/lobby/contest/private";

  static const UPDATE_USER_PROFILE = "/api/ups/user";
  static const GET_USER_PROFILE = "/api/v2/ups/user/info";
  static const CHANGE_PASSWORD = "/api/ups/user/changePassword";
  static const GET_REFERRAL_CODE = "/api/v2/ups/user/referdetails/v2";
  static const CHANGE_TEAM_NAME = "/api/ups/user/updateUserName";
  static const GET_ACCOUNT_DETAILS = "/api/account/overview";
  static const PARTNER_REQUEST = "/api/ups/partner-request";
  static const DEPOSIT_INFO = "/api/v2/payment/player/deposit/v3";
  static const PAYMENT_MODE = "/api/v2/payment/player/deposit/proceed/v3";
  static const VALIDATE_PROMO = "/api/v2/payment/player/deposit/validate/promo";
  static const VALIDATE_PROMO_V2 =
      "/api/v2/payment/player/deposit/validate/promo/v2";
  static const INIT_PAYMENT = "/api/payment/player/deposit/init-pay?";
  static const INIT_PAYMENT_SEAMLESS =
      "/api/v2/payment/player/deposit/init-pay-seamless?";
  static const INIT_PAYMENT_TECHPROCESS =
      "/api/v2/payment/player/deposit/init-pay-techprocess?";
  static const CONTACTUS_SUBMIT = "/api/ups/contactUs/submit";
  static const CONTACTUS_FORM = "/api/ups/contactUsForm";

  static const AUTH_WITHDRAW = "/api/v2/ups/user/authWithdraw";
  static const WITHDRAW = "/api/ups/user/withdraw";
  static const WITHDRAW_HISTORY = "/api/ups/user/withdraw/list";
  static const CANCEL_WITHDRAW = "/api/ups/user/withdraw/cancel/";
  static const CHECK_APP_UPDATE = "/api/v2/lobby/update";
  static const PAYMENT_SUCCESS = "/assets/payment-response.html";
  static const SUCCESS_PAY =
      "/api/payment/success-razor-pay?type_id=4&source=RAZORPAY";
  // static const TECHPROCESS_SUCCESS_PAY =
  //     "/api/v2/payment/success-pay?type_id=5&source=TECHPROCESS_SEAMLESS";

  static const TECHPROCESS_SUCCESS_PAY =
      "/api/payment/success-techprocess?type_id=5&source=TECHPROCESS_SEAMLESS";
  static const SAVE_SHEET = "/api/v2/lobby/quiz/save-answer-sheet";
  static const JOIN_PREDICTION_CONTEST = "/api/v2/lobby/quiz/join";
  static const GET_MY_CONTEST_MY_SHEETS =
      "/api/v2/lobby/quiz/mycontest-all-answersheet";
  static const GET_MY_ALL_CONTESTS = "/api/v2/lobby/mycontests/";
  static const GET_MY_ALL_MATCHES = "/api/v2/lobby/mymatches/";
  static const GET_LEAGUE_FLIPS = "/api/v2/lobby/quiz/get-flips/";
  static const GET_FLIP_BALANCE = "/api/v2/lobby/quiz/get-flips/usable/";
  static const GET_CONTEST_SHEETS = "/api/lobby/contest/";
  static const GET_ANSWER_SHEET_DETAILS = "/api/v2/lobby/quiz/answersheet/";
  static const GET_ALL_ANSWER_SHEETS = "/api/v2/lobby/quiz/get-answer-sheets";
  static const GET_CONTEST_MY_ANSWER_SHEETS =
      "/api/v2/lobby/quiz/contest-all-my-answersheets";

  static const QUIZ_USER_BALANCE = "/api/v2/lobby/quiz-userbalance";
  static const GET_BANNERS = "/api/v2/lobby/banners";

  static const GET_PROMOCODES = "/api/v2/payment/promocodes/";
}

class PrivateAttribution {
  static bool disableBranchIOAttribution = false;
  static String attributionNumber = "3";
  static String currentVersion = "3_59";
  static bool getdisableBranchIOAttribution() {
    return disableBranchIOAttribution;
  }

  static String getPrivateAttributionName() {
    var attributionName = attributionNumber;
    switch (attributionName) {
      case "1":
        return "oppo";
      case "2":
        return "xiaomi";
      case "3":
        return "indusos";
      default:
        return "";
    }
  }

  static String getApkNameToDelete() {
    String apkNameToDelete = "";
    var attributionName = attributionNumber;
    switch (attributionName) {
      case "1":
        apkNameToDelete = "hz_oppo_" + currentVersion + ".apk";
        break;
      case "2":
        apkNameToDelete = "hz_xiaomi_" + currentVersion + ".apk";
        break;
      case "3":
        apkNameToDelete = "hz_indusos" + currentVersion + ".apk";
        break;
      default:
        apkNameToDelete = "howzat.apk";
        break;
    }
    return apkNameToDelete;
  }
}
