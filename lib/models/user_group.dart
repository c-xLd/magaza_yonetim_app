import 'package:equatable/equatable.dart';

class UserGroup extends Equatable {
  final String id;
  final String name;
  final String description;
  final List<String> userIds;
  final List<String>? assignedProductIds;
  final DateTime createdAt;
  final String createdBy;
  final bool isActive;

  const UserGroup({
    required this.id,
    required this.name,
    required this.description,
    required this.userIds,
    this.assignedProductIds,
    required this.createdAt,
    required this.createdBy,
    this.isActive = true,
  });

  factory UserGroup.fromJson(Map<String, dynamic> json) {
    return UserGroup(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      userIds: (json['userIds'] as List<dynamic>).map((e) => e as String).toList(),
      assignedProductIds: json['assignedProductIds'] != null
          ? (json['assignedProductIds'] as List<dynamic>).map((e) => e as String).toList()
          : null,
      createdAt: DateTime.parse(json['createdAt'] as String),
      createdBy: json['createdBy'] as String,
      isActive: json['isActive'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'userIds': userIds,
      'assignedProductIds': assignedProductIds,
      'createdAt': createdAt.toIso8601String(),
      'createdBy': createdBy,
      'isActive': isActive,
    };
  }

  // Yeni kullanıcı eklemek için kopyalama metodu
  UserGroup copyWith({
    String? id,
    String? name,
    String? description,
    List<String>? userIds,
    List<String>? assignedProductIds,
    DateTime? createdAt,
    String? createdBy,
    bool? isActive,
  }) {
    return UserGroup(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      userIds: userIds ?? this.userIds,
      assignedProductIds: assignedProductIds ?? this.assignedProductIds,
      createdAt: createdAt ?? this.createdAt,
      createdBy: createdBy ?? this.createdBy,
      isActive: isActive ?? this.isActive,
    );
  }

  // Kullanıcı eklemek için yardımcı metod
  UserGroup addUser(String userId) {
    final updatedUserIds = List<String>.from(userIds);
    if (!updatedUserIds.contains(userId)) {
      updatedUserIds.add(userId);
    }
    return copyWith(userIds: updatedUserIds);
  }

  // Kullanıcı çıkarmak için yardımcı metod
  UserGroup removeUser(String userId) {
    final updatedUserIds = List<String>.from(userIds);
    updatedUserIds.remove(userId);
    return copyWith(userIds: updatedUserIds);
  }

  // Ürün atamak için yardımcı metod
  UserGroup assignProduct(String productId) {
    final currentProducts = assignedProductIds ?? [];
    final updatedProducts = List<String>.from(currentProducts);
    if (!updatedProducts.contains(productId)) {
      updatedProducts.add(productId);
    }
    return copyWith(assignedProductIds: updatedProducts);
  }

  // Ürün çıkarmak için yardımcı metod
  UserGroup removeProduct(String productId) {
    final currentProducts = assignedProductIds ?? [];
    final updatedProducts = List<String>.from(currentProducts);
    updatedProducts.remove(productId);
    return copyWith(assignedProductIds: updatedProducts);
  }

  @override
  List<Object?> get props => [
        id,
        name,
        description,
        userIds,
        assignedProductIds,
        createdAt,
        createdBy,
        isActive,
      ];
}
