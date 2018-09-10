class SignInError {
  SignInError({String error});

  factory SignInError.fromJson(Map<String, dynamic> json) {
    return SignInError(error: json['error']);
  }
}
