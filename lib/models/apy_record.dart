class ApyRecord {
  double netApy;
  double grossApy;
  DateTime timestamp;

  ApyRecord({
    required this.netApy,
    required this.grossApy,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
        'netApy': netApy,
        'grossApy': grossApy,
        'timestamp': timestamp.toIso8601String(),
      };

  static ApyRecord fromJson(Map<String, dynamic> json) {
    return ApyRecord(
      netApy: (json['netApy'] ?? 0.0) as double,
      grossApy: (json['grossApy'] ?? 0.0) as double,
      timestamp: DateTime.parse(json['timestamp'] ?? DateTime.now().toIso8601String()),
    );
  }
}