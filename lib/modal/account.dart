class Account {
  double bonusAmount;
  double totalBalance;
  double winningAmount;
  double depositAmount;
  double unreleasedBonus;
  List<Transaction> recentTransactions;

  Account({
    this.bonusAmount = 0.0,
    this.totalBalance = 0.0,
    this.depositAmount = 0.0,
    this.winningAmount = 0.0,
    this.unreleasedBonus = 0.0,
    this.recentTransactions,
  });

  factory Account.fromJson(Map<String, dynamic> json) {
    return Account(
      bonusAmount: (json["bonusAmount"]).toDouble(),
      totalBalance: (json["totalBalance"]).toDouble(),
      depositAmount: (json["depositAmount"]).toDouble(),
      winningAmount: (json["winningAmount"]).toDouble(),
      unreleasedBonus: (json["unreleasedBonus"]).toDouble(),
      recentTransactions: (json["recentTransactions"] as List)
          .map((i) => Transaction.fromJson(i))
          .toList(),
    );
  }
}

class Transaction {
  int id;
  bool debit;
  String date;
  String type;
  String txnId;
  double amount;
  String bucket;

  Transaction({
    this.id,
    this.date,
    this.type,
    this.debit,
    this.txnId,
    this.amount,
    this.bucket,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json["id"],
      date: json["date"],
      type: json["type"],
      debit: json["debit"],
      txnId: json["txnId"],
      bucket: json["bucket"],
      amount: (json["amount"]).toDouble(),
    );
  }
}
