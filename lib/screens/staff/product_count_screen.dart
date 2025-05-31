import 'package:flutter/material.dart';
import 'dart:async';
import '../../models/product.dart';
import '../../models/product_assignment.dart';
import '../../models/user.dart';
import '../../services/product_assignment_service.dart';
import '../../theme/app_theme.dart';
import 'package:intl/intl.dart';
import '../../widgets/custom_list_card.dart';


class ProductCountScreen extends StatefulWidget {
  final User currentUser;
  final String? groupId; // Belirli bir grup için sayım yapılacaksa

  const ProductCountScreen({
    super.key,
    required this.currentUser,
    this.groupId,
  });

  @override
  State<ProductCountScreen> createState() => _ProductCountScreenState();
}

class _ProductCountScreenState extends State<ProductCountScreen> {
  // Modern kavisli üst başlık widget'ı
  Widget _buildScreenHeader(String title, {String? subtitle, IconData? icon, VoidCallback? onIconPressed}) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                if (subtitle != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      subtitle,
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 13,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (icon != null)
            IconButton(
              icon: Icon(icon, color: Colors.grey, size: 26),
              onPressed: onIconPressed,
              tooltip: 'Yenile',
            ),
        ],
      ),
    );
  }

  final ProductAssignmentService _assignmentService =
      ProductAssignmentService();

  List<Product> _assignedProducts = [];
  List<ProductAssignment> _activeAssignments = [];
  bool _isLoading = true;

  // Stok sayım sistem değişkenleri
  bool _isEveningCountAllowed = false; // Akşam sayımına izin veriliyor mu?
  bool _isMorningInputAllowed =
      false; // Sabah satış girişine izin veriliyor mu?
  final bool _stockDiscrepancyDetected = false; // Stok tutarsızlığı tespit edildi mi?

  // Ürün sayım verileri
  final Map<String, int> _eveningCounts =
      {}; // Akşam sayımı verileri (product.id -> count)
  final Map<String, int> _salesCounts =
      {}; // Satış verileri (product.id -> count)
  final Map<String, int> _recountValues =
      {}; // Tekrar sayım verileri (product.id -> count)

  // Akşam sayımı için saat kontrolü (21:20)
  
  Timer? _timeCheckTimer;

  @override
  void initState() {
    super.initState();
    _loadData();
    _setupTimeCheck();
    _loadSavedCounts(); // Kayıtlı sayımları yükle
  }

  @override
  void dispose() {
    _timeCheckTimer?.cancel();
    super.dispose();
  }

  // Saat kontrolünü kurar
  void _setupTimeCheck() {
    // Bu noktada gerçek bir uygulama için DateTime.now() kullanılacak
    // Test için sabit bir saat atayabilirsiniz
    _checkTimePermissions();

    // Her dakika saat kontrollerini yenile
    _timeCheckTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      _checkTimePermissions();
    });
  }

  // Saat izinlerini kontrol et
  void _checkTimePermissions() {
    final now = DateTime.now();
    final currentHour = now.hour;
    final currentMinute = now.minute;

    // Akşam sayımı kontrolü (21:20 sonrası)
    if (currentHour >= 21 && currentMinute >= 20) {
      setState(() {
        _isEveningCountAllowed = true;
        _isMorningInputAllowed = false;
      });
    }
    // Sabah satış girişi kontrolü (akşam 23:59'dan sabah 9:00'a kadarki süre)
    else if ((currentHour >= 0 && currentHour < 21) ||
        (currentHour == 23 && currentMinute > 0)) {
      setState(() {
        _isEveningCountAllowed = false;
        _isMorningInputAllowed = true;
      });
    } else {
      setState(() {
        _isEveningCountAllowed = false;
        _isMorningInputAllowed = false;
      });
    }
  }

  // Kayıtlı sayımları yükleme (Gerçek uygulamada veritabanından alınacak)
  Future<void> _loadSavedCounts() async {
    // Örnek veri yükleme - gerçek uygulamada veritabanından gelecek
    // Akşam sayımı verileri
    // _eveningCounts = {'product1': 100, 'product2': 50};

    // Sabah satış verileri
    // _salesCounts = {'product1': 5, 'product2': 2};
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    if (widget.groupId != null) {
      // Belirli bir grup için sayım yapılacaksa
      try {
        await _loadGroupProducts(widget.groupId!);
        await _loadGroupAssignments(widget.groupId!);
      } catch (e) {
        // Eğer belirtilen grup bulunamazsa ve başka gruplar varsa ilkini kullan
        if (_assignedProducts.isNotEmpty) {
          await _loadGroupProducts(_assignedProducts.first.id);
          await _loadGroupAssignments(_assignedProducts.first.id);
        }
      }
    } else if (_assignedProducts.isNotEmpty) {
      // Varsayılan olarak ilk grubu seç
      await _loadGroupProducts(_assignedProducts.first.id);
      await _loadGroupAssignments(_assignedProducts.first.id);
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _loadGroupProducts(String groupId) async {
    // Gruba atanmış ürünleri yükle
    _assignedProducts = await _assignmentService.getGroupProducts(groupId);

    // Gerçek uygulamada aşağıdaki kod Firebase veya başka bir veritabanı ile
    // entegre edilecek ve productIds listesindeki ID'lere göre ürünler getirilecek
    // Şimdilik boş liste olarak bırakıyoruz, ancak gerçek uygulamada bu kısım
    // veritabanından ürünleri çekecek şekilde kodlanacak
    if (_assignedProducts.isNotEmpty) {
      // NOT: Veritabanı entegrasyonu için mock veriler ekleyebilirsiniz
      // Örnek: _assignedProducts.forEach((product) { fetchProductById(product.id); });
    }
  }

  Future<void> _loadGroupAssignments(String groupId) async {
    // Gruba atanmış aktif görevleri yükle
    _activeAssignments = _assignmentService.getGroupAssignments(groupId);
  }

  @override
  Widget build(BuildContext context) {
    final now = DateFormat('HH:mm').format(DateTime.now());
    final isStaff = widget.currentUser.role == UserRole.staff;
    final isManager = widget.currentUser.role == UserRole.manager ||
        widget.currentUser.role == UserRole.superAdmin;

    return Scaffold(
      appBar: null, // AppBar'ı kaldırıyoruz
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _assignedProducts.isEmpty
              ? _buildNoGroupsAvailable()
              : Column(
                  children: [
                    // Modern üst başlık
                    _buildScreenHeader('Ürün Sayım Ekranı', subtitle: now, icon: Icons.refresh, onIconPressed: () async {
                      await _loadData();
                      _checkTimePermissions(); // Saat izinlerini yeniden kontrol et
                    }),
                    
                    // Üst bilgi bannerı
                    _buildInfoBanner(isStaff, isManager),

                    // Ürün listesi
                    Expanded(
                      child: _buildProductsList(isStaff, isManager),
                    ),

                    // Alt butonlar
                    _buildBottomButtons(isStaff, isManager),
                  ],
                ),
    );
  }

  // Bilgi bannerı widget'ı
  Widget _buildInfoBanner(bool isStaff, bool isManager) {
    String message = '';
    Color backgroundColor = Colors.blue.shade100;

    if (isStaff && _isEveningCountAllowed) {
      message = 'Akşam Sayım Modu - Lütfen tüm ürünleri sayınız ve kaydediniz.';
      backgroundColor = Colors.orange.shade100;
    } else if (isManager && _isMorningInputAllowed) {
      message = 'Satış Giriş Modu - Lütfen gece yapılan satışları giriniz.';
      backgroundColor = Colors.blue.shade100;
    } else if (_stockDiscrepancyDetected) {
      message =
          'Stok Tutarsızlığı Tespit Edildi - Lütfen işaretli ürünleri tekrar sayınız.';
      backgroundColor = Colors.red.shade100;
    } else {
      message = isStaff
          ? 'Sayım yapmak için 21:20 saatini beklemelisiniz.'
          : 'Hoş geldiniz, yönetici.';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      color: backgroundColor,
      child: Text(
        message,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildNoGroupsAvailable() {
  return const Center(
    child: Text('Hiçbir ürün bulunamadı.', style: TextStyle(fontSize: 18)),
  );
}

Widget _buildNoGroupsMessage() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.group_off,
            size: 64,
            color: AppTheme.currentColorScheme.primary.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'Henüz hiçbir sayım grubuna dahil edilmediniz',
            style: TextStyle(
              fontSize: 18,
              color: AppTheme.currentColorScheme.onSurface.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Yöneticinizden sizi bir gruba eklemesini isteyin',
            style: TextStyle(
              fontSize: 16,
              color: AppTheme.currentColorScheme.onSurface.withOpacity(0.5),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildProductCountUI() {
    return Column(
      children: [
        // Ürün listesi
        Expanded(
          child: _assignedProducts.isEmpty
              ? _buildEmptyProductsMessage()
              : _buildProductList(),
        ),
      ],
    );
  }

  Widget _buildEmptyProductsMessage() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inventory_2_outlined,
            size: 64,
            color: AppTheme.currentColorScheme.primary.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'Bu gruba henüz ürün atanmamış',
            style: TextStyle(
              fontSize: 18,
              color: AppTheme.currentColorScheme.onSurface.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildProductList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _assignedProducts.length,
      itemBuilder: (context, index) {
        final product = _assignedProducts[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: CustomListCard(
            icon: Icons.inventory,
            iconBgColor: AppTheme.currentColorScheme.primary.withOpacity(0.12),
            title: product.name,
            subtitle: 'Kod: ${product.code} | Stok: ${product.stock} | Beklenen: ${product.expectedStock}',
            trailing: const Icon(Icons.keyboard_arrow_right, color: Colors.grey),
            onTap: () => _showCountDialog(product),
            cardColor: Colors.white,
            borderRadius: 16,
          ),
        );
      },
    );
  }

  void _showCountDialog(Product product) {
    final TextEditingController countController = TextEditingController();
    final TextEditingController locationController = TextEditingController();
    final TextEditingController notesController = TextEditingController();

    if (product.location != null && product.location!.isNotEmpty) {
      locationController.text = product.location!;
    }

    final stockAnalysis = product.analyzeStockStatus();
    final bool hasPossiblePackage =
        stockAnalysis['isPossibleNewPackage'] as bool;
    final bool hasSalesDiscrepancy =
        stockAnalysis['hasSalesDiscrepancy'] as bool;
    final bool hasExcessSalesForSingle =
        stockAnalysis['hasExcessSalesForSingle'] as bool;
    final int excessSaleAmount =
        (stockAnalysis['excessSaleAmount'] as int?) ?? 0;

    // Tekli ürünlerde fazla satış varsa, önce yeni gelen ürün miktarını sor
    if (hasExcessSalesForSingle && excessSaleAmount > 0) {
      _showNewSingleItemsDialog(product, excessSaleAmount)
          .then((updatedProduct) {
        // Eğer updatedProduct null değilse (kullanıcı diyaloğu tamamladıysa)
        if (updatedProduct != null) {
          // Güncellenmiş ürünle tekrar sayım diyaloğunu göster
          _showCountDialog(updatedProduct);
        }
      });
      return; // Diyalog zincirini başlat ve mevcut diyaloğu açma
    }

    // Otomatik stok düzeltme seçeneği için değişken
    bool autoCorrectStock = false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(product.name),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Ürün bilgileri
                    Text('Ürün Kodu: ${product.code}'),
                    const SizedBox(height: 4),

                    // Stok bilgileri
                    Text('Mevcut Stok: ${product.stock}'),
                    Text('Beklenen Stok: ${product.expectedStock}'),

                    // Ek ürün bilgileri
                    if (product.packageQuantity > 1)
                      Text('Koli İçi Adet: ${product.packageQuantity}'),

                    if (product.salesSinceLastCount > 0)
                      Text(
                          'Son Sayımdan Sonraki Satış: ${product.salesSinceLastCount}'),

                    // Stok uyumsuzluğu varsa uyarı mesajı göster
                    if (hasSalesDiscrepancy)
                      Container(
                        margin: const EdgeInsets.only(top: 12),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade100,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.amber.shade800),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.warning_amber_rounded,
                                    color: Colors.amber.shade800),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Stok Uyumsuzluğu Tespit Edildi',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.amber.shade800,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Satış miktarı (${product.salesSinceLastCount}) mevcut stoktan (${product.stock}) fazla. '
                              'Muhtemelen yeni bir koli/paket açıldı.',
                              style: const TextStyle(fontSize: 13),
                            ),
                          ],
                        ),
                      ),

                    // Son sayım tarihi ve kim tarafından sayıldığı
                    const SizedBox(height: 12),
                    Text(
                      'Son Sayım: ${_formatDate(product.lastCountDate)}${product.lastCountedBy != null ? ' (${product.lastCountedBy})' : ''}',
                      style:
                          TextStyle(fontSize: 12, color: Colors.grey.shade700),
                    ),

                    const Divider(height: 24),

                    // Sayım bilgileri giriş alanları
                    TextField(
                      controller: countController,
                      decoration: const InputDecoration(
                        labelText: 'Sayılan Miktar',
                        hintText: 'Sayım sonucunu girin',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: locationController,
                      decoration: const InputDecoration(
                        labelText: 'Konum',
                        hintText: 'Ürünün konumu',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: notesController,
                      decoration: const InputDecoration(
                        labelText: 'Notlar',
                        hintText: 'Ek bilgiler',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 2,
                    ),

                    // Otomatik stok düzeltme seçeneği
                    if (hasSalesDiscrepancy || hasPossiblePackage) ...[
                      const SizedBox(height: 12),
                      CheckboxListTile(
                        title: const Text('Otomatik Stok Düzeltme'),
                        subtitle: const Text(
                          'Stok ve satış tutarsızlıklarını otomatik çöz',
                          style: TextStyle(fontSize: 12),
                        ),
                        value: autoCorrectStock,
                        onChanged: (value) {
                          setState(() {
                            autoCorrectStock = value ?? false;
                          });
                        },
                        activeColor: AppTheme.currentColorScheme.primary,
                      )
                    ]
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('İptal'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (countController.text.isNotEmpty) {
                      final countedQuantity =
                          int.tryParse(countController.text) ?? 0;

                      // Yeni ürün verilerini hazırla
                      final updatedProduct = product.recordCount(
                        countedQuantity,
                        widget.currentUser.id,
                        locationInfo: locationController.text.isNotEmpty
                            ? locationController.text
                            : null,
                        countNotes: notesController.text.isNotEmpty
                            ? notesController.text
                            : null,
                      );

                      // Sayım kaydını ekle ve akıllı stok yönetimini kullan
                      _assignmentService.updateProductAndAddCount(
                        product: updatedProduct,
                        countedQuantity: countedQuantity,
                        countedBy: widget.currentUser.id,
                        groupId: widget.groupId!,
                        autoCorrectStock: autoCorrectStock,
                        notes: notesController.text.isNotEmpty
                            ? notesController.text
                            : null,
                        storeId:
                            null, // Şu an store ID'yi ilgili ekrandan alabiliriz ama şimdilik boş bırakıyoruz
                      );

                      Navigator.pop(context);

                      // Başarılı mesajı göster
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(autoCorrectStock
                              ? 'Sayım kaydedildi ve stok otomatik düzeltildi'
                              : 'Sayım kaydedildi'),
                          backgroundColor: Colors.green,
                        ),
                      );

                      // Listeyi yenile
                      _loadData();
                    }
                  },
                  child: const Text('Kaydet'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Tekli ürünler için yeni gelen ürün miktarını soran diyalog
  Future<Product?> _showNewSingleItemsDialog(
      Product product, int excessSaleAmount) async {
    final TextEditingController newItemsController = TextEditingController();
    newItemsController.text = excessSaleAmount
        .toString(); // Varsayılan olarak fazla satış miktarını göster

    return showDialog<Product?>(
      context: context,
      barrierDismissible: false, // Kullanıcı dışarı tıklayarak kapatamaz
      builder: (context) {
        return AlertDialog(
          title: const Text('Yeni Ürün Girişi Tespit Edildi'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Dünkü stoktan fazla satış tespit edildi!',
                style:
                    TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
              ),
              const SizedBox(height: 12),
              Text(
                'Dünkü stok: ${product.stock} adet\n'
                'Satış miktarı: ${product.salesSinceLastCount} adet\n\n'
                'Eksik stok miktarı: $excessSaleAmount adet',
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 16),
              const Text(
                'Dün mağazaya kaç adet yeni ürün geldi?',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: newItemsController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Gelen Ürün Adedi',
                  hintText: 'En az $excessSaleAmount adet giriş olmalı',
                  border: const OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                // Girilen değeri kontrol et
                final newItemCount = int.tryParse(newItemsController.text) ?? 0;
                if (newItemCount < excessSaleAmount) {
                  // Yetersiz miktar
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(
                        'En az $excessSaleAmount adet giriş yapılmalıdır!'),
                    backgroundColor: Colors.red,
                  ));
                  return;
                }

                // Stoğu güncelle
                final updatedProduct =
                    product.updateSingleItemStock(newItemCount);

                // Diyaloğu kapat ve güncellenmiş ürünü döndür
                Navigator.of(context).pop(updatedProduct);
              },
              child: const Text('Kaydet'),
            ),
          ],
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}.${date.month}.${date.year}';
  }
}
