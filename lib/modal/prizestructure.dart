class PrizeStructureRange {
  final String rank;
  final double amount;

  PrizeStructureRange({
    this.rank,
    this.amount,
  });

  factory PrizeStructureRange.fromJson(Map<String, dynamic> json) {
    return PrizeStructureRange(
      rank: json['rank'],
      amount: (json['amount']).toDouble(),
    );
  }
}

class PrizeStructure {
  final int rank;
  double amount;

  PrizeStructure({
    this.rank,
    this.amount,
  });

  factory PrizeStructure.fromJson(Map<String, dynamic> json) {
    return PrizeStructure(
      rank: json['rank'],
      amount: (json['amount']).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
        "rank": rank,
        "amount": amount,
      };
}
