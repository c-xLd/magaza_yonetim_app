import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class InventoryCountScreen extends StatefulWidget {
  const InventoryCountScreen({super.key});

  @override
  State<InventoryCountScreen> createState() => _InventoryCountScreenState();
}

class _InventoryCountScreenState extends State<InventoryCountScreen> {
  final Map<String, int> _countedQuantities = {};
  bool _isLoading = false;
  DateTime _selectedDate = DateTime.now();
  Map<String, int> _savedCounts = {};
  bool _alreadyCounted = false;
  final Map<String, TextEditingController> _controllers = {};

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
    final today = DateTime.now();
    final todayStr = "${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}";
    final selectedDateStr = "${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}";
    final userId = Provider.of<AuthProvider>(context, listen: false).phoneNumber;
    final userRole = Provider.of<AuthProvider>(context, listen: false).role;

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('inventoryCounts').doc(selectedDateStr).get(),
      builder: (context, countSnapshot) {
        if (countSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        Map<String, dynamic>? countData = countSnapshot.data?.data() as Map<String, dynamic>?;
        Map<String, dynamic> userCounts = {};
        if (countData != null && countData['userCounts'] != null && countData['userCounts'][userId] != null) {
          userCounts = countData['userCounts'][userId] as Map<String, dynamic>;
          _alreadyCounted = true;
          _savedCounts = userCounts.map((k, v) => MapEntry(k, (v as Map)['count'] ?? 0));
        } else {
          _alreadyCounted = false;
          _savedCounts = {};
        }

        return Scaffold(
          backgroundColor: colorScheme.surface,
          appBar: AppBar(
            title: Text('Günlük Sayım', style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
            actions: [
              IconButton(
                icon: Icon(Icons.calendar_today_rounded, color: colorScheme.primary, size: 22),
                tooltip: 'Tarih Seç',
                onPressed: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate,
                    firstDate: DateTime.now().subtract(const Duration(days: 1)),
                    lastDate: DateTime.now(),
                    locale: const Locale('tr', 'TR'),
                  );
                  if (picked != null) {
                    setState(() {
                      _selectedDate = picked;
                    });
                  }
                },
              ),
            ],
            backgroundColor: colorScheme.secondaryContainer,
            centerTitle: true,
            elevation: 0,
          ),
          body: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('products').snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final docs = snapshot.data!.docs;
              if (docs.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.inventory_2_rounded, size: 90, color: colorScheme.primary.withOpacity(0.18)),
                      const SizedBox(height: 18),
                      Text('Bugün için ürün yok.', style: textTheme.headlineSmall?.copyWith(color: colorScheme.outline)),
                      const SizedBox(height: 8),
                      Text('Yönetici yeni ürün eklediğinde burada göreceksiniz.', style: textTheme.bodyLarge?.copyWith(color: colorScheme.outline)),
                    ],
                  ),
                );
              }
              final products = docs.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                return {
                  'id': doc.id,
                  'name': data['name'] ?? '',
                  'code': data['code'] ?? '',
                  'category': data['category'] ?? '',
                  'expectedStock': data['expectedStock'] ?? 0,
                  'stock': data['stock'] ?? 0,
                  'role': data['role'] ?? 'staff',
                };
              }).where((product) => product['role'] == userRole).toList();

              final allCounted = products.isNotEmpty && products.every((p) {
                final ctrl = _controllers[p['id']];
                if (ctrl == null) return false;
                final val = int.tryParse(ctrl.text);
                // 0 ve 0'dan büyük değerler kabul
                return val != null && val >= 0 && ctrl.text.isNotEmpty;
              });

              return Column(
                children: [
                  // Kompakt özet kartı
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
                                Text('Grubu', style: textTheme.labelMedium?.copyWith(color: colorScheme.primary)),
                                Consumer<AuthProvider>(
                                  builder: (context, auth, _) {
                                    final role = auth.role;
                                    return Text(
                                      AuthProvider.getDisplayRole(role),
                                      style: textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
                                    );
                                  },
                                ),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text('Toplam: ${products.length}', style: textTheme.bodyMedium),
                                Text('Girilen: ${_countedQuantities.length}', style: textTheme.bodyMedium),
                                Text('Kalan: ${products.length - _countedQuantities.length}', style: textTheme.bodyMedium?.copyWith(color: colorScheme.primary)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // M3 Expressive ürün listesi
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.only(bottom: 16),
                      itemCount: products.length,
                      itemBuilder: (context, i) {
                        final product = products[i];
                        final productId = product['id'];
                        final countedQuantity = _alreadyCounted
                            ? (_savedCounts[productId] ?? 0)
                            : (_countedQuantities[productId] ?? 0);
                        if (!_controllers.containsKey(productId)) {
                          _controllers[productId] = TextEditingController(text: countedQuantity.toString());
                        } else {
                          if (_alreadyCounted && _controllers[productId]!.text != (_savedCounts[productId] ?? 0).toString()) {
                            _controllers[productId]!.text = (_savedCounts[productId] ?? 0).toString();
                            _controllers[productId]!.selection = TextSelection.fromPosition(
                              TextPosition(offset: _controllers[productId]!.text.length),
                            );
                          }
                          if (!_alreadyCounted && _controllers[productId]!.text != countedQuantity.toString()) {
                            _controllers[productId]!.text = countedQuantity.toString();
                            _controllers[productId]!.selection = TextSelection.fromPosition(
                              TextPosition(offset: _controllers[productId]!.text.length),
                            );
                          }
                        }
                        // Dünkü sayım veya stok bilgisini göstermek için FutureBuilder ekle
                        return FutureBuilder<int?>(
                          future: () async {
                            // Eğer seçili günün sayımı yoksa, bir önceki günün sayımını getir
                            if (!_alreadyCounted) {
                              final prevDate = _selectedDate.subtract(const Duration(days: 1));
                              final prevDateStr = "${prevDate.year}-${prevDate.month.toString().padLeft(2, '0')}-${prevDate.day.toString().padLeft(2, '0')}";
                              final prevDoc = await FirebaseFirestore.instance.collection('inventoryCounts').doc(prevDateStr).get();
                              if (prevDoc.exists) {
                                final prevData = prevDoc.data();
                                if (prevData != null && prevData['userCounts'] != null && prevData['userCounts'][userId] != null) {
                                  final prevUserCounts = prevData['userCounts'][userId] as Map<String, dynamic>;
                                  if (prevUserCounts[productId] != null && prevUserCounts[productId]['count'] != null) {
                                    return prevUserCounts[productId]['count'] as int;
                                  }
                                }
                              }
                            }
                            // Eğer dünkü sayım yoksa stok bilgisini döndür
                            return product['stock'] as int?;
                          }(),
                          builder: (context, snapshot) {
                            int? prevCountOrStock = snapshot.data;
                            return AnimatedContainer(
                              duration: const Duration(milliseconds: 250),
                              curve: Curves.easeInOut,
                              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: countedQuantity > 0 ? colorScheme.surfaceContainerHighest : colorScheme.surface,
                                borderRadius: BorderRadius.circular(24),
                                boxShadow: [
                                  if (countedQuantity > 0)
                                    BoxShadow(
                                      color: colorScheme.primary.withOpacity(0.10),
                                      blurRadius: 16,
                                      offset: const Offset(0, 4),
                                    ),
                                ],
                                border: Border.all(
                                  color: countedQuantity > 0 ? colorScheme.primary : colorScheme.outlineVariant,
                                  width: 1.3,
                                ),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(20),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            product['name'].toString().toUpperCase(),
                                            style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600, fontSize: 15),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          children: [
                                            Icon(Icons.history, color: colorScheme.outline, size: 20),
                                            const SizedBox(width: 4),
                                            Text(
                                              !_alreadyCounted && prevCountOrStock != null
                                                  ? 'Dünkü Sayım: $prevCountOrStock'
                                                  : 'Stok: ${product['stock'] ?? 0}',
                                              style: textTheme.bodyLarge,
                                            ),
                                          ],
                                        ),
                                        Text(product['code'], style: textTheme.labelMedium?.copyWith(color: colorScheme.outline, fontSize: 13)),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    TextField(
                                      enabled: (!_alreadyCounted && (_selectedDate.difference(DateTime.now()).inDays == 0 || _selectedDate.difference(DateTime.now()).inDays == -1)),
                                      keyboardType: TextInputType.number,
                                      decoration: InputDecoration(
                                        labelText: 'Bugünkü Sayım',
                                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                                        prefixIcon: Icon(Icons.edit, color: colorScheme.primary),
                                        filled: true,
                                        fillColor: colorScheme.surfaceContainerLow,
                                      ),
                                      style: textTheme.titleMedium,
                                      controller: _controllers[productId],
                                      onChanged: (value) {
                                        final number = int.tryParse(value);
                                        if (number != null && number >= 0) {
                                          _countedQuantities[productId] = number;
                                        } else {
                                          _countedQuantities.remove(productId);
                                        }
                                        setState(() {});
                                      },
                                    ),
                                  ],
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ),
                  // M3 Expressive butonlar
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
                    child: Row(
                      children: [
                        Expanded(
                          child: FilledButton.icon(
                            style: FilledButton.styleFrom(
                              minimumSize: const Size.fromHeight(60),
                              backgroundColor: _isLoading ? colorScheme.primaryContainer : colorScheme.primary,
                              foregroundColor: colorScheme.onPrimary,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                              elevation: 4,
                              textStyle: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, letterSpacing: 0.2),
                              shadowColor: colorScheme.shadow.withOpacity(0.18),
                            ),
                            onPressed: (_isLoading || _alreadyCounted) ? null : () async {
                              setState(() => _isLoading = true);
                              // Firestore'a seçilen günün sayımını kaydet
                              final batch = FirebaseFirestore.instance.batch();
                              final userCountsUpdate = <String, dynamic>{};
                              for (final product in products) {
                                final id = product['id'];
                                final qty = _countedQuantities[id] ?? 0;
                                final role = product['role'] ?? 'staff';
                                if (!userCountsUpdate.containsKey(role)) {
                                  userCountsUpdate[role] = {};
                                }
                                userCountsUpdate[role][id] = {
                                  'count': qty,
                                  'name': product['name'],
                                  'code': product['code'],
                                  'category': product['category'],
                                  'role': role,
                                };
                              }
                              batch.set(
                                FirebaseFirestore.instance.collection('inventoryCounts').doc(selectedDateStr),
                                {
                                  'date': selectedDateStr,
                                  'userCounts': {userId: userCountsUpdate},
                                  'countCompleted': true,
                                },
                                SetOptions(merge: true),
                              );
                              await batch.commit();
                              setState(() => _isLoading = false);
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sayım kaydedildi!')));
                            },
                            icon: _isLoading
                                ? const SizedBox(width: 28, height: 28, child: CircularProgressIndicator(strokeWidth: 3, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)))
                                : const Icon(Icons.check_circle_outline, size: 32),
                            label: const Text('Kaydet'),
                          ),
                        ),
                        const SizedBox(width: 18),
                        Expanded(
                          child: FilledButton.icon(
                            style: FilledButton.styleFrom(
                              minimumSize: const Size.fromHeight(60),
                              backgroundColor: (_alreadyCounted && (_selectedDate.difference(DateTime.now()).inDays == 0)) ? colorScheme.secondary : colorScheme.secondaryContainer,
                              foregroundColor: colorScheme.onSecondary,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                              elevation: 4,
                            ),
                            onPressed: (_alreadyCounted && (_selectedDate.difference(DateTime.now()).inDays == 0))
                                ? () {
                                    setState(() {
                                      _alreadyCounted = false;
                                    });
                                  }
                                : null,
                            icon: const Icon(Icons.edit_note, size: 32),
                            label: const Text('Düzenle'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }
}