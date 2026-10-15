class CallRecord {
  const CallRecord({
    required this.contactName,
    required this.direction,
    required this.createdAt,
    this.missed = false,
    this.video = false,
  });

  final String contactName;
  final String direction; // incoming | outgoing
  final DateTime createdAt;
  final bool missed;
  final bool video;
}
