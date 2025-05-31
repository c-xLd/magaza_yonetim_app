import 'package:flutter/material.dart';

/// Ürün kategori sınıfı
class ProductCategory {
  final String code;
  final String name;
  final IconData icon;
  
  const ProductCategory({
    required this.code,
    required this.name,
    required this.icon,
  });

  /// Kategori kodundan (ilk iki basamak) kategori tespiti
  static ProductCategory? fromCode(String code) {
    if (code.length < 2) return null;
    final categoryCode = code.substring(0, 2);
    return categories.firstWhere(
      (category) => category.code == categoryCode,
      orElse: () => unknownCategory,
    );
  }
  
  /// Barkoddan ürün kodu çıkartma
  static String? extractProductCodeFromBarcode(String barcode) {
    // Uygulama içi barkod formatı kontrolü
    if (barcode.length < 8) return null;
    
    // Örnek: Barkod "869118020156" -> Ürün kodu "11002432"
    // Not: Gerçek projede bu dönüşüm mantığı iş kurallarına göre belirlenmelidir
    // Bu örnek bir yaklaşımdır
    return barcode.substring(barcode.length - 8);
  }
  
  /// Barkoddan direkt kategori tespiti
  static ProductCategory? getCategoryFromBarcode(String barcode) {
    final productCode = extractProductCodeFromBarcode(barcode);
    if (productCode == null) return null;
    return fromCode(productCode);
  }
  
  // Bilinmeyen kategori
  static const ProductCategory unknownCategory = ProductCategory(
    code: "00",
    name: "Diğer",
    icon: Icons.help_outline,
  );

  // Tüm kategoriler
  static const List<ProductCategory> categories = [
    ProductCategory(
      code: "11",
      name: "Et ve Tavuk Ürünleri",
      icon: Icons.emoji_food_beverage,
    ),
    ProductCategory(
      code: "12",
      name: "Süt ve Süt Ürünleri",
      icon: Icons.local_drink,
    ),
    ProductCategory(
      code: "13",
      name: "Sıvı İçecekler",
      icon: Icons.local_bar,
    ),
    ProductCategory(
      code: "14",
      name: "Bakliyat ve Makarna",
      icon: Icons.grain,
    ),
    ProductCategory(
      code: "15",
      name: "Kuruyemiş ve Cips",
      icon: Icons.fastfood,
    ),
    ProductCategory(
      code: "16",
      name: "Kahvaltılık ve Gevrek",
      icon: Icons.free_breakfast,
    ),
    ProductCategory(
      code: "17",
      name: "Çikolata ve Şekerleme",
      icon: Icons.cake,
    ),
    ProductCategory(
      code: "18",
      name: "Çorba, Konserve ve Baharat",
      icon: Icons.spa,
    ),
    ProductCategory(
      code: "19",
      name: "Sıvı Yağlar",
      icon: Icons.opacity,
    ),
    ProductCategory(
      code: "20",
      name: "Meyve ve Sebze",
      icon: Icons.eco,
    ),
    ProductCategory(
      code: "21",
      name: "Donuk Ürünler",
      icon: Icons.ac_unit,
    ),
    ProductCategory(
      code: "22",
      name: "Deterjan Ev Temizliği",
      icon: Icons.cleaning_services,
    ),
    ProductCategory(
      code: "23",
      name: "Kağıt",
      icon: Icons.sticky_note_2,
    ),
    ProductCategory(
      code: "24",
      name: "Sağlık Güzellik",
      icon: Icons.spa,
    ),
    ProductCategory(
      code: "25",
      name: "Ev Gereksinimleri",
      icon: Icons.home,
    ),
    ProductCategory(
      code: "27",
      name: "Çikolata ve Şekerleme",
      icon: Icons.cake,
    ),
    ProductCategory(
      code: "28",
      name: "Un, Şeker, Pasta Malzemeleri",
      icon: Icons.bakery_dining,
    ),
    ProductCategory(
      code: "30",
      name: "Çay ve Kahve",
      icon: Icons.coffee,
    ),
  ];
}
