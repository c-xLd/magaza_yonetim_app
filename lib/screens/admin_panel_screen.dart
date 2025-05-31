import 'package:flutter/material.dart';
import '../models/user.dart';
import '../theme.dart';
import '../util.dart';
import '../services/excel_service.dart';
// import 'product_management_screen.dart'; // Dosya yok, kaldırıldı
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../models/product_category.dart';
import '../providers/auth_provider.dart';

class _NavDestination {
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  const _NavDestination({
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });
}

class AdminPanelScreen extends StatefulWidget {
  const AdminPanelScreen({super.key});

  @override
  State<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen> with SingleTickerProviderStateMixin {
  TabController? _tabController;
  User? _currentUser;
  bool _isLoading = true;

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _loadCurrentUserAndData();
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentUserAndData() async {
    setState(() => _isLoading = true);
    _currentUser = null; // Firestore ile entegre, local _users kullanılmıyor
    _tabController?.dispose();
    _tabController = TabController(length: _navDestinations.length, vsync: this);
    _tabController?.addListener(() { setState(() {}); });
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  // M3 Expressive Navigation Destinations
  final List<_NavDestination> _navDestinations = const [
    _NavDestination(
      icon: Icons.people_alt_outlined,
      selectedIcon: Icons.people_alt,
      label: 'Personel',
    ),
    _NavDestination(
      icon: Icons.inventory_2_outlined,
      selectedIcon: Icons.inventory_2,
      label: 'Ürünler',
    ),
    _NavDestination(
      icon: Icons.upload_file_outlined,
      selectedIcon: Icons.upload_file,
      label: 'Stok Aktarımı',
    ),
    _NavDestination(
      icon: Icons.settings_outlined,
      selectedIcon: Icons.settings,
      label: 'Ayarlar',
    ),
  ];

  Widget _buildMainContent() {
    if (_tabController == null) return const Center(child: CircularProgressIndicator());
    return TabBarView(
      controller: _tabController,
      children: [
        _buildUserManagementView(),
        _buildProductManagementView(),
        _buildStockImportView(),
        _buildSystemSettingsView(),
      ],
    );
  }

  Widget _buildUserManagementView() {
    return FutureBuilder<List<List<Widget>>>(
      future: _getUserSections(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final sections = snapshot.data!;
        return ListView(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 0),
          children: [
            // Onay Bekleyenler
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
              child: Text('Onay Bekleyenler', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            ),
            if (sections[0].isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                child: Text('Onay bekleyen başvuru yok.', style: Theme.of(context).textTheme.bodyMedium),
              )
            else ...sections[0],
            const SizedBox(height: 24),
            // Aktif Personel
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
              child: Text('Aktif Personel', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            ),
            if (sections[1].isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                child: Text('Hiç personel yok.', style: Theme.of(context).textTheme.bodyMedium),
              )
            else ...sections[1],
          ],
        );
      },
    );
  }

  Future<List<List<Widget>>> _getUserSections() async {
    final pendingSnapshot = await FirebaseFirestore.instance.collection('users').where('isActive', isEqualTo: false).get();
    final activeSnapshot = await FirebaseFirestore.instance.collection('users').where('isActive', isEqualTo: true).get();
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    List<Widget> pending = pendingSnapshot.docs.map((doc) {
      final data = doc.data();
      final id = doc.id;
      final name = (data['name'] ?? '').toString();
      final phone = (data['phoneNumber'] ?? '').toString();
      final currentRole = data['role'] ?? 'staff';
      String? selectedRole = currentRole;
      return StatefulBuilder(
        builder: (context, setState) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
            child: Card(
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(22),
              ),
              color: colorScheme.surfaceContainerHigh,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        CircleAvatar(
                          radius: 28,
                          backgroundColor: colorScheme.primaryContainer,
                          child: Text(
                            (name.isNotEmpty ? name[0] : '?').toUpperCase(),
                            style: textTheme.headlineSmall?.copyWith(
                              color: colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 18),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(name, style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Icon(Icons.phone_outlined, size: 16, color: colorScheme.tertiary),
                                  const SizedBox(width: 4),
                                  Text(phone, style: textTheme.bodyMedium?.copyWith(color: colorScheme.tertiary)),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButton<String>(
                          value: selectedRole,
                          hint: const Text('Rol Seç'),
                          items: const [
                            DropdownMenuItem(value: 'admin', child: Text('Yönetici (Admin)')),
                            DropdownMenuItem(value: 'manager', child: Text('Mağaza Sorumlusu')),
                            DropdownMenuItem(value: 'staff', child: Text('Mağaza Personeli')),
                          ],
                          onChanged: (val) {
                            setState(() {
                              selectedRole = val;
                            });
                          },
                          ),
                        ),
                        const SizedBox(width: 12),
                        FilledButton(
                          child: const Text('Onayla'),
                          onPressed: () async {
                            if (selectedRole != null) {
                              await FirebaseFirestore.instance.collection('users').doc(id).update({
                                'isActive': true,
                                'role': selectedRole,
                              });
                              if (mounted) setState(() {});
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('$name onaylandı ve $selectedRole rolüne atandı.')),
                              );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Lütfen rol seçin.')),
                              );
                            }
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    }).toList();

    List<Widget> active = activeSnapshot.docs.map((doc) {
      final data = doc.data();
      final id = doc.id;
      final name = (data['name'] ?? '').toString();
      final role = data['role'] ?? 'staff';
      final phone = (data['phoneNumber'] ?? '').toString();
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        child: Card(
          elevation: 3,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          color: colorScheme.surfaceContainerHigh,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: colorScheme.primaryContainer,
                      child: Text(
                        (name.isNotEmpty ? name[0] : '?').toUpperCase(),
                        style: textTheme.headlineSmall?.copyWith(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 18),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(name, style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Icon(Icons.badge_outlined, size: 16, color: colorScheme.secondary),
                              const SizedBox(width: 4),
                              Text(AuthProvider.getDisplayRole(role.toString()), style: textTheme.bodyMedium?.copyWith(color: colorScheme.secondary, fontWeight: FontWeight.w600)),
                            ],
                          ),
                          if (phone.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(Icons.phone_outlined, size: 16, color: colorScheme.tertiary),
                                const SizedBox(width: 4),
                                Text(phone, style: textTheme.bodyMedium?.copyWith(color: colorScheme.tertiary)),
                              ],
                            ),
                          ]
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextButton.icon(
                      icon: Icon(Icons.edit_rounded, color: colorScheme.primary),
                      label: Text('Düzenle', style: textTheme.labelLarge?.copyWith(color: colorScheme.primary)),
                      onPressed: () => _showUserFormDialogFirestore(id: id, data: data),
                    ),
                    const SizedBox(width: 8),
                    TextButton.icon(
                      icon: Icon(Icons.delete_rounded, color: colorScheme.error),
                      label: Text('Sil', style: textTheme.labelLarge?.copyWith(color: colorScheme.error)),
                      onPressed: () => _confirmDeleteDialog(
                        "Personeli Sil",
                        "$name adlı personeli silmek istediğinizden emin misiniz?",
                        () async {
                          await FirebaseFirestore.instance.collection('users').doc(id).delete();
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    }).toList();

    return [pending, active];
  }

  Widget _buildProductManagementView() {
    return Expanded(
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('products').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final docs = snapshot.data!.docs;
          if (docs.isEmpty) return const Center(child: Text('Hiç ürün yok.'));
          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final colorScheme = Theme.of(context).colorScheme;
              final textTheme = Theme.of(context).textTheme;
              final name = (data['name'] ?? '').toString();
              final category = (data['category'] ?? '').toString();
              final stock = data['stock'] is int ? data['stock'] : int.tryParse(data['stock']?.toString() ?? '') ?? 0;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                child: Card(
                  elevation: 3,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(22),
                  ),
                  color: colorScheme.surfaceContainerHigh,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            CircleAvatar(
                              radius: 28,
                              backgroundColor: colorScheme.primaryContainer,
                              child: Text(
                                (name.isNotEmpty ? name[0] : '?').toUpperCase(),
                                style: textTheme.headlineSmall?.copyWith(
                                  color: colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 18),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(name, style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      Icon(Icons.category_outlined, size: 16, color: colorScheme.onSurfaceVariant),
                                      const SizedBox(width: 4),
                                      Flexible(child: Text(category, style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant))),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Icon(Icons.inventory_2_outlined, size: 16, color: colorScheme.tertiary),
                                      const SizedBox(width: 4),
                                      Text("Stok: $stock", style: textTheme.bodyMedium?.copyWith(color: colorScheme.tertiary)),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            TextButton.icon(
                              icon: Icon(Icons.edit_rounded, color: colorScheme.primary),
                              label: Text('Düzenle', style: textTheme.labelLarge?.copyWith(color: colorScheme.primary)),
                              onPressed: () => _showProductFormDialog(product: data),
                            ),
                            const SizedBox(width: 8),
                            TextButton.icon(
                              icon: Icon(Icons.delete_rounded, color: colorScheme.error),
                              label: Text('Sil', style: textTheme.labelLarge?.copyWith(color: colorScheme.error)),
                              onPressed: () => _confirmDeleteDialog(
                                "Ürünü Sil",
                                "$name adlı ürünü silmek istediğinizden emin misiniz?",
                                () async {
                                  if (data['id'] != null) {
                                    await FirebaseFirestore.instance.collection('products').doc(data['id']).delete();
                                  }
                                },
                                product: data,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(String title, String searchHint) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 16),
          TextField(
            decoration: InputDecoration(
              hintText: searchHint,
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              filled: true,
              fillColor: colorScheme.surfaceContainerLow,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholderView(String title, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 16),
          Text(
            title,
            style: Theme.of(context).textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildStockImportView() {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.upload_file_rounded, size: 64, color: colorScheme.primary),
            const SizedBox(height: 16),
            Text("Stok Aktarımı", style: textTheme.headlineSmall, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            Text("Excel veya CSV dosyası seçerek toplu stok aktarımı yapabilirsiniz.",
                style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
                textAlign: TextAlign.center),
            const SizedBox(height: 24),
            FilledButton.icon(
              icon: const Icon(Icons.file_upload_outlined),
              label: const Text("Dosya Seç ve Yükle"),
              onPressed: _handleStockImport,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleStockImport() async {
    final excelService = ExcelService();
    final pickedFile = await excelService.pickExcelFile();
    if (pickedFile == null) return;
    final result = await excelService.processExcelFile(pickedFile.path!, "admin");
    if (!result.success) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("Aktarım Hatası"),
            content: Text(result.message),
            actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text("Kapat"))],
          ),
        );
      }
      return;
    }
    // Eşleşme ve güncelleme işlemi Firestore ile yapılacak
    int updated = 0;
    int added = 0;
    final batch = FirebaseFirestore.instance.batch();
    for (final imported in result.products) {
      final query = await FirebaseFirestore.instance
          .collection('products')
          .where('barcode', isEqualTo: imported['barcode'])
          .get();
      if (query.docs.isNotEmpty) {
        // Güncelle
        final docRef = query.docs.first.reference;
        batch.update(docRef, {
          'name': imported['name'],
          'code': imported['code'],
          'barcode': imported['barcode'],
          'unit': imported['unit'],
          'packageQuantity': imported['packageQuantity'],
        });
        updated++;
      } else {
        // Yeni ürün ekle
        final newDoc = FirebaseFirestore.instance.collection('products').doc();
        batch.set(newDoc, {
          'id': newDoc.id,
          'name': imported['name'],
          'code': imported['code'],
          'barcode': imported['barcode'],
          'unit': imported['unit'],
          'packageQuantity': imported['packageQuantity'],
          'stock': 0,
          'category': '',
        });
        added++;
      }
    }
    await batch.commit();
    if (mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("Stok Aktarım Sonucu"),
          content: Text("${result.processedCount} satır işlendi.\n$updated ürün güncellendi, $added yeni ürün eklendi."),
          actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text("Kapat"))],
        ),
      );
    }
  }

  Widget _buildSystemSettingsView() {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text("Sistem Ayarları", style: textTheme.headlineSmall),
        const SizedBox(height: 18),
        Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          color: colorScheme.surfaceContainerHigh,
          elevation: 2,
          child: ListTile(
            leading: Icon(Icons.palette_outlined, color: colorScheme.primary),
            title: Text("Tema Ayarı", style: textTheme.titleMedium),
            subtitle: Text("Açık/Koyu tema seçimi (demo)", style: textTheme.bodyMedium),
            trailing: Switch(
              value: true,
              onChanged: (v) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Demo: Tema değiştirici!")));
              },
            ),
          ),
        ),
        const SizedBox(height: 14),
        Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          color: colorScheme.surfaceContainerHigh,
          elevation: 2,
          child: ListTile(
            leading: Icon(Icons.info_outline, color: colorScheme.secondary),
            title: Text("Sürüm Bilgisi", style: textTheme.titleMedium),
            subtitle: Text("Uygulama v1.0.0", style: textTheme.bodyMedium),
          ),
        ),
        const SizedBox(height: 14),
        Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          color: colorScheme.surfaceContainerHigh,
          elevation: 2,
          child: ListTile(
            leading: Icon(Icons.security_outlined, color: colorScheme.tertiary),
            title: Text("Gizlilik Politikası", style: textTheme.titleMedium),
            subtitle: Text("Verileriniz güvende! (demo)", style: textTheme.bodyMedium),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Demo: Gizlilik politikası!")));
            },
          ),
        ),
      ],
    );
  }

  void _showUserFormDialogFirestore({String? id, Map<String, dynamic>? data}) {
    final formKey = GlobalKey<FormState>();
    String? name = data?['name'];
    String? phone = data?['phoneNumber'];
    String role = data?['role'] ?? 'staff';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        final colorScheme = Theme.of(context).colorScheme;
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            top: 16,
            left: 8,
            right: 8,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            ),
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(id == null ? "Yeni Personel Ekle" : "Personeli Düzenle", style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 24),
                  _buildTextFormField(
                    initialValue: name,
                    labelText: "Ad Soyad",
                    onSaved: (value) => name = value!,
                    validator: (value) => value!.isEmpty ? "Lütfen ad soyad girin" : null,
                  ),
                  const SizedBox(height: 16),
                  _buildTextFormField(
                    initialValue: phone,
                    labelText: "Telefon",
                    onSaved: (value) => phone = value,
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: role,
                    decoration: const InputDecoration(labelText: "Rol"),
                    dropdownColor: Theme.of(context).colorScheme.surface,
                    style: Theme.of(context).textTheme.bodyMedium,
                    items: const [
                      DropdownMenuItem(value: 'admin', child: Text('Yönetici')),
                      DropdownMenuItem(value: 'manager', child: Text('Mağaza Sorumlusu')),
                      DropdownMenuItem(value: 'staff', child: Text('Mağaza Personeli')),
                    ],
                    onChanged: (String? newValue) {
                      if (newValue != null) role = newValue;
                    },
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        child: const Text("İptal"),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      const SizedBox(width: 8),
                      FilledButton(
                        child: Text(id == null ? "Ekle" : "Kaydet"),
                        onPressed: () async {
                          if (formKey.currentState!.validate()) {
                            formKey.currentState!.save();
                            final userData = {
                              'name': name,
                              'phoneNumber': phone ?? '',
                              'role': role,
                            };
                            if (id == null) {
                              await FirebaseFirestore.instance.collection('users').add(userData);
                            } else {
                              await FirebaseFirestore.instance.collection('users').doc(id).update(userData);
                            }
                            Navigator.of(context).pop();
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showProductFormDialog({Map<String, dynamic>? product}) {
    final formKey = GlobalKey<FormState>();
    String? name = product?['name'];
    String? code = product?['code'];
    int? stock = product?['stock'];
    String? id = product?['id'];
    String? role = product?['role'] ?? 'Sorumlu';
    final codeController = TextEditingController(text: code);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        final colorScheme = Theme.of(context).colorScheme;
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            top: 16,
            left: 8,
            right: 8,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            ),
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(product == null ? "Yeni Ürün Ekle" : "Ürünü Düzenle", style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 24),
                  _buildTextFormField(
                    initialValue: name,
                    labelText: "Ürün Adı",
                    onSaved: (value) => name = value!,
                    validator: (value) => value!.isEmpty ? "Lütfen ürün adı girin" : null,
                  ),
                  const SizedBox(height: 16),
                  _buildTextFormField(
                    initialValue: code,
                    labelText: "Ürün Kodu",
                    onSaved: (value) => code = value!,
                    validator: (value) => value!.isEmpty ? "Lütfen ürün kodu girin" : null,
                  ),
                  const SizedBox(height: 16),
                  _buildTextFormField(
                    initialValue: stock?.toString(),
                    labelText: "Stok Miktarı",
                    onSaved: (value) => stock = int.tryParse(value ?? ''),
                    keyboardType: TextInputType.number,
                    validator: (value) => (int.tryParse(value ?? '') == null || int.parse(value!) < 0) ? "Geçerli bir stok girin" : null,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: (role == 'manager' || role == 'staff') ? role : 'manager',
                    decoration: const InputDecoration(labelText: "Kim Sayacak (Rol)"),
                    items: const [
                      DropdownMenuItem(value: 'manager', child: Text('Mağaza Sorumlusu')),
                      DropdownMenuItem(value: 'staff', child: Text('Mağaza Personeli')),
                    ],
                    onChanged: (val) {
                      if (val != null) setState(() { role = val; });
                    },
                    onSaved: (val) {
                      if (val != null) role = val;
                    },
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        child: const Text("İptal"),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      const SizedBox(width: 8),
                      FilledButton(
                        child: Text(product == null ? "Ekle" : "Kaydet"),
                        onPressed: () async {
                          if (formKey.currentState!.validate()) {
                            formKey.currentState!.save();
                            final newId = id ?? const Uuid().v4();
                            // Kategori kodunu ürün kodunun ilk iki hanesine göre otomatik belirle
                            String category = '';
                            if ((code?.length ?? 0) >= 2) {
                              final cat = ProductCategory.fromCode(code!);
                              category = cat?.name ?? '';
                            }
                            final newProductData = {
                              'id': newId,
                              'name': name,
                              'code': code,
                              'category': category,
                              'stock': stock,
                              'role': role,
                            };
                            if (product == null) {
                              await FirebaseFirestore.instance.collection('products').doc(newId).set(newProductData);
                            } else {
                              await FirebaseFirestore.instance.collection('products').doc(newId).update(newProductData);
                            }
                            Navigator.of(context).pop();
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTextFormField({
    String? initialValue,
    required String labelText,
    required FormFieldSetter<String> onSaved,
    FormFieldValidator<String>? validator,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      initialValue: initialValue,
      decoration: InputDecoration(
        labelText: labelText,
        border: const OutlineInputBorder(),
        filled: true,
        fillColor: Theme.of(context).colorScheme.surfaceContainerLow,
      ),
      onSaved: onSaved,
      validator: validator,
      keyboardType: keyboardType,
      style: Theme.of(context).textTheme.bodyMedium,
    );
  }

  void _confirmDeleteDialog(String title, String content, VoidCallback onConfirm, {Map<String, dynamic>? product}) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          title: Text(title, style: Theme.of(context).textTheme.titleLarge),
          content: Text(content),
          actions: <Widget>[
            TextButton(
              child: const Text("İptal"),
              onPressed: () => Navigator.of(context).pop(),
            ),
            FilledButton(
              child: const Text("Sil"),
              onPressed: () async {
                onConfirm();
                if (product != null && product['id'] != null) {
                  await FirebaseFirestore.instance.collection('products').doc(product['id']).delete();
                }
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  FloatingActionButton? _buildFloatingActionButton() {
    if (_tabController == null) return null;
    final index = _tabController!.index;
    switch (index) {
      case 0:
        return FloatingActionButton.extended(
          onPressed: () => _showUserFormDialogFirestore(),
          tooltip: "Yeni Personel Ekle",
          icon: const Icon(Icons.person_add_alt_1_outlined),
          label: const Text("Yeni Personel"),
        );
      case 1:
        return FloatingActionButton.extended(
          onPressed: () => _showProductFormDialog(),
          tooltip: "Yeni Ürün Ekle",
          icon: const Icon(Icons.add_business_outlined),
          label: const Text("Yeni Ürün"),
        );
      case 2:
        return FloatingActionButton.extended(
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Demo: Dosya seçme açılır!")));
          },
          tooltip: "Stok Dosyası Yükle",
          icon: const Icon(Icons.upload_file_outlined),
          label: const Text("Dosya Yükle"),
        );
      case 3:
        return FloatingActionButton.extended(
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Demo: Ayarları sıfırla!")));
          },
          tooltip: "Ayarları Sıfırla",
          icon: const Icon(Icons.restart_alt_outlined),
          label: const Text("Ayarları Sıfırla"),
        );
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = createTextTheme(context, 'Roboto', 'Roboto');
    final theme = MaterialTheme(textTheme).dark();
    final colorScheme = theme.colorScheme;
    final localTextTheme = theme.textTheme;
    if (_isLoading) {
      return Theme(
        data: theme,
        child: const Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 20),
                Text("Yükleniyor..."),
              ],
            ),
          ),
        ),
      );
    }
    return Theme(
      data: theme,
      child: Scaffold(
        key: _scaffoldKey,
        appBar: AppBar(
          automaticallyImplyLeading: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              if (Navigator.canPop(context)) {
                Navigator.pop(context);
              } else {
                Navigator.pushReplacementNamed(context, '/');
              }
            },
          ),
          title: Text(
            'Yönetim Paneli',
            style: localTextTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          backgroundColor: colorScheme.secondaryContainer,
          foregroundColor: colorScheme.onSecondaryContainer,
          elevation: 0,
          centerTitle: true,
          surfaceTintColor: colorScheme.secondaryContainer,
          actions: [
            IconButton(
              icon: const Icon(Icons.logout_outlined),
              tooltip: "Çıkış Yap",
              onPressed: () async {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Çıkış yapıldı (simüle edildi)")),
                );
              },
            ),
          ],
          bottom: _tabController == null
              ? null
              : TabBar(
                  controller: _tabController,
                  isScrollable: false,
                  indicatorColor: theme.colorScheme.primary,
                  tabs: _navDestinations
                      .map((dest) => Tab(
                            icon: Icon(dest.icon),
                            text: dest.label,
                          ))
                      .toList(),
                ),
        ),
        body: _buildMainContent(),
        floatingActionButton: _buildFloatingActionButton(),
      ),
    );
  }
}
