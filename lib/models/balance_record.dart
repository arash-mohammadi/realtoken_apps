class BalanceRecord {
  final String tokenType;
  double balance;
  DateTime timestamp;

  BalanceRecord({
    required this.tokenType,
    required this.balance,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
        'tokenType': tokenType,
        'balance': balance,
        'timestamp': timestamp.toIso8601String(),
      };

  static BalanceRecord fromJson(Map<String, dynamic> json) {
    return BalanceRecord(
      tokenType: json['tokenType'],
      balance: json['balance'],
      timestamp: DateTime.parse(json['timestamp']),
    );
  }
}