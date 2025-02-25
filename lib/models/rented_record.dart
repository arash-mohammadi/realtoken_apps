class RentedRecord {
  double percentage;
  DateTime timestamp;

  RentedRecord({
    required this.percentage,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
        'percentage': percentage,
        'timestamp': timestamp.toIso8601String(),
      };

  static RentedRecord fromJson(Map<String, dynamic> json) {
    return RentedRecord(
      percentage: json['percentage'],
      timestamp: DateTime.parse(json['timestamp']),
    );
  }
}
