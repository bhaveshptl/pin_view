import 'package:playfantasy/utils/stringtable.dart';

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
          _title = strings.get("ACCOUNT_BLOCKED");
          _errorMessage = strings.get("AC_BLOCKED_MSG");
          _bIsBlockedUser = true;
          break;
        case 2:
          _title = strings.get("ACCOUNT_CLOSED");
          _errorMessage = strings.get("AC_CLOSED_MSG");
          _bIsBlockedUser = true;
          break;
        case 4:
          _title = strings.get("ALERT");
          _errorMessage = strings.get("AGE_LESS_MSG");
          _bIsBlockedUser = true;
          break;
        case 5:
          _title = strings.get("ALERT");
          _errorMessage = strings.get("STATE_BLOCKED_MSG");
          _bIsBlockedUser = true;
          break;
        case 11:
          _title = strings.get("N_I_A");
          _errorMessage = strings.get("NOT_IN_INDIA_MSG");
          _bIsBlockedUser = true;
          break;
        case 13:
          _title = strings.get("NOT_ALLOWED");
          _errorMessage = strings.get("CONTEST_FOR_NEW");
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
    if (_errorCodes.indexOf(12) != -1 || _errorCodes.indexOf(-7) != -1) {
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
