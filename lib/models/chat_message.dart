import 'package:equatable/equatable.dart';

enum MessageType {
  text,    // Metin mesajı
  image,   // Görsel mesajı
  system,  // Sistem mesajı (bildirim)
  pinned,  // Sabitlenmiş mesaj
}

/// Sohbet mesaj modelini temsil eden sınıf.
class ChatMessage extends Equatable {
  final String id;
  final String senderId;
  final String senderName;
  final String? senderPhotoUrl;
  final String content;
  final String? imageUrl;
  final DateTime timestamp;
  final bool isRead;
  final MessageType type;
  final DateTime? pinnedUntil; // Mesajın sabitlenmiş kalacağı süre
  final bool isDeleted;
  final bool isEdited;
  final String? storeId; // Hangi mağaza sohbetine ait
  
  const ChatMessage({
    required this.id,
    required this.senderId,
    required this.senderName,
    this.senderPhotoUrl,
    required this.content,
    this.imageUrl,
    required this.timestamp,
    this.isRead = false,
    this.type = MessageType.text,
    this.pinnedUntil,
    this.isDeleted = false,
    this.isEdited = false,
    this.storeId,
  });

  /// JSON objesinden ChatMessage oluşturan factory constructor
  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] as String,
      senderId: json['senderId'] as String,
      senderName: json['senderName'] as String,
      senderPhotoUrl: json['senderPhotoUrl'] as String?,
      content: json['content'] as String,
      imageUrl: json['imageUrl'] as String?,
      timestamp: DateTime.parse(json['timestamp'] as String),
      isRead: json['isRead'] as bool? ?? false,
      type: MessageType.values.firstWhere(
        (e) => e.toString() == 'MessageType.${json['type']}',
        orElse: () => MessageType.text,
      ),
      pinnedUntil: json['pinnedUntil'] != null
          ? DateTime.parse(json['pinnedUntil'] as String)
          : null,
      isDeleted: json['isDeleted'] as bool? ?? false,
      isEdited: json['isEdited'] as bool? ?? false,
      storeId: json['storeId'] as String?,
    );
  }

  /// ChatMessage objesini JSON'a çeviren metod
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'senderId': senderId,
      'senderName': senderName,
      'senderPhotoUrl': senderPhotoUrl,
      'content': content,
      'imageUrl': imageUrl,
      'timestamp': timestamp.toIso8601String(),
      'isRead': isRead,
      'type': type.toString().split('.').last,
      'pinnedUntil': pinnedUntil?.toIso8601String(),
      'isDeleted': isDeleted,
      'isEdited': isEdited,
      'storeId': storeId,
    };
  }

  /// Mesajı okundu olarak işaretler
  ChatMessage markAsRead() {
    return copyWith(isRead: true);
  }

  /// Mesajı düzenler
  ChatMessage editMessage(String newContent) {
    return copyWith(
      content: newContent,
      isEdited: true,
    );
  }

  /// Mesajı siler (gerçekten silmez, silinmiş olarak işaretler)
  ChatMessage delete() {
    return copyWith(
      isDeleted: true,
      content: "Bu mesaj silindi",
    );
  }

  /// Mesajı sabitler
  ChatMessage pin(DateTime until) {
    return copyWith(
      type: MessageType.pinned,
      pinnedUntil: until,
    );
  }

  /// Mesajın sabitlemesini kaldırır
  ChatMessage unpin() {
    return copyWith(
      type: MessageType.text,
      pinnedUntil: null,
    );
  }

  /// Kopyalama metodu
  ChatMessage copyWith({
    String? id,
    String? senderId,
    String? senderName,
    String? senderPhotoUrl,
    String? content,
    String? imageUrl,
    DateTime? timestamp,
    bool? isRead,
    MessageType? type,
    DateTime? pinnedUntil,
    bool? isDeleted,
    bool? isEdited,
    String? storeId,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      senderPhotoUrl: senderPhotoUrl ?? this.senderPhotoUrl,
      content: content ?? this.content,
      imageUrl: imageUrl ?? this.imageUrl,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      type: type ?? this.type,
      pinnedUntil: pinnedUntil ?? this.pinnedUntil,
      isDeleted: isDeleted ?? this.isDeleted,
      isEdited: isEdited ?? this.isEdited,
      storeId: storeId ?? this.storeId,
    );
  }

  @override
  List<Object?> get props => [
        id,
        senderId,
        senderName,
        senderPhotoUrl,
        content,
        imageUrl,
        timestamp,
        isRead,
        type,
        pinnedUntil,
        isDeleted,
        isEdited,
        storeId,
      ];
}
