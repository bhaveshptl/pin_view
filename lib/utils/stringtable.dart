StringTable strings = new StringTable();

class StringTable {
  StringTable._internal();
  factory StringTable() => StringTable._internal();

  static Map<String, String> table;
  String rupee = "₹";

  String get(String title) {
    return table[title];
  }

  set() {
    table = {
      "CRICKET": "Cricket",
      "FOOTBALL": "Football",
      "UPCOMING": "Upcoming",
      "RESULT": "Result",
      "LIVE": "Live",
      "COMING_SOON": "Coming soon",
      "ALL": "All",
      "SERIES": "Series",
      "CONTEST_CODE": "Contest code",
      "MY_CONTESTS": "My contests",
      "ADD_CASH": "Add cash",
      "EARN_CASH": "Earn cash",
      "NO_MATCHES": "There are no ~ matches",
      "KABADDI": "Kabaddi",
      "MATCHES": "Matches",
      "MY_PROFILE": "My profile",
      "MY_ACCOUNTS": "My accounts",
      "LOGOUT": "Logout",
      "PRIVACY_POLICY": "Privacy policy",
      "TC": "Terms and conditions",
      "ABOUT_US": "About us",
      "BLOG": "Blog",
      "FORUM": "Forum",
      "SUPPORT": "Support",
      "HELP": "Help",
      "SCORING_SYSTEM": "Scoring system",
      "B_A_PARTNER": "Become a partner",
      "CHANGE_LANG": "Change language",
      "WITHDRAW_CASH": "Withdraw cash",
      "IN_PROGRESS": "In progress",
      "COMPLETED": "Completed",
      "DO_U_W_EXIT": "Do you want to exit an app",
      "OK": "Ok",
      "CANCEL": "Cancel",
      "EXIT": "Exit",
      "CHANGE": "Change",
      "SELECT_LANGUAGE": "Select language",
      "ACCOUNT_BLOCKED": "Account blocked",
      "AC_BLOCKED_MSG":
          "Your account has been blocked.\nPlease contact us at support@playfantasy.com to get more information.",
      "ACCOUNT_CLOSED": "Accout closed",
      "AC_CLOSED_MSG":
          "Your account has been closed.\nPlease contact us at support@playfantasy.com to get more information.",
      "AGE_LESS_MSG": "Your age is less than 18.\nYou cannot add any cash.",
      "STATE_BLOCKED_MSG":
          "You are from a blocked state.\nHence, you cannot add any cash.",
      "NOT_IN_INDIA_MSG": "You are not playing from India",
      "N_I_A": "Not in india",
      "MATCH": "Match",
      "NORMAL": "Normal",
      "FANTASY": "Fantasy",
      "PRIZE_MONEY": "Prize money",
      "N_O_WINNERS": "No.Of winners",
      "TEAMS_JOINED": "Teams joined",
      "FULL": "Full",
      "JOIN": "Join",
      "JOIN+": "Join +",
      "INVITE": "Invite",
      "POPULAR": "Popular",
      "TOTAL_PRIZE": "Total prize",
      "WINNERS": "Winners",
      "YOUR_BEST_TEAM": "Your best team",
      "RANK": "Rank",
      "SCORE": "Score",
      "YOU_WON": "You Won -",
      "CREATE_CONTEST": "Create contest",
      "CREATE_TEAMS": "Create teams",
      "CREATE_TEAM_B_JC": "Create your Team before joining contest.",
      "CREATE_TEAM": "Create team",
      "MATCH_LIVE_CANNOT_CC": "Match is live, You can not create contest now.",
      "DATA_N_LOADED": "Data not loaded",
      "NO_CONTEST": "No ~ contests",
      "CASH": "Cash",
      "PRACTICE": "Practice",
      "LIST_OF_CONTESTS": "List of contests",
      "INNINGS": "Innings",
      "PLAYER_SELECTED": "Player selected",
      "C_LEFT": "Credits Left",
      "AC_PP": "Avg. credits / Players",
      "PICK": "PICK",
      "P_T_CC": "Proceed to choose captains",
      "PLAYERS": "Players",
      "CREDITS": "Credits",
      "CHOSE_CAPTAIN": "Choose captain",
      "P_C_MP_F_DT": "Please choose ~ more players to complete your dream team",
      "P_C_P_F_DT": "Please choose ~ players to complete your dream team",
      "MIN_XYZ_TBS": "Minimum ~ ~ to be selected",
      "Y_C_C_MORE_T": "You can\'t choose more than ~ ~.",
      "F_PLAYERS": "foreign players",
      "P_PER_TEAM": "players from one team",
      "MINI_XYZ_SELECTED": "Minimum ~ ~ should be selected",
      "CAPTAIN": "Captain",
      "V_CAPTAIN": "V.Captain",
      "PLEASE_SELECT": "Please select",
      "aND": "and",
      "JOIN_CONTEST": "Join Contest",
      "CASH_BALANCES": "Cash balance",
      "BONUS": "Bonus ",
      "ENTRY_FEE": "Entry fee",
      "BONUS_USABLE": "Usable bonus",
      "SELECT_TEAM": "Select team",
      "VS": "vs",
      "Y_H_NO_CONTEST": "You have no ~ Contests.",
      "J_B_M": "Join the below matches.",
      "SAVE_TEAM": "Save Team",
      "CONTEST_ARC_MSG":
          "Current contest is archived. You will be redirected to ",
      "TEAMS_NOT_UPDATED":
          "Teams are not yet updated. Please try after some time.",
      "CONTEST_DETAILS": "Contest Details",
      "TEAM": "Team",
      "PRIZE": "Prize",
      "SWITCH": "Switch",
      "P_G_E_CON_N_F": "Prize is Guaranteed even if contest is not filled",
      "M_NO_OF_ENTRIES": "Max number of Entries in this contest",
      "U_BONUS_USE": "upto ~ % of bonus can be used*",
      "PRIZE_STRUCTURE": "Prize structure",
      "TOTAL_PRIZE_AMOUNT": "Total Prize Amount ",
      "B_S_PRIZE_BRKUP": "prize breakup for ~ winners is shown below",
      "PRIZE_AMOUNT": "Prize Amount",
      "PRIZE_STRUCTURE_TEXT_1":
          "Actual prize structure may vary based on the number of teams joined.",
      "PRIZE_STRUCTURE_TEXT_2": "Check FAQ's for further details.",
      "PRIZE_STRUCTURE_TEXT_3":
          "As per government regulation, 30.9% of tax will be deduct for winings above rs. 10,000.",
      "EDIT": "Edit",
      "CLONE": "Clone",
      "MY_TEAMS": "My Teams",
      "ENTRY_CLOSED": "Entry Closed",
      "SWITCH_TEAM": "Switch Team",
      "MSG_SWITCH_TEAM": "You are switching your team from ~ to",
      "VIEW": "VIEW",
      "Wicket Keeper": "Wicket Keeper",
      "Batsman": "Batsman",
      "Bowler": "Bowler",
      "All Rounder": "All Rounder",
      "Goalkeeper": "Goalkeeper",
      "Defender": "Defender",
      "Midfielder": "Midfielder",
      "Forward": "Forward",
      "Raider": "Raider",
      "All-Rounder": "All-Rounder",
      "AGE_LESS_MSG_ADD_CASH":
          "Your age is less than 18.\nYou cannot add any cash.",
      "STATE_BLOCKED_MSG_ADD_CASH":
          "You are from a blocked state.\nHence, you cannot add any cash.",
      "AGE_LESS_MSG_WITHDRAW":
          "Your age is less than 18.\nYou cannot withdraw any cash.",
      "STATE_BLOCKED_MSG_WITHDRAW":
          "You are from a blocked state.\nHence, you cannot withdraw any cash.",
      "AGE_LESS_MSG_CASH_GAME":
          "Your age is less than 18.\nYou cannot play cash game.",
      "STATE_BLOCKED_MSG_CASH_GAME":
          "You are from a blocked state.\nHence, you cannot play cash game.",
      "APP_CLOSE_TITLE": "Are you sure?",
      "YES": "Yes",
      "NO": "No",
      "CONFIRMATION": "Confirmation",
      "CASH_TO_PAY": "Cash to be paid",
      "DETAILS": "Details",
      "SUBMIT": "Submit",
      "STATE": "State",
      "DOB": "Date of birth",
      "INSUFFICIENT_FUND": "Insufficient funds!!",
      "INSUFFICIENT_FUND_MSG": "Please deposit funds to join cash contest!!",
      "DEPOSIT": "Deposit",
      "ALERT": "Alert",
      "CREATE_TEAM_WARNING":
          "No team created for this match. Please create one to join contest.",
      "CREATE": "Create",
      "ACCOUNT_VERIFICATION": "Account verification",
      "VERIFY": "Verify",
      "EMAIL": "E-mail",
      "MOBILE": "Mobile",
      "KYC": "KYC (ID and address verification)",
      "SEND_OTP": "Send OTP",
      "UPLOAD": "Upload",
      "WINNINGS": "Winnings",
      "TOTAL_WINNINGS": "Total winnings",
      "NOTES": "Notes",
    };
  }
}
