import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

// Ürün sayım bilgilerini tutan geçici sınıf
class ProductCount {
  String productId;
  int? eveningCount; // Akşam sayımı değeri
  int? salesCount; // Satış miktarı
  int? recountValue; // Tekrar sayım değeri
  bool hasDiscrepancy = false; // Stok tutarsızlığı var mı?
  int? expectedStock; // Beklenen stok (akşam sayımı - satış)
  
  // Form controller'ları - geçici kullanım için
  TextEditingController countController = TextEditingController();
  TextEditingController salesController = TextEditingController();
  TextEditingController recountController = TextEditingController();
  
  ProductCount({required this.productId});
}

class Product extends Equatable {
  final String id;
  final String name;
  final String code;
  final String category;
  final int stock; // Mevcut sayılan stok
  final int expectedStock; // Beklenen teorik stok
  final int packageQuantity; // Koli içi adet sayısı (örn: bir kolide 10 adet var)
  final int salesSinceLastCount; // Son sayımdan sonraki satış adedi
  final DateTime? lastCountDate; // Son sayım tarihi
  final DateTime? lastSalesUpdate; // Son satış güncelleme tarihi
  final String? imageUrl;
  final String? location;
  final DateTime? sktDate;
  final bool isProblematic;
  final String? lastCountedBy;
  final String? notes; // Stok durumu ile ilgili notlar
  final String? barcode;
  final String? unit;
  
  // Ürün sayım ekranı için kullanılan kontrollerler
  final TextEditingController? countController; // Akşam sayımı için controller
  final TextEditingController? salesController; // Satış girişi için controller
  final TextEditingController? recountController; // Tekrar sayım için controller
  final bool hasDiscrepancy; // Stok tutarsızlığı var mı?

  const Product({
    required this.id,
    required this.name,
    required this.code,
    required this.category,
    required this.stock,
    required this.expectedStock,
    this.packageQuantity = 1,
    this.salesSinceLastCount = 0,
    this.lastCountDate,
    this.lastSalesUpdate,
    this.imageUrl,
    this.location,
    this.sktDate,
    this.isProblematic = false,
    this.lastCountedBy,
    this.notes,
    this.countController,
    this.salesController,
    this.recountController,
    this.hasDiscrepancy = false,
    this.barcode,
    this.unit,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] as String,
      name: json['name'] as String,
      code: json['code'] as String,
      category: json['category'] as String,
      stock: json['stock'] as int,
      expectedStock: json['expectedStock'] as int,
      packageQuantity: json['packageQuantity'] as int? ?? 1, // Varsayılan olarak 1
      salesSinceLastCount: json['salesSinceLastCount'] as int? ?? 0,
      lastCountDate: DateTime.parse(json['lastCountDate'] as String),
      lastSalesUpdate: json['lastSalesUpdate'] != null
          ? DateTime.parse(json['lastSalesUpdate'] as String)
          : null,
      imageUrl: json['imageUrl'] as String?,
      location: json['location'] as String?,
      sktDate: DateTime.parse(json['sktDate'] as String),
      isProblematic: json['isProblematic'] as bool? ?? false,
      lastCountedBy: json['lastCountedBy'] as String?,
      notes: json['notes'] as String?,
      countController: TextEditingController(),
      salesController: TextEditingController(),
      recountController: TextEditingController(),
      hasDiscrepancy: json['hasDiscrepancy'] as bool? ?? false,
      barcode: json['barcode'] as String?,
      unit: json['unit'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'code': code,
      'category': category,
      'stock': stock,
      'expectedStock': expectedStock,
      'packageQuantity': packageQuantity,
      'salesSinceLastCount': salesSinceLastCount,
      'lastCountDate': lastCountDate?.toIso8601String(),
      'lastSalesUpdate': lastSalesUpdate?.toIso8601String(),
      'imageUrl': imageUrl,
      'location': location,
      'sktDate': sktDate?.toIso8601String(),
      'isProblematic': isProblematic,
      'lastCountedBy': lastCountedBy,
      'notes': notes,
      'barcode': barcode,
      'unit': unit,
    };
  }
  
  // AKILLI STOK YÖNETİMİ İÇİN YARDIMCI METOTLAR
  
  // Stok durumunun kopyasını oluşturan yapıcı (immutable design pattern)
  Product copyWith({
    String? id,
    String? name,
    String? code,
    String? category,
    int? stock,
    int? expectedStock,
    int? packageQuantity,
    int? salesSinceLastCount,
    DateTime? lastCountDate,
    DateTime? lastSalesUpdate,
    String? imageUrl,
    String? location,
    DateTime? sktDate,
    bool? isProblematic,
    String? lastCountedBy,
    String? notes,
    TextEditingController? countController,
    TextEditingController? salesController,
    TextEditingController? recountController,
    bool? hasDiscrepancy,
    String? barcode,
    String? unit,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      code: code ?? this.code,
      category: category ?? this.category,
      stock: stock ?? this.stock,
      expectedStock: expectedStock ?? this.expectedStock,
      packageQuantity: packageQuantity ?? this.packageQuantity,
      salesSinceLastCount: salesSinceLastCount ?? this.salesSinceLastCount,
      lastCountDate: lastCountDate ?? this.lastCountDate,
      lastSalesUpdate: lastSalesUpdate ?? this.lastSalesUpdate,
      imageUrl: imageUrl ?? this.imageUrl,
      location: location ?? this.location,
      sktDate: sktDate ?? this.sktDate,
      isProblematic: isProblematic ?? this.isProblematic,
      lastCountedBy: lastCountedBy ?? this.lastCountedBy,
      notes: notes ?? this.notes,
      countController: countController ?? this.countController,
      salesController: salesController ?? this.salesController,
      recountController: recountController ?? this.recountController,
      hasDiscrepancy: hasDiscrepancy ?? this.hasDiscrepancy,
      barcode: barcode ?? this.barcode,
      unit: unit ?? this.unit,
    );
  }
  
  // Satış miktarını güncelleyerek stok durumunu otomatik hesaplar
  Product updateSales(int salesQuantity, {DateTime? salesDate}) {
    final newSalesSinceLastCount = salesSinceLastCount + salesQuantity;
    final newExpectedStock = stock - newSalesSinceLastCount;
    
    return copyWith(
      salesSinceLastCount: newSalesSinceLastCount,
      expectedStock: newExpectedStock,
      lastSalesUpdate: salesDate ?? DateTime.now(),
      // Eğer beklenen stok negatif olursa, muhtemelen yeni ürün gelmiştir
      notes: newExpectedStock < 0 
          ? 'Olası stok girişi: Yeni koli açılmış olabilir. Sayarak doğrulayın.' 
          : notes,
    );
  }
  
  // Stok sayımı sonucunu kaydeder ve satış verilerini sıfırlar
  Product recordCount(int countedStock, String countedById, {String? locationInfo, String? countNotes}) {
    final difference = countedStock - expectedStock;
    String statusNote = '';
    bool stockProblem = false;
    
    // Stok farkı durumunu değerlendir
    if (difference != 0) {
      if (difference < 0) {
        // Stok eksiği var
        statusNote = 'Stok eksik: Beklenen: $expectedStock, Sayılan: $countedStock, Fark: $difference';
        stockProblem = true;
      } else {
        // Stok fazlası var - yeni koli açılmış olabilir
        final possibleNewPackages = difference / packageQuantity;
        if (possibleNewPackages >= 1 && difference % packageQuantity == 0) {
          statusNote = 'Olası yeni koli: ${possibleNewPackages.toInt()} koli ($packageQuantity adet/koli)';
        } else {
          statusNote = 'Stok fazla: Beklenen: $expectedStock, Sayılan: $countedStock, Fark: +$difference';
          stockProblem = true;
        }
      }
    }
    
    // Lokasyon bilgisi ve kullanıcı notu ekle
    if (locationInfo != null && locationInfo.isNotEmpty) {
      statusNote += '\nKonum: $locationInfo';
    }
    if (countNotes != null && countNotes.isNotEmpty) {
      statusNote += '\nNot: $countNotes';
    }
    
    return copyWith(
      stock: countedStock,
      expectedStock: countedStock, // Beklenen stok sayılan stok olarak güncellenir
      salesSinceLastCount: 0, // Satış sayısı sıfırlanır
      lastCountDate: DateTime.now(),
      lastCountedBy: countedById,
      location: locationInfo ?? location,
      isProblematic: stockProblem,
      notes: statusNote.isNotEmpty ? statusNote : null,
    );
  }
  
  // Stok durumunu analiz eder
  Map<String, dynamic> analyzeStockStatus() {
    final difference = stock - expectedStock;
    final stockStatus = difference == 0 
        ? 'Normal' 
        : difference > 0 
            ? 'Stok Fazlası' 
            : 'Stok Eksiği';
    
    // Stok ve satış arasında tutarsızlık var mı?
    final bool hasSalesDiscrepancy = salesSinceLastCount > 0 && expectedStock < 0;
    
    // Tekli ürünlerde dünkü stoktan fazla satış olup olmadığını kontrol et
    final bool hasExcessSalesForSingle = packageQuantity == 1 && 
                                       salesSinceLastCount > stock && 
                                       expectedStock < 0;
    
    // Koliyle ilişkili stok hareketini analiz et
    final bool isPossibleNewPackage = packageQuantity > 1 && 
                                     difference > 0 && 
                                     difference % packageQuantity == 0;
    
    return {
      'status': stockStatus,
      'difference': difference,
      'hasSalesDiscrepancy': hasSalesDiscrepancy,
      'hasExcessSalesForSingle': hasExcessSalesForSingle,
      'isPossibleNewPackage': isPossibleNewPackage,
      'possiblePackageCount': isPossibleNewPackage ? (difference / packageQuantity).floor() : 0,
      'excessSaleAmount': hasExcessSalesForSingle ? (expectedStock < 0 ? -expectedStock : expectedStock) : 0,
    };
  }
  
  // Tekli ürün için yeni gelen ürün miktarını kaydederek stoğu düzeltir
  Product updateSingleItemStock(int newItemsReceived) {
    // Yeni beklenen stok hesaplaması
    final updatedExpectedStock = stock + newItemsReceived - salesSinceLastCount;
    
    // Not oluştur
    final String statusNote = '$newItemsReceived adet yeni ürün girişi kaydedildi.';
    
    return copyWith(
      expectedStock: updatedExpectedStock,
      notes: notes != null && notes!.isNotEmpty
          ? '$notes\n$statusNote'
          : statusNote,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        code,
        category,
        stock,
        expectedStock,
        packageQuantity,
        salesSinceLastCount,
        lastCountDate,
        lastSalesUpdate,
        imageUrl,
        location,
        sktDate,
        isProblematic,
        lastCountedBy,
        notes,
        hasDiscrepancy,
        barcode,
        unit,
        // Controller'lar dinamik nesneler oldukları için props'a eklemiyoruz
      ];
}
