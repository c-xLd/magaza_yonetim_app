import 'package:equatable/equatable.dart';

class ProductCount extends Equatable {
  final String id;
  final String productId;
  final int countedQuantity;
  final String countedBy; // Sayan kullanıcının ID'si
  final String groupId; // Hangi grup için sayıldığı
  final DateTime countDate;
  final String? notes;
  final bool isVerified; // Yönetici onayı olup olmadığı
  final String? verifiedBy; // Onaylayan yönetici ID'si
  final DateTime? verificationDate;
  final String? storeId; // Mağaza ID'si
  final String? locationInStore; // Mağaza içindeki konum

  const ProductCount({
    required this.id,
    required this.productId,
    required this.countedQuantity,
    required this.countedBy,
    required this.groupId,
    required this.countDate,
    this.notes,
    this.isVerified = false,
    this.verifiedBy,
    this.verificationDate,
    this.storeId,
    this.locationInStore,
  });

  factory ProductCount.fromJson(Map<String, dynamic> json) {
    return ProductCount(
      id: json['id'] as String,
      productId: json['productId'] as String,
      countedQuantity: json['countedQuantity'] as int,
      countedBy: json['countedBy'] as String,
      groupId: json['groupId'] as String,
      countDate: DateTime.parse(json['countDate'] as String),
      notes: json['notes'] as String?,
      isVerified: json['isVerified'] as bool? ?? false,
      verifiedBy: json['verifiedBy'] as String?,
      verificationDate: json['verificationDate'] != null
          ? DateTime.parse(json['verificationDate'] as String)
          : null,
      storeId: json['storeId'] as String?,
      locationInStore: json['locationInStore'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'productId': productId,
      'countedQuantity': countedQuantity,
      'countedBy': countedBy,
      'groupId': groupId,
      'countDate': countDate.toIso8601String(),
      'notes': notes,
      'isVerified': isVerified,
      'verifiedBy': verifiedBy,
      'verificationDate': verificationDate?.toIso8601String(),
      'storeId': storeId,
      'locationInStore': locationInStore,
    };
  }

  // Sayımı doğrulamak için kopyalama metodu
  ProductCount verify({
    required String verifiedById,
    required DateTime verificationDateTime,
  }) {
    return ProductCount(
      id: id,
      productId: productId,
      countedQuantity: countedQuantity,
      countedBy: countedBy,
      groupId: groupId,
      countDate: countDate,
      notes: notes,
      isVerified: true,
      verifiedBy: verifiedById,
      verificationDate: verificationDateTime,
      storeId: storeId,
      locationInStore: locationInStore,
    );
  }
  
  // Sayıma not eklemek için (immutable pattern)
  ProductCount addNote(String additionalNote) {
    // Eski not varsa, yeni notu ona ekle
    final updatedNotes = notes != null && notes!.isNotEmpty
        ? '$notes\n$additionalNote'
        : additionalNote;
    
    return ProductCount(
      id: id,
      productId: productId,
      countedQuantity: countedQuantity,
      countedBy: countedBy,
      groupId: groupId,
      countDate: countDate,
      notes: updatedNotes,
      isVerified: isVerified,
      verifiedBy: verifiedBy,
      verificationDate: verificationDate,
      storeId: storeId,
      locationInStore: locationInStore,
    );
  }

  @override
  List<Object?> get props => [
        id,
        productId,
        countedQuantity,
        countedBy,
        groupId,
        countDate,
        notes,
        isVerified,
        verifiedBy,
        verificationDate,
        storeId,
        locationInStore,
      ];
}
