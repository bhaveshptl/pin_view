class JoinContestError {
  bool _bIsBlockedUser = false;
  String _title = "";
  String _errorMessage = "";
  List<dynamic> _errorCodes = [];

  JoinContestError(List<dynamic> errors) {
    _errorCodes = errors;
    for (int error in errors) {
      switch (error) {
        case 1:
          _title = "Account Blocked";
          _errorMessage =
              "Your account has been blocked.\nPlease contact us at support@playfantasy.com to get more information.";
          _bIsBlockedUser = true;
          break;
        case 2:
          _title = "Account Closed";
          _errorMessage =
              "Your account has been closed.\nPlease contact us at support@playfantasy.com to get more information.";
          _bIsBlockedUser = true;
          break;
        case 4:
          _title = "Alert";
          _errorMessage =
              "Your age is less than 18.\nYou cannot verificationFor.";
          _bIsBlockedUser = true;
          break;
        case 5:
          _title = "Alert";
          _errorMessage =
              "You are from a blocked state.\nHence, you cannot verificationFor.";
          _bIsBlockedUser = true;
          break;
        case 11:
          _title = "Not in India";
          _errorMessage = "You are not playing from India.";
          _bIsBlockedUser = true;
          break;
        case 13:
          _title = "Not allowed";
          _errorMessage =
              "Contest is for only new users. You have already played contest(s).";
          _bIsBlockedUser = true;
          break;
      }
    }
  }

  String getTitle() {
    return _title;
  }

  String getErrorMessage() {
    return _errorMessage;
  }

  bool isBlockedUser() {
    return _bIsBlockedUser;
  }

  int getErrorCode() {
    if (_errorCodes.indexOf(12) != -1) {
      return 12;
    } else if (_errorCodes.indexOf(3) != -1) {
      return 3;
    } else if (_errorCodes.indexOf(6) != -1 ||
        _errorCodes.indexOf(7) != -1 ||
        _errorCodes.indexOf(8) != -1 ||
        _errorCodes.indexOf(9) != -1) {
      return 6;
    } else {
      return -1;
    }
  }
}
