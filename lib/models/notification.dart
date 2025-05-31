import 'package:equatable/equatable.dart';

// Firebase yerine kendi Timestamp sınıfımızı oluşturuyoruz
class Timestamp {
  final int seconds;
  final int nanoseconds;
  
  const Timestamp(this.seconds, this.nanoseconds);
  
  factory Timestamp.now() {
    final now = DateTime.now();
    return Timestamp.fromDate(now);
  }
  
  factory Timestamp.fromDate(DateTime date) {
    final milliseconds = date.millisecondsSinceEpoch;
    final seconds = (milliseconds / 1000).floor();
    final nanoseconds = (milliseconds % 1000) * 1000000;
    return Timestamp(seconds, nanoseconds);
  }
  
  DateTime toDate() {
    return DateTime.fromMillisecondsSinceEpoch(seconds * 1000 + (nanoseconds / 1000000).floor());
  }
}

class NotificationType {
  static const String stock = 'stock';
  static const String skt = 'skt';
  static const String count = 'count';
  static const String announcement = 'announcement';
}

class NotificationModel extends Equatable {
  final String id;
  final String title;
  final String body;
  final String type;
  final String userId;
  final DateTime createdAt;
  final bool isRead;

  const NotificationModel({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.userId,
    required this.createdAt,
    this.isRead = false,
  });

  factory NotificationModel.fromMap(Map<String, dynamic> map) {
    return NotificationModel(
      id: map['id'] as String,
      title: map['title'] as String,
      body: map['body'] as String,
      type: map['type'] as String,
      userId: map['userId'] as String,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      isRead: map['isRead'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'body': body,
      'type': type,
      'userId': userId,
      'createdAt': Timestamp.fromDate(createdAt),
      'isRead': isRead,
    };
  }

  NotificationModel copyWith({
    String? id,
    String? title,
    String? body,
    String? type,
    String? userId,
    DateTime? createdAt,
    bool? isRead,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      type: type ?? this.type,
      userId: userId ?? this.userId,
      createdAt: createdAt ?? this.createdAt,
      isRead: isRead ?? this.isRead,
    );
  }

  @override
  List<Object?> get props => [
        id,
        title,
        body,
        type,
        userId,
        createdAt,
        isRead,
      ];
}
