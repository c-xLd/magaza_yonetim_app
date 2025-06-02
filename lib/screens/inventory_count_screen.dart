import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart'; // AuthProvider dosyanızın yolu
import 'package:intl/intl.dart'; // Tarih formatlama için

class InventoryCountScreen extends StatefulWidget {
  const InventoryCountScreen({super.key});

  @override
  State<InventoryCountScreen> createState() => _InventoryCountScreenState();
}

class _InventoryCountScreenState extends State<InventoryCountScreen> {
  final Map<String, int> _countedQuantities = {};
  bool _isSubmittingCount = false;
  final DateTime _selectedDate = DateTime.now(); // Tarih her zaman bugün
  Map<String, int> _savedCounts = {};
  bool _alreadyCounted = false;
  final Map<String, TextEditingController> _controllers = {};

  bool _isCountStarted = false;
  DateTime? _countStartTime;

  bool _disableEditDueToSalesOrCompletion = false;
  bool _isLoadingInitialStatus = true; // İlk yükleme durumu için flag

  @override
  void initState() {
    super.initState();
    _loadInitialCountStatusAndCheckSales();
  }

  Future<void> _loadInitialCountStatusAndCheckSales() async {
    if (!mounted) return;
    setState(() {
      _isLoadingInitialStatus = true;
      // Veri çekmeden önce yüklü verilere bağlı durumları sıfırla
      // _isCountStarted burada false ayarlanacak, çünkü buton görünürlüğü buna bağlı.
      // Eğer sayım yoksa, setState sonunda true'ya dönecek.
      _isCountStarted = false;
      _alreadyCounted = false;
      _savedCounts.clear();
      _countedQuantities.clear();
      _controllers.forEach((_, controller) => controller.text = ""); // HintText için kontrolcüleri temizle
      _disableEditDueToSalesOrCompletion = false;
    });

    final selectedDateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.phoneNumber;
    final userRole = authProvider.role;

    bool initialAlreadyCounted = false;
    Map<String, int> initialSavedCounts = {};
    bool initialDisableEdit = false;

    try {
      final inventoryDoc = await FirebaseFirestore.instance.collection('inventoryCounts').doc(selectedDateStr).get();

      if (inventoryDoc.exists) {
        final data = inventoryDoc.data();
        final userRoleCounts = data?['userCounts']?[userId]?[userRole] as Map<String, dynamic>?;

        if (userRoleCounts != null && userRoleCounts.isNotEmpty) {
          initialAlreadyCounted = true;
          userRoleCounts.forEach((productId, productDetails) {
            if (productDetails is Map && productDetails.containsKey('count')) {
              initialSavedCounts[productId] = (productDetails['count'] as num? ?? 0).toInt();
            }
          });

          if (_selectedDate.difference(DateTime.now()).inDays == 0) { // Sadece bugün için satış kontrolü
            final bool overallSalesCompleted = data?['salesCompleted'] == true;
            if (overallSalesCompleted) {
              initialDisableEdit = true;
              print("$selectedDateStr için genel satışlar tamamlanmış. Düzenleme devre dışı.");
            } else {
              final salesData = data?['sales'] as Map<String, dynamic>?;
              if (salesData != null) {
                for (String countedProductId in initialSavedCounts.keys) {
                  if (salesData.containsKey(countedProductId)) {
                    final productSaleInfo = salesData[countedProductId] as Map<String, dynamic>?;
                    if (productSaleInfo != null && (productSaleInfo['sales'] as num? ?? 0) > 0) {
                      initialDisableEdit = true;
                      print("$countedProductId ürünü için satış bulundu. Düzenleme devre dışı.");
                      break;
                    }
                  }
                }
              }
            }
          }
        }
      }
    } catch (e) {
      print("İlk sayım durumu yüklenirken hata: $e");
      initialDisableEdit = true;
    }

    if (mounted) {
      setState(() {
        _alreadyCounted = initialAlreadyCounted;
        _savedCounts = initialSavedCounts;
        _disableEditDueToSalesOrCompletion = initialDisableEdit;

        if (!initialAlreadyCounted) { // Bugün için sayım YOKSA, otomatik başlat
          _isCountStarted = true;
          _countStartTime = DateTime.now();
          _countedQuantities.clear(); // Yeni sayım için temiz olduğundan emin ol
          _controllers.forEach((key, controller) { // Kontrolcüleri temizle
             controller.text = ""; // HintText'in görünmesi için
          });
        }
        // Eğer initialAlreadyCounted true ise, _isCountStarted false kalır,
        // kullanıcı "Düzenle" butonuna basana kadar.
        _isLoadingInitialStatus = false;
      });
    }
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.phoneNumber;
    final userRole = authProvider.role;
    final selectedDateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);

    if (_isLoadingInitialStatus) { // _isCountStarted kontrolü kaldırıldı, sadece yükleme durumuna bak
      return Scaffold(body: Center(child: CircularProgressIndicator(key: const Key("loadingIndicatorMain"))));
    }

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Text('Günlük Sayım', style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
        backgroundColor: colorScheme.secondaryContainer,
        centerTitle: true,
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: _isCountStarted
                ? Column( // SAYIM BAŞLADIYSA (yeni veya düzenleme): Özet Kartı + Ürün Listesi/Kaydet Butonu
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
                        child: Card(
                          color: colorScheme.surfaceContainerLow,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Grubunuz', style: textTheme.labelMedium?.copyWith(color: colorScheme.primary)),
                                    Text(AuthProvider.getDisplayRole(userRole), style: textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600)),
                                  ],
                                ),
                                StreamBuilder<QuerySnapshot>(
                                  stream: FirebaseFirestore.instance.collection('products').where('role', isEqualTo: userRole).snapshots(),
                                  builder: (context, productSnapshotForSummary) {
                                    int totalProducts = 0;
                                    if (productSnapshotForSummary.hasData) {
                                      totalProducts = productSnapshotForSummary.data!.docs.length;
                                    }
                                    return Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                         Text('Toplam Ürün: $totalProducts', style: textTheme.bodyMedium),
                                         Text('Girilen: ${_countedQuantities.length}', style: textTheme.bodyMedium),
                                      ],
                                    );
                                  }
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: StreamBuilder<QuerySnapshot>(
                          stream: FirebaseFirestore.instance.collection('products').where('role', isEqualTo: userRole).snapshots(),
                          builder: (context, productSnapshot) {
                            if (productSnapshot.connectionState == ConnectionState.waiting) {
                              return Center(child: CircularProgressIndicator(key: const Key("loadingIndicatorProducts")));
                            }
                            if (productSnapshot.hasError) {
                              return Center(child: Text("Ürünler yüklenirken hata: ${productSnapshot.error}", style: TextStyle(color: colorScheme.error)));
                            }
                            if (!productSnapshot.hasData || productSnapshot.data!.docs.isEmpty) {
                              return Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.no_backpack_rounded, size: 80, color: colorScheme.outline.withOpacity(0.5)),
                                    const SizedBox(height: 16),
                                    Text('Size atanmış ürün bulunmamaktadır.', style: textTheme.titleMedium?.copyWith(color: colorScheme.outline)),
                                  ],
                                ),
                              );
                            }

                            final products = productSnapshot.data!.docs.map((doc) {
                              final data = doc.data() as Map<String, dynamic>;
                              return {
                                'id': doc.id,
                                'name': data['name'] ?? 'İsimsiz Ürün',
                                'code': data['code'] ?? 'Kod Yok',
                                'category': data['category'] ?? 'Kategori Yok',
                                'stock': (data['stock'] as num? ?? 0).toInt(),
                              };
                            }).toList();

                            final allProductsCounted = products.isNotEmpty && products.every((p) {
                              final ctrl = _controllers[p['id']];
                              if (ctrl == null) return false;
                              final val = int.tryParse(ctrl.text);
                              return val != null && val >= 0 && ctrl.text.isNotEmpty;
                            });

                            return Column(
                              children: [
                                Expanded(
                                  child: ListView.builder(
                                    padding: const EdgeInsets.only(bottom: 16),
                                    itemCount: products.length,
                                    itemBuilder: (context, i) {
                                      final product = products[i];
                                      final productId = product['id'] as String;
                                      final int stockCount = product['stock'] as int? ?? 0;

                                      if (!_controllers.containsKey(productId)) {
                                        // Düzenleme modunda _countedQuantities dolu olacak, yeni sayımda boş olacak.
                                        final initialText = _countedQuantities[productId]?.toString() ?? "";
                                        _controllers[productId] = TextEditingController(text: initialText);
                                      } else {
                                        // Eğer _isCountStarted true ise ve controller'daki değer _countedQuantities ile eşleşmiyorsa güncelle (düzenleme için)
                                        // Bu, _loadInitialCountStatusAndCheckSales'ten sonra _isCountStarted true olduğunda
                                        // _countedQuantities'in _savedCounts'tan doldurulması durumunu ele alır.
                                        final currentControllerText = _controllers[productId]!.text;
                                        final currentQuantityText = _countedQuantities[productId]?.toString() ?? "";
                                        if (_isCountStarted && currentControllerText != currentQuantityText) {
                                           _controllers[productId]!.text = currentQuantityText;
                                           _controllers[productId]!.selection = TextSelection.fromPosition(
                                               TextPosition(offset: _controllers[productId]!.text.length),
                                           );
                                        }
                                      }


                                      bool hasValidInput = _controllers[productId]?.text.isNotEmpty == true && int.tryParse(_controllers[productId]!.text) != null && int.parse(_controllers[productId]!.text) >=0 ;

                                      return AnimatedContainer(
                                        duration: const Duration(milliseconds: 250),
                                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                        decoration: BoxDecoration(
                                          color: hasValidInput ? colorScheme.surfaceContainerHighest : colorScheme.surface,
                                          borderRadius: BorderRadius.circular(24),
                                          border: Border.all(
                                            color: hasValidInput ? colorScheme.primary : colorScheme.outlineVariant,
                                            width: 1.3,
                                          ),
                                        ),
                                        child: Padding(
                                          padding: const EdgeInsets.all(20),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(product['name'].toString().toUpperCase(), style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                                              const SizedBox(height: 10),
                                              Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                children: [
                                                  Row(
                                                    children: [
                                                      Icon(Icons.inventory_2_outlined, color: colorScheme.outline, size: 20),
                                                      const SizedBox(width: 4),
                                                      Text('Stok: $stockCount', style: textTheme.bodyLarge),
                                                    ],
                                                  ),
                                                  Text(product['code'].toString(), style: textTheme.labelMedium?.copyWith(color: colorScheme.outline)),
                                                ],
                                              ),
                                              const SizedBox(height: 12),
                                              TextField(
                                                key: ValueKey(productId),
                                                enabled: _isCountStarted,
                                                keyboardType: TextInputType.number,
                                                decoration: InputDecoration(
                                                  labelText: 'Bugünkü Sayım Adedi',
                                                  hintText: "0",
                                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                                                  prefixIcon: Icon(Icons.edit_rounded, color: colorScheme.primary),
                                                  filled: true,
                                                  fillColor: colorScheme.surfaceContainerLow,
                                                ),
                                                style: textTheme.titleMedium,
                                                controller: _controllers[productId],
                                                onChanged: (value) {
                                                  final number = int.tryParse(value);
                                                  setState(() {
                                                    if (number != null && number >= 0) {
                                                      _countedQuantities[productId] = number;
                                                    } else if (value.isEmpty) {
                                                      _countedQuantities.remove(productId);
                                                    } else {
                                                      _countedQuantities.remove(productId);
                                                    }
                                                  });
                                                },
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(24.0),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: FilledButton.icon(
                                          key: const Key('saveCountButtonStream'),
                                          icon: _isSubmittingCount
                                              ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 3, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)))
                                              : const Icon(Icons.check_circle_outline_rounded, size: 28),
                                          label: const Text('Sayımı Kaydet'),
                                          style: FilledButton.styleFrom(
                                            minimumSize: const Size.fromHeight(60),
                                            backgroundColor: colorScheme.primary,
                                            foregroundColor: colorScheme.onPrimary,
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                            textStyle: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                                          ),
                                          onPressed: (_isSubmittingCount || !allProductsCounted)
                                              ? null
                                              : () async {
                                                  setState(() => _isSubmittingCount = true);
                                                  final batch = FirebaseFirestore.instance.batch();
                                                  final countsDocRef = FirebaseFirestore.instance.collection('inventoryCounts').doc(selectedDateStr);
                                                  Map<String, dynamic> productCountsForRole = {};
                                                  for (final productData in products) {
                                                    final id = productData['id'] as String;
                                                    final qty = _countedQuantities[id] ?? 0;
                                                    productCountsForRole[id] = {
                                                      'count': qty, 'name': productData['name'], 'code': productData['code'], 'category': productData['category'],
                                                    };
                                                  }
                                                  Map<String, dynamic> dataToSave = {
                                                    'userCounts.$userId.$userRole': productCountsForRole,
                                                    'date': selectedDateStr, 'lastUpdatedBy': userId, 'lastUpdateTime': FieldValue.serverTimestamp(),
                                                    'userCounts.$userId.rolesCompleted.$userRole': true,
                                                  };
                                                  if (_countStartTime != null) {
                                                    final endTime = DateTime.now();
                                                    final duration = endTime.difference(_countStartTime!);
                                                    dataToSave['userCounts.$userId.$userRole.metadata'] = {
                                                      'startTime': _countStartTime!.toIso8601String(), 'endTime': endTime.toIso8601String(), 'durationInSeconds': duration.inSeconds,
                                                    };
                                                  }
                                                  batch.set(countsDocRef, dataToSave, SetOptions(merge: true));
                                                  try {
                                                    await batch.commit();
                                                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sayım başarıyla kaydedildi!'), backgroundColor: Colors.green));
                                                    // Sayım kaydedildikten sonra, _isCountStarted false olmalı ki "Düzenle" butonu görünsün.
                                                    // _loadInitialCountStatusAndCheckSales çağrısı bunu yönetecek.
                                                    setState(() {
                                                      _isSubmittingCount = false;
                                                      // _isCountStarted = false; // Bu _loadInitial... tarafından ayarlanacak
                                                      _countStartTime = null;
                                                      // _alreadyCounted ve _savedCounts _loadInitial... tarafından güncellenecek
                                                    });
                                                    _loadInitialCountStatusAndCheckSales(); // Durumu yeniden yükle
                                                  } catch (e) {
                                                    print("Kaydetme hatası: $e");
                                                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Sayım kaydedilemedi: $e'), backgroundColor: Colors.red));
                                                    setState(() => _isSubmittingCount = false);
                                                  }
                                                },
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    ],
                  )
                : Padding( // SAYIM BAŞLAMADIYSA (ve yükleme bittiyse): Sadece "Düzenle" butonu (eğer _alreadyCounted true ise)
                    padding: const EdgeInsets.all(24.0),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.rule_rounded, size: 100, color: colorScheme.primary.withOpacity(0.6)),
                          const SizedBox(height: 20),
                          Text( // Bu metin _alreadyCounted'a göre değişecek, _loadInitial... sonrası
                            _alreadyCounted
                             ? "Bugünkü sayım daha önce yapılmış."
                             : "Bugün için sayım bulunamadı.", // Bu durum _isCountStarted true olacağı için normalde görünmemeli
                            textAlign: TextAlign.center,
                            style: textTheme.titleMedium,
                          ),
                          const SizedBox(height: 30),

                          if (_alreadyCounted) ...[ // Bugün için sayım VARSA
                            ElevatedButton.icon(
                              key: const Key('editCountButtonCentered'),
                              icon: const Icon(Icons.edit_note_rounded),
                              label: const Text('Bugünkü Sayımı Düzenle'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _disableEditDueToSalesOrCompletion ? colorScheme.onSurface.withOpacity(0.12) : colorScheme.secondary,
                                foregroundColor: _disableEditDueToSalesOrCompletion ? colorScheme.onSurface.withOpacity(0.38) : colorScheme.onSecondary,
                                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                                textStyle: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              onPressed: _disableEditDueToSalesOrCompletion ? null : () {
                                setState(() {
                                  _isCountStarted = true; _countStartTime = DateTime.now();
                                  _countedQuantities.clear(); _countedQuantities.addAll(_savedCounts);
                                  _savedCounts.forEach((productId, count) {
                                    if(_controllers.containsKey(productId)) {
                                      _controllers[productId]!.text = count.toString();
                                    } else {
                                      _controllers[productId] = TextEditingController(text: count.toString());
                                    }
                                  });
                                });
                              },
                            ),
                            if(_disableEditDueToSalesOrCompletion)
                              Padding(
                                padding: const EdgeInsets.only(top: 16.0),
                                child: Text("Satış yapıldığından bu sayım düzenlenemez.", style: textTheme.bodyMedium?.copyWith(color: colorScheme.error), textAlign: TextAlign.center,),
                              )
                          ]
                          // Eğer _alreadyCounted false ise, _isCountStarted true olacağı için bu bloğa girilmeyecek,
                          // dolayısıyla "Sayımı Başlat" butonuna burada gerek yok.
                        ],
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
