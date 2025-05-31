import 'package:equatable/equatable.dart';

/// Mağaza modelini temsil eden sınıf.
class Store extends Equatable {
  final String id;
  final String name;
  final String address;
  final String? phoneNumber;
  final String? managerUserId;
  final bool isActive;
  final String? location; // Konum bilgisi (enlem, boylam)
  final DateTime createdAt;
  final String createdBy;

  const Store({
    required this.id,
    required this.name,
    required this.address,
    this.phoneNumber,
    this.managerUserId,
    required this.isActive,
    this.location,
    required this.createdAt,
    required this.createdBy,
  });

  /// JSON objesinden Store oluşturan factory constructor
  factory Store.fromJson(Map<String, dynamic> json) {
    return Store(
      id: json['id'] as String,
      name: json['name'] as String,
      address: json['address'] as String,
      phoneNumber: json['phoneNumber'] as String?,
      managerUserId: json['managerUserId'] as String?,
      isActive: json['isActive'] as bool,
      location: json['location'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      createdBy: json['createdBy'] as String,
    );
  }

  /// Store objesini JSON'a çeviren metod
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'phoneNumber': phoneNumber,
      'managerUserId': managerUserId,
      'isActive': isActive,
      'location': location,
      'createdAt': createdAt.toIso8601String(),
      'createdBy': createdBy,
    };
  }

  /// Kopyalama metodu
  Store copyWith({
    String? id,
    String? name,
    String? address,
    String? phoneNumber,
    String? managerUserId,
    bool? isActive,
    String? location,
    DateTime? createdAt,
    String? createdBy,
  }) {
    return Store(
      id: id ?? this.id,
      name: name ?? this.name,
      address: address ?? this.address,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      managerUserId: managerUserId ?? this.managerUserId,
      isActive: isActive ?? this.isActive,
      location: location ?? this.location,
      createdAt: createdAt ?? this.createdAt,
      createdBy: createdBy ?? this.createdBy,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        address,
        phoneNumber,
        managerUserId,
        isActive,
        location,
        createdAt,
        createdBy,
      ];
}
