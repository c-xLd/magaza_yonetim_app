import 'dart:async';
import 'app_config.dart';

// Firebase ile benzer arayüze sahip sahte sınıflar

class MockUser {
  final String uid;
  final String? email;
  final String? displayName;
  final String? phoneNumber;

  MockUser({
    required this.uid,
    this.email,
    this.displayName,
    this.phoneNumber,
  });
}

class MockUserCredential {
  final MockUser? user;

  MockUserCredential({this.user});
}

class MockFirebaseAuth {
  MockUser? _currentUser;

  MockUser? get currentUser => _currentUser;

  // Test kullanıcıları
  final Map<String, MockUser> _users = {
    'test@example.com': MockUser(
      uid: '1',
      email: 'test@example.com',
      displayName: 'Test User',
      phoneNumber: '+905551234567',
    ),
    'admin@example.com': MockUser(
      uid: '2',
      email: 'admin@example.com',
      displayName: 'Admin User',
      phoneNumber: '+905557654321',
    ),
  };

  // Stream controller kimlik doğrulama durumu değişikliklerini simüle etmek için
  final StreamController<MockUser?> _authStateController =
      StreamController.broadcast();

  Stream<MockUser?> get authStateChanges => _authStateController.stream;

  MockFirebaseAuth() {
    // Başlangıçta null kullanıcı durumu
    _authStateController.add(null);
  }

  Future<MockUserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    // Test gecikmesi ekle
    await Future.delayed(AppConfig.testDelay);

    // Test kullanıcısını bul
    if (_users.containsKey(email) && password == '123456') {
      _currentUser = _users[email];
      _authStateController.add(_currentUser);
      return MockUserCredential(user: _currentUser);
    }

    // Hata durumu
    throw Exception('Geçersiz e-posta veya şifre');
  }

  Future<void> signOut() async {
    await Future.delayed(AppConfig.testDelay);
    _currentUser = null;
    _authStateController.add(null);
  }

  Future<MockUserCredential> createUserWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    await Future.delayed(AppConfig.testDelay);

    if (_users.containsKey(email)) {
      throw Exception('Bu e-posta zaten kullanımda');
    }

    final newUser = MockUser(
      uid: DateTime.now().millisecondsSinceEpoch.toString(),
      email: email,
      displayName: null,
      phoneNumber: null,
    );

    _users[email] = newUser;
    _currentUser = newUser;
    _authStateController.add(_currentUser);

    return MockUserCredential(user: newUser);
  }
}

class MockTimestamp {
  final DateTime dateTime;

  MockTimestamp(this.dateTime);

  static MockTimestamp now() {
    return MockTimestamp(DateTime.now());
  }

  static MockTimestamp fromDate(DateTime dateTime) {
    return MockTimestamp(dateTime);
  }

  DateTime toDate() {
    return dateTime;
  }
}

class MockDocumentReference {
  final String id;
  final Map<String, dynamic> _data;
  final MockFirestore _firestore;

  MockDocumentReference(this.id, this._data, this._firestore);

  Future<void> set(Map<String, dynamic> data, {bool merge = false}) async {
    await Future.delayed(AppConfig.testDelay);

    if (merge) {
      _data.addAll(data);
    } else {
      _data.clear();
      _data.addAll(data);
    }

    return;
  }

  Future<void> update(Map<String, dynamic> data) async {
    await Future.delayed(AppConfig.testDelay);
    _data.addAll(data);
  }

  Future<MockDocumentSnapshot> get() async {
    await Future.delayed(AppConfig.testDelay);
    return MockDocumentSnapshot(id, _data.isNotEmpty, _data, this);
  }

  Future<void> delete() async {
    await Future.delayed(AppConfig.testDelay);
    _data.clear();
  }
}

class MockDocumentSnapshot {
  final String id;
  final bool exists;
  final Map<String, dynamic> _data;
  final MockDocumentReference reference;

  MockDocumentSnapshot(this.id, this.exists, this._data, this.reference);

  Map<String, dynamic> data() {
    return Map<String, dynamic>.from(_data);
  }

  dynamic get(String field) {
    final parts = field.split('.');
    dynamic value = _data;

    for (final part in parts) {
      if (value is Map && value.containsKey(part)) {
        value = value[part];
      } else {
        return null;
      }
    }

    return value;
  }
}

class MockQuerySnapshot {
  final List<MockDocumentSnapshot> docs;

  MockQuerySnapshot(this.docs);

  int get size => docs.length;
}

class MockQuery {
  final List<Map<String, dynamic>> _documents;
  final MockFirestore _firestore;
  final List<List<dynamic>> _filters = [];

  MockQuery(this._documents, this._firestore);

  MockQuery where(
    String field, {
    dynamic isEqualTo,
    dynamic isGreaterThan,
    dynamic isGreaterThanOrEqualTo,
    dynamic isLessThan,
    dynamic isLessThanOrEqualTo,
    dynamic arrayContains,
    List<dynamic>? arrayContainsAny,
    List<dynamic>? whereIn,
  }) {
    final newDocs = List<Map<String, dynamic>>.from(_documents);
    final newQuery = MockQuery(newDocs, _firestore);

    newQuery._filters.addAll(_filters);

    if (isEqualTo != null) {
      newQuery._filters.add([field, '==', isEqualTo]);
    }

    if (isGreaterThan != null) {
      newQuery._filters.add([field, '>', isGreaterThan]);
    }

    // Diğer filtreler benzer şekilde eklenebilir...

    return newQuery;
  }

  MockQuery orderBy(String field, {bool descending = false}) {
    final newDocs = List<Map<String, dynamic>>.from(_documents);
    return MockQuery(newDocs, _firestore);
  }

  MockQuery limit(int limit) {
    final newDocs = List<Map<String, dynamic>>.from(_documents);
    return MockQuery(newDocs, _firestore);
  }

  Future<MockQuerySnapshot> get() async {
    await Future.delayed(AppConfig.testDelay);

    // Filtreleri uygula
    List<Map<String, dynamic>> filteredDocs = List.from(_documents);

    for (final filter in _filters) {
      final field = filter[0];
      final op = filter[1];
      final value = filter[2];

      filteredDocs = filteredDocs.where((doc) {
        if (op == '==') {
          final fieldValue = _getFieldValue(doc, field);
          return fieldValue == value;
        }
        // Diğer operatörler için filtreler eklenebilir
        return true;
      }).toList();
    }

    final docSnapshots = filteredDocs.map((doc) {
      final id =
          doc['id'] ?? 'mock-id-${DateTime.now().millisecondsSinceEpoch}';
      return MockDocumentSnapshot(
          id, true, doc, MockDocumentReference(id, doc, _firestore));
    }).toList();

    return MockQuerySnapshot(docSnapshots);
  }

  dynamic _getFieldValue(Map<String, dynamic> doc, String field) {
    final parts = field.split('.');
    dynamic value = doc;

    for (final part in parts) {
      if (value is Map && value.containsKey(part)) {
        value = value[part];
      } else {
        return null;
      }
    }

    return value;
  }
}

class MockCollectionReference extends MockQuery {
  final String path;

  MockCollectionReference(
      this.path, List<Map<String, dynamic>> documents, MockFirestore firestore)
      : super(documents, firestore);

  MockDocumentReference doc([String? id]) {
    id = id ?? 'mock-id-${DateTime.now().millisecondsSinceEpoch}';

    final existingDocIndex = _documents.indexWhere((doc) => doc['id'] == id);

    if (existingDocIndex >= 0) {
      return MockDocumentReference(
          id, _documents[existingDocIndex], _firestore);
    } else {
      final newDoc = <String, dynamic>{
        'id': id,
      };
      _documents.add(newDoc);
      return MockDocumentReference(id, newDoc, _firestore);
    }
  }

  Future<MockDocumentReference> add(Map<String, dynamic> data) async {
    await Future.delayed(AppConfig.testDelay);

    final id = 'mock-id-${DateTime.now().millisecondsSinceEpoch}';
    data['id'] = id;

    _documents.add(data);

    return MockDocumentReference(id, data, _firestore);
  }
}

class MockFieldValue {
  static dynamic serverTimestamp() {
    return MockTimestamp(DateTime.now());
  }

  static dynamic increment(num value) {
    return value; // Gerçek artırma yapılamayacağından, sadece değeri döndürüyoruz
  }

  static dynamic arrayUnion(List<dynamic> elements) {
    return elements;
  }

  static dynamic arrayRemove(List<dynamic> elements) {
    return [];
  }

  static dynamic delete() {
    return null;
  }
}

class MockFirestore {
  final Map<String, List<Map<String, dynamic>>> _collections = {};

  MockFirestore() {
    // Test verileri ekle
    _collections['users'] = [
      {
        'id': '1',
        'name': 'Yönetici Kullanıcı',
        'email': 'admin@example.com',
        'role': 'Super Admin',
        'created_at': MockTimestamp(DateTime.now()),
      },
      {
        'id': '2',
        'name': 'Test Kullanıcı',
        'email': 'test@example.com',
        'role': 'Manager',
        'created_at': MockTimestamp(DateTime.now()),
      },
    ];

    _collections['notifications'] = [
      {
        'id': '1',
        'title': 'Hoş Geldiniz',
        'body': 'Site yönetim uygulamasına hoş geldiniz!',
        'created_at': MockTimestamp(DateTime.now()),
        'is_read': false,
        'user_id': '1',
      },
    ];
  }

  MockCollectionReference collection(String path) {
    if (!_collections.containsKey(path)) {
      _collections[path] = [];
    }

    return MockCollectionReference(path, _collections[path]!, this);
  }
}

class MockRemoteMessage {
  final Map<String, dynamic> data;
  final String? title;
  final String? body;

  MockRemoteMessage({
    this.data = const {},
    this.title,
    this.body,
  });
}

class MockFirebaseMessaging {
  final StreamController<MockRemoteMessage> _onMessageController =
      StreamController.broadcast();

  Stream<MockRemoteMessage> get onMessage => _onMessageController.stream;

  Future<String> getToken() async {
    await Future.delayed(AppConfig.testDelay);
    return 'mock-fcm-token-${DateTime.now().millisecondsSinceEpoch}';
  }

  Future<void> subscribeToTopic(String topic) async {
    await Future.delayed(AppConfig.testDelay);
  }

  Future<void> unsubscribeFromTopic(String topic) async {
    await Future.delayed(AppConfig.testDelay);
  }

  void simulateMessage(
      {String? title, String? body, Map<String, dynamic>? data}) {
    _onMessageController.add(MockRemoteMessage(
      title: title,
      body: body,
      data: data ?? {},
    ));
  }
}

// Mock servislerini yöneten merkezi sınıf
class MockServices {
  static final MockFirebaseAuth auth = MockFirebaseAuth();
  static final MockFirestore firestore = MockFirestore();
  static final MockFirebaseMessaging messaging = MockFirebaseMessaging();
}

// Eğer Firebase bulunamazsa bu mock implementasyonların kullanılabilmesi için
// aynı arayüzü sunan "shim" sınıflar
class FirebaseAuth {
  static MockFirebaseAuth get instance => MockServices.auth;
}

class FirebaseFirestore {
  static MockFirestore get instance => MockServices.firestore;
}

class FirebaseMessaging {
  static MockFirebaseMessaging get instance => MockServices.messaging;
}

class Timestamp extends MockTimestamp {
  Timestamp(super.dateTime);

  static Timestamp now() => MockTimestamp.now();
  static Timestamp fromDate(DateTime dateTime) =>
      MockTimestamp.fromDate(dateTime);
}

class FieldValue {
  static dynamic serverTimestamp() => MockFieldValue.serverTimestamp();
  static dynamic increment(num value) => MockFieldValue.increment(value);
  static dynamic arrayUnion(List<dynamic> elements) =>
      MockFieldValue.arrayUnion(elements);
  static dynamic arrayRemove(List<dynamic> elements) =>
      MockFieldValue.arrayRemove(elements);
  static dynamic delete() => MockFieldValue.delete();
}

// Kullanıcı sınıfını uyarla
class AuthUser {
  final String uid;
  final String? email;
  final String? displayName;
  final String? phoneNumber;

  AuthUser({
    required this.uid,
    this.email,
    this.displayName,
    this.phoneNumber,
  });

  factory AuthUser.fromMockUser(MockUser user) {
    return AuthUser(
      uid: user.uid,
      email: user.email,
      displayName: user.displayName,
      phoneNumber: user.phoneNumber,
    );
  }
}
