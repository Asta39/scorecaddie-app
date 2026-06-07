import 'dart:convert';

enum NotificationType {
  leaderboardRankUp,
  leaderboardRankDown,
  friendOvertook,
  enteredTopTen,
  handicapImproved,
  personalBest,
  friendJoined,
  friendCompletedRound,
}

class AppNotification {
  final String id;
  final NotificationType type;
  final String title;
  final String body;
  final Map<String, dynamic> payload;
  final bool read;
  final DateTime createdAt;

  AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.payload,
    required this.read,
    required this.createdAt,
  });

  factory AppNotification.fromSupabase(Map<String, dynamic> data) {
    Map<String, dynamic> parsedPayload = {};
    if (data['dataJson'] != null) {
      try {
        parsedPayload = jsonDecode(data['dataJson'] as String);
      } catch (_) {}
    }

    final typeStr = parsedPayload['type'] ?? 'friendJoined';

    return AppNotification(
      id: data['id'],
      type: NotificationType.values.firstWhere(
        (e) => e.name == typeStr,
        orElse: () => NotificationType.friendJoined,
      ),
      title: data['title'] ?? '',
      body: data['body'] ?? '',
      payload: parsedPayload,
      read: data['isRead'] ?? false,
      createdAt: DateTime.parse(data['createdAt'] as String),
    );
  }
}
