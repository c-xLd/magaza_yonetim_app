import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../providers/auth_provider.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class InventorySalesScreen extends StatefulWidget {
  const InventorySalesScreen({super.key});

  @override
  State<InventorySalesScreen> createState() => _InventorySalesScreenState();
}

class _InventorySalesScreenState extends State<InventorySalesScreen> {
  final Map<String, int> _salesQuantities = {};
  bool _isLoading = false;
  bool _alreadySaved = false;
  final Map<String, TextEditingController> _controllers = {};
  final Map<String, int> _yesterdayCounts = {};
  final List<String> _waitingRoles = [];
  DateTime _selectedDate = DateTime.now();
  List<DateTime> _enabledDates = [];

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
    final formattedDate = DateFormat('d MMMM y', 'tr_TR').format(_selectedDate);
    final yesterday = _selectedDate.subtract(const Duration(days: 1));
    final yesterdayStr = "${yesterday.year}-${yesterday.month.toString().padLeft(2, '0')}-${yesterday.day.toString().padLeft(2, '0')}";
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.phoneNumber;
    final userRole = authProvider.role;

    // 3. STAFF erişim engeli
    if (userRole == 'staff') {
      return Scaffold(
        appBar: AppBar(title: const Text('Satış Girişi')),
        body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
              Icon(Icons.lock_outline, size: 80, color: colorScheme.primary.withOpacity(0.18)),
              const SizedBox(height: 18),
              Text('Erişim Yetkiniz Yok', style: textTheme.titleLarge?.copyWith(color: colorScheme.outline)),
              const SizedBox(height: 8),
              Text('Bu sayfaya sadece yönetici ve mağaza sorumlusu erişebilir.', style: textTheme.bodyLarge?.copyWith(color: colorScheme.outline)),
                const SizedBox(height: 24),
                FilledButton.icon(
                onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.arrow_back_rounded),
                  label: const Text('Geri Dön'),
              ),
            ],
          ),
        ),
      );
    }

    // Takvimde sadece sayım yapılmış ve satışı girilmemiş günler seçilebilsin
    // Bunu ilk FutureBuilder ile, sayım ve satış tamamlanma durumlarını çekerek belirleyeceğiz
    return FutureBuilder<QuerySnapshot>(
      future: FirebaseFirestore.instance.collection('inventoryCounts').get(),
      builder: (context, allCountsSnapshot) {
        if (allCountsSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        final allDocs = allCountsSnapshot.data?.docs ?? [];
        _enabledDates = allDocs
          .where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final countCompleted = data['countCompleted'] == true;
            final salesCompleted = data.containsKey('salesCompleted') ? data['salesCompleted'] == true : false;
            return countCompleted && !salesCompleted;
          })
          .map((doc) {
            final parts = doc.id.split('-');
            return DateTime(
              int.parse(parts[0]),
              int.parse(parts[1]),
              int.parse(parts[2]),
            );
          }).toList();
        // Eğer seçili gün uygun değilse, ilk uygun güne ayarla
        if (!_enabledDates.any((d) => d.year == _selectedDate.year && d.month == _selectedDate.month && d.day == _selectedDate.day)) {
          if (_enabledDates.isNotEmpty) {
            _selectedDate = _enabledDates.first;
          }
        }
        final selectedDateStr = "${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}";
        final formattedDate = DateFormat('d MMMM y', 'tr_TR').format(_selectedDate);
        final yesterday = _selectedDate.subtract(const Duration(days: 1));
        final yesterdayStr = "${yesterday.year}-${yesterday.month.toString().padLeft(2, '0')}-${yesterday.day.toString().padLeft(2, '0')}";

        // 1. Seçili günün sayım verisini çek
        return FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance.collection('inventoryCounts').doc(selectedDateStr).get(),
          builder: (context, countSnapshot) {
            if (countSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(body: Center(child: CircularProgressIndicator()));
            }
            Map<String, dynamic>? countData = countSnapshot.data?.data() as Map<String, dynamic>?;
            Map<String, dynamic> userCounts = {};
            if (countData != null && countData['userCounts'] != null) {
              userCounts = countData['userCounts'] as Map<String, dynamic>;
            }

            // --- KULLANICI GRUBU (ROLE) KONTROLÜ ---
            // Eksik rollerin bulunması için Firestore'dan user koleksiyonunu çekiyoruz
            return FutureBuilder<QuerySnapshot>(
              future: FirebaseFirestore.instance.collection('users').get(),
              builder: (context, userSnapshot) {
                if (!userSnapshot.hasData) {
                  return const Scaffold(body: Center(child: CircularProgressIndicator()));
                }
                final userDocs = userSnapshot.data!.docs;
                // userId -> role eşlemesi
                Map<String, String> userIdToRole = {};
                for (final doc in userDocs) {
                  final data = doc.data() as Map<String, dynamic>;
                  userIdToRole[doc.id] = data['role'] ?? '';
                }
                // Tüm roller
                final allRoles = userIdToRole.values.toSet();
                // Hangi roller sayım yapmış?
                final countedRoles = <String>{};
                (userCounts).forEach((uid, val) {
                  final role = userIdToRole[uid];
                  if (role != null && (val as Map).isNotEmpty) {
                    countedRoles.add(role);
                  }
                });

                

                // --- Tüm gruplar sayım yaptıysa, normal satış ekranı devam etsin ---
                // Ürünleri Firestore'dan çek
                return StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance.collection('products').snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final docs = snapshot.data!.docs;
                    // Ürün yoksa, bekleyen kullanıcı grubu mesajı göster ve girişe izin verme
                    if (docs.isEmpty) {
                      return Scaffold(
                        appBar: AppBar(
                          title: Text('Satış Girişi', style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                          actions: [
                            IconButton(
                              icon: Icon(Icons.calendar_today_rounded, color: colorScheme.primary, size: 22),
                              tooltip: 'Tarih Seç',
                              onPressed: () async {
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: _selectedDate,
                                  firstDate: DateTime(2023, 1, 1),
                                  lastDate: DateTime.now(),
                                  locale: const Locale('tr', 'TR'),
                                  selectableDayPredicate: (date) {
                                    return _enabledDates.any((d) => d.year == date.year && d.month == date.month && d.day == date.day);
                                  },
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
                        body: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.inventory_2_rounded, size: 90, color: colorScheme.primary.withOpacity(0.18)),
                            ],
                          ),
                        ),
                      );
                    }
                    List<Map<String, dynamic>> products = docs.map((doc) {
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
                    }).toList();
                    // Seçili günün sayım verisini bul
                    Map<String, int> sayimVerisi = {};
                    if (userCounts.isNotEmpty) {
                      userCounts.forEach((userId, productsMap) {
                        (productsMap as Map<String, dynamic>).forEach((productId, productData) {
              final count = (productData as Map<String, dynamic>)['count'] ?? 0;
                        sayimVerisi[productId] = (sayimVerisi[productId] ?? 0) + (count as int);
              });
            });
                    }
                    final allSalesEntered = products.isNotEmpty && products.every((p) => _salesQuantities[p['id']] != null && _salesQuantities[p['id']]! > 0);
            return Scaffold(
                      backgroundColor: colorScheme.surface,
                      appBar: AppBar(
                        title: Text('Satış Girişi', style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                        actions: [
                          IconButton(
                            icon: Icon(Icons.calendar_today_rounded, color: colorScheme.primary, size: 22),
                            tooltip: 'Tarih Seç',
                            onPressed: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: _selectedDate,
                                firstDate: DateTime(2023, 1, 1),
                                lastDate: DateTime.now(),
                                locale: const Locale('tr', 'TR'),
                                selectableDayPredicate: (date) {
                                  return _enabledDates.any((d) => d.year == date.year && d.month == date.month && d.day == date.day);
                                },
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
                      body: Column(
                        children: [
                          Expanded(
                            child: ListView.builder(
                              padding: const EdgeInsets.only(bottom: 16),
                              itemCount: products.length,
                              itemBuilder: (context, i) {
                                final product = products[i];
                                final productId = product['id'];
                                final salesQuantity = _salesQuantities[productId] ?? 0;
                                final sayimCount = sayimVerisi[productId] ?? 0;
                                if (!_controllers.containsKey(productId)) {
                                  _controllers[productId] = TextEditingController(text: salesQuantity > 0 ? salesQuantity.toString() : '');
                                }
                                return AnimatedContainer(
                                  duration: const Duration(milliseconds: 250),
                                  curve: Curves.easeInOut,
                                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: salesQuantity > 0 ? colorScheme.surfaceContainerHighest : colorScheme.surface,
                                    borderRadius: BorderRadius.circular(24),
                                    boxShadow: [
                                      if (salesQuantity > 0)
                                        BoxShadow(
                                          color: colorScheme.primary.withOpacity(0.10),
                                          blurRadius: 16,
                                          offset: const Offset(0, 4),
                                        ),
                                    ],
                                    border: Border.all(
                                      color: salesQuantity > 0 ? colorScheme.primary : colorScheme.outlineVariant,
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
                                            Text('Sayım: $sayimCount', style: textTheme.bodyLarge),
                                          ],
                                        ),
                                        Text(product['code'], style: textTheme.labelMedium?.copyWith(color: colorScheme.outline, fontSize: 13)),
                                        ],
                    ),const SizedBox(height: 12),
                                        TextField(
                                          key: ValueKey(productId),
                                          enabled: !_alreadySaved,
                                          keyboardType: TextInputType.number,
                                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                          decoration: InputDecoration(
                                            labelText: 'Bugünkü Satış',
                                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                                            prefixIcon: Icon(Icons.point_of_sale, color: colorScheme.primary),
                                            filled: true,
                                            fillColor: colorScheme.surfaceContainerLow,
                                          ),
                                          style: textTheme.titleMedium,
                                          controller: _controllers[productId],
                                          onChanged: (value) {
                                            final number = int.tryParse(value) ?? 0;
                                            if (number <= 0 && value.isNotEmpty) {
                                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                                _controllers[productId]?.clear();
                                              });
                                              setState(() {
                                                _salesQuantities.remove(productId);
                                              });
                                            } else {
                                              setState(() {
                                                if (number > 0) {
                                                  _salesQuantities[productId] = number;
                                                } else {
                                                  _salesQuantities.remove(productId);
                                                }
                                              });
                                            }
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
                                    onPressed: (_isLoading || !allSalesEntered || _alreadySaved)
                                        ? null
                                        : () async {
                                            setState(() => _isLoading = true);
                                            // Firestore'a satışları kaydet
                                            final batch = FirebaseFirestore.instance.batch();
                                            final salesUpdate = <String, dynamic>{};
                                            for (final product in products) {
                                              final id = product['id'];
                                              final qty = _salesQuantities[id] ?? 0;
                                              salesUpdate[id] = {'sales': qty};
                                            }
                                            batch.set(
                                              FirebaseFirestore.instance.collection('inventoryCounts').doc(selectedDateStr),
                                              {
                                                'sales': salesUpdate,
                                                'salesCompleted': true,
                                              },
                                              SetOptions(merge: true),
                                            );
                                            await batch.commit();
                                            setState(() {
                                              _isLoading = false;
                                              _alreadySaved = true;
                                            });
                                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Satışlar kaydedildi!')));
                                          },
                                    icon: _isLoading
                                        ? const SizedBox(width: 28, height: 28, child: CircularProgressIndicator(strokeWidth: 3, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)))
                                        : const Icon(Icons.check_circle_outline, size: 32),
                                    label: const Text('Kaydet'),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }

  // Eksik rollerin adlarını Firestore'dan çek
  Future<List<String>> _getWaitingRoleNames(List<String> userIds) async {
    List<String> roleNames = [];
    for (final userId in userIds) {
        final userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
        if (userDoc.exists) {
        final role = userDoc.data()?['role'] ?? '';
        roleNames.add(AuthProvider.getDisplayRole(role));
      }
    }
    return roleNames;
  }
}

// Sınıfları dışarı taşıdık
class _AssistantPulseAnimation extends StatefulWidget {
  @override
  State<_AssistantPulseAnimation> createState() => _AssistantPulseAnimationState();
}

class _AssistantPulseAnimationState extends State<_AssistantPulseAnimation> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(); // Örnek içerik
  }
}

class _ProblemStockDialog extends StatefulWidget {
  final Map<String, dynamic> products;
  final Map<String, int> sales;
  final Map<String, int> counts;
  final Map<String, String> productNames;
  final VoidCallback onAllConfirmed;

  const _ProblemStockDialog({
    required this.products,
    required this.sales,
    required this.counts,
    required this.productNames,
    required this.onAllConfirmed,
  });

  @override
  State<_ProblemStockDialog> createState() => _ProblemStockDialogState();
}

class _ProblemStockDialogState extends State<_ProblemStockDialog> {
  late Map<String, bool> _confirmed;

  @override
  void initState() {
    super.initState();
    _confirmed = {for (var id in widget.sales.keys) id: false};
  }

  @override
  Widget build(BuildContext context) {
    return Container(); // Örnek içerik
  }
}
