import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

// Bu sınıf geçici olarak Firebase yerine mock verilerle çalışacak
class MockFirebaseService {
  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  
  // Mock kullanıcı bilgileri
  final Map<String, dynamic> _currentUser = {
    'uid': 'mock-user-123',
    'displayName': 'Ahmet Şahin',
    'email': 'ahmet@example.com',
    'role': 'Site Yöneticisi',
  };
  
  // Mock veri koleksiyonları
  final Map<String, List<Map<String, dynamic>>> _collections = {
    'users': [
      {
        'uid': 'mock-user-123',
        'displayName': 'Ahmet Şahin',
        'email': 'ahmet@example.com',
        'role': 'Site Yöneticisi',
      },
    ],
    'products': [
      {
        'id': 'product-1',
        'name': 'Su',
        'category': 'İçecek',
        'stock': 25,
        'minStock': 10,
      },
      {
        'id': 'product-2',
        'name': 'Ekmek',
        'category': 'Gıda',
        'stock': 15,
        'minStock': 5,
      },
    ],
    'notifications': [
      {
        'id': 'notif-1',
        'title': 'Stok Uyarısı',
        'body': 'Su ürününde stok azalıyor',
        'type': 'stock',
        'isRead': false,
        'createdAt': DateTime.now().subtract(const Duration(days: 1)),
      },
    ],
  };
  
  // Getter metotlar
  Map<String, dynamic> get currentUser => _currentUser;
  
  // Kullanıcı işlemleri
  Future<void> signOut() async {
    // Mock çıkış işlemi
    print('Çıkış yapıldı');
  }
  
  // Bildirim yönetimi
  Future<void> initializeNotifications() async {
    // Mock bildirim başlatma
    print('Bildirimler başlatıldı');
  }
  
  // Veri getirme işlemleri
  Future<List<Map<String, dynamic>>> fetchNotifications({int limit = 20}) async {
    // Mock bildirimleri getir
    await Future.delayed(const Duration(milliseconds: 500)); // Gerçek API gecikme simülasyonu
    return _collections['notifications'] ?? [];
  }
  
  Future<List<Map<String, dynamic>>> fetchProducts() async {
    // Mock ürünleri getir
    await Future.delayed(const Duration(milliseconds: 500));
    return _collections['products'] ?? [];
  }
  
  // Ürün işlemleri
  Future<void> updateProduct(String productId, Map<String, dynamic> updates) async {
    // Mock ürün güncelleme
    final productIndex = _collections['products']?.indexWhere((p) => p['id'] == productId) ?? -1;
    if (productIndex != -1) {
      _collections['products']?[productIndex].addAll(updates);
    }
  }
}

// Tek bir instance oluşturup uygulamanın her yerinde kullanmak için
final mockFirebaseService = MockFirebaseService();
