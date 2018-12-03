class Profile {
  String dob;
  String city;
  int pincode;
  String lname;
  String fname;
  String email;
  String state;
  String gender;
  String mobile;
  double balance;
  String teamName;
  String address1;
  String address2;
  bool hasPassword;
  List<dynamic> states;
  bool emailVerification;
  bool mobileVerification;
  bool isUserNameChangeAllowed;

  Profile({
    this.dob,
    this.city,
    this.email,
    this.state,
    this.lname,
    this.fname,
    this.gender,
    this.mobile,
    this.states,
    this.pincode,
    this.teamName,
    this.address1,
    this.address2,
    this.balance = 0.0,
    this.hasPassword = false,
    this.emailVerification = false,
    this.mobileVerification = false,
    this.isUserNameChangeAllowed = false,
  });

  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      dob: json["dob"],
      city: json["city"],
      email: json["email"],
      state: json["state"],
      lname: json["lname"],
      fname: json["fname"],
      gender: json["gender"],
      mobile: json["mobile"],
      states: json["states"],
      pincode: json["pincode"],
      teamName: json["teamName"],
      address1: json["address1"],
      address2: json["address2"],
      hasPassword: json["hasPassword"],
      balance: (json["balance"]).toDouble(),
      emailVerification: json["emailVerification"],
      mobileVerification: json["mobileVerification"],
      isUserNameChangeAllowed: json["isUserNameChangeAllowed"],
    );
  }
}
