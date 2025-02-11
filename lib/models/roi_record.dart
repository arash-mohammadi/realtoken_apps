class RoiRecord {
  double roi;
  DateTime timestamp;

  RoiRecord({
    required this.roi,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
        'roi': roi,
        'timestamp': timestamp.toIso8601String(),
      };

  static RoiRecord fromJson(Map<String, dynamic> json) {
    return RoiRecord(
      roi: json['roi'],
      timestamp: DateTime.parse(json['timestamp']),
    );
  }
}
