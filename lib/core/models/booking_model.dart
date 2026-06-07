enum BookingStatus { pending, confirmed, inProgress, completed, cancelled }
enum RoundType { eighteenHoles, frontNine, backNine }
enum InitiatedVia { call, chat }

class BookingModel {
  final String id;
  final String playerId;
  final String providerId;
  final DateTime bookingDate;
  final String status;
  final String initiatedVia;
  final String roundType;
  final DateTime? startTime;
  final DateTime? endTime;
  final int? durationMinutes;
  final double? amountPaid;
  final String? paymentMethod;

  BookingModel({
    required this.id,
    required this.playerId,
    required this.providerId,
    required this.bookingDate,
    required this.status,
    required this.initiatedVia,
    required this.roundType,
    this.startTime,
    this.endTime,
    this.durationMinutes,
    this.amountPaid,
    this.paymentMethod,
  });

  factory BookingModel.fromJson(Map<String, dynamic> json) {
    return BookingModel(
      id: json['id'],
      playerId: json['player_id'] ?? json['playerId'] ?? '',
      providerId: json['provider_id'] ?? json['providerId'] ?? json['caddieId'] ?? '',
      bookingDate: DateTime.parse(json['booking_date'] ?? json['bookingDate']),
      status: json['status'],
      initiatedVia: json['initiated_via'] ?? json['initiatedVia'],
      roundType: json['round_type'] ?? json['roundType'],
      startTime: (json['start_time'] ?? json['startTime']) != null ? DateTime.parse(json['start_time'] ?? json['startTime']) : null,
      endTime: (json['end_time'] ?? json['endTime']) != null ? DateTime.parse(json['end_time'] ?? json['endTime']) : null,
      durationMinutes: json['duration_minutes'] ?? json['durationMinutes'],
      amountPaid: json['amount_paid'] != null ? (json['amount_paid'] as num).toDouble() : (json['amountPaid'] != null ? (json['amountPaid'] as num).toDouble() : null),
      paymentMethod: json['payment_method'] ?? json['paymentMethod'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'player_id': playerId,
      'provider_id': providerId,
      'booking_date': bookingDate.toIso8601String(),
      'status': status,
      'initiated_via': initiatedVia,
      'round_type': roundType,
      'start_time': startTime?.toIso8601String(),
      'end_time': endTime?.toIso8601String(),
      'duration_minutes': durationMinutes,
      'amount_paid': amountPaid,
      'payment_method': paymentMethod,
    };
  }

  BookingModel copyWith({
    String? status,
    DateTime? startTime,
    DateTime? endTime,
    int? durationMinutes,
    double? amountPaid,
    String? paymentMethod,
  }) {
    return BookingModel(
      id: id,
      playerId: playerId,
      providerId: providerId,
      bookingDate: bookingDate,
      status: status ?? this.status,
      initiatedVia: initiatedVia,
      roundType: roundType,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      amountPaid: amountPaid ?? this.amountPaid,
      paymentMethod: paymentMethod ?? this.paymentMethod,
    );
  }
}
