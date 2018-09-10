class User {
  final int userId;
  final String loginName;
  final String emailId;
  final String mobile;
  final int authStatus;
  final String firstName;
  final bool isNewUser;
  final int langId;

  User(
      {this.userId,
      this.loginName,
      this.emailId,
      this.mobile,
      this.authStatus,
      this.firstName,
      this.isNewUser,
      this.langId});

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
        userId: json['user_id'],
        loginName: json['login_name'],
        emailId: json['email_id'],
        mobile: json['mobile'],
        authStatus: json['auth_status'],
        firstName: json['first_name'],
        isNewUser: json['isNewUser'],
        langId: json['lang_id']);
  }
}
