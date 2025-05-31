import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/expiry_product.dart';
import '../models/product_category.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// SKT takibi için ürün servis sınıfı
class ExpiryProductService extends ChangeNotifier {
  // List<ExpiryProduct> _products = []; // Mock kaldırıldı
  
  // Stream controllers
  final _productsStreamController = StreamController<List<ExpiryProduct>>.broadcast();
  
  // Streams
  Stream<List<ExpiryProduct>> get productsStream => FirebaseFirestore.instance
      .collection('expiry_products')
      .snapshots()
      .map((snapshot) => snapshot.docs.map((doc) => ExpiryProduct.fromJson(doc.data())).toList());
  
  // Getters
  // List<ExpiryProduct> get products => _products;
  
  // Kritik SKT'li ürünler (7 gün ve daha az)
  List<ExpiryProduct> get criticalProducts => 
      // _products.where((product) => product.isCritical).toList();
      [];
      
  // Süresi geçmiş ürünler
  List<ExpiryProduct> get expiredProducts => 
      // _products.where((product) => product.isExpired).toList();
      [];
      
  // Belirli bir kategorideki ürünler
  List<ExpiryProduct> getProductsByCategory(String category) => 
      // _products.where((product) => product.category == category).toList();
      [];
      
  // Belirli bir mağazadaki ürünler
  List<ExpiryProduct> getProductsByStore(String storeId) => 
      // _products.where((product) => product.storeId == storeId).toList();
      [];
  
  // Constructor
  ExpiryProductService() {
    // _loadInitialData();
  }
  
  // İlk verileri yükle
  Future<void> _loadInitialData() async {
    // Gerçek uygulamada Firebase'den veri çekilecek
    // _products = [];
    _notifyProductsChanged();
    notifyListeners();
  }
  
  // Stream bildirimi
  void _notifyProductsChanged() {
    // _productsStreamController.add(_products);
  }
  
  // Firestore'dan ürünleri tek seferlik çekmek için
  Future<List<ExpiryProduct>> fetchProducts() async {
    final snapshot = await FirebaseFirestore.instance.collection('expiry_products').get();
    return snapshot.docs.map((doc) => ExpiryProduct.fromJson(doc.data())).toList();
  }
  
  // Yeni SKT ürünü ekle
  Future<ExpiryProduct> addProduct(ExpiryProduct product) async {
    final doc = FirebaseFirestore.instance.collection('expiry_products').doc(product.id);
    await doc.set(product.toJson());
    notifyListeners();
    return product;
  }
  
  // SKT ürününü güncelle
  Future<ExpiryProduct> updateProduct(ExpiryProduct updatedProduct) async {
    final doc = FirebaseFirestore.instance.collection('expiry_products').doc(updatedProduct.id);
    await doc.update(updatedProduct.toJson());
    notifyListeners();
    return updatedProduct;
  }
  
  // SKT ürününü sil
  Future<void> deleteProduct(String productId) async {
    await FirebaseFirestore.instance.collection('expiry_products').doc(productId).delete();
    notifyListeners();
  }
  
  // Barkod ile ürün ara
  Future<ExpiryProduct?> findProductByBarcode(String barcode) async {
    final snapshot = await FirebaseFirestore.instance.collection('expiry_products').where('barcode', isEqualTo: barcode).get();
    if (snapshot.docs.isNotEmpty) {
      return ExpiryProduct.fromJson(snapshot.docs.first.data());
    }
    return null;
  }
  
  // Barkoddan ürün kodu çıkar
  String? extractProductCodeFromBarcode(String barcode) {
    return ProductCategory.extractProductCodeFromBarcode(barcode);
  }
  
  // Ürün kodundan kategori bilgisini çıkar
  ProductCategory? getCategoryFromProductCode(String productCode) {
    return ProductCategory.fromCode(productCode);
  }
  
  // Barkoddan direkt kategori tespiti
  ProductCategory? getCategoryFromBarcode(String barcode) {
    return ProductCategory.getCategoryFromBarcode(barcode);
  }
  
  // Barkod tarama sonrası ürün bulunamazsa yeni ürün oluşturmaya yardımcı metod
  ExpiryProduct createNewProductFromBarcode(String barcode) {
    final productCode = extractProductCodeFromBarcode(barcode);
    final category = getCategoryFromBarcode(barcode);
    
    return ExpiryProduct(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: '',
      code: '', // Eklenen: zorunlu kod parametresi
      barcode: barcode,
      productCode: productCode,
      category: category?.name ?? 'Diğer',
      expiryDate: DateTime.now().add(const Duration(days: 30)), // Varsayılan 30 gün
      quantity: 1,
      addedBy: 'Kullanıcı', // Kullanıcı adı burada girilecek
      addedAt: DateTime.now(),
    );
  }
  
  // Ürünleri kategorilere göre grupla
  Map<String, List<ExpiryProduct>> getProductsByCategories() {
    final Map<String, List<ExpiryProduct>> result = {};
    
    for (final product in []) {
      if (!result.containsKey(product.category)) {
        result[product.category] = [];
      }
      result[product.category]!.add(product);
    }
    
    return result;
  }
  
  // Bildirim gönderilmesi gereken ürünleri al
  List<ExpiryProduct> getProductsForNotification() {
    // Firestore ile canlı veri için bu fonksiyonun kullanılmayan hali:
    return <ExpiryProduct>[];
  }
  
  // Belirli bir tarihe göre ürünleri filtrele
  List<ExpiryProduct> filterByDate(DateTime targetDate) {
    // Firestore ile canlı veri için bu fonksiyonun kullanılmayan hali:
    return <ExpiryProduct>[];
  }
  
  // Toplu ürün ekleme (Excel/CSV import için)
  Future<void> bulkAddProducts(List<ExpiryProduct> products) async {
    final batch = FirebaseFirestore.instance.batch();
    for (final product in products) {
      final doc = FirebaseFirestore.instance.collection('expiry_products').doc(product.id);
      batch.set(doc, product.toJson());
    }
    await batch.commit();
    notifyListeners();
  }
  
  // Temizlik
  @override
  void dispose() {
    // _productsStreamController.close();
    super.dispose();
  }
}
