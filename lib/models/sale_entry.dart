import 'package:equatable/equatable.dart';

/// Satış girişi modelini temsil eden sınıf.
class SaleEntry extends Equatable {
  final String id;
  final String productId;
  final String productName;
  final int quantity;
  final DateTime saleDate;
  final String addedBy;
  final DateTime addedAt;
  final String? storeId;
  final bool isVerified;
  final String? verifiedBy;
  final DateTime? verificationDate;
  
  const SaleEntry({
    required this.id,
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.saleDate,
    required this.addedBy,
    required this.addedAt,
    this.storeId,
    this.isVerified = false,
    this.verifiedBy,
    this.verificationDate,
  });

  /// JSON objesinden SaleEntry oluşturan factory constructor
  factory SaleEntry.fromJson(Map<String, dynamic> json) {
    return SaleEntry(
      id: json['id'] as String,
      productId: json['productId'] as String,
      productName: json['productName'] as String,
      quantity: json['quantity'] as int,
      saleDate: DateTime.parse(json['saleDate'] as String),
      addedBy: json['addedBy'] as String,
      addedAt: DateTime.parse(json['addedAt'] as String),
      storeId: json['storeId'] as String?,
      isVerified: json['isVerified'] as bool? ?? false,
      verifiedBy: json['verifiedBy'] as String?,
      verificationDate: json['verificationDate'] != null
          ? DateTime.parse(json['verificationDate'] as String)
          : null,
    );
  }

  /// SaleEntry objesini JSON'a çeviren metod
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'productId': productId,
      'productName': productName,
      'quantity': quantity,
      'saleDate': saleDate.toIso8601String(),
      'addedBy': addedBy,
      'addedAt': addedAt.toIso8601String(),
      'storeId': storeId,
      'isVerified': isVerified,
      'verifiedBy': verifiedBy,
      'verificationDate': verificationDate?.toIso8601String(),
    };
  }

  /// Satış girişini doğrular
  SaleEntry verify({
    required String verifier,
    required DateTime verificationTime,
  }) {
    return copyWith(
      isVerified: true,
      verifiedBy: verifier,
      verificationDate: verificationTime,
    );
  }

  /// Kopyalama metodu
  SaleEntry copyWith({
    String? id,
    String? productId,
    String? productName,
    int? quantity,
    DateTime? saleDate,
    String? addedBy,
    DateTime? addedAt,
    String? storeId,
    bool? isVerified,
    String? verifiedBy,
    DateTime? verificationDate,
  }) {
    return SaleEntry(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      quantity: quantity ?? this.quantity,
      saleDate: saleDate ?? this.saleDate,
      addedBy: addedBy ?? this.addedBy,
      addedAt: addedAt ?? this.addedAt,
      storeId: storeId ?? this.storeId,
      isVerified: isVerified ?? this.isVerified,
      verifiedBy: verifiedBy ?? this.verifiedBy,
      verificationDate: verificationDate ?? this.verificationDate,
    );
  }

  @override
  List<Object?> get props => [
        id,
        productId,
        productName,
        quantity,
        saleDate,
        addedBy,
        addedAt,
        storeId,
        isVerified,
        verifiedBy,
        verificationDate,
      ];
}
