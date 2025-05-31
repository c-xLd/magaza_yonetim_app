import 'package:equatable/equatable.dart';

// Atama durumlarını tanımlayan enum
enum AssignmentStatus {
  pending,   // Beklemede
  active,    // Aktif
  completed, // Tamamlandı
  verified,  // Onaylandı
  expired    // Süresi doldu
}

// Enum değerlerini string'e dönüştürmek için extension
extension AssignmentStatusExtension on AssignmentStatus {
  String get name {
    switch (this) {
      case AssignmentStatus.pending:
        return 'Beklemede';
      case AssignmentStatus.active:
        return 'Aktif';
      case AssignmentStatus.completed:
        return 'Tamamlandı';
      case AssignmentStatus.verified:
        return 'Onaylandı';
      case AssignmentStatus.expired:
        return 'Süresi Doldu';
    }
  }

  // String'den enum'a dönüştürmek için yardımcı metod
  static AssignmentStatus fromString(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
      case 'beklemede':
        return AssignmentStatus.pending;
      case 'active':
      case 'aktif':
        return AssignmentStatus.active;
      case 'completed':
      case 'tamamlandı':
        return AssignmentStatus.completed;
      case 'verified':
      case 'onaylandı':
        return AssignmentStatus.verified;
      case 'expired':
      case 'süresi doldu':
        return AssignmentStatus.expired;
    }
    print('Bilinmeyen AssignmentStatus string: $status');
    return AssignmentStatus.pending; // Güvenli bir varsayılan
  }
}

class ProductAssignment extends Equatable {
  final String id;
  final String groupId;           // Hangi gruba atandığı
  final List<String> productIds;  // Atanan ürün ID'leri
  final DateTime assignedDate;
  final String assignedBy;
  final DateTime deadlineDate;    // Tamamlanması gereken tarih
  final AssignmentStatus status;
  final String? notes;
  final DateTime? completedDate;
  final String? storeId;

  const ProductAssignment({
    required this.id,
    required this.groupId,
    required this.productIds,
    required this.assignedDate,
    required this.assignedBy,
    required this.deadlineDate,
    this.status = AssignmentStatus.pending,
    this.notes,
    this.completedDate,
    this.storeId,
  });

  factory ProductAssignment.fromJson(Map<String, dynamic> json) {
    final statusStr = json['status'] as String;
    
    return ProductAssignment(
      id: json['id'] as String,
      groupId: json['groupId'] as String,
      productIds: (json['productIds'] as List<dynamic>).map((e) => e as String).toList(),
      assignedDate: DateTime.parse(json['assignedDate'] as String),
      assignedBy: json['assignedBy'] as String,
      deadlineDate: DateTime.parse(json['deadlineDate'] as String),
      status: AssignmentStatusExtension.fromString(statusStr),
      notes: json['notes'] as String?,
      completedDate: json['completedDate'] != null
          ? DateTime.parse(json['completedDate'] as String)
          : null,
      storeId: json['storeId'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'groupId': groupId,
      'productIds': productIds,
      'assignedDate': assignedDate.toIso8601String(),
      'assignedBy': assignedBy,
      'deadlineDate': deadlineDate.toIso8601String(),
      'status': status.toString().split('.').last,
      'notes': notes,
      'completedDate': completedDate?.toIso8601String(),
      'storeId': storeId,
    };
  }

  // Durum güncellemesi için kopyalama metodu
  ProductAssignment copyWith({
    String? id,
    String? groupId,
    List<String>? productIds,
    DateTime? assignedDate,
    String? assignedBy,
    DateTime? deadlineDate,
    AssignmentStatus? status,
    String? notes,
    DateTime? completedDate,
    String? storeId,
  }) {
    return ProductAssignment(
      id: id ?? this.id,
      groupId: groupId ?? this.groupId,
      productIds: productIds ?? this.productIds,
      assignedDate: assignedDate ?? this.assignedDate,
      assignedBy: assignedBy ?? this.assignedBy,
      deadlineDate: deadlineDate ?? this.deadlineDate,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      completedDate: completedDate ?? this.completedDate,
      storeId: storeId ?? this.storeId,
    );
  }

  // Görevi tamamlandı olarak işaretleme
  ProductAssignment markAsCompleted() {
    return copyWith(
      status: AssignmentStatus.completed,
      completedDate: DateTime.now(),
    );
  }

  // Görevi onaylandı olarak işaretleme
  ProductAssignment markAsVerified() {
    return copyWith(
      status: AssignmentStatus.verified,
    );
  }

  // Ürün ekleme
  ProductAssignment addProduct(String productId) {
    if (productIds.contains(productId)) return this;
    
    final updatedProductIds = List<String>.from(productIds)..add(productId);
    return copyWith(productIds: updatedProductIds);
  }

  // Ürün çıkarma
  ProductAssignment removeProduct(String productId) {
    if (!productIds.contains(productId)) return this;
    
    final updatedProductIds = List<String>.from(productIds)..remove(productId);
    return copyWith(productIds: updatedProductIds);
  }

  // Görev süresi doldu mu kontrolü
  bool get isExpired => DateTime.now().isAfter(deadlineDate) && status != AssignmentStatus.completed && status != AssignmentStatus.verified;

  @override
  List<Object?> get props => [
        id,
        groupId,
        productIds,
        assignedDate,
        assignedBy,
        deadlineDate,
        status,
        notes,
        completedDate,
        storeId,
      ];
}
