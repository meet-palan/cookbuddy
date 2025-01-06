class TransactionModel {
  int? id;
  int recipeId;
  int buyerId;
  int sellerId;
  int credits;
  DateTime transactionDate;

  TransactionModel({
    this.id,
    required this.recipeId,
    required this.buyerId,
    required this.sellerId,
    required this.credits,
    required this.transactionDate,
  });

  // Convert a Transaction object to a Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'recipeId': recipeId,
      'buyerId': buyerId,
      'sellerId': sellerId,
      'credits': credits,
      'transactionDate': transactionDate.toIso8601String(),
    };
  }

  // Convert a Map to a Transaction object
  factory TransactionModel.fromMap(Map<String, dynamic> map) {
    return TransactionModel(
      id: map['id'],
      recipeId: map['recipeId'],
      buyerId: map['buyerId'],
      sellerId: map['sellerId'],
      credits: map['credits'],
      transactionDate: DateTime.parse(map['transactionDate']),
    );
  }
}
