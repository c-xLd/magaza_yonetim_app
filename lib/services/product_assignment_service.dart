import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/product.dart';
import '../models/product_assignment.dart';
import '../models/product_count.dart';

// Product Assignment ve Sayım Yönetimi Servisi
class ProductAssignmentService extends ChangeNotifier {
  // Veritabanı entegrasyonu için gerçek implementasyonda bu mockup veriler
  // Firebase veya başka bir veritabanından gelecektir
  List<ProductAssignment> _assignments = [];
  List<ProductCount> _productCounts = [];

  // Stream controllers for real-time updates
  final _assignmentStreamController =
      StreamController<List<ProductAssignment>>.broadcast();
  final _countStreamController =
      StreamController<List<ProductCount>>.broadcast();

  // Streams to listen to
  Stream<List<ProductAssignment>> get assignmentsStream =>
      _assignmentStreamController.stream;
  Stream<List<ProductCount>> get countsStream => _countStreamController.stream;

  // Getters
  List<ProductAssignment> get assignments => _assignments;
  List<ProductCount> get productCounts => _productCounts;

  // Constructor
  ProductAssignmentService() {
    // Veritabanı bağlantısı ve başlangıç verilerini yükleme işlemleri
    // Firebase veya başka bir backend kullanıldığında bu kısım değişecek
    _loadInitialData();
  }

  // Veri yükleme (mockup)
  Future<void> _loadInitialData() async {
    // Bu kısımda gerçek uygulamada Firebase veya başka backend'den veri çekilecek
    // Şimdilik boş verilerle başlıyoruz
    _assignments = [];
    _productCounts = [];

    // Stream'lere ilk verileri gönderme
    _notifyAssignmentsChanged();
    _notifyCountsChanged();

    notifyListeners();
  }

  // Stream bildirim metodları
  void _notifyAssignmentsChanged() {
    _assignmentStreamController.add(_assignments);
  }

  void _notifyCountsChanged() {
    _countStreamController.add(_productCounts);
  }

  // ********** ÜRÜN ATAMA YÖNETİMİ **********

  // Yeni ürün atama görevi oluşturma
  Future<ProductAssignment> createAssignment({
    required String groupId,
    required List<String> productIds,
    required String assignedBy,
    required DateTime deadlineDate,
    String? notes,
    String? storeId,
  }) async {
    final now = DateTime.now();
    final newAssignment = ProductAssignment(
      id: 'assignment_${now.millisecondsSinceEpoch}',
      groupId: groupId,
      productIds: productIds,
      assignedDate: now,
      assignedBy: assignedBy,
      deadlineDate: deadlineDate,
      status: AssignmentStatus.pending,
      notes: notes,
      storeId: storeId,
    );

    // Veri kaynağına ekleme
    _assignments.add(newAssignment);
    _notifyAssignmentsChanged();
    notifyListeners();

    return newAssignment;
  }

  // Görev durumunu güncelleme
  Future<ProductAssignment> updateAssignmentStatus(
      String assignmentId, AssignmentStatus newStatus) async {
    final index =
        _assignments.indexWhere((assignment) => assignment.id == assignmentId);

    if (index >= 0) {
      final updatedAssignment = _assignments[index].copyWith(
        status: newStatus,
        completedDate:
            newStatus == AssignmentStatus.completed ? DateTime.now() : null,
      );

      _assignments[index] = updatedAssignment;
      _notifyAssignmentsChanged();
      notifyListeners();

      return updatedAssignment;
    } else {
      throw Exception('Görev bulunamadı');
    }
  }

  // Görev silme
  Future<void> deleteAssignment(String assignmentId) async {
    _assignments.removeWhere((assignment) => assignment.id == assignmentId);
    _notifyAssignmentsChanged();
    notifyListeners();
  }

  // Belirli bir gruba ait görevleri getirme
  List<ProductAssignment> getGroupAssignments(String groupId) {
    return _assignments
        .where((assignment) => assignment.groupId == groupId)
        .toList();
  }

  // ********** ÜRÜN SAYIM YÖNETİMİ **********

  // Yeni ürün sayımı ekleme
  Future<ProductCount> addProductCount({
    required String productId,
    required int countedQuantity,
    required String countedBy,
    required String groupId,
    String? notes,
    String? storeId,
    String? locationInStore,
  }) async {
    final now = DateTime.now();
    final newCount = ProductCount(
      id: 'count_${now.millisecondsSinceEpoch}',
      productId: productId,
      countedQuantity: countedQuantity,
      countedBy: countedBy,
      groupId: groupId,
      countDate: now,
      notes: notes,
      storeId: storeId,
      locationInStore: locationInStore,
    );

    // Veri kaynağına ekleme
    _productCounts.add(newCount);
    _notifyCountsChanged();
    notifyListeners();

    return newCount;
  }

  // Sayım doğrulama (yönetici onayı)
  Future<ProductCount> verifyProductCount(
      String countId, String verifiedBy) async {
    final index = _productCounts.indexWhere((count) => count.id == countId);

    if (index >= 0) {
      final verifiedCount = _productCounts[index].verify(
        verifiedById: verifiedBy,
        verificationDateTime: DateTime.now(),
      );

      _productCounts[index] = verifiedCount;
      _notifyCountsChanged();
      notifyListeners();

      return verifiedCount;
    } else {
      throw Exception('Sayım kaydı bulunamadı');
    }
  }

  // Belirli bir gruba ait sayımları getirme
  List<ProductCount> getGroupCounts(String groupId) {
    return _productCounts.where((count) => count.groupId == groupId).toList();
  }

  // Belirli bir ürüne ait sayımları getirme
  List<ProductCount> getProductCounts(String productId) {
    return _productCounts
        .where((count) => count.productId == productId)
        .toList();
  }

  // Belirli bir kullanıcının yaptığı sayımları getirme
  List<ProductCount> getUserCounts(String userId) {
    return _productCounts.where((count) => count.countedBy == userId).toList();
  }

  // Ürün güncelleme ve sayım kaydı ekleme - akıllı stok yönetimi
  Future<void> updateProductAndAddCount({
    required Product product,
    required int countedQuantity,
    required String countedBy,
    required String groupId,
    bool autoCorrectStock = false,
    String? notes,
    String? storeId,
  }) async {
    final now = DateTime.now();

    // 1. Sayım kaydı oluştur
    var newCount = ProductCount(
      id: 'count_${now.millisecondsSinceEpoch}',
      productId: product.id,
      countedQuantity: countedQuantity,
      countedBy: countedBy,
      groupId: groupId,
      countDate: now,
      notes: notes,
      storeId: storeId,
      locationInStore: product.location,
    );

    // 2. Ürünün stok durumunu analiz et
    final stockAnalysis = product.analyzeStockStatus();
    final bool hasSalesDiscrepancy =
        stockAnalysis['hasSalesDiscrepancy'] as bool;
    final bool isPossibleNewPackage =
        stockAnalysis['isPossibleNewPackage'] as bool;

    // 3. Otomatik stok düzeltme yapılması isteniyorsa
    if (autoCorrectStock && (hasSalesDiscrepancy || isPossibleNewPackage)) {
      // Stok farkı hesapla
      final difference = countedQuantity - product.expectedStock;
      String correctionNote = '';

      if (difference > 0 && isPossibleNewPackage) {
        // Muhtemelen yeni koli açılmış, stok artışı koli içi miktara tam bölünüyor
        final newPackageCount = difference / product.packageQuantity;
        if (newPackageCount >= 1 && difference % product.packageQuantity == 0) {
          correctionNote =
              '${newPackageCount.toInt()} yeni koli açılmış olarak işaretlendi. '
              'Her koli içi ${product.packageQuantity} adet ürün bulunmakta.';
        } else {
          correctionNote = 'Stok fazlası tespit edildi (+$difference adet). '
              'Fazla stok otomatik olarak kaydedildi.';
        }
      } else if (difference < 0) {
        // Stok eksiği var
        correctionNote = 'Stok eksiği tespit edildi ($difference adet). '
            'Sayım sonucu stok güncellendi.';
      }

      // Sayım notlarına düzeltme bilgisi ekle
      if (correctionNote.isNotEmpty) {
        // addNote immutable bir metod olduğundan dönüş değerini kullanmalıyız
        final updatedCount =
            newCount.addNote('Otomatik düzeltme: $correctionNote');
        newCount = updatedCount; // newCount değişkenini güncelle
      }
    }

    // 4. Sayım kaydını veritabanına ekle
    _productCounts.add(newCount);
    _notifyCountsChanged();

    // 5. Ürün bilgilerini veritabanında güncelle
    // NOT: Gerçek uygulamada bu kısım Firebase veya başka bir veritabanı ile entegre edilecek
    // Şimdilik yalnızca sayım kaydı ekleniyor, gerçek ürün güncellemesi yapılmıyor

    notifyListeners();
  }

  // Temizlik
  @override
  void dispose() {
    _assignmentStreamController.close();
    _countStreamController.close();
    super.dispose();
  }
}
