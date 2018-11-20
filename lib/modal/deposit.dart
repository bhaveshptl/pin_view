class Deposit {
  String bannerImage;
  ChooseAmountData chooseAmountData;
  Map<String, dynamic> refreshData;

  Deposit({
    this.bannerImage,
    this.refreshData,
    this.chooseAmountData,
  });

  factory Deposit.fromJson(Map<String, dynamic> json) {
    return Deposit(
      bannerImage: json["bannerImage"],
      refreshData: json["refreshData"],
      chooseAmountData: ChooseAmountData.fromJson(json["chooseAmountData"]),
    );
  }
}

class ChooseAmountData {
  int minAmount;
  Balance balance;
  int depositLimit;
  bool isFirstDeposit;
  List<int> amountTiles;
  List<dynamic> bonusArray;
  List<dynamic> lastPaymentArray;

  ChooseAmountData({
    this.balance,
    this.minAmount,
    this.bonusArray,
    this.amountTiles,
    this.depositLimit,
    this.isFirstDeposit,
    this.lastPaymentArray,
  });

  factory ChooseAmountData.fromJson(Map<String, dynamic> json) {
    return ChooseAmountData(
      minAmount: json["minAmount"],
      bonusArray: json["bonusArray"],
      depositLimit: json["depositLimit"],
      isFirstDeposit: json["isFirstDeposit"],
      balance: Balance.fromJson(json["balance"]),
      lastPaymentArray: json["lastPaymentArray"],
      amountTiles:
          (json["amountTiles"] as List).map((i) => (i as int).toInt()).toList(),
    );
  }
}

class Balance {
  double deposited;
  double nonPlayable;
  double withdrawable;
  double nonWithdrawable;

  Balance({
    this.deposited = 0.0,
    this.nonPlayable = 0.0,
    this.withdrawable = 0.0,
    this.nonWithdrawable = 0.0,
  });

  factory Balance.fromJson(Map<String, dynamic> json) {
    return Balance(
      deposited: (json["deposited"]).toDouble(),
      nonPlayable: (json["nonPlayable"]).toDouble(),
      withdrawable: (json["withdrawable"]).toDouble(),
      nonWithdrawable: (json["nonWithdrawable"]).toDouble(),
    );
  }
}
