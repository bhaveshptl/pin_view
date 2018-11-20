class Withhdraw {
  final String accountNumber;
  final String loginName;
  final String ifscCode;
  final int numberOfFreeWithdraw;
  final int totalWithdraw;
  int withdrawCost;
  final int minWithdraw;
  final int maxWithdraw;
  final int paytmMaxWithdraw;
  final int paytmMinWithdraw;
  final double withdrawableAmount;
  final String mobile;
  final String panVerification;
  final bool mobileVerification;
  final String addressVerification;

  Withhdraw({
    this.withdrawableAmount,
    this.loginName,
    this.accountNumber,
    this.ifscCode,
    this.numberOfFreeWithdraw,
    this.totalWithdraw,
    this.withdrawCost,
    this.minWithdraw,
    this.paytmMinWithdraw,
    this.maxWithdraw,
    this.paytmMaxWithdraw,
    this.mobile,
    this.mobileVerification,
    this.panVerification,
    this.addressVerification,
  });

  factory Withhdraw.fromJson(Map<String, dynamic> json) {
    if (json == null) {
      return Withhdraw();
    } else {
      return Withhdraw(
        mobile: json["mobile"],
        ifscCode: json["ifsc_code"],
        loginName: json["login_name"],
        minWithdraw: json["minWithdraw"],
        maxWithdraw: json["maxWithdraw"],
        withdrawCost: json["withdrawCost"],
        totalWithdraw: json["totalWithdraw"],
        accountNumber: json["account_number"],
        paytmMaxWithdraw: json["paytmMaxWithdraw"],
        paytmMinWithdraw: json["paytmMinWithdraw"],
        numberOfFreeWithdraw: json["numberOfFreeWithdraw"],
        withdrawableAmount: (json["withdrawableAmount"]).toDouble(),
        addressVerification: json["address_verification"],
        mobileVerification: json["mobile_verification"],
        panVerification: json["pan_verification"],
      );
    }
  }
}
