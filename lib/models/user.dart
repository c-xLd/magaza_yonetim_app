import 'package:equatable/equatable.dart';

// Sistem rollerini tanımlayan enum
enum UserRole {
  superAdmin, // Süper Admin - Tüm sistem yönetimi
  manager,    // Müdür - Bölüm yönetimi ve raporlama
  staff       // Personel - Temel işlemler
}

// Enum değerlerini string'e dönüştürmek için extension
extension UserRoleExtension on UserRole {
  String get name {
    switch (this) {
      case UserRole.superAdmin:
        return 'Süper Admin';
      case UserRole.manager:
        return 'Müdür';
      case UserRole.staff:
        return 'Personel';
    }
  }
  
  // Rol bazlı yetkilendirme kontrolü
  // Süper Admin tüm işlemleri yapabilir
  // Müdür kendi bölümünü ve personeli yönetebilir
  // Personel sadece temel işlemleri yapabilir
  
  // Kullanıcı yönetimi - Sadece süper admin ve müdür
  bool canManageUsers() {
    return this == UserRole.superAdmin || this == UserRole.manager;
  }
  
  // Ürün yönetimi - Tüm roller yapabilir, personel düzenleyemez, sadece ekleyebilir ve görüntüleyebilir
  bool canManageProducts() {
    return this == UserRole.superAdmin || this == UserRole.manager;
  }
  
  // Sayım yapabilme yetkisi - Tüm roller yapabilir
  bool canCountProducts() {
    return true; // Tüm roller sayım yapabilir
  }
  
  // Rapor görüntüleme - Süper admin tüm raporları, Müdür kendi bölümünün
  bool canViewReports() {
    return this == UserRole.superAdmin || this == UserRole.manager;
  }
  
  // Grup yönetimi - Süper admin ve müdür
  bool canManageGroups() {
    return this == UserRole.superAdmin || this == UserRole.manager;
  }
  
  // Süper admin özel yetkileri
  bool canManageAdmins() {
    return this == UserRole.superAdmin;
  }
  
  bool canImportExportData() {
    return this == UserRole.superAdmin;
  }
  
  bool canConfigureSystem() {
    return this == UserRole.superAdmin;
  }
  
  bool canManageApartment() {
    return this == UserRole.superAdmin;
  }
  
  // String'den enum'a dönüştürmek için yardımcı metod
  static UserRole fromString(String role) {
    switch (role.toLowerCase()) {
      case 'superadmin':
      case 'süper admin':
      case 'super admin':
      case 'admin':
      case 'yönetici':
        return UserRole.superAdmin;
      case 'manager':
      case 'müdür':
      case 'mağaza müdürü':
      case 'bölüm müdürü':
        return UserRole.manager;
      case 'staff':
      case 'personel':
      case 'sayım personeli':
      case 'izleyici':
        return UserRole.staff; 
    }
    print('Bilinmeyen UserRole string: $role');
    return UserRole.staff; // Güvenli bir varsayılan
  }
}

class User with EquatableMixin {
  final String id;
  final String name;
  final UserRole role;
  final bool isActive;
  final String phoneNumber; // Telefon numarası zorunlu alan
  final String? photoUrl;
  final String? managedStoreId; // Yönettiği site/bölüm ID'si (yöneticiler için)
  final DateTime? lastLoginDate;
  
  const User({
    required this.id,
    required this.name,
    required this.role,
    this.isActive = true,
    required this.phoneNumber, // Telefon numarası zorunlu alan
    this.photoUrl,
    this.managedStoreId,
    this.lastLoginDate,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    // Role string olarak geliyorsa enum'a çeviriyoruz
    final roleStr = json['role'] as String;
    final userRole = UserRoleExtension.fromString(roleStr);
    
    // Telefon numarası yoksa varsayılan değer atama
    final phoneNumber = json['phoneNumber'] as String? ?? '';
    if (phoneNumber.isEmpty) {
      throw Exception('Telefon numarası zorunludur.');
    }
    
    return User(
      id: json['id'] as String,
      name: json['name'] as String,
      role: userRole,
      isActive: json['isActive'] as bool? ?? true,
      phoneNumber: phoneNumber, // Telefon numarası zorunlu
      photoUrl: json['photoUrl'] as String?,
      managedStoreId: json['managedStoreId'] as String?,
      lastLoginDate: json['lastLoginDate'] != null 
          ? DateTime.parse(json['lastLoginDate'] as String) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'role': role.toString().split('.').last, // enum değerini string'e çeviriyoruz
      'isActive': isActive,
      'phoneNumber': phoneNumber,
      'photoUrl': photoUrl,
      'managedStoreId': managedStoreId,
      'lastLoginDate': lastLoginDate?.toIso8601String(),
    };
  }
  
  // Yetki kontrolleri için kolay erişim metodları
  bool get canManageUsers => role.canManageUsers();
  bool get canManageProducts => role.canManageProducts();
  bool get canCountProducts => role.canCountProducts();
  bool get canViewReports => role.canViewReports();
  bool get canManageGroups => role.canManageGroups();
  
  // Immutable model için yeni bir kopya ile güncelleme yapar
  User copyWith({
    String? id,
    String? name,
    UserRole? role,
    bool? isActive,
    String? phoneNumber,
    String? photoUrl,
    String? managedStoreId,
    DateTime? lastLoginDate,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      role: role ?? this.role,
      isActive: isActive ?? this.isActive,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      photoUrl: photoUrl ?? this.photoUrl,
      managedStoreId: managedStoreId ?? this.managedStoreId,
      lastLoginDate: lastLoginDate ?? this.lastLoginDate,
    );
  }
  
  // Kullanıcı rolünü güncelleme - yeni bir kopya döndürür
  User withRole(UserRole newRole) {
    return copyWith(role: newRole);
  }

  @override
  List<Object?> get props => [id, name, role, isActive, phoneNumber, photoUrl, managedStoreId, lastLoginDate];
}
