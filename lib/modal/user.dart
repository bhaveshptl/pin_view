class User {
  final int userId;
  final int langId;
  final String mobile;
  final String emailId;
  final bool isNewUser;
  final int authStatus;
  final String lastName;
  final String loginName;
  final String firstName;
  final double withdrawable;
  final double depositBucket;
  final double nonWithdrawable;
  final double nonPlayableBucket;
  final VerificationStatus verificationStatus;

  User({
    this.userId,
    this.mobile,
    this.langId,
    this.emailId,
    this.lastName,
    this.loginName,
    this.firstName,
    this.isNewUser,
    this.authStatus,
    this.withdrawable,
    this.depositBucket,
    this.nonWithdrawable,
    this.nonPlayableBucket,
    this.verificationStatus,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      mobile: json['mobile'],
      langId: json['lang_id'],
      userId: json['user_id'],
      emailId: json['email_id'],
      lastName: json['last_name'],
      isNewUser: json['isNewUser'],
      firstName: json['first_name'],
      loginName: json['login_name'],
      authStatus: json['auth_status'],
      withdrawable: json["withdrawable"] == null
          ? 0.0
          : (json["withdrawable"]).toDouble(),
      depositBucket: json["depositBucket"] == null
          ? 0.0
          : (json["depositBucket"]).toDouble(),
      nonWithdrawable: json["nonWithdrawable"] == null
          ? 0.0
          : (json["nonWithdrawable"]).toDouble(),
      nonPlayableBucket: json["nonPlayableBucket"] == null
          ? 0.0
          : (json["nonPlayableBucket"]).toDouble(),
      verificationStatus: json['verificationStatus'] == null
          ? VerificationStatus()
          : VerificationStatus.fromJson(json['verificationStatus']),
    );
  }
}

class VerificationStatus {
  final String addressVerification;
  final bool emailVerification;
  final bool mobileVerification;
  final String panVerification;

  VerificationStatus({
    this.panVerification = "",
    this.addressVerification = "",
    this.emailVerification = false,
    this.mobileVerification = false,
  });

  factory VerificationStatus.fromJson(Map<String, dynamic> json) {
    return VerificationStatus(
      panVerification: json["pan_verification"],
      emailVerification: json["email_verification"],
      mobileVerification: json["mobile_verification"],
      addressVerification: json["address_verification"],
    );
  }
}
