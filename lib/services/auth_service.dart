// NOT: Bu dosya geçici olarak Firebase yerine mock veri kullanmaktadır.
// Firebase kurulduğunda bu dosyayı gerçek Firebase implementasyonu ile değiştirin.

import '../models/user.dart';

// Mock AuthService - Firebase olmadan çalışacak şekilde tasarlandı
class AuthService {
  // Geçici olarak belleğimizde tutulan kullanıcı verileri
  static User? _currentUser;

  // Sabit test kullanıcıları (gerçek uygulamada Firebase'den alınacak)
  final List<User> _mockUsers = [
    User(
      id: 'admin123',
      name: 'Admin Kullanıcı',
      email: 'admin@example.com',
      role: UserRole.superAdmin,
      isActive: true,
      phoneNumber: '555-123-4567',
      photoUrl: null,
      groupIds: ['group1', 'group2'],
      managedStoreId: 'store1',
      lastLoginDate: DateTime.now(),
    ),
    User(
      id: 'manager123',
      name: 'Müdür Kullanıcı',
      email: 'manager@example.com',
      role: UserRole.manager,
      isActive: true,
      phoneNumber: '555-765-4321',
      photoUrl: null,
      groupIds: ['group2'],
      managedStoreId: 'store2',
      lastLoginDate: DateTime.now(),
    ),
    User(
      id: 'staff123',
      name: 'Personel Kullanıcı',
      email: 'staff@example.com',
      role: UserRole.staff,
      isActive: true,
      phoneNumber: '555-987-6543',
      photoUrl: null,
      groupIds: ['group3'],
      managedStoreId: null,
      lastLoginDate: DateTime.now(),
    ),
  ];

  // Yapıcı metot - Varsayılan olarak süper admin kullanıcısını giriş yapmış olarak ayarla
  AuthService() {
    // Uygulama başlatıldığında varsayılan olarak admin kullanıcısını giriş yapmış olarak ayarla
    _currentUser ??= _mockUsers.first;
  }

  // Mevcut kullanıcı bilgilerini getir
  Future<User?> getCurrentUser() async {
    // Gerçek bir asenkron işlem simule etmek için kısa bir gecikme ekleyelim
    await Future.delayed(const Duration(milliseconds: 300));
    return _currentUser;
  }

  // Test amacıyla kullanıcıyı değiştirmek için (gerçek uygulamada giriş yapma fonksiyonu olacak)
  Future<User?> switchUser(String userId) async {
    final foundUser = _mockUsers.firstWhere(
      (user) => user.id == userId,
      orElse: () => _mockUsers.first,
    );

    _currentUser = foundUser;
    return _currentUser;
  }

  // Kullanıcı rolüne göre izinleri kontrol etme
  bool canUserAccess(String featureId) {
    if (_currentUser == null) return false;

    // Süper admin herşeye erişebilir
    if (_currentUser!.role == UserRole.superAdmin) return true;

    // Müdürün erişebileceği özellikler
    final managerFeatures = ['product_count', 'assign_tasks', 'manage_staff'];
    if (_currentUser!.role == UserRole.manager &&
        managerFeatures.contains(featureId)) {
      return true;
    }

    // Personelin erişebileceği özellikler
    final staffFeatures = ['product_count', 'view_tasks'];
    if (_currentUser!.role == UserRole.staff &&
        staffFeatures.contains(featureId)) {
      return true;
    }

    return false;
  }

  // NOT: Firebase kurulduğunda, bu sınıf yerine gerçek Firebase auth implementasyonunu kullanın.
}
