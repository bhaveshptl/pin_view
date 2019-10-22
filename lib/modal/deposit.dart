class Deposit {
  String bannerImage;
  bool bAllowRepeatDeposit;
  bool bshowBonusDistribution;
  bool bShowLockedAmount;
  Map<String, dynamic> refreshData;
  ChooseAmountData chooseAmountData;

  Deposit({
    this.bannerImage,
    this.refreshData,
    this.chooseAmountData,
    this.bAllowRepeatDeposit,
    this.bshowBonusDistribution,
    this.bShowLockedAmount = false,
  });

  factory Deposit.fromJson(Map<String, dynamic> json) {
    return Deposit(
      bannerImage: json["bannerImage"],
      refreshData: json["refreshData"],
      bshowBonusDistribution: json["showBonusDistribution"],
      chooseAmountData: ChooseAmountData.fromJson(json["chooseAmountData"]),
      bAllowRepeatDeposit:
          json["repeatAllowed"] == null ? false : json["repeatAllowed"],
      bShowLockedAmount: 
          json["bShowLockedAmount"] == null ? false : json["bShowLockedAmount"],
    );
  }
}

class ChooseAmountData {
  int minAmount;
  Balance balance;
  int depositLimit;
  bool isFirstDeposit;
  List<int> amountTiles;
  List<int> hotTiles;
  List<int> bestTiles;
  List<dynamic> bonusArray;
  List<dynamic> lastPaymentArray;
  int addCashPromoAb;

  ChooseAmountData({
    this.balance,
    this.minAmount,
    this.bonusArray,
    this.amountTiles,
    this.hotTiles,
    this.bestTiles,
    this.depositLimit,
    this.isFirstDeposit,
    this.lastPaymentArray,
    this.addCashPromoAb,
  });

  factory ChooseAmountData.fromJson(Map<String, dynamic> json) {
    return ChooseAmountData(
      minAmount: json["minAmount"],
      bonusArray: json["bonusArray"],
      depositLimit: json["depositLimit"],
      addCashPromoAb: json["addCashPromoAb"],
      balance: Balance.fromJson(json["balance"]),
      lastPaymentArray: json["lastPaymentArray"],
      isFirstDeposit:
          json["isFirstDeposit"] == null ? false : json["isFirstDeposit"],
      amountTiles:
          (json["amountTiles"] as List).map((i) => (i as int).toInt()).toList(),
      hotTiles:
          (json["hotTiles"] as List).map((i) => (i as int).toInt()).toList(),
      bestTiles: 
          json["bestTiles"] == null 
          ? []
          : (json["bestTiles"] as List).map((i) => (i as int).toInt()).toList(),
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
