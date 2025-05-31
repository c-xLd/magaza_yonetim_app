import 'package:equatable/equatable.dart';
import 'product_category.dart';

/// Son kullanma tarihli ürün modeli
class ExpiryProduct extends Equatable {
  final String id;
  String _name = '';
  String _code = '';
  final String barcode;
  final String? productCode; // Ürün kodu (barkoddan çıkarılan)
  final String? location; // Mağazadaki konum
  final String category;
  DateTime? _expiryDate;
  final String? imageUrl; // Ürün görseli
  final int quantity; // Adet
  final String? storeId; // Hangi mağazada olduğu
  final String? batchNumber; // Parti numarası
  final String? notes; // Notlar
  final String addedBy; // Ekleyen kişi
  final DateTime addedAt; // Eklenme tarihi
  final DateTime? modifiedAt; // Son düzenleme tarihi
  final bool isActive; // Aktif mi

  ExpiryProduct({
    required this.id,
    required String name,
    required String code,
    required this.barcode,
    this.productCode,
    this.location,
    required this.category,
    required DateTime expiryDate,
    this.imageUrl,
    required this.quantity,
    this.storeId,
    this.batchNumber,
    this.notes,
    required this.addedBy,
    required this.addedAt,
    this.modifiedAt,
    this.isActive = true,
  })  : _name = name,
        _code = code,
        _expiryDate = expiryDate;

  /// Barkoddan ürün kodu çıkarır
  static String? extractProductCodeFromBarcode(String barcode) {
    return ProductCategory.extractProductCodeFromBarcode(barcode);
  }

  /// Barkoddan ürün kategorisini belirler
  static String getCategoryFromBarcode(String barcode) {
    final category = ProductCategory.getCategoryFromBarcode(barcode);
    return category?.name ?? 'Diğer';
  }

  // Getter ve Setter metodları
  String get name => _name;
  set name(String value) => _name = value;

  String get code => _code;
  set code(String value) => _code = value;

  DateTime get expiryDate => _expiryDate ?? DateTime(0);
  set expiryDate(DateTime? value) => _expiryDate = value;

  /// Boş bir ExpiryProduct örneği oluşturur - sadece kontrol için kullanılır
  factory ExpiryProduct.empty() {
    return ExpiryProduct(
      id: '',
      name: '',
      code: '',
      barcode: '',
      location: '',
      category: '',
      expiryDate: DateTime.now(),
      imageUrl: '',
      quantity: 0,
      storeId: '',
      addedBy: '',
      addedAt: DateTime.now(),
    );
  }

  factory ExpiryProduct.fromJson(Map<String, dynamic> json) {
    return ExpiryProduct(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      code: json['code'] as String? ?? '',
      barcode: json['barcode'] as String? ?? '',
      productCode: json['productCode'] as String?,
      location: json['location'] as String?,
      category: json['category'] as String? ?? '',
      expiryDate: DateTime.parse(json['expiryDate'] as String? ?? DateTime.now().toIso8601String()),
      imageUrl: json['imageUrl'] as String?,
      quantity: json['quantity'] as int? ?? 0,
      storeId: json['storeId'] as String?,
      batchNumber: json['batchNumber'] as String?,
      notes: json['notes'] as String?,
      addedBy: json['addedBy'] as String? ?? '',
      addedAt: DateTime.parse(json['addedAt'] as String? ?? DateTime.now().toIso8601String()),
      modifiedAt: json['modifiedAt'] != null
          ? DateTime.parse(json['modifiedAt'] as String)
          : null,
      isActive: json['isActive'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': _name,
      'barcode': barcode,
      'productCode': productCode,
      'location': location,
      'category': category,
      'expiryDate': _expiryDate?.toIso8601String(),
      'imageUrl': imageUrl,
      'quantity': quantity,
      'storeId': storeId,
      'batchNumber': batchNumber,
      'notes': notes,
      'addedBy': addedBy,
      'addedAt': addedAt.toIso8601String(),
      'modifiedAt': modifiedAt?.toIso8601String(),
      'isActive': isActive,
    };
  }

  /// SKT'nin kritik olup olmadığını kontrol eder
  bool get isCritical {
    if (_expiryDate == null) return false;
    final daysUntilExpiry = _expiryDate!.difference(DateTime.now()).inDays;
    return daysUntilExpiry <= 7 && daysUntilExpiry >= 0;
  }

  /// SKT'nin geçmiş olup olmadığını kontrol eder
  bool get isExpired {
    if (_expiryDate == null) return false;
    return DateTime.now().isAfter(_expiryDate!);
  }

  /// SKT'ye kaç gün kaldığını hesaplar
  int get daysUntilExpiry {
    if (_expiryDate == null) return 0;
    return _expiryDate!.difference(DateTime.now()).inDays;
  }

  /// Ürünü günceller
  ExpiryProduct copyWith({
    String? id,
    String? name,
    String? barcode,
    String? productCode,
    String? location,
    String? category,
    DateTime? expiryDate,
    String? imageUrl,
    int? quantity,
    String? storeId,
    String? batchNumber,
    String? notes,
    String? addedBy,
    DateTime? addedAt,
    DateTime? modifiedAt,
    bool? isActive,
    String? code,
  }) {
    return ExpiryProduct(
      id: id ?? this.id,
      name: name ?? this.name,
      barcode: barcode ?? this.barcode,
      productCode: productCode ?? this.productCode,
      location: location ?? this.location,
      category: category ?? this.category,
      expiryDate: expiryDate ?? this.expiryDate,
      imageUrl: imageUrl ?? this.imageUrl,
      quantity: quantity ?? this.quantity,
      storeId: storeId ?? this.storeId,
      batchNumber: batchNumber ?? this.batchNumber,
      notes: notes ?? this.notes,
      addedBy: addedBy ?? this.addedBy,
      addedAt: addedAt ?? this.addedAt,
      modifiedAt: modifiedAt ?? DateTime.now(),
      isActive: isActive ?? this.isActive,
      code: code ?? this.code,
    );
  }

  @override
  List<Object?> get props => [
        id,
        _name,
        barcode,
        productCode,
        location,
        category,
        _expiryDate,
        imageUrl,
        quantity,
        storeId,
        batchNumber,
        notes,
        addedBy,
        addedAt,
        modifiedAt,
        isActive,
      ];
}
